# coding: utf-8

module Tweetwine
  class UrlShortener
    def initialize(options)
      raise "UrlShortener should be disabled" if options[:disable]
      @method = (options[:method] || :get).to_sym
      unless [:get, :post].include? @method
        raise CommandLineError, "Unsupported HTTP request method for URL shortening: #{@method}"
      end
      @service_url    = require_option options, :service_url
      @url_param_name = require_option options, :url_param_name
      @xpath_selector = require_option options, :xpath_selector
      @extra_params   = options[:extra_params] || {}
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

    def require_option(options, key)
      options[key] or raise RequiredOptionError.new(key, :url_shortener)
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
        raise "Unrecognized HTTP request method; should have been supported"
      end
    end
  end
end
