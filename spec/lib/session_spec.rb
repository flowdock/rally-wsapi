require 'wsapi/session'
require 'uri'

describe Wsapi::Session do
  before :all do
    @token = "deadbeefdeadbeef"
    @refresh_token = "monkeymonkey"
  end

  before :each do
    @wsapi = Wsapi::Session.new(@token)
  end

  describe "API version" do
    let(:user_data) { File.read(File.join("spec", "fixtures", "wsapi", "user.json")) }

    it "defaults to API v3" do
      stub_request(:get, wsapi_url_regexp("/User/1", "v3.0")).to_return(status: 200, body: user_data)
      Wsapi::Session.new(SecureRandom.hex).get_user(1)
      expect(WebMock).to have_requested(:get, wsapi_url_regexp("/User/1", "v3.0")).once
    end

    it "allows API version to be overwritten" do
      stub_request(:get, wsapi_url_regexp("/User/1", "v2.0")).to_return(status: 200, body: user_data)
      Wsapi::Session.new(SecureRandom.hex, version: "2.0").get_user(1)
      expect(WebMock).to have_requested(:get, wsapi_url_regexp("/User/1", "v2.0")).once
    end
  end

  describe "with users" do
    before :each do
      @user_data = File.read(File.join("spec", "fixtures", "wsapi", "user.json"))
      @users_query_name_data = File.read(File.join("spec", "fixtures", "wsapi", "users_by_username.json"))
      @users_query_email_data = File.read(File.join("spec", "fixtures", "wsapi", "users_by_email.json"))
    end

    it "fetches user information" do
      stub_request(:get, wsapi_url_regexp('/User/1')).to_return(status: 200, body: @user_data)
      user = @wsapi.get_user(1)
      expect(user.name).to eq("Antti Pitkanen")
      expect(user.email).to eq("apitkanen@rallydev.com")
    end

    it "fetches current user" do
      stub_request(:get, wsapi_url_regexp('/User')).with(
        query: {"pagesize" => "200", "start" => "1", "fetch" => "true"} # must not include 'query', otherwise all users are returned
      ).to_return(status: 200, body: @user_data)
      user = @wsapi.get_current_user
      expect(user.name).to eq("Antti Pitkanen")
      expect(user.email).to eq("apitkanen@rallydev.com")
    end

    it "fetches user by username" do
      stub_request(:get, wsapi_url_regexp('/User')).with(
        query: hash_including({"pagesize" => "1", "query" => "(UserName = \"antti\")"})
      ).to_return(status: 200, body: @users_query_name_data)
      user = @wsapi.get_user_by_username("antti")
      expect(user.username).to eq("antti")
      expect(user.email).to eq("apitkanen@rallydev.com")
    end

    it "fetches users with query" do
      stub_request(:get, wsapi_url_regexp('/User')).with(
        query: hash_including({"query" => "(EmailAddress = apitkanen@rallydev.com)", "fetch" => "true"})
      ).to_return(status: 200, body: @users_query_name_data)

      users = @wsapi.get_users("EmailAddress = apitkanen@rallydev.com")
      expect(users.first.email).to eq("apitkanen@rallydev.com")
    end
  end

  describe "with projects" do
    before :each do
      @project_data = File.read(File.join("spec", "fixtures", "wsapi", "project.json"))
      @projects_data = File.read(File.join("spec", "fixtures", "wsapi", "projects.json"))
      @editors_data = File.read(File.join("spec", "fixtures", "wsapi", "editors.json"))
      stub_request(:get, wsapi_url_regexp('/Project/1')).to_return(status: 200, body: @project_data)
      stub_request(:get, wsapi_url_regexp('/Project')).to_return(status: 200, body: @projects_data)
      stub_request(:get, wsapi_url_regexp('/Project/1/Editors')).to_return(status: 200, body: @editors_data)
    end

    it "fetches given project" do
      project = @wsapi.get_project(1)
      expect(project.name).to eq("The Chuck Norris")
    end

    it "fetches all projects" do
      projects = @wsapi.get_projects
      expect(projects.size).to eq(4)
      projects.each do |project|
        expect(project.name).not_to be_nil
      end
    end

    it "fetches editors for given project" do
      editors = @wsapi.get_editors(1)
      expect(editors.length).to eq(5)
      expect(editors.first.email).to eq("gjohnson@rallydev.com")
      expect(editors.first.username).to eq("Greg")
    end
  end

  describe "with subscriptions" do
    before :each do
      @subscription_data = File.read(File.join("spec", "fixtures", "wsapi", "subscription.json"))
      stub_request(:get, wsapi_url_regexp('/Subscription/1')).to_return(status: 200, body: @subscription_data)
      stub_request(:get, wsapi_url_regexp('/Subscription')).to_return(status: 200, body: @subscription_data)
    end

    it "fetches user subscription" do
      subscription = @wsapi.get_user_subscription
      expect(subscription.name).to eq("Rally Development")
    end

    it "fetches given subscription" do
      subscription = @wsapi.get_subscription(1)
      expect(subscription.name).to eq("Rally Development")
    end
  end

  describe "with paging" do
    before :each do
      @page1 = File.read(File.join("spec", "fixtures", "wsapi", "page1.json"))
      @page2 = File.read(File.join("spec", "fixtures", "wsapi", "page2.json"))
      @page3 = File.read(File.join("spec", "fixtures", "wsapi", "page3.json"))
      stub_request(:get, wsapi_url_regexp('/Project/1/Editors')).with(
        query: {"pagesize" => "1", "start" => "1", "fetch" => "true"}
      ).to_return(status: 200, body: @page1)
      stub_request(:get, wsapi_url_regexp('/Project/1/Editors')).with(
        query: {"pagesize" => "1", "start" => "2", "fetch" => "true"}
      ).to_return(status: 200, body: @page2)
      stub_request(:get, wsapi_url_regexp('/Project/1/Editors')).with(
        query: {"pagesize" => "1", "start" => "3", "fetch" => "true"}
      ).to_return(status: 200, body: @page3)
    end

    it "fetches all the pages" do
      editors = @wsapi.get_editors(1, {start: 1, pagesize: 1})
      expect(editors.length).to eq(3)
    end
  end

  describe "with errors" do
    context "with refresh_token" do
      let(:authorization_error) { File.read(File.join("spec", "fixtures", "wsapi", "authorization_error.html")) }
      let(:refresh_token) { File.read(File.join("spec", "fixtures", "wsapi", "refresh_token.json")) }
      let(:user_data) { File.read(File.join("spec", "fixtures", "wsapi", "user.json")) }

      before :each do
        @failing_request = stub_request(:get, wsapi_url_regexp('/User/1'))
          .with(headers: {'Zsessionid' => "deadbeefdeadbeef"})
          .to_return(status: 401, body: authorization_error)
        @successful_request = stub_request(:get, wsapi_url_regexp('/User/1'))
          .with(headers: { "Zsessionid" => "new_access_token"})
          .to_return(status: 200, body: user_data)
        @refresh_token_request = stub_request(:post, Wsapi::AUTH_URL).to_return(status: 200, body: refresh_token)
      end

      it "requests a new access token with refresh token" do
        @wsapi.setup_refresh_token("foobar", "thisisasecret", @refresh_token)
        user = @wsapi.get_user(1)
        expect(user.name).to eq("Antti Pitkanen")
        expect(user.email).to eq("apitkanen@rallydev.com")

        expect(@failing_request).to have_been_made
        expect(@refresh_token_request).to have_been_made
        expect(@successful_request).to have_been_made
      end

      it "calls the block given in setup_refresh_token with new tokens" do
        expect { |b|
          @wsapi.setup_refresh_token("foobar", "thisisasecret", @refresh_token, &b)
          @wsapi.get_user(1)
        }.to yield_with_args({
          "id_token"=>"???",
          "refresh_token"=>"new_refresh_token",
          "expires_in"=>15552000,
          "token_type"=>"Bearer",
          "access_token"=>"new_access_token"
        })
      end
    end

    context "without refresh_token" do
      it "raises exception when response is 401" do
        stub_request(:get, /.*/).to_return(status: 401)

        expect {
          @wsapi.get_user_subscription
        }.to raise_error(Wsapi::AuthorizationError)
      end

      it "raises exception when response is 403" do
        stub_request(:get, /.*/).to_return(status: 403)

        expect {
          @wsapi.get_user_subscription
        }.to raise_error(Wsapi::AuthorizationError)
      end
    end

    it "raises exception with query error" do
      @error_data = File.read(File.join("spec", "fixtures", "wsapi", "query_error.json"))
      stub_request(:get, /.*/).to_return(status: 200, body: @error_data)

      expect {
        @wsapi.get_projects
      }.to raise_error(Wsapi::ApiError)
    end

    it "raises exception when object is not found" do
      @error_data = File.read(File.join("spec", "fixtures", "wsapi", "not_found_error.json"))
      stub_request(:get, /.*/).to_return(status: 200, body: @error_data)

      expect {
        @wsapi.get_user_subscription
      }.to raise_error(Wsapi::ObjectNotFoundError)
    end

    it "raises exception when response body can't be parsed" do
      stub_request(:get, /.*/).to_return(status: 423, body: "{invalid_json: ")

      expect {
        @wsapi.get_user_subscription
      }.to raise_error(Wsapi::ApiError)
    end

    it "raises exception when response is 401" do
      stub_request(:get, /.*/).to_return(status: 401)

      expect {
        @wsapi.get_user_subscription
      }.to raise_error(Wsapi::AuthorizationError)
    end

    it "raises exception when response is 500" do
      stub_request(:get, /.*/).to_return(status: 500)

      expect {
        @wsapi.get_user_subscription
      }.to raise_error(Wsapi::ApiError)
    end

    it "raises exception when response is 503" do
      stub_request(:get, /.*/).to_return(status: 503)

      expect {
        @wsapi.get_user_subscription
      }.to raise_error(Wsapi::ApiError)
    end

    it "raises a specific exception if IP address is blocked" do
      stub_request(:get, /.*/)
        .to_return(status: 404, body: File.read(File.join("spec", "fixtures", "wsapi", "ip_address_restriction.html")))
      expect {
        @wsapi.get_user_subscription
      }.to raise_error(Wsapi::IpAddressLimited)
    end
  end

  describe "with updates" do
    let(:defect_uuid) { SecureRandom.uuid }
    let(:user_id) { SecureRandom.uuid }
    let(:response_data) { File.read(File.join("spec", "fixtures", "wsapi", "defect.json")) }
    it "sends post request to api" do
      stubbed_request = stub_request(:post, wsapi_url_regexp("defect/#{defect_uuid}"))
        .with(body: { "defect" => {"Owner" => "/user/#{user_id}"}})
        .to_return({
          status: 200,
          body: response_data
        })
      @wsapi.update_artifact(:defect, defect_uuid, Owner: "/user/#{user_id}")
      expect(stubbed_request).to have_been_made
    end
  end

  def wsapi_url_regexp(path, version = "v3.0")
    base = File.join(Wsapi::WSAPI_URL, version, path).to_s
    /#{Regexp.escape(base)}(?:\?.*|\Z)/
  end
end
