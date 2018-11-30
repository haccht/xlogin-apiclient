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

      def run(vendor, req = Request.new, &block)
        uri = URI(@base_uri)
        uri.path = "/vendors/#{vendor}/actions"

        block.call(req) if block
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
	body.nil? ? {} : JSON.parse(body)
      end

    end

    class Request

      def initialize
        @captures = []
      end

      def xlogin(args = nil)
        return @xlogin if args.nil?
        @xlogin = args
      end

      def command(args = nil)
        return @command if args.nil?
        @command = args
      end

      def capture(**args)
        @captures ||= []
        @captures << args
      end

    end
  end
end
