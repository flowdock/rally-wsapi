module Wsapi
  class Object
    attr_reader :raw_data

    def initialize(raw_data)
      @raw_data = raw_data
    end

    def name
      @raw_data['_refObjectName']
    end

    def id
      @raw_data['ObjectID']
    end

    def url
      @raw_data['_ref']
    end

    def workspace
      @raw_data["Workspace"]["_refObjectName"]
    end

    def self.from_data(type, raw_data)
      if type && Wsapi.const_defined?(type)
        Wsapi.const_get(type).new(raw_data)
      else
        Object.new(raw_data)
      end
    end
  end
end
