# frozen_string_literal: true

require "net/smtp"

module Loforo
  class EmailNotifier
    DEFAULT_SUBJECT = "Loforo dir upload"

    def initialize(from:, to:, subject: DEFAULT_SUBJECT, mailer:)
      @from = from
      @to = Array(to)
      @subject = subject
      @mailer = mailer
    end

    def self.from_env(mailer: default_mailer_from_env)
      return nil if mailer.nil?

      from = ENV["EMAIL_FROM"]&.strip
      to = ENV["EMAIL_TO"]&.strip
      return nil if from.nil? || from.empty? || to.nil? || to.empty?

      subject = ENV.fetch("EMAIL_SUBJECT", DEFAULT_SUBJECT)
      recipients = to.split(/\s*,\s*/)

      new(from: from, to: recipients, subject: subject, mailer: mailer)
    end

    def self.default_mailer_from_env
      host = ENV["SMTP_HOST"]&.strip
      return nil if host.nil? || host.empty?

      port = Integer(ENV.fetch("SMTP_PORT", "587"))
      user = ENV["SMTP_USER"]&.strip
      password = ENV["SMTP_PASSWORD"]
      tls = ENV.fetch("SMTP_TLS", "true") != "false"

      SmtpMailer.new(host: host, port: port, user: user, password: password, tls: tls)
    end

    def notify_run(result)
      body = format_run_report(result)
      subject = run_subject(result)
      @mailer.deliver(from: @from, to: @to, subject: subject, body: body)
    end

    def format_run_report(result)
      lines = ["Dir upload finished.", ""]
      lines.concat(format_uploaded_section(result.uploaded))
      lines << "" unless result.uploaded.empty?
      lines.concat(format_failed_section(result.failures))
      lines.join("\n")
    end

    def deliver(body, subject: @subject)
      @mailer.deliver(from: @from, to: @to, subject: subject, body: body)
    end

    private

    def run_subject(result)
      parts = []
      parts << "#{result.uploaded.size} uploaded" unless result.uploaded.empty?
      parts << "#{result.failures.size} failed" unless result.failures.empty?
      return @subject if parts.empty?

      "#{@subject}: #{parts.join(", ")}"
    end

    def format_uploaded_section(uploaded)
      return ["Uploaded: none"] if uploaded.empty?

      header = "Uploaded (#{uploaded.size}):"
      entries = uploaded.map do |entry|
        "  #{entry["filename"]} — #{entry["uploaded_at"]}"
      end
      [header, *entries]
    end

    def format_failed_section(failures)
      return ["Failed: none"] if failures.empty?

      header = "Failed (#{failures.size}):"
      entries = failures.map do |entry|
        "  #{entry["filename"]} — #{entry["status"]}"
      end
      [header, *entries]
    end
  end

  class SmtpMailer
    def initialize(host:, port:, user: nil, password: nil, tls: true, smtp_start: nil)
      @host = host
      @port = port
      @user = user
      @password = password
      @tls = tls
      @smtp_start = smtp_start
    end

    def deliver(from:, to:, subject:, body:)
      message = build_message(from: from, to: to, subject: subject, body: body)
      recipients = Array(to)

      open_smtp do |smtp|
        smtp.authenticate(@user, @password) if authenticate?
        smtp.send_message(message, from, recipients)
      end
    end

    private

    def authenticate?
      @user && !@user.empty?
    end

    def open_smtp(&block)
      if @smtp_start
        @smtp_start.call(&block)
      else
        Net::SMTP.start(@host, @port, tls: @tls, &block)
      end
    end

    def build_message(from:, to:, subject:, body:)
      to_header = Array(to).join(", ")
      <<~MESSAGE.gsub("\n", "\r\n")
        From: #{from}
        To: #{to_header}
        Subject: #{subject}
        Content-Type: text/plain; charset=UTF-8

        #{body}
      MESSAGE
    end
  end
end
