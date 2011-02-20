# coding: utf-8

module Tweetwine::Test
  module TweetHelper
    FIELD_PATHS = {
      :from_user  => %w{screen_name},
      :to_user    => %w{status in_reply_to_screen_name},
      :retweet    => %w{retweeted_status},
      :created_at => %w{status created_at},
      :status     => %w{status text}
    }.freeze

    DEFAULT_FIELD_VALUES = {
      :from_user  => 'fred',
      :to_user    => nil,
      :retweet    => nil,
      :created_at => Time.utc(2011, 'feb', 17, 22, 28, 0).iso8601,
      :status     => nil
    }.freeze

    RECORD_SKELETON = {
      'screen_name'       => nil,
      'retweeted_status'  => nil,
      'status'            => {
        'in_reply_to_screen_name' => nil,
        'created_at'              => nil,
        'text'                    => nil
      }.freeze
    }.freeze

    def create_record(fields = {})
      record = create_nonrt_record(nonrt_fields(fields))
      modify_to_rt_record(record, fields[:rt_user]) if fields[:rt_user]
      record
    end

    def create_tweet(fields = {})
      Tweetwine::Tweet.new(create_record(fields), FIELD_PATHS)
    end

    private

    def find_hash_of_field_path(hash, path)
      path = [path] unless path.is_a? Array
      if path.size > 1
        hash_path, field = path[0..-2], path.last
        [Tweetwine::Support.find_hash_path(hash, hash_path), field]
      else
        [hash, path.first]
      end
    end

    def nonrt_fields(fields)
      DEFAULT_FIELD_VALUES.merge(fields.reject { |(k, v)| k == :rt_user })
    end

    def create_nonrt_record(fields)
      FIELD_PATHS.inject(deep_copy(RECORD_SKELETON)) do |result, (path_name, path_actual)|
        hash, field = find_hash_of_field_path(result, path_actual)
        hash[field] = fields[path_name]
        result
      end
    end

    def modify_to_rt_record(record, rt_user)
      rt_hash, rt_field = find_hash_of_field_path(record, FIELD_PATHS[:retweet])
      fr_hash, fr_field = find_hash_of_field_path(record, FIELD_PATHS[:from_user])
      st_hash, st_field = find_hash_of_field_path(record, FIELD_PATHS[:status])
      rt_hash[rt_field] = {
        fr_field => fr_hash[fr_field].dup,
        'status' => st_hash.dup
      }
      fr_hash[fr_field] = rt_user
      st_hash[st_field] = 'retweeted status text. you should not see me.'
      cr_hash, cr_field = find_hash_of_field_path(record, FIELD_PATHS[:created_at])
      cr_hash[cr_field] = 'old created timestamp. you should not see me.'
    end

    def deep_copy(obj)
      Marshal.load(Marshal.dump(obj))
    end
  end
end
