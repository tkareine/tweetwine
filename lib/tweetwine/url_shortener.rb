# coding: utf-8

module Tweetwine
  class UrlShortener
    def initialize(config)
      @method         = (config[:method] || :get).to_sym
      @service_url    = config[:service_url] || raise_error(:service_url)
      @url_param_name = config[:url_param_name] || raise_error(:url_param_name)
      @xpath_selector = config[:xpath_selector] || raise_error(:xpath_selector)
      @extra_params   = config[:extra_params] || {}
      if @method == :get
        tmp = []
        @extra_params.each_pair { |k, v| tmp << "#{k}=#{v}" }
        @extra_params = tmp
      end
    end

    def shorten(url)
      require "nokogiri"
      response = CLI.http.send(@method, *get_service_url_and_params(url))
      doc = Nokogiri::HTML(response)
      doc.xpath(@xpath_selector).first.to_s
    end

    private

    def raise_error(key)
      raise RequiredOptionError.new(key, :url_shortener)
    end

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
