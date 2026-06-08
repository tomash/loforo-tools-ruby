# frozen_string_literal: true

require "json"
require "open3"

module Loforo
  class VideoUploadCheck
    # Loforo often accepts the API call but omits video on longer clips (~15s+).
    MAX_DURATION_SEC = 15.0

    def initialize(ffprobe_executable: "ffprobe", ffprobe_available: :detect, duration_for: nil)
      @ffprobe_executable = ffprobe_executable
      @ffprobe_available = ffprobe_available unless ffprobe_available == :detect
      @duration_for = duration_for
    end

    def uploadable?(file_path)
      return true unless PostContent.video?(file_path)
      return true unless ffprobe_available?

      duration = probe_duration(file_path)
      return true if duration.nil?

      duration <= MAX_DURATION_SEC
    end

    private

    def ffprobe_available?
      return @ffprobe_available unless @ffprobe_available.nil?

      _stdout, _stderr, status = Open3.capture3(@ffprobe_executable, "-version")
      @ffprobe_available = status.success?
    rescue Errno::ENOENT
      @ffprobe_available = false
    end

    def probe_duration(file_path)
      return @duration_for.call(file_path) if @duration_for

      stdout, _stderr, status = Open3.capture3(
        @ffprobe_executable, "-v", "error",
        "-show_entries", "format=duration",
        "-of", "json",
        file_path
      )
      return nil unless status.success?

      format = JSON.parse(stdout)["format"]
      format && format["duration"]&.to_f
    rescue JSON::ParserError, TypeError
      nil
    end
  end
end
