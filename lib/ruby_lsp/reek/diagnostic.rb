# frozen_string_literal: true

module RubyLsp
  module Reek
    # Translates a Reek smell warning into the LSP diagnostic that Ruby LSP
    # reports back to the editor.
    module Diagnostic
      # @param warning [Reek::SmellWarning] The warning to convert to a diagnostic.
      # @return [RubyLsp::Interface::Diagnostic] The diagnostic.
      def self.from_warning(warning)
        lines = warning.lines
        ::RubyLsp::Interface::Diagnostic.new(
          range: ::RubyLsp::Interface::Range.new(
            start: ::RubyLsp::Interface::Position.new(
              line: lines.first - 1,
              character: 0
            ),
            end: ::RubyLsp::Interface::Position.new(
              line: lines.last - 1,
              character: 0
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
