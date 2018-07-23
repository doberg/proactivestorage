# frozen_string_literal: true

# Provides asynchronous analysis of ProActiveStorage::Blob records via ProActiveStorage::Blob#analyze_later.
class ProActiveStorage::AnalyzeJob < ProActiveStorage::BaseJob
  def perform(blob)
    blob.analyze
  end
end
