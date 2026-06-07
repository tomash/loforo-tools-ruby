# frozen_string_literal: true

require "test_helper"

class LoforoPostContentTest < Minitest::Test
  ORIGINAL_PROBE = Loforo::PostContent.method(:probe_format)
  def test_keeps_explicit_content
    assert_equal "caption", Loforo::PostContent.resolve("/tmp/x.mp4", "caption")
  end

  def test_keeps_empty_content_for_non_video
    assert_equal "", Loforo::PostContent.resolve("/tmp/x.jpg", "")
  end

  def test_keeps_empty_content_for_short_video
    with_stubbed_format("duration" => "13.5", "tags" => { "comment" => "vid:abc" }) do
      assert_equal "", Loforo::PostContent.resolve("/tmp/short.mp4", "")
    end
  end

  def test_uses_comment_for_long_video_when_content_empty
    with_stubbed_format("duration" => "32.4", "tags" => { "comment" => "vid:v26044gc0000" }) do
      assert_equal "vid:v26044gc0000", Loforo::PostContent.resolve("/tmp/long.mp4", "")
    end
  end

  def test_uses_fallback_for_long_video_without_comment
    with_stubbed_format("duration" => "20.0", "tags" => {}) do
      assert_equal Loforo::PostContent::FALLBACK_CONTENT,
                   Loforo::PostContent.resolve("/tmp/long.mp4", "")
    end
  end

  def test_keeps_empty_when_duration_unknown
    with_stubbed_format(nil) do
      assert_equal "", Loforo::PostContent.resolve("/tmp/long.mp4", "")
    end
  end

  private

  def with_stubbed_format(format)
    Loforo::PostContent.define_singleton_method(:probe_format) { |_path| format }
    yield
  ensure
    Loforo::PostContent.define_singleton_method(:probe_format, ORIGINAL_PROBE)
  end
end
