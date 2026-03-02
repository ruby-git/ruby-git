# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/object_content'

RSpec.describe Git::Commands::CatFile::ObjectContent, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  # Pattern: "<sha> <type> <size>" header line produced by --batch
  let(:batch_header_pattern) { /\A[0-9a-f]{40} \w+ \d+\z/ }

  describe '#call' do
    context 'with HEAD (a commit object)' do
      it 'returns a CommandLineResult' do
        result = command.call('HEAD')
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'exits with status 0' do
        result = command.call('HEAD')
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns a header line followed by raw content' do
        result = command.call('HEAD')
        first_line = result.stdout.lines.first.chomp
        expect(first_line).to match(batch_header_pattern)
      end

      it 'includes the commit message in the content' do
        result = command.call('HEAD')
        expect(result.stdout).to include('Initial commit')
      end
    end

    context 'with HEAD:README.md (a blob)' do
      it 'identifies the blob type in the header' do
        result = command.call('HEAD:README.md')
        _sha, type, _size = result.stdout.lines.first.chomp.split(' ', 3)
        expect(type).to eq('blob')
      end

      it 'includes the file content after the header' do
        result = command.call('HEAD:README.md')
        expect(result.stdout).to include("# Hello\n")
      end

      it 'reports the correct byte size in the header' do
        result = command.call('HEAD:README.md')
        _sha, _type, size = result.stdout.lines.first.chomp.split(' ', 3)
        # Compare against the content bytesize rather than File.size: on Windows,
        # File.size includes CRLF bytes but git stores blobs with LF only.
        expect(size.to_i).to eq("# Hello\n".bytesize)
      end
    end

    context 'with multiple objects' do
      it 'returns a successful result with non-empty output when all are found' do
        result = command.call('HEAD', 'HEAD:README.md')
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end

      it 'includes the content of each object when all are found' do
        result = command.call('HEAD', 'HEAD:README.md')
        expect(result.stdout).to include('Initial commit')
        expect(result.stdout).to include("# Hello\n")
      end

      it 'returns content for found objects and a missing line for unknown objects' do
        result = command.call('HEAD', 'not-a-valid-ref', 'HEAD:README.md')
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to include('Initial commit')
        expect(result.stdout).to include("# Hello\n")
        expect(result.stdout).to include('missing')
      end

      it 'returns a missing line for every object when none are found' do
        result = command.call('not-a-valid-ref', 'also-not-valid')
        expect(result.status.exitstatus).to eq(0)
        missing_lines = result.stdout.lines.map(&:chomp).select { |l| l.include?('missing') }
        expect(missing_lines.count).to eq(2)
      end
    end

    context 'with a missing object' do
      it 'returns a "missing" line (exit 0)' do
        result = command.call('deadbeef' * 5)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to match(/missing/)
      end
    end

    context 'with an unknown object name' do
      it 'returns a "missing" line rather than raising an error' do
        result = command.call('not-a-valid-ref')
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to include('missing')
      end
    end

    context 'with batch_all_objects: true' do
      it 'returns a successful result with content for all objects' do
        result = command.call(batch_all_objects: true)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
        # At minimum the README blob content must appear
        expect(result.stdout).to include('# Hello')
      end
    end

    context 'with a binary blob' do
      let(:binary_content) { (0..255).map(&:chr).join.encode('BINARY') }

      before do
        blob_path = File.join(repo_dir, 'binary.bin')
        File.binwrite(blob_path, binary_content)
        repo.add('binary.bin')
        repo.commit('Add binary file')
      end

      it 'does not raise when fetching a binary blob' do
        expect { command.call('HEAD:binary.bin') }.not_to raise_error
      end

      it 'preserves binary bytes exactly in stdout' do
        result = command.call('HEAD:binary.bin')
        # The --batch output is: "<sha> blob <size>\n<content>\n"
        # Everything after the first newline up to the final trailing newline is the blob.
        header, *rest = result.stdout.b.split("\n".b, 2)
        expect(header).to match(/\A[0-9a-f]{40} blob #{binary_content.bytesize}\z/)
        content_and_trailer = rest.first
        expect(content_and_trailer.b[0, binary_content.bytesize]).to eq(binary_content.b)
      end
    end

    context 'with no objects and no options' do
      it 'raises ArgumentError before calling git' do
        expect { command.call }.to raise_error(
          ArgumentError, 'at least one of :objects, :batch_all_objects must be provided'
        )
      end
    end
  end
end
