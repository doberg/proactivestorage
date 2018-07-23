# frozen_string_literal: true

require_relative "gem_version"

module ProActiveStorage
  # Returns the version of the currently loaded ProActiveStorage as a <tt>Gem::Version</tt>
  def self.version
    gem_version
  end
end
