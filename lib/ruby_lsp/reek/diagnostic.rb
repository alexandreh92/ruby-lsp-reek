# frozen_string_literal: true

module RubyLsp
  module Reek
    # Translates a Reek smell warning into the LSP diagnostic that Ruby LSP
    # reports back to the editor.
    module Diagnostic
      # @param warning [Reek::SmellWarning] The warning to convert to a diagnostic.
      # @return [RubyLsp::Interface::Diagnostic] The diagnostic.
      def self.from_warning(warning, source)
        line = warning.lines.first - 1
        line_source = source.lines[line]&.chomp || ""

        start_character = line_source.index(/\S/) || 0
        end_character = line_source.rstrip.length

        ::RubyLsp::Interface::Diagnostic.new(
          range: ::RubyLsp::Interface::Range.new(
            start: ::RubyLsp::Interface::Position.new(
              line: line,
              character: start_character
            ),
            end: ::RubyLsp::Interface::Position.new(
              line: line,
              character: end_character
            )
          ),
          severity: Constant::DiagnosticSeverity::WARNING,
          code: warning.smell_type,
          code_description: ::RubyLsp::Interface::CodeDescription.new(href: warning.explanatory_link),
          source: "Reek",
          message: warning.message
        )
      end
    end
  end
end
