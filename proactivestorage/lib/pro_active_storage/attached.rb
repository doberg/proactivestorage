# frozen_string_literal: true

require "action_dispatch"
require "action_dispatch/http/upload"
require "active_support/core_ext/module/delegation"

module ProActiveStorage
  # Abstract base class for the concrete ProActiveStorage::Attached::One and ProActiveStorage::Attached::Many
  # classes that both provide proxy access to the blob association for a record.
  class Attached
    attr_reader :name, :record, :dependent, :prefix

    def initialize(name, record, dependent:, prefix: nil)
      @name, @record, @dependent, @prefix = name, record, dependent, prefix
    end

    private
      def create_blob_from(attachable)
        case attachable
        when ProActiveStorage::Blob
          attachable
        when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
          ProActiveStorage::Blob.create_after_upload! \
            io: attachable.open,
            filename: attachable.original_filename,
            content_type: attachable.content_type,
            metadata: { prefix: prefix }
        when Hash
          ProActiveStorage::Blob.create_after_upload!(attachable)
        when String
          ProActiveStorage::Blob.find_signed(attachable)
        else
          nil
        end
      end
  end
end

require "pro_active_storage/attached/one"
require "pro_active_storage/attached/many"
require "pro_active_storage/attached/macros"
