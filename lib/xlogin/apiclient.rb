require 'json'
require 'net/http'
require 'addressable/uri'
require "xlogin/apiclient/version"

module Xlogin
  class APIClient
    class Error < StandardError; end

    class << self
      attr_accessor :base_url
    end

    def initialize(base_url: self.class.base_url, **args)
      raise Error.new('base_url not defined') unless base_url

      @uri  = Addressable::URI.parse(base_url)
      @type = args.delete(:type)
      @args = args
    end

    def cmd(args)
      params = {driver: @type, target: @args, command: args}
      resp = request(**params.transform_keys(&:to_sym))
      resp['payload'].join
    end

    private
    def request(**params)
      uri = @uri.dup
      uri.query = "q=#{URI.encode_www_form_component(JSON.generate(params))}"

      req = Net::HTTP::Get.new(uri.request_uri)
      req["Accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      body = http.request(req).body
      resp = body ? JSON.parse(body) : {}
      return resp if resp['success']

      raise Error.new(resp['error'])
    end
  end
end
