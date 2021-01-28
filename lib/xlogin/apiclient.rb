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

    attr_reader :type, :args

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
      resp = http.request(req)
      raise Error.new(resp.message) unless resp.code =~ /^2[0-9]{2}$/

      data = resp.body ? JSON.parse(resp.body) : {}
      raise Error.new(data['error']) unless data['success']

      return data
    end
  end
end
