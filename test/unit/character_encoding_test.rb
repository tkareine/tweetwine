# coding: utf-8

require "unit_helper"

module Tweetwine::Test

class CharacterEncodingTest < UnitTestCase
  if "".respond_to?(:encode)
    context "when transcoding to UTF-8 when String supports encoding" do
      should "transcode string to UTF-8" do
        str_utf8 = "groß résumé"
        str_latin1 = str_utf8.encode('ISO-8859-1')
        assert_equal str_utf8, CharacterEncoding.to_utf8(str_latin1)
      end

      should "raise exception if result is invalid UTF-8" do
        assert_raise(TranscodeError) { CharacterEncoding.to_utf8("\xa4") }
      end
    end
  else
    context "when transcoding to UTF-8 when String does not support encoding" do
      # résumé
      RESUME_EUC    = "r\x8F\xAB\xB1sum\x8F\xAB\xB1"
      RESUME_LATIN1 = "r\xe9sum\xe9"
      RESUME_UTF8   = "r\xc3\xa9sum\xc3\xa9"

      # ホーム ("home" in Japanese)
      HOME_SJIS     = "\x83\x7a\x81\x5b\x83\x80"
      HOME_UTF8     = "\xe3\x83\x9b\xe3\x83\xbc\xe3\x83\xa0"

      setup do
        Tweetwine::CharacterEncoding.forget_guess
      end

      [
        ['EUC',   RESUME_EUC, RESUME_UTF8],
        ['SJIS',  HOME_SJIS,  HOME_UTF8]
      ].each do |(kcode, original, expected)|
        should "transcode with Iconv, guessing first from $KCODE, case #{kcode}" do
          tmp_kcode(kcode) do
            assert_equal expected, CharacterEncoding.to_utf8(original)
          end
        end
      end

      [
        ['latin1',    RESUME_LATIN1,  RESUME_UTF8],
        ['EUC-JP',    RESUME_EUC,     RESUME_UTF8],
        ['SHIFT_JIS', HOME_SJIS,      HOME_UTF8]
      ].each do |(lang, original, expected)|
        should "transcode with Iconv, guessing second from envar $LANG, case #{lang}" do
          tmp_kcode('NONE') do
            tmp_env(:LANG => lang) do
              assert_equal expected, CharacterEncoding.to_utf8(original)
            end
          end
        end
      end

      should "pass string as is, if guess is UTF-8, case $KCODE is UTF-8" do
        tmp_kcode('UTF8') do
          assert_same RESUME_UTF8, CharacterEncoding.to_utf8(RESUME_UTF8)
        end
      end

      %w{utf8 UTF-8 en_US.UTF-8 fi_FI.utf-8 fi_FI.utf8}.each do |lang|
        should "pass string as is, if guess is UTF-8, case envar $LANG is '#{lang}'" do
          tmp_kcode('NONE') do
            tmp_env(:LANG => lang) do
              assert_same RESUME_UTF8, CharacterEncoding.to_utf8(RESUME_UTF8)
            end
          end
        end
      end

      should "raise exception if conversion cannot be done because we couldn't guess external encoding" do
        tmp_kcode('NONE') do
          tmp_env(:LANG => nil) do
            assert_raise(Tweetwine::TranscodeError) { CharacterEncoding.to_utf8(RESUME_LATIN1) }
          end
        end
      end
    end
  end
end

end
