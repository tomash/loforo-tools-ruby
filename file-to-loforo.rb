# frozen_string_literal: true

require_relative "lib/loforo"

begin
  Loforo::FileUploader.new(ARGV[0], client: Loforo.client_from_env).run
rescue ArgumentError => e
  abort e.message
end
