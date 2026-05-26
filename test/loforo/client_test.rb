# frozen_string_literal: true

require "test_helper"

class LoforoClientTest < Minitest::Test
  def test_post_file_sends_multipart_form
    response = success_response
    calls = []
    http = Object.new
    http.define_singleton_method(:post) do |endpoint, form:|
      calls << { endpoint: endpoint, form: form }
      response
    end

    Dir.mktmpdir do |dir|
      path = File.join(dir, "photo.jpg")
      File.write(path, "jpeg-bytes")

      client = Loforo::Client.new(
        api_key: "secret-key",
        endpoint: "https://example.test/post",
        http: http
      )
      client.post_file(path, content: "hi", title: "t", status: "2")

      assert_equal 1, calls.size
      assert_equal "https://example.test/post", calls[0][:endpoint]
      form = calls[0][:form]
      assert_equal "secret-key", form[:key]
      assert_equal "hi", form[:content]
      assert_equal "t", form[:title]
      assert_equal "2", form[:status]
      assert_instance_of HTTP::FormData::File, form[:media]
      assert_equal File.basename(path), form[:media].filename
    end
  end

  def test_default_endpoint
    assert_equal "https://loforo.com/api/post/create", Loforo::Client::DEFAULT_ENDPOINT
  end
end
