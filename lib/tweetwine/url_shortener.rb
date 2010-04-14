# coding: utf-8

module Tweetwine
  class UrlShortener
    def initialize(http_client, options)
      @http_client = http_client
      options = Options.new(options, "URL shortening")
      @method = (options[:method] || :get).to_sym
      @service_url = options.require :service_url
      @url_param_name = options.require :url_param_name
      @extra_params = options[:extra_params] || {}
      if @method == :get
        tmp = []
        @extra_params.each_pair { |k, v| tmp << "#{k}=#{v}" }
        @extra_params = tmp
      end
      @xpath_selector = options.require :xpath_selector
    end

    def shorten(url)
      require "nokogiri"
      response = @http_client.send(@method, *get_service_url_and_params(url))
      doc = Nokogiri::HTML(response)
      doc.xpath(@xpath_selector).first.to_s
    end

    private

    def get_service_url_and_params(url_to_shorten)
      case @method
      when :get
        tmp = @extra_params.dup
        tmp << "#{@url_param_name}=#{url_to_shorten}"
        service_url = "#{@service_url}?#{tmp.join('&')}"
        [service_url]
      when :post
        service_url = @service_url
        params = @extra_params.merge({ @url_param_name.to_sym => url_to_shorten })
        [service_url, params]
      else
        raise "Unrecognized HTTP request method"
      end
    end
  end
end
