# frozen_string_literal: true

require "rails"
require "pro_active_storage"

require "pro_active_storage/previewer/poppler_pdf_previewer"
require "pro_active_storage/previewer/mupdf_previewer"
require "pro_active_storage/previewer/video_previewer"

require "pro_active_storage/analyzer/image_analyzer"
require "pro_active_storage/analyzer/video_analyzer"

require "pro_active_storage/reflection"

module ProActiveStorage
  class Engine < Rails::Engine # :nodoc:
    isolate_namespace ProActiveStorage

    config.pro_active_storage = ActiveSupport::OrderedOptions.new
    config.pro_active_storage.previewers = [ ProActiveStorage::Previewer::PopplerPDFPreviewer, ProActiveStorage::Previewer::MuPDFPreviewer, ProActiveStorage::Previewer::VideoPreviewer ]
    config.pro_active_storage.analyzers = [ ProActiveStorage::Analyzer::ImageAnalyzer, ProActiveStorage::Analyzer::VideoAnalyzer ]
    config.pro_active_storage.paths = ActiveSupport::OrderedOptions.new

    config.pro_active_storage.variable_content_types = %w(
      image/png
      image/gif
      image/jpg
      image/jpeg
      image/vnd.adobe.photoshop
      image/vnd.microsoft.icon
    )

    config.pro_active_storage.content_types_to_serve_as_binary = %w(
      text/html
      text/javascript
      image/svg+xml
      application/postscript
      application/x-shockwave-flash
      text/xml
      application/xml
      application/xhtml+xml
    )

    config.eager_load_namespaces << ProActiveStorage

    initializer "pro_active_storage.configs" do
      config.after_initialize do |app|
        ProActiveStorage.logger             = app.config.pro_active_storage.logger || Rails.logger
        ProActiveStorage.queue              = app.config.pro_active_storage.queue
        ProActiveStorage.variant_processor  = app.config.pro_active_storage.variant_processor || :mini_magick
        ProActiveStorage.previewers         = app.config.pro_active_storage.previewers || []
        ProActiveStorage.analyzers          = app.config.pro_active_storage.analyzers || []
        ProActiveStorage.paths              = app.config.pro_active_storage.paths || {}
        ProActiveStorage.default_prefix = app.config.pro_active_storage.default_prefix || ":hash"

        ProActiveStorage.variable_content_types = app.config.pro_active_storage.variable_content_types || []
        ProActiveStorage.content_types_to_serve_as_binary = app.config.pro_active_storage.content_types_to_serve_as_binary || []
        ProActiveStorage.service_urls_expire_in = app.config.pro_active_storage.service_urls_expire_in || 5.minutes
      end
    end

    initializer "pro_active_storage.attached" do
      require "pro_active_storage/attached"

      ActiveSupport.on_load(:active_record) do
        extend ProActiveStorage::Attached::Macros
      end
    end

    initializer "pro_active_storage.verifier" do
      config.after_initialize do |app|
        ProActiveStorage.verifier = app.message_verifier("ProActiveStorage")
      end
    end

    initializer "pro_active_storage.services" do
      ActiveSupport.on_load(:pro_active_storage_blob) do
        if config_choice = Rails.configuration.pro_active_storage.service
          configs = Rails.configuration.pro_active_storage.service_configurations ||= begin
            config_file = Pathname.new(Rails.root.join("config/storage.yml"))
            raise("Couldn't find Pro Active Storage configuration in #{config_file}") unless config_file.exist?

            require "yaml"
            require "erb"

            YAML.load(ERB.new(config_file.read).result) || {}
          rescue Psych::SyntaxError => e
            raise "YAML syntax error occurred while parsing #{config_file}. " \
                  "Please note that YAML must be consistently indented using spaces. Tabs are not allowed. " \
                  "Error: #{e.message}"
          end

          ProActiveStorage::Blob.service =
            begin
              ProActiveStorage::Service.configure config_choice, configs
            rescue => e
              raise e, "Cannot load `Rails.config.pro_active_storage.service`:\n#{e.message}", e.backtrace
            end
        end
      end
    end

    initializer "pro_active_storage.reflection" do
      ActiveSupport.on_load(:active_record) do
        include Reflection::ActiveRecordExtensions
        ActiveRecord::Reflection.singleton_class.prepend(Reflection::ReflectionExtension)
      end
    end
  end
end
