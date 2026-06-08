# frozen_string_literal: true

require "test_helper"

class LoforoVideoUploadCheckTest < Minitest::Test
  def test_non_video_is_always_uploadable
    check = Loforo::VideoUploadCheck.new(ffprobe_available: true, duration_for: ->(_) { 999 })
    assert check.uploadable?("/tmp/photo.jpg")
  end

  def test_short_mp4_is_uploadable
    check = Loforo::VideoUploadCheck.new(ffprobe_available: true, duration_for: ->(_) { 15.0 })
    assert check.uploadable?("/tmp/clip.mp4")
  end

  def test_long_mp4_is_not_uploadable
    check = Loforo::VideoUploadCheck.new(ffprobe_available: true, duration_for: ->(_) { 15.1 })
    refute check.uploadable?("/tmp/clip.mp4")
  end

  def test_uppercase_mp4_extension
    check = Loforo::VideoUploadCheck.new(ffprobe_available: true, duration_for: ->(_) { 20 })
    refute check.uploadable?("/tmp/clip.MP4")
  end

  def test_unknown_duration_allows_upload
    check = Loforo::VideoUploadCheck.new(ffprobe_available: true, duration_for: ->(_) { nil })
    assert check.uploadable?("/tmp/clip.mp4")
  end

  def test_missing_ffprobe_allows_upload
    check = Loforo::VideoUploadCheck.new(ffprobe_available: false, duration_for: ->(_) { 60 })
    assert check.uploadable?("/tmp/clip.mp4")
  end
end
