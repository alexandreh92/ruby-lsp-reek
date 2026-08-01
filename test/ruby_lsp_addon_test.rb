$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "bundler/setup"
require "minitest/autorun"
require "tmpdir"
require "ruby_lsp/internal"
require "ruby_lsp/test_helper"
require "pry"
require "ruby_lsp/reek/addon"

class RubyLspAddonTest < Minitest::Test
  include RubyLsp::TestHelper

  def setup
    @addon = RubyLsp::Reek::Addon.new
    super
  end

  def test_name
    assert_equal "Reek: Code smell detector for Ruby", @addon.name
  end

  def test_version
    assert_equal RubyLsp::Reek::VERSION, @addon.version
  end

  def test_diagnostic
    source = <<~RUBY
      def foo
        s = 'hello'
        puts s
      end
    RUBY
    with_server(source, "simple.rb") do |server, uri|
      server.process_message(
        id: 2,
        method: "textDocument/diagnostic",
        params: {
          textDocument: {
            uri:
          }
        }
      )

      result = pop_result(server)

      assert_equal "full", result.response.kind
      assert_equal 1, result.response.items.size
      item = result.response.items.first
      assert_equal({line: 1, character: 0}, item.range.start.to_hash)
      assert_equal({line: 1, character: 0}, item.range.end.to_hash)
      assert_equal RubyLsp::Constant::DiagnosticSeverity::WARNING, item.severity
      assert_equal "UncommunicativeVariableName", item.code
      assert_equal(
        "https://github.com/troessner/reek/blob/v#{Reek::Version::STRING}/docs/Uncommunicative-Variable-Name.md",
        item.code_description.href
      )
      assert_equal "Reek", item.source
      assert_equal("has the variable name 's'", item.message)
    end
  end

  # The source being linted comes from the editor buffer, but Reek resolves
  # directory directives from the origin of that source. The origin therefore
  # has to follow the file on disk, not the buffer.
  def test_diagnostic_resolves_directives_from_the_file_path
    Dir.mktmpdir do |tmpdir|
      workspace = File.realpath(tmpdir)
      models = File.join(workspace, "app", "models")
      FileUtils.mkdir_p(models)
      FileUtils.mkdir_p(File.join(workspace, "lib"))
      File.write(File.join(workspace, ".reek.yml"), <<~YAML)
        directories:
          "app/models":
            UncommunicativeVariableName:
              enabled: false
      YAML

      document = Struct.new(:source).new(<<~RUBY)
        def foo
          s = 'hello'
          puts s
        end
      RUBY

      Dir.chdir(workspace) do
        runner = RubyLsp::Reek::Runner.new

        assert_empty runner.run_diagnostic(
          URI::Generic.from_path(path: File.join(models, "user.rb")),
          document
        )

        assert_equal ["UncommunicativeVariableName"], runner.run_diagnostic(
          URI::Generic.from_path(path: File.join(workspace, "lib", "user.rb")),
          document
        ).map(&:code)
      end
    end
  end

  private

  # Overridden from RubyLsp::TestHelper so that we can override the linters
  # configuration and build a URI inside the workspace, which Reek needs in
  # order to resolve directory directives from .reek.yml.
  def with_server(source = nil, path = "fake.rb", **kwargs, &block)
    uri = URI::Generic.from_path(path: File.join(Dir.pwd, path))

    super(source, uri, **kwargs) do |server, server_uri|
      server.global_state.instance_variable_set(:@linters, ["reek"])
      block.call(server, server_uri)
    end
  end
end
