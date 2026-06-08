# frozen_string_literal: true

require "fileutils"

module Loforo
  class FileUploader
    def initialize(file_path, client:, logger: $stdout, video_upload_check: VideoUploadCheck.new)
      @file_path = file_path
      @client = client
      @logger = logger
      @video_upload_check = video_upload_check
    end

    def run
      validate!
      @logger.puts "#{@file_path} ..."
      unless @video_upload_check.uploadable?(@file_path)
        @logger.puts "skipping #{@file_path}: MP4 longer than #{VideoUploadCheck::MAX_DURATION_SEC}s"
        move_to_skipped_subdir
        return nil
      end

      response = @client.post_file(@file_path)
      if response.status.success?
        @logger.puts "upload successful: #{response.inspect}"
      else
        @logger.puts "upload failed: #{response.status.to_s}"
      end
      response
    end

    private

    def validate!
      unless @file_path && File.exist?(@file_path) && File.file?(@file_path)
        raise ArgumentError, "need valid path to media file"
      end
    end

    def move_to_skipped_subdir
      dir = File.dirname(@file_path)
      skipped_dir = File.join(dir, "skipped")
      FileUtils.mkdir_p(skipped_dir)
      dst = File.join(skipped_dir, File.basename(@file_path))
      FileUtils.move(@file_path, dst) if File.exist?(@file_path)
    end
  end
end
