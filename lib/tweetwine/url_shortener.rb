module Tweetwine
  class UrlShortener
    def initialize(options)
      require "nokogiri"
      options = Options.new(options)
      @method = options[:method].to_sym || :get
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
      rest = case @method
      when :get
        tmp = @extra_params.dup
        tmp << @url_param_name + "=" + url
        service_url = @service_url + "?" + tmp.join("&")
        [service_url]
      when :post
        service_url = @service_url
        params = @extra_params.merge({ @url_param_name.to_sym => url })
        [service_url, params]
      else
        raise "Unrecognized HTTP request method"
      end
      response = RestClientWrapper.send(@method, *rest)
      doc = Nokogiri::HTML(response)
      doc.xpath(@xpath_selector).first.to_s
    end
  end
end