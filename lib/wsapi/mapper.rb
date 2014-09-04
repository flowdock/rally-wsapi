require 'multi_json'

require_relative './models/object'
require_relative './models/subscription'
require_relative './models/user'
require_relative './models/project'

module Wsapi
  class Mapper
    def self.get_errors(json)
      if result = json["QueryResult"]
        result["Errors"]
      elsif result = json["OperationResult"]
        result["Errors"]
      else
        []
      end
    end

    def self.get_object(response)
      json = MultiJson.load(response.body)
      if get_errors(json).empty? && json.size == 1
        Wsapi::Object.from_data(json.keys.first, json.values.first)
      else
        raise ApiError.new("Errors: #{get_errors(json).inspect}", response)
      end
    rescue MultiJson::LoadError
      raise ApiError.new("Invalid JSON response from WSAPI: #{response.body}", response)
    end

    def self.get_objects(response)
      json = MultiJson.load(response.body)
      if get_errors(json).empty? && query_result = json["QueryResult"]
        query_result["Results"].map { |object| Wsapi::Object.from_data(object["_type"], object) }
      else
        raise ApiError.new("Errors: #{get_errors(json).inspect}", response)
      end
    rescue MultiJson::LoadError
      raise ApiError.new("Invalid JSON response from WSAPI: #{response.body}", response)
    end
  end
end
