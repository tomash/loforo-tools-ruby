# frozen_string_literal: true

require "json"
require "open3"

module Loforo
  module PostContent
    # Loforo rejects long video uploads when the multipart `content` field is blank
    # (HTTP 400, message "Missing 'content'"), while shorter clips accept "".
    LONG_VIDEO_MIN_DURATION_SEC = 18.0
    VIDEO_SUFFIXES = %w[.mp4 .MP4].freeze
    FALLBACK_CONTENT = " "

    module_function

    def resolve(file_path, content)
      return content unless content.empty?
      return content unless video?(file_path)

      format = probe_format(file_path)
      duration = format&.fetch("duration", nil)&.to_f
      return content if duration.nil? || duration < LONG_VIDEO_MIN_DURATION_SEC

      comment = format&.dig("tags", "comment")
      comment.to_s.strip.empty? ? FALLBACK_CONTENT : comment
    end

    def video?(file_path)
      VIDEO_SUFFIXES.include?(File.extname(file_path))
    end

    def probe_format(file_path)
      stdout, _stderr, status = Open3.capture3(
        "ffprobe", "-v", "error",
        "-show_entries", "format=duration:format_tags=comment",
        "-of", "json",
        file_path
      )
      return nil unless status.success?

      JSON.parse(stdout).fetch("format", nil)
    rescue JSON::ParserError
      nil
    end
  end
end
