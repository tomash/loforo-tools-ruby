# frozen_string_literal: true

require "fileutils"
require "json"

module Loforo
  class DirUploader
    RunResult = Struct.new(:uploaded, :failures, keyword_init: true) do
      def processed_any?
        !uploaded.empty? || !failures.empty?
      end
    end

    MEDIA_GLOB = "*.{jpg,JPG,jpeg,JPEG,png,PNG,webp,WEBP,gif,GIF,mp4,MP4}"

    def initialize(dir_path, client:, logger: $stdout, now: -> { Time.now.utc })
      @dir_path = dir_path
      @client = client
      @logger = logger
      @now = now
    end

    def run
      validate!
      @logger.puts "#{@dir_path} ..."

      FileUtils.mkdir_p(uploaded_dir)
      result = upload_media_files
      persist_uploaded_json(merge_upload_history(result.uploaded))
      move_files(result.uploaded)
      result
    end

    def media_file_paths
      Dir.glob(File.join(@dir_path, MEDIA_GLOB)).sort
    end

    private

    def validate!
      unless @dir_path && File.exist?(@dir_path) && File.directory?(@dir_path)
        raise ArgumentError, "need valid path to media directory"
      end
    end

    def uploaded_dir
      File.join(@dir_path, "uploaded")
    end

    def uploaded_json_path
      File.join(@dir_path, "uploaded.json")
    end

    def upload_media_files
      uploaded = []
      failures = []
      media_file_paths.each do |file_path|
        entry, failure = upload_file(file_path)
        uploaded << entry if entry
        failures << failure if failure
      end
      RunResult.new(uploaded: uploaded, failures: failures)
    end

    def upload_file(file_path)
      response = @client.post_file(file_path)
      basename = File.basename(file_path)
      if response.status.success?
        @logger.puts "posting file #{file_path} successful :)"
        entry = { "filename" => basename, "uploaded_at" => @now.call.iso8601 }
        [entry, nil]
      else
        status = response.status.to_s
        @logger.puts "posting file #{file_path} failed :( \t\t details: #{status}"
        failure = { "filename" => basename, "status" => status }
        [nil, failure]
      end
    end

    def move_files(entries)
      entries.each do |entry|
        src = File.join(@dir_path, entry["filename"])
        dst = File.join(uploaded_dir, entry["filename"])
        FileUtils.move(src, dst) if File.exist?(src)
      end
    end

    def merge_upload_history(new_entries)
      history = if File.exist?(uploaded_json_path)
                  JSON.load_file(uploaded_json_path)
                else
                  []
                end
      history + new_entries
    end

    def persist_uploaded_json(entries)
      File.write(uploaded_json_path, JSON.dump(entries))
    end
  end
end
