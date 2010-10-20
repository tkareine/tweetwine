# coding: utf-8

module Tweetwine
  class CharacterEncoding
    class << self
      if "".respond_to?(:encode)
        def to_utf8(str)
          result = str.encode('UTF-8')
          raise TranscodeError, "invalid UTF-8 byte sequence when transcoding '#{str}'" unless result.valid_encoding?
          result
        end
      else
        def to_utf8(str)
          guess = guess_external_encoding
          if guess != 'UTF-8'
            begin
              require "iconv"
              Iconv.conv('UTF-8//TRANSLIT', guess, str)
            rescue => e
              raise TranscodeError, e
            end
          else
            str
          end
        end
      end

      private

      def guess_external_encoding
        guess = guess_external_encoding_from_kcode || guess_external_encoding_from_env_lang
        raise TranscodeError, "could not determine your external encoding" unless guess
        guess
      end

      def guess_external_encoding_from_kcode
        guess = nil
        guess = case $KCODE
        when 'EUC'  then 'EUC-JP'
        when 'SJIS' then 'SHIFT-JIS'
        when 'UTF8' then 'UTF-8'
        else nil
        end if defined?($KCODE)
        guess
      end

      def guess_external_encoding_from_env_lang
        lang = ENV['LANG']
        return 'UTF-8' if lang =~ /(utf-8|utf8)\z/i
        Util.blank?(lang) ? nil : lang
      end
    end
  end
end
