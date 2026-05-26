# frozen_string_literal: true

require_relative "lib/loforo"

begin
  Loforo::DirUploader.new(ARGV[0], client: Loforo.client_from_env).run
rescue ArgumentError => e
  abort e.message
end
