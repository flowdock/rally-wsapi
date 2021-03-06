module Wsapi
  class Subscription < Wsapi::Object
    def subscription_id
      @raw_data["SubscriptionID"].to_s
    end

    def obj_id
      @raw_data["ObjectID"]
    end

    def subscription_type
      @raw_data["SubscriptionType"]
    end
  end
end
