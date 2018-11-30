require 'json'
require 'net/http'
require 'ostruct'
require "xlogin/apiclient/version"

module Xlogin
  module APIClient
    class APIError < StandardError; end

    class Client

      def initialize(uri)
	@base_uri = URI(uri)
      end

      def exec(req = Request.new, &block)
        vendor = self.class.name.slice(/\w+$/).downcase
        method("exec_#{vendor}").call(req, &block)
      end

      def method_missing(name, *args, &block)
        super unless name =~ /^exec_(\w+)$/

        begin
          req = args.shift || Request.new
          uri = URI(@base_uri)
          uri.path = "/vendors/#{$1}/actions"

          block.call(req) if block
          http(:post, uri, req.to_h)
        rescue => e
          raise APIError.new(e.message)
        end
      end

      def respond_to_missing?(name, include_private = false)
        name =~ /^exec_(\w+)$/
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
	body.nil? ? {} : JSON.parse(body)
      end

    end

    class Request < OpenStruct
      def initialize(*args)
        super(*args)
        self.captures ||= []
      end
    end
  end
end
