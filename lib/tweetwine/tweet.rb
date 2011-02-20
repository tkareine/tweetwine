# coding: utf-8

module Tweetwine
  class Tweet
    attr_reader :from_user, :to_user, :rt_user, :created_at, :status

    def initialize(record, paths)
      if field_present? record, paths[:retweet]
        @rt_user = parse_string_field record, paths[:from_user]
        fields   = Support.find_hash_path record, paths[:retweet]
      else
        @rt_user = nil
        fields   = record
      end
      @to_user    = parse_string_field fields, paths[:to_user]
      @from_user  = parse_string_field fields, paths[:from_user]
      raise ArgumentError, 'from user record field is required' unless @from_user
      @created_at = parse_time_field   fields, paths[:created_at]
      @status     = parse_string_field fields, paths[:status]
    end

    def timestamped?
      !@created_at.nil?
    end

    def retweet?
      !@rt_user.nil?
    end

    def status?
      !@status.nil?
    end

    def reply?
      !@to_user.nil?
    end

    def ==(other)
      other.is_a?(self.class) &&
        self.rt_user    == other.rt_user    &&
        self.to_user    == other.to_user    &&
        self.from_user  == other.from_user  &&
        self.created_at == other.created_at &&
        self.status     == other.status
    end

    private

    def field_present?(record, path)
      !!find_field(record, path) { |f| Support.present?(f) }
    end

    def field_presence(record, path, &block)
      find_field(record, path) { |f| Support.presence(f, &block) }
    end

    def parse_string_field(record, path)
      field_presence(record, path) { |f| f.to_s }
    end

    def parse_time_field(record, path)
      field_presence(record, path) { |f| Time.parse(f.to_s) }
    end

    def find_field(record, path)
      yield(Support.find_hash_path(record, path)) rescue nil
    end
  end
end
