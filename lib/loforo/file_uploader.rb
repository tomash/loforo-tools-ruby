# frozen_string_literal: true

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
  end
end
