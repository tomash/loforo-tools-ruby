# frozen_string_literal: true

module Loforo
  class FileUploader
    def initialize(file_path, client:, logger: $stdout)
      @file_path = file_path
      @client = client
      @logger = logger
    end

    def run
      validate!
      @logger.puts "#{@file_path} ..."
      response = @client.post_file(@file_path)
      @logger.puts response.inspect
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
