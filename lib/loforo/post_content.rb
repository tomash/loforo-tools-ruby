# frozen_string_literal: true

module Loforo
  module PostContent
    # Loforo returns HTTP 400 ("Missing 'content'") for some MP4 uploads when the
    # multipart content field is blank. Use the filename stem (not whitespace):
    # a space-only caption is stripped in the UI and, if video processing fails,
    # the post looks completely empty even though the API returned success.
    VIDEO_SUFFIXES = %w[.mp4 .MP4].freeze

    module_function

    def resolve(file_path, content)
      return content unless content.empty?
      return content unless video?(file_path)

      File.basename(file_path, File.extname(file_path))
    end

    def video?(file_path)
      VIDEO_SUFFIXES.include?(File.extname(file_path))
    end
  end
end
