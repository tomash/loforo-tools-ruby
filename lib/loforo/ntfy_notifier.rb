# frozen_string_literal: true

require "http"

module Loforo
  class NtfyNotifier
    DEFAULT_SERVER = "https://ntfy.sh"
    DEFAULT_TITLE = "Loforo upload"
    TIMEOUT_OPTIONS = { connect: 5, read: 30 }.freeze

    def initialize(topic:, server: DEFAULT_SERVER, title: DEFAULT_TITLE, token: nil,
                   http: HTTP.timeout(TIMEOUT_OPTIONS))
      @topic = topic
      @server = server
      @title = title
      @token = token
      @http = http
    end

    def self.from_env(http: HTTP.timeout(TIMEOUT_OPTIONS))
      topic = ENV["NTFY_TOPIC"]&.strip
      return nil if topic.nil? || topic.empty?

      new(
        topic: topic,
        server: ENV.fetch("NTFY_SERVER", DEFAULT_SERVER),
        title: ENV.fetch("NTFY_TITLE", DEFAULT_TITLE),
        token: ENV["NTFY_TOKEN"],
        http: http
      )
    end

    def notify_uploads(entries)
      filenames = entries.map { |entry| entry["filename"] }
      count = filenames.size
      noun = count == 1 ? "file" : "files"
      body = "#{count} #{noun} uploaded:\n#{filenames.join("\n")}"
      deliver(body)
    end

    def deliver(message)
      headers = { "Title" => @title }
      headers["Authorization"] = "Bearer #{@token}" if @token && !@token.empty?
      @http.post(topic_url, body: message, headers: headers)
    end

    private

    def topic_url
      "#{@server.chomp('/')}/#{@topic}"
    end
  end
end
