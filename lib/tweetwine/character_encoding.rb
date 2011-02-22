# coding: utf-8

module Tweetwine
  class CharacterEncoding
    class << self
      if defined? Encoding
        def to_utf8(str)
          result = str.encode('UTF-8')
          raise TranscodeError, "invalid UTF-8 byte sequence when transcoding '#{str}'" unless result.valid_encoding?
          result
        end
      else
        def to_utf8(str)
          if guess_external_encoding != 'UTF-8'
            begin
              require "iconv"
              Iconv.conv('UTF-8//TRANSLIT', guess_external_encoding, str)
            rescue => e
              raise TranscodeError, e
            end
          else
            str
          end
        end
      end

      def forget_guess
        @guess_external_encoding = nil
      end

      private

      def guess_external_encoding
        @guess_external_encoding ||= begin
          guess = guess_external_encoding_from_kcode || guess_external_encoding_from_env_lang
          raise TranscodeError, "could not determine your external encoding" unless guess
          guess
        end
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
        Support.presence(lang)
      end
    end
  end
end
