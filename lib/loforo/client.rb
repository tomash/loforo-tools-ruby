# frozen_string_literal: true

require "http"

module Loforo
  class Client
    DEFAULT_ENDPOINT = "https://loforo.com/api/post/create"

    TIMEOUT_OPTIONS = { connect: 5, read: 30 }.freeze

    def initialize(api_key:, endpoint: DEFAULT_ENDPOINT, http: HTTP.timeout(TIMEOUT_OPTIONS))
      @api_key = api_key
      @endpoint = endpoint
      @http = http
    end

    def post_file(file_path, content: "", title: "", status: "0")
      content = PostContent.resolve(file_path, content)
      @http.post(@endpoint, form: {
        key: @api_key,
        content: content,
        title: title,
        status: status,
        media: HTTP::FormData::File.new(file_path)
      })
    end
  end
end
