# frozen_string_literal: true

require "test_helper"

class LoforoFileUploaderTest < Minitest::Test
  def test_run_posts_file_and_logs_response
    client = fake_client
    log = StringIO.new

    Dir.mktmpdir do |dir|
      path = File.join(dir, "photo.jpg")
      File.write(path, "jpg")

      response = Loforo::FileUploader.new(path, client: client, logger: log).run

      assert_equal [path], client.posted
      assert response.status.success?
      assert_match(/upload successful/, log.string)
    end
  end

  def test_run_logs_failure_on_error_response
    response = failure_response
    client = Class.new do
      define_method(:post_file) { |_path, **| response }
    end.new
    log = StringIO.new

    Dir.mktmpdir do |dir|
      path = File.join(dir, "photo.jpg")
      File.write(path, "jpg")

      result = Loforo::FileUploader.new(path, client: client, logger: log).run

      refute result.status.success?
      assert_match(/upload failed/, log.string)
    end
  end

  def test_validate_raises_for_missing_file
    uploader = Loforo::FileUploader.new("/no/such/file.jpg", client: fake_client, logger: StringIO.new)
    assert_raises(ArgumentError) { uploader.run }
  end
end
