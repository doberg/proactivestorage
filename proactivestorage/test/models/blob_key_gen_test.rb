# frozen_string_literal: true

require "test_helper"
require "database/setup"

class ProActiveStorage::BlobKeyGenTest < ActiveSupport::TestCase
  setup do
    @blob = create_blob(filename: "original.txt")
  end

  teardown { ProActiveStorage::Blob.all.each(&:purge) }

  test "generate blob key according to blob prefix" do
    @blob.prefix = ":environment/:namespace/system/:extension/:hash/:filename.:extension"

    key = ProActiveStorage::BlobKeyGen.new(@blob).generate

    assert_match /system\/txt\/[a-zA-Z0-9]+\/original\.txt/, key
  end

  test "with invalid token it raises error" do
    @blob.prefix = "system/:invalid_key"

    error = assert_raises ProActiveStorage::InvalidPrefixOptionError do
      ProActiveStorage::BlobKeyGen.new(@blob).generate
    end

    assert_equal "Invalid option for prefix: :invalid_key", error.message
  end
end
