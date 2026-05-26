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
      assert_match(/photo\.jpg/, log.string)
    end
  end

  def test_validate_raises_for_missing_file
    uploader = Loforo::FileUploader.new("/no/such/file.jpg", client: fake_client, logger: StringIO.new)
    assert_raises(ArgumentError) { uploader.run }
  end
end
