# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/status_operations'

# Private is a private_constant inside Git::Repository::StatusOperations.
# Its module_function helpers are tested directly via module_eval, which
# evaluates the constant reference inside the module's own constant-resolution
# scope where private constants are accessible.

RSpec.describe Git::Repository::StatusOperations do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  let(:ls_files_command) { instance_double(Git::Commands::LsFiles) }

  before do
    allow(Git::Commands::LsFiles).to receive(:new).with(execution_context).and_return(ls_files_command)
  end

  describe '#ls_files' do
    subject(:result) { described_instance.ls_files(location) }

    let(:location) { nil }

    context 'when no location is given (nil)' do
      it "delegates to LsFiles#call with '.' as the default location" do
        expect(ls_files_command).to receive(:call).with('.', stage: true).and_return(command_result(''))
        result
      end

      it 'returns an empty hash when git output is empty' do
        allow(ls_files_command).to receive(:call).with('.', stage: true).and_return(command_result(''))
        expect(result).to eq({})
      end
    end

    context 'when an explicit location is given' do
      let(:location) { 'lib/' }

      it 'delegates to LsFiles#call with the given location' do
        expect(ls_files_command).to receive(:call).with('lib/', stage: true).and_return(command_result(''))
        result
      end
    end

    context 'when stdout contains a plain (unquoted) file path' do
      let(:sha) { 'abc1234567890abcdef1234567890abcdef12345678' }
      let(:stdout) { "100644 #{sha} 0\tREADME.md\n" }

      before do
        allow(ls_files_command).to receive(:call).with('.', stage: true).and_return(command_result(stdout))
      end

      it 'returns a hash keyed by the file path' do
        expect(result.keys).to eq(['README.md'])
      end

      it 'includes the correct index metadata for the file' do
        expect(result['README.md']).to eq(path: 'README.md', mode_index: '100644', sha_index: sha, stage: '0')
      end
    end

    context 'when stdout contains a git-quoted (escaped) file path' do
      # Git octal-escapes non-ASCII paths. U+00B5 µ encodes as UTF-8 bytes \302\265.
      let(:sha) { 'abc1234567890abcdef1234567890abcdef12345678' }
      let(:stdout) { "100644 #{sha} 0\t\"\\302\\265.txt\"\n" }

      before do
        allow(ls_files_command).to receive(:call).with('.', stage: true).and_return(command_result(stdout))
      end

      it 'returns the unescaped path as the hash key' do
        expect(result.keys).to eq(['µ.txt'])
      end

      it 'stores the unescaped path in the :path field' do
        expect(result['µ.txt'][:path]).to eq('µ.txt')
      end
    end

    context 'when stdout contains multiple files' do
      let(:sha_a) { 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }
      let(:sha_b) { 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' }
      let(:stdout) do
        "100644 #{sha_a} 0\ta.rb\n" \
          "100755 #{sha_b} 0\tb.sh\n"
      end

      before do
        allow(ls_files_command).to receive(:call).with('.', stage: true).and_return(command_result(stdout))
      end

      it 'returns an entry for each file' do
        expect(result.keys).to contain_exactly('a.rb', 'b.sh')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Private helper tests
  #
  # Private is a private_constant; module_eval evaluates the constant reference
  # inside StatusOperations' scope where it is accessible.
  # ---------------------------------------------------------------------------

  let(:private_mod) { described_class.module_eval('Private', __FILE__, __LINE__) }

  describe 'Private.split_status_line' do
    context 'with a normal tab-delimited ls-files line' do
      it 'returns a two-element array with the info part and the filename' do
        expect(private_mod.split_status_line("100644 abc123 0\tfile.rb")).to eq(['100644 abc123 0', 'file.rb'])
      end
    end

    context 'with a line whose filename is git-quoted' do
      it 'returns the info part and the unescaped filename' do
        result = private_mod.split_status_line("100644 abc123 0\t\"\\302\\265.txt\"")
        expect(result).to eq(['100644 abc123 0', 'µ.txt'])
      end
    end

    context 'with an empty string (no tab delimiters)' do
      it 'returns an empty array without raising' do
        expect(private_mod.split_status_line('')).to eq([])
      end
    end
  end

  describe 'Private.unescape_quoted_path' do
    context 'with an unquoted plain path' do
      it 'returns the path unchanged' do
        expect(private_mod.unescape_quoted_path('file.rb')).to eq('file.rb')
      end
    end

    context 'with a properly git-quoted path (surrounded by double-quotes)' do
      it 'strips the surrounding double-quotes and unescapes octal sequences' do
        expect(private_mod.unescape_quoted_path('"\\302\\265.txt"')).to eq('µ.txt')
      end
    end

    context 'with a path that starts with a double-quote but does not end with one' do
      it 'returns the path unchanged' do
        expect(private_mod.unescape_quoted_path('"partial-quote')).to eq('"partial-quote')
      end
    end
  end
end
