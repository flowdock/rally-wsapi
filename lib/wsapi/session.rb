require 'multi_json'
require 'faraday'
require 'faraday_middleware'
require 'excon'

require_relative './mapper'
module Wsapi
  class StandardErrorWithResponse < StandardError
    attr_reader :response
    def initialize(msg, response = nil)
      @response = response
      super(msg)
    end
  end
  class BadRequestError < StandardErrorWithResponse; end
  class AuthorizationError < StandardErrorWithResponse; end
  class ApiError < StandardErrorWithResponse; end
  class ObjectNotFoundError < StandardErrorWithResponse; end
  class IpAddressLimited < StandardErrorWithResponse; end
  class TimeoutError < StandardError; end

  WSAPI_URL = ENV['WSAPI_URL'] || 'https://rally1.rallydev.com/slm/webservice/'
  AUTH_URL = ENV['RALLY_AUTHENTICATION_URL'] || "https://rally1.rallydev.com/login/oauth2/token"

  class WsapiAuthentication < Faraday::Middleware
    def initialize(logger, session_id)
      @session_id = session_id
      super(logger)
    end

    def call(env)
      env[:request_headers]['ZSESSIONID'] = @session_id
      @app.call(env)
    end
  end

  class Session
    attr_accessor :workspace_id

    def initialize(session_id, opts = {})
      @api_version = opts[:version] || "3.0"
      @workspace_id = opts[:workspace_id]
      @timeout = opts[:timeout]
      @conn = connection(session_id)
    end

    def setup_refresh_token(client_id, client_secret, refresh_token, &block)
      @oauth2 = {
        client_id: client_id,
        client_secret: client_secret,
        refresh_token: refresh_token,
        refresh_token_updated: block
      }
    end

    def get_user_subscription
      response = wsapi_get(wsapi_resource_url("Subscription"))
      Mapper.get_object(response)
    end

    def get_subscription(id)
      response = wsapi_get(wsapi_resource_url("Subscription/#{id}"))
      Mapper.get_object(response)
    end

    def get_subscription_by_subscription_id(subscription_id)
      response = wsapi_get(wsapi_resource_url("Subscription"), query: "(SubscriptionId = #{subscription_id})", pagesize: 1)
      (Mapper.get_objects(response) ||[]).first
    end

    def get_projects(opts = {})
      fetch_with_pages(opts) do |page_query|
        wsapi_get(wsapi_resource_url("Project"), opts.merge(page_query))
      end
    end

    def get_project(id)
      response = wsapi_get(wsapi_resource_url("Project/#{id}"))
      Mapper.get_object(response)
    end

    def get_current_user
      response = wsapi_get(wsapi_resource_url("User"))
      Mapper.get_object(response)
    end

    def get_users(query = nil)
      fetch_with_pages do |page_query|
        if query
          query_hash = { query: "(#{query})" }
          wsapi_get(wsapi_resource_url("User"), query_hash.merge(page_query))
        else
          wsapi_get(wsapi_resource_url("Users"), page_query)
        end
      end
    end

    def get_user(id)
      response = wsapi_get(wsapi_resource_url("User/#{id}"))
      Mapper.get_object(response)
    end

    def get_user_by_username(username)
      response = wsapi_get(wsapi_resource_url("User"), query: "(UserName = \"#{username}\")", pagesize: 1)
      (Mapper.get_objects(response) ||[]).first
    end

    def get_team_members(project_id, opts = {})
      fetch_with_pages(opts) do |page_query|
        wsapi_get(wsapi_resource_url("Project/#{project_id}/TeamMembers"), opts.merge(page_query))
      end
    end

    def get_editors(project_id, opts = {})
      fetch_with_pages(opts) do |page_query|
        wsapi_get(wsapi_resource_url("Project/#{project_id}/Editors"), opts.merge(page_query))
      end
    end

    def update_artifact(type, id, update_hash)
      response = wsapi_post(wsapi_resource_url("#{type}/#{id}"), "#{type}" => update_hash)
      Mapper.get_object(response)
    end

    private

    def connection(session_id)
      Faraday.new(ssl: {version: :TLSv1}) do |faraday|
        faraday.request :json
        faraday.use WsapiAuthentication, session_id
        faraday.adapter :excon
      end
    end

    def workspace_url
      wsapi_resource_url("Workspace/#{@workspace_id}")
    end

    def wsapi_resource_url(resource)
      File.join(WSAPI_URL, "v#{@api_version}", resource)
    end

    def wsapi_post(url, opts = {})
      response = wsapi_request_with_refresh_token(:post, url, opts)
      check_response_for_errors!(response)

      response
    end

    def wsapi_get(url, opts = {})
      request_options = {}
      request_options['workspace'] = workspace_url if @workspace_id
      request_options['query'] = opts[:query] if opts[:query]
      request_options['start'] = opts[:start] || 1
      request_options['pagesize'] = opts[:pagesize] || 200
      request_options['fetch'] = opts[:fetch] || true # by default, fetch full objects

      response = wsapi_request_with_refresh_token(:get, url, request_options)
      check_response_for_errors!(response)

      response
    end

    def wsapi_request_with_refresh_token(method, url, opts = {})
      response = @conn.send(method, url, opts) { |req| req.options.timeout = @timeout }
      if defined?(@oauth2) && response.status == 401
        refresh_token_response = refresh_token!

        access_token = MultiJson.load(refresh_token_response.body)["access_token"]
        @conn = connection(access_token)
        response = @conn.send(method, url, opts) { |req| req.options.timeout = @timeout } # Try again with fresh token
      end

      response
    rescue Faraday::TimeoutError
      raise TimeoutError.new("Request timed out")
    end

    def refresh_token!
      client = Faraday.new(ssl: {version: :TLSv1}) do |faraday|
        faraday.request :url_encoded
        faraday.adapter :excon
      end

      refresh_params = {
        grant_type: "refresh_token",
        refresh_token: @oauth2[:refresh_token],
        client_id: @oauth2[:client_id],
        client_secret: @oauth2[:client_secret]
      }

      response = client.post(AUTH_URL, refresh_params) { |req| req.options.timeout = @timeout }

      check_response_for_errors!(response)

      response_body = MultiJson.load(response.body)

      @oauth2[:refresh_token] = response_body["refresh_token"]
      if @oauth2[:refresh_token_updated]
        @oauth2[:refresh_token_updated].call(MultiJson.load(response.body))
      end
      response
    end

    def check_response_for_errors!(response)
      raise BadRequestError.new("Bad request", response) if response.status == 400
      raise AuthorizationError.new("Unauthorized", response) if response.status == 401 || response.status == 403
      raise ApiError.new("Internal server error", response) if response.status == 500
      raise ApiError.new("Service unavailable", response) if response.status == 503
      raise ObjectNotFoundError.new("Object not found") if object_not_found?(response)
      raise IpAddressLimited.new("IP Address limited", response) if ip_address_limited?(response)
    end

    def ip_address_limited?(response)
      limit_message = /Your IP address, (?:\d+\.?)+, is not within the allowed range that your subscription administrator has configured./
      response.status > 401 && response.body.match(limit_message)
    end

    def object_not_found?(response)
      if response.status == 200
        result = MultiJson.load(response.body)["OperationResult"]
        if result && error = result["Errors"].first
          error.match("Cannot find object to read")
        else
          false
        end
      else
        false
      end
    end

    def fetch_with_pages(opts = {}, &block)
      page_query = {
        start: opts[:start] || 1,
        pagesize: opts[:pagesize] || 100
      }
      resultCount = nil
      objects = []
      while(!resultCount || resultCount > objects.size) do
        response = yield(page_query)
        resultCount = MultiJson.load(response.body)["QueryResult"]["TotalResultCount"]
        objects += Mapper.get_objects(response)
        page_query[:start] += page_query[:pagesize]
      end
      objects
    end
  end
end

