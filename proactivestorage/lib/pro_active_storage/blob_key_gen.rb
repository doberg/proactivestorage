# frozen_string_literal: true

module ProActiveStorage
  # Generate the blob key according to blob prefix.
  #
  # Example
  #   blob.filename.to_s
  #   # => "example.png"
  #   blob.prefix
  #   # => ":environment/:namespace/avatars/:hash/:filename.:extension"
  #   # :environment is the Rails.env
  #   # :namespace is the Rails application name
  #   ProActiveStorage::BlobKeyGen.new(blob).generate
  #   # => "development/test_app/avatars/2vAjTGganF63Uri3TjBwunbM/example.png"
  class BlobKeyGen
    def initialize(blob)
      @blob   = blob
      @prefix = blob.prefix
    end

    def generate
      prefix.scan(/:\w+/).reduce(prefix) do |pattern, option|
        pattern.sub(option, convert_option(option))
      end
    end

    private
    attr_reader :blob, :prefix

    def convert_option(option)
      case option
      when ":environment"
        Rails.env
      when ":namespace"
        Rails.application.class.parent_name.downcase.underscore
      when ":hash"
        blob.class.generate_unique_secure_token
      when ":filename"
        blob.filename.base
      when ":extension"
        blob.filename.extension_without_delimiter
      else
        raise InvalidPrefixOptionError, "Invalid option for prefix: #{option}"
      end
    end
  end
end
