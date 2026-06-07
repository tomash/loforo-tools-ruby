# frozen_string_literal: true

require_relative "loforo/client"
require_relative "loforo/dir_uploader"
require_relative "loforo/file_uploader"
require_relative "loforo/ntfy_notifier"

module Loforo
  module_function

  def client_from_env(endpoint: Client::DEFAULT_ENDPOINT)
    api_key = ENV.fetch("LOFORO_API_KEY") do
      raise ArgumentError, "LOFORO_API_KEY environment variable is required"
    end
    Client.new(api_key: api_key, endpoint: endpoint)
  end

  def ntfy_notifier_from_env(**)
    NtfyNotifier.from_env(**)
  end
end
