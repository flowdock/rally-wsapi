module Wsapi
  class Project < Wsapi::Object
    def subscription
      @subscription ||= Wsapi::Subscription.new(@raw_data["Subscription"])
    end
  end
end
