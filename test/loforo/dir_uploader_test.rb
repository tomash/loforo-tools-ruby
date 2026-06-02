# frozen_string_literal: true

require "test_helper"

class LoforoDirUploaderTest < Minitest::Test
  def test_uploads_media_moves_file_and_writes_json
    client = fake_client
    log = StringIO.new
    frozen_time = Time.utc(2026, 5, 26, 12, 0, 0)

    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "a.jpg"), "jpg")
      File.write(File.join(dir, "clip.mp4"), "mp4")

      uploader = Loforo::DirUploader.new(
        dir,
        client: client,
        logger: log,
        now: -> { frozen_time }
      )
      uploader.run

      assert_equal 2, client.posted.size
      refute File.exist?(File.join(dir, "a.jpg"))
      refute File.exist?(File.join(dir, "clip.mp4"))
      assert File.exist?(File.join(dir, "uploaded", "a.jpg"))
      assert File.exist?(File.join(dir, "uploaded", "clip.mp4"))

      history = JSON.load_file(File.join(dir, "uploaded.json"))
      assert_equal 2, history.size
      assert_equal "a.jpg", history[0]["filename"]
      assert_equal frozen_time.iso8601, history[0]["uploaded_at"]
    end
  end

  def test_merges_existing_uploaded_json
    client = fake_client
    log = StringIO.new

    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "uploaded.json"), JSON.dump([{ "filename" => "old.png", "uploaded_at" => "yesterday" }]))
      File.write(File.join(dir, "new.jpg"), "jpg")

      Loforo::DirUploader.new(dir, client: client, logger: log, now: -> { Time.utc(2026, 1, 1) }).run

      history = JSON.load_file(File.join(dir, "uploaded.json"))
      assert_equal 2, history.size
      assert_equal "old.png", history[0]["filename"]
      assert_equal "new.jpg", history[1]["filename"]
    end
  end

  def test_failed_upload_leaves_file_in_place
    response = failure_response
    client = Class.new do
      define_method(:post_file) { |_path, **| response }
    end.new

    Dir.mktmpdir do |dir|
      path = File.join(dir, "bad.jpg")
      File.write(path, "jpg")

      Loforo::DirUploader.new(dir, client: client, logger: StringIO.new).run

      assert File.exist?(path)
      assert_equal [], JSON.load_file(File.join(dir, "uploaded.json"))
    end
  end

  def test_media_file_paths_includes_common_extensions
    Dir.mktmpdir do |dir|
      %w[photo.JPG movie.MP4].each { |name| File.write(File.join(dir, name), "x") }
      paths = Loforo::DirUploader.new(dir, client: fake_client, logger: StringIO.new).media_file_paths
      assert_equal 2, paths.size
    end
  end

  def test_validate_raises_for_missing_directory
    uploader = Loforo::DirUploader.new(nil, client: fake_client, logger: StringIO.new)
    assert_raises(ArgumentError) { uploader.run }
  end
end
