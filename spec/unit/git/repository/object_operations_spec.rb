# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/object_operations'

# Integration-level coverage for Git::Repository::ObjectOperations is
# provided by spec/integration/git/repository/object_operations_spec.rb.
# The unit specs below cover the facade's own behavior: argument validation and
# delegation contract. Real git execution is covered by the integration spec.

RSpec.describe Git::Repository::ObjectOperations do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#cat_file_contents' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new)
        .with(execution_context)
        .and_return(raw_command)
    end

    context 'without a block' do
      subject(:result) { described_instance.cat_file_contents('HEAD:README.md') }

      let(:contents_result) { command_result("# Hello\n") }

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(contents_result)
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with the object and p: true' do
        expect(raw_command).to receive(:call).with('HEAD:README.md', p: true).and_return(contents_result)
        result
      end

      it 'returns the stdout of the command as a String' do
        allow(raw_command).to receive(:call).with('HEAD:README.md', p: true).and_return(contents_result)
        expect(result).to eq("# Hello\n")
      end
    end

    context 'with a block' do
      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call) do |_object, **kwargs|
          kwargs[:out].write('content')
          command_result('')
        end
        described_instance.cat_file_contents('HEAD') { |_f| nil }
      end

      it 'calls Git::Commands::CatFile::Raw#call with object, p: true, and an out: File' do
        expect(raw_command).to receive(:call)
          .with('HEAD', p: true, out: instance_of(File))
          .and_return(command_result(''))
        described_instance.cat_file_contents('HEAD') { |_f| nil }
      end

      it 'streams content to a tempfile and yields the rewound file' do
        allow(raw_command).to receive(:call) do |_object, **kwargs|
          kwargs[:out].write('streamed content')
          command_result('')
        end

        yielded = nil
        described_instance.cat_file_contents('HEAD') { |f| yielded = f.read }

        expect(yielded).to eq('streamed content')
      end

      it 'returns the value returned by the block' do
        allow(raw_command).to receive(:call) do |_object, **kwargs|
          kwargs[:out].write('')
          command_result('')
        end

        result = described_instance.cat_file_contents('HEAD') { |_f| :block_return_value }

        expect(result).to eq(:block_return_value)
      end
    end

    context 'when object starts with a hyphen' do
      subject(:result) { described_instance.cat_file_contents('--batch') }

      it 'raises ArgumentError before calling the command' do
        expect(Git::Commands::CatFile::Raw).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end
  end

  describe '#cat_file_size' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new)
        .with(execution_context)
        .and_return(raw_command)
    end

    context 'with a valid object name' do
      subject(:result) { described_instance.cat_file_size('HEAD') }

      let(:size_result) { command_result("265\n") }

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(size_result)
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with the object and s: true' do
        expect(raw_command).to receive(:call).with('HEAD', s: true).and_return(size_result)
        result
      end

      it 'returns the size as an Integer' do
        allow(raw_command).to receive(:call).with('HEAD', s: true).and_return(size_result)
        expect(result).to eq(265)
      end
    end

    context 'with a treeish path reference' do
      subject(:result) { described_instance.cat_file_size('HEAD:README.md') }

      let(:size_result) { command_result("14\n") }

      it 'forwards the treeish reference to Git::Commands::CatFile::Raw#call' do
        expect(raw_command).to receive(:call).with('HEAD:README.md', s: true).and_return(size_result)
        result
      end

      it 'returns the size as an Integer' do
        allow(raw_command).to receive(:call).with('HEAD:README.md', s: true).and_return(size_result)
        expect(result).to eq(14)
      end
    end

    context 'when object starts with a hyphen' do
      subject(:result) { described_instance.cat_file_size('--batch') }

      it 'raises ArgumentError before calling the command' do
        expect(Git::Commands::CatFile::Raw).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end
  end

  describe '#cat_file_type' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new)
        .with(execution_context)
        .and_return(raw_command)
    end

    context 'with a commit reference' do
      subject(:result) { described_instance.cat_file_type('HEAD') }

      let(:type_result) { command_result("commit\n") }

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(type_result)
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with the object and t: true' do
        expect(raw_command).to receive(:call).with('HEAD', t: true).and_return(type_result)
        result
      end

      it 'returns the type as a String with no trailing newline' do
        allow(raw_command).to receive(:call).with('HEAD', t: true).and_return(type_result)
        expect(result).to eq('commit')
      end
    end

    context 'with a treeish path reference to a blob' do
      subject(:result) { described_instance.cat_file_type('HEAD:README.md') }

      let(:blob_result) { command_result("blob\n") }

      it 'forwards the treeish reference to Git::Commands::CatFile::Raw#call' do
        expect(raw_command).to receive(:call).with('HEAD:README.md', t: true).and_return(blob_result)
        result
      end

      it 'returns "blob"' do
        allow(raw_command).to receive(:call).with('HEAD:README.md', t: true).and_return(blob_result)
        expect(result).to eq('blob')
      end
    end

    context 'when object starts with a hyphen' do
      subject(:result) { described_instance.cat_file_type('--batch') }

      it 'raises ArgumentError before calling the command' do
        expect(Git::Commands::CatFile::Raw).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end
  end

  describe '#cat_file_commit' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new)
        .with(execution_context)
        .and_return(raw_command)
    end

    context 'with a single-parent commit' do
      subject(:result) { described_instance.cat_file_commit('HEAD') }

      let(:commit_body) do
        "tree abc123\nparent def456\nauthor A <a@example.com> 1 +0000\n" \
          "committer A <a@example.com> 1 +0000\n\nInitial commit\n"
      end
      let(:commit_result) { command_result(commit_body) }

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(commit_result)
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with type commit and the object' do
        expect(raw_command).to receive(:call).with('commit', 'HEAD').and_return(commit_result)
        result
      end

      it 'returns a Hash with the expected commit data' do
        allow(raw_command).to receive(:call).with('commit', 'HEAD').and_return(commit_result)
        expect(result).to include(
          'sha' => 'HEAD',
          'tree' => 'abc123',
          'parent' => ['def456'],
          'author' => 'A <a@example.com> 1 +0000',
          'committer' => 'A <a@example.com> 1 +0000',
          'message' => "Initial commit\n"
        )
      end
    end

    context 'with a root commit (no parent lines)' do
      subject(:result) { described_instance.cat_file_commit('abc123') }

      let(:commit_body) do
        "tree def456\nauthor A <a@example.com> 1 +0000\n" \
          "committer A <a@example.com> 1 +0000\n\nRoot commit\n"
      end

      it 'returns an empty parent array' do
        allow(raw_command).to receive(:call)
          .with('commit', 'abc123')
          .and_return(command_result(commit_body))
        expect(result).to include('parent' => [])
      end
    end

    context 'with a merge commit (multiple parents)' do
      subject(:result) { described_instance.cat_file_commit('HEAD') }

      let(:commit_body) do
        "tree abc123\nparent def456\nparent ghi789\nauthor A <a@example.com> 1 +0000\n" \
          "committer A <a@example.com> 1 +0000\n\nMerge branch 'feature'\n"
      end

      it 'returns all parent SHAs in the parent array' do
        allow(raw_command).to receive(:call)
          .with('commit', 'HEAD')
          .and_return(command_result(commit_body))
        expect(result).to include('parent' => %w[def456 ghi789])
      end
    end
  end
end
