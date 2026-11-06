# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/inspecting'

# Integration tests for Git::Repository::Inspecting.
#
# #show and #fsck are exercised end-to-end here because each performs
# facade-owned processing that benefits from a real git invocation:
#   * #show joins objectish and path into an `objectish:path` expression before
#     calling git, so a real blob read proves the pre-processing produces a
#     valid object specifier.
#   * #fsck builds a Git::FsckResult from the stdout, stderr, and exit status of
#     `git fsck`, so a real invocation proves the parsing handles actual output
#     and that a finding git reports only in stderr and the exit status reaches
#     the result.
#
# #describe is a single-command delegator whose facade-owned transforms
# (:"exact-match" key translation, option allowlist) are pure-Ruby and fully
# covered by unit tests. The command's own integration spec
# (spec/integration/git/commands/describe_spec.rb) covers the end-to-end git
# interaction, so no facade-level integration tests are required here.

RSpec.describe Git::Repository::Inspecting, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#show' do
    before do
      write_file('README.md', "hello world\n")
      repo.add(all: true)
      repo.commit('Initial commit')
    end

    context 'with an objectish and a path' do
      it 'shows the contents of the file at that revision' do
        expect(described_instance.show('HEAD', 'README.md')).to eq("hello world\n")
      end
    end
  end

  describe '#fsck' do
    before do
      write_file('README.md', "hello world\n")
      repo.add(all: true)
      repo.commit('Initial commit')
    end

    it 'returns a Git::FsckResult' do
      expect(described_instance.fsck).to be_a(Git::FsckResult)
    end

    context 'when the repository is healthy' do
      it 'reports no issues' do
        expect(described_instance.fsck).to have_attributes(empty?: true, exit_status: 0)
      end
    end

    context 'when git reports a finding only in stderr and the exit status' do
      before do
        tag = repo.tag_create('t', annotate: true, message: 't')
        # update-ref refuses this; write the files-backend ref directly
        write_file('.git/refs/heads/points-at-tag', "#{tag.oid}\n")
      end

      it 'reports the issue with the exit status and the ref git named' do
        expect(described_instance.fsck).to have_attributes(
          any_issues?: true,
          exit_status: 8,
          stderr: include('points-at-tag')
        )
      end
    end

    context 'when a dangling object exists' do
      before do
        write_file('orphan.txt', "orphan content\n")
        Dir.chdir(repo_dir) { execution_context.command_capturing('hash-object', '-w', 'orphan.txt') }
      end

      it 'reports the dangling object' do
        expect(described_instance.fsck.dangling).not_to be_empty
      end
    end
  end
end
