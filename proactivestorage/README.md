# DEPRECATED in favor of Rails >= 6.1.0



# Pro Active Storage

Pro Active Storage makes it simple to upload and reference files in cloud services like [Amazon S3](https://aws.amazon.com/s3/), [Google Cloud Storage](https://cloud.google.com/storage/docs/), or [Microsoft Azure Storage](https://azure.microsoft.com/en-us/services/storage/), and attach those files to Active Records. Supports having one main service and mirrors in other services for redundancy. It also provides a disk service for testing or local deployments, but the focus is on cloud storage.

Files can be uploaded from the server to the cloud or directly from the client to the cloud.

Image files can furthermore be transformed using on-demand variants for quality, aspect ratio, size, or any other [MiniMagick](https://github.com/minimagick/minimagick) or [Vips](http://www.rubydoc.info/gems/ruby-vips/Vips/Image) supported transformation.

## Compared to other storage solutions

A key difference to how Pro Active Storage works compared to other attachment solutions in Rails is through the use of built-in [Blob](https://github.com/rails/rails/blob/master/proactivestorage/app/models/pro_active_storage/blob.rb) and [Attachment](https://github.com/rails/rails/blob/master/proactivestorage/app/models/pro_active_storage/attachment.rb) models (backed by Active Record). This means existing application models do not need to be modified with additional columns to associate with files. Pro Active Storage uses polymorphic associations via the `Attachment` join model, which then connects to the actual `Blob`.

`Blob` models store attachment metadata (filename, content-type, etc.), and their identifier key in the storage service. Blob models do not store the actual binary data. They are intended to be immutable in spirit. One file, one blob. You can associate the same blob with multiple application models as well. And if you want to do transformations of a given `Blob`, the idea is that you'll simply create a new one, rather than attempt to mutate the existing one (though of course you can delete the previous version later if you don't need it).

## Installation



In your Gemfile
change `gem 'rails', '5.2.0'` to `gem 'rails', '5.2.0', :git => 'https://github.com/doberg/proactivestorage', :submodules => true`

Then add the following line to your Gemfile:
`gem 'proactivestorage', :git => 'https://github.com/doberg/proactivestorage', :glob => 'proactivestorage/*.gemspec'`

After `bundle update` && `bundle install`

After you bundle install you will need to make a few adjustments to get pro_active_storage working as expected.

Then in each of your config/environments files. Change `config.active_storage.service` to   `config.pro_active_storage.service`

In app/assets/javascripts/application.js change `//= require activestorage` to `//= require proactivestorage`

Run `rails pro_active_storage:install` to copy over pro_active_storage migrations.

Then `bin/rail db:migrate`.

Don't forget to create a `config/storage.yml` file like so:

```
test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

# local:
#   service: Disk
#   root: <%= Rails.root.join("storage") %>

# Use rails credentials:edit to set the AWS secrets (as aws:access_key_id|secret_access_key)
#amazon:
#  service: S3
#  access_key_id:
#  secret_access_key:
#  region: us-west-2
#  bucket: "test-app"

# Remember not to checkin your GCS keyfile to a repository
# google:
#   service: GCS
#   project: your_project
#   credentials: <%= Rails.root.join("path/to/gcs.keyfile") %>
#   bucket: your_own_bucket

# Use rails credentials:edit to set the Azure Storage secret (as azure_storage:storage_access_key)
# microsoft:
#   service: AzureStorage
#   storage_account_name: your_account_name
#   storage_access_key: <%= Rails.application.credentials.dig(:azure_storage, :storage_access_key) %>
#   container: your_container_name

# mirror:
#   service: Mirror
#   primary: local
#   mirrors: [ amazon, google, microsoft ]

```

## Examples

One attachment:

```ruby
class User < ApplicationRecord
  # Associates an attachment and a blob. When the user is destroyed they are
  # purged by default (models destroyed, and resource files deleted).
  #   # :environment is the Rails.env
  #   # :namespace is the Rails application name
  has_one_attached :avatar, prefix: ":environment/:namespace/avatars/:hash/:filename.:extension"
end

# Attach an avatar to the user.
user.avatar.attach(io: File.open("/path/to/face.jpg"), filename: "face.jpg", content_type: "image/jpg")

# Does the user have an avatar?
user.avatar.attached? # => true

# Synchronously destroy the avatar and actual resource files.
user.avatar.purge

# Destroy the associated models and actual resource files async, via Active Job.
user.avatar.purge_later

# Does the user have an avatar?
user.avatar.attached? # => false

# Generate a permanent URL for the blob that points to the application.
# Upon access, a redirect to the actual service endpoint is returned.
# This indirection decouples the public URL from the actual one, and
# allows for example mirroring attachments in different services for
# high-availability. The redirection has an HTTP expiration of 5 min.
url_for(user.avatar)

class AvatarsController < ApplicationController
  def update
    # params[:avatar] contains a ActionDispatch::Http::UploadedFile object
    Current.user.avatar.attach(params.require(:avatar))
    redirect_to Current.user
  end
end
```

Many attachments:

```ruby
class Message < ApplicationRecord
  #   # :environment is the Rails.env
  #   # :namespace is the Rails application name
  has_many_attached :images, prefix: ":environment/:namespace/images/:hash/:filename.:extension"
end
```

```erb
<%= form_with model: @message, local: true do |form| %>
  <%= form.text_field :title, placeholder: "Title" %><br>
  <%= form.text_area :content %><br><br>

  <%= form.file_field :images, multiple: true %><br>
  <%= form.submit %>
<% end %>
```

```ruby
class MessagesController < ApplicationController
  def index
    # Use the built-in with_attached_images scope to avoid N+1
    @messages = Message.all.with_attached_images
  end

  def create
    message = Message.create! params.require(:message).permit(:title, :content)
    message.images.attach(params[:message][:images])
    redirect_to message
  end

  def show
    @message = Message.find(params[:id])
  end
end
```

Variation of image attachment:

```erb
<%# Hitting the variant URL will lazy transform the original blob and then redirect to its new service location %>
<%= image_tag user.avatar.variant(resize_to_fit: [100, 100]) %>
```

## Direct uploads

Pro Active Storage, with its included JavaScript library, supports uploading directly from the client to the cloud.

### Direct upload installation

1. Include `proactivestorage.js` in your application's JavaScript bundle.

    Using the asset pipeline:
    ```js
    //= require proactivestorage
    ```
    Using the npm package:
    ```js
    import * as ProActiveStorage from "proactivestorage"
    ProActiveStorage.start()
    ```
2. Annotate file inputs with the direct upload URL.

    ```ruby
    <%= form.file_field :attachments, multiple: true, direct_upload: true %>
    ```
3. That's it! Uploads begin upon form submission.

### Direct upload JavaScript events

| Event name | Event target | Event data (`event.detail`) | Description |
| --- | --- | --- | --- |
| `direct-uploads:start` | `<form>` | None | A form containing files for direct upload fields was submitted. |
| `direct-upload:initialize` | `<input>` | `{id, file}` | Dispatched for every file after form submission. |
| `direct-upload:start` | `<input>` | `{id, file}` | A direct upload is starting. |
| `direct-upload:before-blob-request` | `<input>` | `{id, file, xhr}` | Before making a request to your application for direct upload metadata. |
| `direct-upload:before-storage-request` | `<input>` | `{id, file, xhr}` | Before making a request to store a file. |
| `direct-upload:progress` | `<input>` | `{id, file, progress}` | As requests to store files progress. |
| `direct-upload:error` | `<input>` | `{id, file, error}` | An error occurred. An `alert` will display unless this event is canceled. |
| `direct-upload:end` | `<input>` | `{id, file}` | A direct upload has ended. |
| `direct-uploads:end` | `<form>` | None | All direct uploads have ended. |

## License

Pro Active Storage is released under the [MIT License](https://opensource.org/licenses/MIT).

## Support

API documentation is at:

* http://api.rubyonrails.org

Bug reports for the Ruby on Rails project can be filed here:

* https://github.com/rails/rails/issues

Feature requests should be discussed on the rails-core mailing list here:

* https://groups.google.com/forum/?fromgroups#!forum/rubyonrails-core
