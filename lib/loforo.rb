# frozen_string_literal: true

require "dotenv"

require_relative "loforo/client"
require_relative "loforo/dir_uploader"
require_relative "loforo/file_uploader"
require_relative "loforo/ntfy_notifier"
require_relative "loforo/email_notifier"

module Loforo
  module_function

  PROJECT_ROOT = File.expand_path("..", __dir__).freeze
  DEFAULT_ENV_FILE = File.join(PROJECT_ROOT, ".env").freeze

  def load_env_file(path = DEFAULT_ENV_FILE)
    Dotenv.load(path)
  end

  def client_from_env(endpoint: Client::DEFAULT_ENDPOINT)
    api_key = ENV.fetch("LOFORO_API_KEY") do
      raise ArgumentError, "LOFORO_API_KEY environment variable is required"
    end
    Client.new(api_key: api_key, endpoint: endpoint)
  end

  def ntfy_notifier_from_env(**)
    NtfyNotifier.from_env(**)
  end

  def email_notifier_from_env(**)
    EmailNotifier.from_env(**)
  end
end

Loforo.load_env_file
