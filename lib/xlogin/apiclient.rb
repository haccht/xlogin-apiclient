require 'json'
require 'net/http'
require 'ostruct'
require "xlogin/apiclient/version"

module Xlogin
  module APIClient
    class APIError < StandardError; end

    class Client
      def initialize(base_uri, type:, **args)
        @uri  = base_uri
        @type = type
        @args = args
      end

      def cmd(req = Request.new, &block)
        if req.kind_of?(String)
          req, _req = Request.new, req
          req.command = _req
        end

        req.xlogin = @args
        block.call(req) if block

        uri = @uri.dup
        uri.path += "/vendors/#{@type}/actions"

        http(:post, uri, req.to_h)
      rescue => e
        raise APIError.new(e.message)
      end

      private
      def http(method, uri, **args)
	http = Net::HTTP.new(uri.host, uri.port)

	klass = Net::HTTP.const_get(method.to_s.capitalize)
	req  = klass.new(uri.path)
	req["Accept"] = "application/json"

	unless args.empty?
	  req["Content-Type"] = "application/json"
	  req.body = JSON.dump(args)
	end

	resp = http.request(req)
	body = resp.body

        Response.new(body.nil? ? {} : JSON.parse(body))
      end
    end

    class Factory
      def initialize(uri)
	@base_uri = URI(uri)
      end

      def create(**args)
        Client.new(@base_uri, args)
      end
    end

    class Request < OpenStruct
      def initialize(**args)
        super(*args)
        self.captures ||= []
      end

      def to_h
        super.delete_if { |k, v| k == :captures && v.empty? }
      end
    end

    class Response < OpenStruct
    end
  end
end
