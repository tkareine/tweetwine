# coding: utf-8

require "test_helper"

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
      setup do
        @resume_euc     = "r\x8F\xAB\xB1sum\x8F\xAB\xB1"
        @resume_latin1  = "r\xe9sum\xe9"
        @resume_utf8    = "r\xc3\xa9sum\xc3\xa9"
        @home_sjis      = "\x83\x7a\x81\x5b\x83\x80"
        @home_utf8      = "\xe3\x83\x9b\xe3\x83\xbc\xe3\x83\xa0"
      end

      should "transcode with Iconv, guessing first from $KCODE" do
        tmp_kcode('EUC') do
          assert_equal @resume_utf8, CharacterEncoding.to_utf8(@resume_euc)
        end
        tmp_kcode('SJIS') do
          assert_equal @home_utf8, CharacterEncoding.to_utf8(@home_sjis)
        end
      end

      should "transcode with Iconv, guessing second from envar $LANG" do
        tmp_kcode('NONE') do
          tmp_env(:LANG => 'latin1') do
            assert_equal @resume_utf8, CharacterEncoding.to_utf8(@resume_latin1)
          end
          tmp_env(:LANG => 'EUC-JP') do
            assert_equal @resume_utf8, CharacterEncoding.to_utf8(@resume_euc)
          end
          tmp_env(:LANG => 'SHIFT_JIS') do
            assert_equal @home_utf8, CharacterEncoding.to_utf8(@home_sjis)
          end
        end
      end

      should "pass string as is, if guess is UTF-8" do
        tmp_kcode('UTF8') do
          assert_same @resume_utf8, CharacterEncoding.to_utf8(@resume_utf8)
        end
        tmp_kcode('NONE') do
          tmp_env(:LANG => 'UTF-8') do
            assert_same @resume_utf8, CharacterEncoding.to_utf8(@resume_utf8)
          end
          tmp_env(:LANG => 'en_US.UTF-8') do
            assert_same @resume_utf8, CharacterEncoding.to_utf8(@resume_utf8)
          end
          tmp_env(:LANG => 'fi_FI.utf-8') do
            assert_same @resume_utf8, CharacterEncoding.to_utf8(@resume_utf8)
          end
          tmp_env(:LANG => 'fi_FI.utf8') do
            assert_same @resume_utf8, CharacterEncoding.to_utf8(@resume_utf8)
          end
        end
      end

      should "raise exception if conversion cannot be done because we couldn't guess external encoding" do
        tmp_kcode('NONE') do
          tmp_env(:LANG => nil) do
            assert_raise(Tweetwine::TranscodeError) { CharacterEncoding.to_utf8(@resume_latin1) }
          end
        end
      end
    end
  end
end

end
