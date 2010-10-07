# coding: utf-8

unless defined?(BasicObject)
  module Tweetwine
    # Adapted from
    # <http://sequel.heroku.com/2010/03/31/sequelbasicobject-and-ruby-18/>.
    class BasicObject
      KEEP_METHODS = %w{__id__ __send__ instance_eval == equal? initialize}

      def self.remove_methods!
        ((private_instance_methods + instance_methods) - KEEP_METHODS).each do |m|
          undef_method m
        end
      end

      remove_methods!
    end
  end
end
