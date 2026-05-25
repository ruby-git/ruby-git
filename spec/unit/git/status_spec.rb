# frozen_string_literal: true

require 'spec_helper'
require 'git/status'
require 'git/repository'

# Unit tests for Git::Status::StatusFileFactory polymorphism.
#
# The factory has two provider paths:
#   1. Git::Repository path — when base responds to :diff_index (has it as a
#      facade method), the factory uses base directly as the provider.
#   2. Legacy Git::Base path — when base does not respond to :diff_index, the
#      factory falls back to base.lib.
#
# Each path has two sub-branches in #merge_head_diffs:
#   - When the provider reports no commits (no_commits? / empty? is true), the
#     factory skips the diff_index call entirely.
#   - When there are commits, the factory calls diff_index('HEAD') to merge
#     HEAD diffs into the status hash.
RSpec.describe Git::Status::StatusFileFactory do
  describe '#construct_files' do
    subject(:result) { described_class.new(base).construct_files }

    context 'when base is a Git::Repository (responds to :diff_index)' do
      let(:base) { instance_double(Git::Repository) }

      before do
        allow(base).to receive(:ls_files).and_return({})
        allow(base).to receive(:untracked_files).and_return([])
        allow(base).to receive(:diff_files).and_return({})
        # instance_double(Git::Repository) already responds to :diff_index
        # because the real class defines it. This stub provides a return value
        # for any call that reaches it (overridden with specific expectations
        # in nested contexts).
        allow(base).to receive(:diff_index).and_return({})
      end

      context 'when no_commits? returns true (repository has no commits)' do
        before do
          allow(base).to receive(:no_commits?).and_return(true)
        end

        it 'does not call diff_index' do
          # not_to receive overrides the outer allow for this example
          expect(base).not_to receive(:diff_index)
          result
        end

        it 'returns an empty hash when no files are present' do
          expect(result).to eq({})
        end
      end

      context 'when no_commits? returns false (repository has commits)' do
        before do
          allow(base).to receive(:no_commits?).and_return(false)
          # Override outer allow to verify HEAD is passed
          allow(base).to receive(:diff_index).with('HEAD').and_return({})
        end

        it 'calls diff_index with HEAD' do
          expect(base).to receive(:diff_index).with('HEAD').and_return({})
          result
        end

        it 'returns an empty hash when all data is empty' do
          expect(result).to eq({})
        end
      end

      context 'when provider methods return non-empty data and no_commits? is false' do
        let(:sha_index) { 'aaaa1234567890abcdef1234567890abcdef1234' }
        let(:sha_repo)  { 'bbbb1234567890abcdef1234567890abcdef1234' }

        before do
          allow(base).to receive(:ls_files).and_return(
            'a.rb' => { path: 'a.rb', mode_index: '100644', sha_index: sha_index, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return(['new.rb'])
          allow(base).to receive(:diff_files).and_return(
            'a.rb' => { path: 'a.rb', type: 'M', mode_index: '100644', mode_repo: '100644',
                        sha_index: sha_index, sha_repo: sha_repo }
          )
          allow(base).to receive(:no_commits?).and_return(false)
          allow(base).to receive(:diff_index).with('HEAD').and_return(
            'b.rb' => { path: 'b.rb', type: 'A', mode_index: '100644', mode_repo: '000000',
                        sha_index: sha_repo, sha_repo: nil }
          )
        end

        it 'returns a hash whose values are all StatusFile instances' do
          expect(result.values).to all(be_a(Git::Status::StatusFile))
        end

        it 'includes the untracked file with untracked: true' do
          expect(result['new.rb']).to be_a(Git::Status::StatusFile)
          expect(result['new.rb'].untracked).to be(true)
        end

        it 'merges diff_files data into files from ls_files' do
          expect(result['a.rb'].type).to eq('M')
        end

        it 'merges diff_index data for files not already in ls_files' do
          expect(result['b.rb']).to be_a(Git::Status::StatusFile)
          expect(result['b.rb'].type).to eq('A')
        end
      end
    end

    context 'when base is a legacy Git::Base (does not respond to :diff_index)' do
      # Plain doubles are used here because:
      # - base must NOT respond to :diff_index to exercise the legacy code path;
      #   instance_double(Git::Base) would verify against the real class, which
      #   may include modules that define :diff_index, making the test brittle.
      # - lib_double represents Git::Lib, a large class not loaded in this spec;
      #   a plain double avoids pulling in that dependency.
      let(:lib_double) { double('lib') }                           # plain double: Git::Lib not loaded in this spec
      let(:base)       { double('legacy_base', lib: lib_double) }  # plain double: must NOT respond to :diff_index

      before do
        allow(lib_double).to receive(:ls_files).and_return({})
        allow(lib_double).to receive(:untracked_files).and_return([])
        allow(lib_double).to receive(:diff_files).and_return({})
      end

      context 'when empty? returns true (repository has no commits)' do
        before do
          allow(lib_double).to receive(:empty?).and_return(true)
        end

        it 'does not call diff_index' do
          expect(lib_double).not_to receive(:diff_index)
          result
        end

        it 'returns an empty hash' do
          expect(result).to eq({})
        end
      end

      context 'when empty? returns false (repository has commits)' do
        before do
          allow(lib_double).to receive(:empty?).and_return(false)
          allow(lib_double).to receive(:diff_index).with('HEAD').and_return({})
        end

        it 'calls diff_index with HEAD on the lib provider' do
          expect(lib_double).to receive(:diff_index).with('HEAD').and_return({})
          result
        end

        it 'returns an empty hash when all data is empty' do
          expect(result).to eq({})
        end
      end
    end
  end
end
