# frozen_string_literal: true

module Loforo
  module PostContent
    # Loforo returns HTTP 400 ("Missing 'content'") for some MP4 uploads when the
    # multipart content field is blank; always send a non-empty value for video.
    VIDEO_SUFFIXES = %w[.mp4 .MP4].freeze
    FALLBACK_CONTENT = " "

    module_function

    def resolve(file_path, content)
      return content unless content.empty?
      return content unless video?(file_path)

      FALLBACK_CONTENT
    end

    def video?(file_path)
      VIDEO_SUFFIXES.include?(File.extname(file_path))
    end
  end
end
