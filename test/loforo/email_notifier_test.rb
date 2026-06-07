# frozen_string_literal: true

require "test_helper"

class LoforoEmailNotifierTest < Minitest::Test
  def test_format_run_report_lists_uploaded_and_failed
    result = Loforo::DirUploader::RunResult.new(
      uploaded: [{ "filename" => "a.jpg", "uploaded_at" => "2026-01-01T00:00:00Z" }],
      failures: [{ "filename" => "bad.png", "status" => "500 Error" }]
    )
    body = Loforo::EmailNotifier.new(from: "a@b", to: "c@d", mailer: fake_mailer).format_run_report(result)

    assert_includes body, "Uploaded (1):"
    assert_includes body, "  a.jpg — 2026-01-01T00:00:00Z"
    assert_includes body, "Failed (1):"
    assert_includes body, "  bad.png — 500 Error"
  end

  def test_format_run_report_shows_none_sections_when_empty
    result = Loforo::DirUploader::RunResult.new(uploaded: [], failures: [])
    body = Loforo::EmailNotifier.new(from: "a@b", to: "c@d", mailer: fake_mailer).format_run_report(result)

    assert_includes body, "Uploaded: none"
    assert_includes body, "Failed: none"
  end

  def test_notify_run_delivers_with_dynamic_subject
    calls = []
    mailer = Object.new
    mailer.define_singleton_method(:deliver) { |**kwargs| calls << kwargs }

    result = Loforo::DirUploader::RunResult.new(
      uploaded: [{ "filename" => "a.jpg", "uploaded_at" => "2026-01-01T00:00:00Z" }],
      failures: [{ "filename" => "x.gif", "status" => "timeout" }]
    )
    Loforo::EmailNotifier.new(
      from: "cron@example.test",
      to: ["me@example.test"],
      subject: "Loforo",
      mailer: mailer
    ).notify_run(result)

    assert_equal 1, calls.size
    assert_equal "cron@example.test", calls[0][:from]
    assert_equal ["me@example.test"], calls[0][:to]
    assert_equal "Loforo: 1 uploaded, 1 failed", calls[0][:subject]
    assert_includes calls[0][:body], "a.jpg"
    assert_includes calls[0][:body], "x.gif"
  end

  def test_from_env_returns_nil_without_email_to
    saved = save_env(%w[EMAIL_FROM EMAIL_TO SMTP_HOST])
    ENV["EMAIL_FROM"] = "a@b"
    ENV.delete("EMAIL_TO")
    ENV["SMTP_HOST"] = "smtp.example.test"

    assert_nil Loforo::EmailNotifier.from_env(mailer: fake_mailer)
  ensure
    restore_env(saved)
  end

  def test_from_env_returns_nil_without_smtp_host
    saved = save_env(%w[EMAIL_FROM EMAIL_TO SMTP_HOST])
    ENV["EMAIL_FROM"] = "a@b"
    ENV["EMAIL_TO"] = "c@d"
    ENV.delete("SMTP_HOST")

    assert_nil Loforo::EmailNotifier.from_env
  ensure
    restore_env(saved)
  end

  def test_from_env_splits_comma_separated_recipients
    saved = save_env(%w[EMAIL_FROM EMAIL_TO SMTP_HOST])
    ENV["EMAIL_FROM"] = "cron@example.test"
    ENV["EMAIL_TO"] = "a@b, c@d"
    ENV["SMTP_HOST"] = "smtp.example.test"

    calls = []
    mailer = Object.new
    mailer.define_singleton_method(:deliver) { |**kwargs| calls << kwargs }
    Loforo::EmailNotifier.from_env(mailer: mailer).deliver("ping")

    assert_equal %w[a@b c@d], calls[0][:to]
  ensure
    restore_env(saved)
  end

  def test_smtp_mailer_builds_plaintext_message
    calls = []
    fake_smtp = Object.new
    fake_smtp.define_singleton_method(:authenticate) { |*_args| }
    fake_smtp.define_singleton_method(:send_message) do |message, from, to|
      calls << { message: message, from: from, to: to }
    end
    smtp_start = proc { |&block| block.call(fake_smtp) }

    Loforo::SmtpMailer.new(
      host: "smtp.example.test",
      port: 587,
      user: "u",
      password: "p",
      smtp_start: smtp_start
    ).deliver(
      from: "from@example.test",
      to: ["to@example.test"],
      subject: "Hi",
      body: "Body line"
    )

    assert_equal "from@example.test", calls[0][:from]
    assert_equal ["to@example.test"], calls[0][:to]
    assert_includes calls[0][:message], "Subject: Hi"
    assert_includes calls[0][:message], "Body line"
  end

  private

  def fake_mailer
    Object.new.tap do |mailer|
      mailer.define_singleton_method(:deliver) { |**_kwargs| }
    end
  end

  def save_env(keys)
    keys.to_h { |key| [key, ENV[key]] }
  end

  def restore_env(saved)
    saved.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end
end
