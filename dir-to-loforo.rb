# frozen_string_literal: true

require_relative "lib/loforo"

begin
  uploaded = Loforo::DirUploader.new(ARGV[0], client: Loforo.client_from_env).run
  if uploaded.any?
    notifier = Loforo.ntfy_notifier_from_env
    notifier&.notify_uploads(uploaded)
  end
rescue ArgumentError => e
  abort e.message
end
