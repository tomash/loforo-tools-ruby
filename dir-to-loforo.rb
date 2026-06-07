# frozen_string_literal: true

require_relative "lib/loforo"

begin
  result = Loforo::DirUploader.new(ARGV[0], client: Loforo.client_from_env).run
  if result.uploaded.any?
    Loforo.ntfy_notifier_from_env&.notify_uploads(result.uploaded)
  end
  if result.processed_any?
    Loforo.email_notifier_from_env&.notify_run(result)
  end
rescue ArgumentError => e
  abort e.message
end
