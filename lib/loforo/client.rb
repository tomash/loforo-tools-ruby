# frozen_string_literal: true

require "http"

module Loforo
  class Client
    DEFAULT_ENDPOINT = "https://loforo.com/api/post/create"

    def initialize(api_key:, endpoint: DEFAULT_ENDPOINT, http: HTTP)
      @api_key = api_key
      @endpoint = endpoint
      @http = http
    end

    def post_file(file_path, content: "", title: "", status: "0")
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
