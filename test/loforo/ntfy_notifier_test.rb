# frozen_string_literal: true

require "test_helper"

class LoforoNtfyNotifierTest < Minitest::Test
  def test_deliver_posts_message_to_topic_url
    calls = []
    http = Object.new
    http.define_singleton_method(:post) do |url, body:, headers:|
      calls << { url: url, body: body, headers: headers }
    end

    notifier = Loforo::NtfyNotifier.new(
      topic: "my-secret-topic",
      server: "https://ntfy.sh",
      title: "Upload done",
      http: http
    )
    notifier.deliver("hello")

    assert_equal 1, calls.size
    assert_equal "https://ntfy.sh/my-secret-topic", calls[0][:url]
    assert_equal "hello", calls[0][:body]
    assert_equal "Upload done", calls[0][:headers]["Title"]
    refute calls[0][:headers].key?("Authorization")
  end

  def test_deliver_sends_bearer_token_when_configured
    calls = []
    http = Object.new
    http.define_singleton_method(:post) { |url, body:, headers:| calls << headers }

    Loforo::NtfyNotifier.new(topic: "t", token: "sekrit", http: http).deliver("x")

    assert_equal "Bearer sekrit", calls[0]["Authorization"]
  end

  def test_notify_uploads_formats_filenames
    calls = []
    http = Object.new
    http.define_singleton_method(:post) { |_url, body:, **| calls << body }

    entries = [
      { "filename" => "a.jpg", "uploaded_at" => "2026-01-01T00:00:00Z" },
      { "filename" => "b.mp4", "uploaded_at" => "2026-01-01T00:00:01Z" }
    ]
    Loforo::NtfyNotifier.new(topic: "t", http: http).notify_uploads(entries)

    assert_equal "2 files uploaded:\na.jpg\nb.mp4", calls[0]
  end

  def test_notify_uploads_singular_message
    calls = []
    http = Object.new
    http.define_singleton_method(:post) { |_url, body:, **| calls << body }

    Loforo::NtfyNotifier.new(topic: "t", http: http).notify_uploads(
      [{ "filename" => "only.png", "uploaded_at" => "2026-01-01T00:00:00Z" }]
    )

    assert_equal "1 file uploaded:\nonly.png", calls[0]
  end

  def test_from_env_returns_nil_without_topic
    original = ENV.delete("NTFY_TOPIC")
    assert_nil Loforo::NtfyNotifier.from_env
  ensure
    ENV["NTFY_TOPIC"] = original if original
  end

  def test_from_env_returns_nil_for_empty_topic
    original = ENV["NTFY_TOPIC"]
    ENV["NTFY_TOPIC"] = "  "
    assert_nil Loforo::NtfyNotifier.from_env
  ensure
    if original.nil?
      ENV.delete("NTFY_TOPIC")
    else
      ENV["NTFY_TOPIC"] = original
    end
  end

  def test_from_env_builds_notifier_from_environment
    keys = %w[NTFY_TOPIC NTFY_SERVER NTFY_TITLE NTFY_TOKEN]
    saved = keys.to_h { |key| [key, ENV[key]] }
    ENV["NTFY_TOPIC"] = "cron-uploads"
    ENV["NTFY_SERVER"] = "https://ntfy.example.test/"
    ENV["NTFY_TITLE"] = "NUC"
    ENV["NTFY_TOKEN"] = "tok"

    calls = []
    http = Object.new
    http.define_singleton_method(:post) do |url, body:, headers:|
      calls << { url: url, headers: headers }
    end

    Loforo::NtfyNotifier.from_env(http: http).deliver("ping")

    assert_equal "https://ntfy.example.test/cron-uploads", calls[0][:url]
    assert_equal "NUC", calls[0][:headers]["Title"]
    assert_equal "Bearer tok", calls[0][:headers]["Authorization"]
  ensure
    keys.each do |key|
      if saved[key].nil?
        ENV.delete(key)
      else
        ENV[key] = saved[key]
      end
    end
  end
end
