# frozen_string_literal: true

class ProActiveStorage::BaseJob < ActiveJob::Base
  queue_as { ProActiveStorage.queue }
end
