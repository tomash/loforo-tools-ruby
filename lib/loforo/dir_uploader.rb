# frozen_string_literal: true

require "fileutils"
require "json"

module Loforo
  class DirUploader
    RunResult = Struct.new(:uploaded, :failures, :skipped, keyword_init: true) do
      def processed_any?
        !uploaded.empty? || !failures.empty?
      end
    end

    MEDIA_GLOB = "*.{jpg,JPG,jpeg,JPEG,png,PNG,webp,WEBP,gif,GIF,mp4,MP4}"

    def initialize(dir_path, client:, logger: $stdout, now: -> { Time.now.utc },
                   video_upload_check: VideoUploadCheck.new)
      @dir_path = dir_path
      @client = client
      @logger = logger
      @now = now
      @video_upload_check = video_upload_check
    end

    def run
      validate!
      @logger.puts "#{@dir_path} ..."

      FileUtils.mkdir_p(uploaded_dir)
      result = upload_media_files
      persist_uploaded_json(merge_upload_history(result.uploaded))
      move_files(result.uploaded)
      move_to_subdir("skipped", Array(result.skipped))
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
      skipped = []
      media_file_paths.each do |file_path|
        entry, failure, skipped_basename = upload_file(file_path)
        uploaded << entry if entry
        failures << failure if failure
        skipped << skipped_basename if skipped_basename
      end
      RunResult.new(uploaded: uploaded, failures: failures, skipped: skipped)
    end

    def upload_file(file_path)
      unless @video_upload_check.uploadable?(file_path)
        @logger.puts "skipping #{file_path}: MP4 longer than #{VideoUploadCheck::MAX_DURATION_SEC}s"
        return [nil, nil, File.basename(file_path)]
      end

      response = @client.post_file(file_path)
      basename = File.basename(file_path)
      if response.status.success?
        @logger.puts "posting file #{file_path} successful :)"
        entry = { "filename" => basename, "uploaded_at" => @now.call.iso8601 }
        [entry, nil, nil]
      else
        status = response.status.to_s
        @logger.puts "posting file #{file_path} failed :( \t\t details: #{status}"
        failure = { "filename" => basename, "status" => status }
        [nil, failure, nil]
      end
    end

    def move_files(entries)
      move_to_subdir("uploaded", entries.map { |entry| entry["filename"] })
    end

    def move_to_subdir(subdir, basenames)
      return if basenames.empty?

      dest_dir = File.join(@dir_path, subdir)
      FileUtils.mkdir_p(dest_dir)
      basenames.each do |basename|
        src = File.join(@dir_path, basename)
        dst = File.join(dest_dir, basename)
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
