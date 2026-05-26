# frozen_string_literal: true

require_relative "lib/loforo"

LOFORO_API_KEY = ENV.fetch("LOFORO_API_KEY") do
  abort "LOFORO_API_KEY environment variable is required"
end

def post_file_to_loforo(file_path, endpoint, api_key)
  Loforo::Client.new(api_key: api_key, endpoint: endpoint).post_file(file_path)
end
