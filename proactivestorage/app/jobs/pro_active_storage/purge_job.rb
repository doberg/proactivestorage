# frozen_string_literal: true

# Provides asynchronous purging of ProActiveStorage::Blob records via ProActiveStorage::Blob#purge_later.
class ProActiveStorage::PurgeJob < ProActiveStorage::BaseJob
  # FIXME: Limit this to a custom ProActiveStorage error
  retry_on StandardError

  def perform(blob)
    blob.purge
  end
end
