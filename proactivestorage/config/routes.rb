# frozen_string_literal: true

Rails.application.routes.draw do
  get "/rails/pro_active_storage/blobs/:signed_id/*filename" => "pro_active_storage/blobs#show", as: :rails_service_blob

  direct :rails_blob do |blob, options|
    route_for(:rails_service_blob, blob.signed_id, blob.filename, options)
  end

  resolve("ProActiveStorage::Blob")       { |blob, options| route_for(:rails_blob, blob, options) }
  resolve("ProActiveStorage::Attachment") { |attachment, options| route_for(:rails_blob, attachment.blob, options) }


  get "/rails/pro_active_storage/representations/:signed_blob_id/:variation_key/*filename" => "pro_active_storage/representations#show", as: :rails_blob_representation

  direct :rails_representation do |representation, options|
    signed_blob_id = representation.blob.signed_id
    variation_key  = representation.variation.key
    filename       = representation.blob.filename

    route_for(:rails_blob_representation, signed_blob_id, variation_key, filename, options)
  end

  resolve("ProActiveStorage::Variant") { |variant, options| route_for(:rails_representation, variant, options) }
  resolve("ProActiveStorage::Preview") { |preview, options| route_for(:rails_representation, preview, options) }


  get  "/rails/pro_active_storage/disk/:encoded_key/*filename" => "pro_active_storage/disk#show", as: :rails_disk_service
  put  "/rails/pro_active_storage/disk/:encoded_token" => "pro_active_storage/disk#update", as: :update_rails_disk_service
  post "/rails/pro_active_storage/direct_uploads" => "pro_active_storage/direct_uploads#create", as: :rails_direct_uploads
end
