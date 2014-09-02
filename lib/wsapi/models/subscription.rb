module Wsapi
  class Subscription < Wsapi::Object
    def subscription_id
      @raw_data["SubscriptionID"].to_s
    end
  end
end
