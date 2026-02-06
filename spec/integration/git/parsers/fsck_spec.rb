# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/fsck'

# Integration tests for Git::Parsers::Fsck
#
# These tests verify that the parser correctly handles real git fsck output.
#
RSpec.describe Git::Parsers::Fsck, :integration do
  include_context 'in an empty repository'

  # Helper to run git fsck and return raw output
  def git_fsck_output(*args)
    result = repo.lib.command('fsck', '--no-progress', *args, raise_on_failure: false)
    result.stdout
  end

  describe '.parse' do
    context 'when repository is clean' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'returns an empty result' do
        output = git_fsck_output
        result = described_class.parse(output)
        expect(result.empty?).to be true
        expect(result.any_issues?).to be false
      end

      it 'returns FsckResult with all empty arrays' do
        output = git_fsck_output
        result = described_class.parse(output)
        expect(result.dangling).to eq([])
        expect(result.missing).to eq([])
        expect(result.unreachable).to eq([])
        expect(result.warnings).to eq([])
      end
    end

    context 'with dangling objects' do
      let(:expected_blob_oid) { 'cf3f826230a67eac544a2ce2912965f004e94bd7' }

      before do
        write_file('file.txt', 'original content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        write_file('orphan.txt', 'orphaned content')
        repo.add('orphan.txt')
        repo.reset('HEAD', hard: true)
      end

      it 'detects dangling blobs' do
        output = git_fsck_output
        result = described_class.parse(output)
        expect(result.dangling.any? { |obj| obj.type == :blob }).to be true
      end

      it 'returns FsckObject with the expected oid' do
        output = git_fsck_output
        result = described_class.parse(output)
        dangling_blob = result.dangling.find { |obj| obj.type == :blob }
        expect(dangling_blob.oid).to eq(expected_blob_oid)
      end

      it 'sets correct type on dangling objects' do
        output = git_fsck_output
        result = described_class.parse(output)
        result.dangling.each do |obj|
          expect(obj.type).to eq(:blob)
        end
      end
    end

    context 'with root commits' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('First root commit')

        repo.branch('orphan-branch').checkout
        `cd #{repo_dir} && git checkout --orphan another-root >/dev/null 2>&1 && \
git commit --allow-empty -m "Another root" >/dev/null 2>&1`
      end

      it 'reports root commits' do
        output = git_fsck_output('--root')
        result = described_class.parse(output)
        expect(result.root).not_to be_empty
      end

      it 'returns root commits as FsckObject with :commit type' do
        output = git_fsck_output('--root')
        result = described_class.parse(output)
        result.root.each do |obj|
          expect(obj.type).to eq(:commit)
          expect(obj.oid).to match(/^[0-9a-f]{40}$/)
        end
      end
    end

    context 'with tagged objects' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0', annotate: true, message: 'Version 1.0.0')
      end

      it 'reports tagged objects' do
        output = git_fsck_output('--tags')
        result = described_class.parse(output)
        expect(result.tagged).not_to be_empty
      end

      it 'returns tagged objects with tag name' do
        output = git_fsck_output('--tags')
        result = described_class.parse(output)
        tag_obj = result.tagged.find { |t| t.name == 'v1.0.0' }
        expect(tag_obj).not_to be_nil
        expect(tag_obj.oid).to match(/^[0-9a-f]{40}$/)
      end
    end
  end

  describe 'output format validation' do
    # These tests validate that fsck output patterns match the regex patterns
    # used in unit test fixtures

    context 'with dangling objects' do
      before do
        write_file('file.txt', 'original content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        write_file('orphan.txt', 'orphaned content')
        repo.add('orphan.txt')
        repo.reset('HEAD', hard: true)
      end

      it 'matches OBJECT_PATTERN for dangling lines' do
        output = git_fsck_output
        dangling_lines = output.lines.select { |l| l.start_with?('dangling') }
        expect(dangling_lines).not_to be_empty

        dangling_lines.each do |line|
          expect(line.strip).to match(described_class::OBJECT_PATTERN),
                                "Expected line to match OBJECT_PATTERN: #{line.inspect}"
        end
      end
    end

    context 'with root commits' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'matches ROOT_PATTERN for root lines' do
        output = git_fsck_output('--root')
        root_lines = output.lines.select { |l| l.start_with?('root') }
        expect(root_lines).not_to be_empty

        root_lines.each do |line|
          expect(line.strip).to match(described_class::ROOT_PATTERN),
                                "Expected line to match ROOT_PATTERN: #{line.inspect}"
        end
      end
    end

    context 'with tagged objects' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0', annotate: true, message: 'Version 1.0.0')
      end

      it 'matches TAGGED_PATTERN for tagged lines' do
        output = git_fsck_output('--tags')
        tagged_lines = output.lines.select { |l| l.start_with?('tagged') }
        expect(tagged_lines).not_to be_empty

        tagged_lines.each do |line|
          expect(line.strip).to match(described_class::TAGGED_PATTERN),
                                "Expected line to match TAGGED_PATTERN: #{line.inspect}"
        end
      end
    end
  end
end
