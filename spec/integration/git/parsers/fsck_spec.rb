# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/fsck'

# Integration tests for Git::Parsers::Fsck
#
# These tests verify that the parser correctly handles real git fsck output.
#
RSpec.describe Git::Parsers::Fsck, :integration do
  include_context 'in an empty repository'

  # Helper to run git fsck and return the whole command result
  def git_fsck(*args)
    repo.execution_context.command_capturing('fsck', '--no-progress', *args, raise_on_failure: false)
  end

  # Helper to parse a command result the way the facade does
  def parse(fsck)
    described_class.parse(fsck.stdout, exit_status: fsck.status.exitstatus, stderr: fsck.stderr)
  end

  describe '.parse' do
    context 'when repository is clean' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'returns an empty result' do
        result = parse(git_fsck)
        expect(result.empty?).to be true
        expect(result.any_issues?).to be false
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
        result = parse(git_fsck)
        expect(result.dangling.any? { |obj| obj.type == :blob }).to be true
      end
    end

    context 'with root commits' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('First root commit')

        repo.checkout('orphan-branch', new_branch: true)
        repo.checkout('another-root', orphan: true)
        repo.commit('Another root', allow_empty: true)
      end

      it 'reports root commits' do
        result = parse(git_fsck('--root'))
        expect(result.root).not_to be_empty
      end

      it 'returns root commits as FsckObject with :commit type' do
        result = parse(git_fsck('--root'))
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
        repo.tag_create('v1.0.0', annotate: true, message: 'Version 1.0.0')
      end

      it 'returns tagged objects with tag name' do
        result = parse(git_fsck('--tags'))
        tag_obj = result.tagged.find { |t| t.name == 'v1.0.0' }
        expect(tag_obj).not_to be_nil
        expect(tag_obj.oid).to match(/^[0-9a-f]{40}$/)
      end
    end
  end
end
