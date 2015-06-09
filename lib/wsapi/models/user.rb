module Wsapi
  class User < Wsapi::Object
    def username
      @raw_data["UserName"]
    end

    def first_name
      @raw_data["FirstName"]
    end

    def last_name
      @raw_data["LastName"]
    end

    def name
      "#{@raw_data['FirstName']} #{@raw_data['LastName']}"
    end

    def email
      @raw_data["EmailAddress"]
    end

    def subscription_id
      @raw_data["SubscriptionID"]
    end

    def admin?
      @raw_data["SubscriptionAdmin"]
    end
  end
end
