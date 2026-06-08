# frozen_string_literal: true

require "test_helper"

class LoforoPostContentTest < Minitest::Test
  def test_keeps_explicit_content
    assert_equal "caption", Loforo::PostContent.resolve("/tmp/x.mp4", "caption")
  end

  def test_keeps_empty_content_for_non_video
    assert_equal "", Loforo::PostContent.resolve("/tmp/x.jpg", "")
  end

  def test_fills_empty_content_for_mp4
    assert_equal "clip", Loforo::PostContent.resolve("/tmp/clip.mp4", "")
  end

  def test_fills_empty_content_for_uppercase_mp4
    assert_equal "clip", Loforo::PostContent.resolve("/tmp/clip.MP4", "")
  end
end
