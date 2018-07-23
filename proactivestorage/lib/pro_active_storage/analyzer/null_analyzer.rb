# frozen_string_literal: true

module ProActiveStorage
  class Analyzer::NullAnalyzer < Analyzer # :nodoc:
    def self.accept?(blob)
      true
    end

    def metadata
      {}
    end
  end
end
