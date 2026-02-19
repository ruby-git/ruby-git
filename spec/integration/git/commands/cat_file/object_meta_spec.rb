# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/object_meta'

RSpec.describe Git::Commands::CatFile::ObjectMeta, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  # Pattern: "<sha> <type> <size>" per object
  let(:batch_check_line_pattern) { /\A[0-9a-f]{40} \w+ \d+\z/ }

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

      it 'returns a single metadata line for HEAD' do
        result = command.call('HEAD')
        lines = result.stdout.lines.map(&:chomp).reject(&:empty?)
        expect(lines.count).to eq(1)
        expect(lines.first).to match(batch_check_line_pattern)
      end

      it 'identifies HEAD as a commit object' do
        result = command.call('HEAD')
        _sha, type, _size = result.stdout.chomp.split(' ', 3)
        expect(type).to eq('commit')
      end
    end

    context 'with HEAD:README.md (a blob)' do
      it 'identifies the blob type' do
        result = command.call('HEAD:README.md')
        _sha, type, _size = result.stdout.chomp.split(' ', 3)
        expect(type).to eq('blob')
      end

      it 'reports the correct size for the blob' do
        result = command.call('HEAD:README.md')
        _sha, _type, size = result.stdout.chomp.split(' ', 3)
        # Compare against the content bytesize rather than File.size: on Windows,
        # File.size includes CRLF bytes but git stores blobs with LF only.
        expect(size.to_i).to eq("# Hello\n".bytesize)
      end
    end

    context 'with multiple objects' do
      it 'returns one metadata line per object when all are found' do
        result = command.call('HEAD', 'HEAD:README.md')
        lines = result.stdout.lines.map(&:chomp).reject(&:empty?)
        expect(lines.count).to eq(2)
        lines.each { |line| expect(line).to match(batch_check_line_pattern) }
      end

      it 'returns a missing line for each unknown object and a metadata line for each found object' do
        result = command.call('HEAD', 'not-a-valid-ref', 'HEAD:README.md')
        lines = result.stdout.lines.map(&:chomp).reject(&:empty?)
        expect(lines.count).to eq(3)
        expect(lines.count { |l| l.match?(batch_check_line_pattern) }).to eq(2)
        expect(lines.count { |l| l.include?('missing') }).to eq(1)
      end

      it 'returns a missing line for every object when none are found' do
        result = command.call('not-a-valid-ref', 'also-not-valid')
        lines = result.stdout.lines.map(&:chomp).reject(&:empty?)
        expect(lines.count).to eq(2)
        lines.each { |line| expect(line).to include('missing') }
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
      it 'returns metadata lines for all objects without reading stdin' do
        result = command.call(batch_all_objects: true)
        expect(result.status.exitstatus).to eq(0)
        lines = result.stdout.lines.map(&:chomp).reject(&:empty?)
        expect(lines.count).to be >= 2 # at least the commit and the blob
        lines.each { |line| expect(line).to match(batch_check_line_pattern) }
      end
    end

    context 'with no objects and no options' do
      it 'raises ArgumentError before calling git' do
        expect { command.call }.to raise_error(
          ArgumentError, 'at least one object is required unless batch_all_objects: true'
        )
      end
    end
  end
end
