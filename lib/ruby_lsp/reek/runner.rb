# frozen_string_literal: true

require "reek"
require_relative "diagnostic"

module RubyLsp
  module Reek
    # Implements Ruby LSP Formatter interface: specifically run_diagnostic
    class Runner
      include RubyLsp::Requests::Support::Formatter

      def initialize
        @config = ::Reek::Configuration::AppConfiguration.from_default_path
      end

      # We are not implementing this method, but it is required by the
      # interface. Reek is a linter, so there is nothing to format and the
      # source is handed back untouched.
      #
      # :reek:UtilityFunction { enabled: false } - the interface requires an
      # instance method, so it cannot depend on instance state.
      #
      # @param uri [URI::Generic] The URI of the document to format.
      # @param document [RubyLsp::RubyDocument] The document to format.
      # @return [String] The formatted document.
      def run_formatting(_uri, document)
        document.source
      end

      # @param uri [URI::Generic] The URI of the document to run diagnostics on.
      # @param document [RubyLsp::RubyDocument] The document to run diagnostics on.
      def run_diagnostic(uri, document)
        path = Pathname.new(uri.path)
        return [] if path_excluded?(path)

        # We lint the source as it currently stands in the editor, but Reek
        # resolves directory directives from the origin, so the origin has to
        # be set explicitly to the file on disk rather than defaulting to
        # "string".
        examiner = ::Reek::Examiner.new(
          ::Reek::Source::SourceCode.from(document.source, origin: path.to_s),
          configuration: config
        )
        examiner.smells.map { |smell| Diagnostic.from_warning(smell) }
      end

      private

      attr_reader :config

      def path_excluded?(path)
        path.ascend do |ascendant|
          break true if config.path_excluded?(ascendant)

          false
        end
      end
    end
  end
end
