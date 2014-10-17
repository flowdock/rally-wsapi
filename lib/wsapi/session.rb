require 'multi_json'
require 'faraday'

require_relative './mapper'

module Wsapi
  class StandardErrorWithResponse < StandardError
    attr_reader :response
    def initialize(msg, response = nil)
      @response = response
      super(msg)
    end
  end
  class AuthorizationError < StandardErrorWithResponse; end
  class ApiError < StandardErrorWithResponse; end
  class ObjectNotFoundError < StandardErrorWithResponse; end
  class IpAddressLimited < StandardErrorWithResponse; end

  WSAPI_URL = ENV['WSAPI_URL'] || 'https://rally1.rallydev.com/slm/webservice/'

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
      @session_id = session_id
      @workspace_id = opts[:workspace_id]
      @conn = Faraday.new(ssl: { verify: false} ) do |faraday|
        faraday.request  :url_encoded # form-encode POST params
        faraday.use WsapiAuthentication, @session_id
        faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
      end
    end

    def get_user_subscription
      response = wsapi_request(wsapi_resource_url("Subscription"))
      Mapper.get_object(response)
    end

    def get_subscription(id)
      response = wsapi_request(wsapi_resource_url("Subscription/#{id}"))
      Mapper.get_object(response)
    end

    def get_projects(opts = {})
      fetch_with_pages(opts) do |page_query|
        wsapi_request(wsapi_resource_url("Project"), opts.merge(page_query))
      end
    end

    def get_project(id)
      response = wsapi_request(wsapi_resource_url("Project/#{id}"))
      Mapper.get_object(response)
    end

    def get_current_user
      response = wsapi_request(wsapi_resource_url("User"))
      Mapper.get_object(response)
    end

    def get_user(id)
      response = wsapi_request(wsapi_resource_url("User/#{id}"))
      Mapper.get_object(response)
    end

    def get_user_by_username(username)
      response = wsapi_request(wsapi_resource_url("User"), query: "(UserName = \"#{username}\")", pagesize: 1)
      (Mapper.get_objects(response) ||[]).first
    end

    def get_team_members(project_id, opts = {})
      fetch_with_pages(opts) do |page_query|
        wsapi_request(wsapi_resource_url("Project/#{project_id}/TeamMembers"), opts.merge(page_query))
      end
    end

    def get_editors(project_id, opts = {})
      fetch_with_pages(opts) do |page_query|
        wsapi_request(wsapi_resource_url("Project/#{project_id}/Editors"), opts.merge(page_query))
      end
    end

    private

    def workspace_url
      wsapi_resource_url("Workspace/#{@workspace_id}")
    end

    def wsapi_resource_url(resource)
      File.join(WSAPI_URL, "v#{@api_version}", resource)
    end

    def wsapi_request(url, opts = {})
      response = @conn.get do |req|
        req.url url
        req.params['workspace'] = workspace_url if @workspace_id
        req.params['query'] = opts[:query] if opts[:query]
        req.params['start'] = opts[:start] || 1
        req.params['pagesize'] = opts[:pagesize] || 200
        req.params['fetch'] = opts[:fetch] || true # by default, fetch full objects
      end
      raise AuthorizationError.new("Unauthorized", response) if response.status == 401
      raise ApiError.new("Internal server error", response) if response.status == 500
      raise ApiError.new("Service unavailable", response) if response.status == 503
      raise ObjectNotFoundError.new("Object not found") if object_not_found?(response)
      raise IpAddressLimited.new("IP Address limited", response) if ip_address_limited?(response)
      response
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

