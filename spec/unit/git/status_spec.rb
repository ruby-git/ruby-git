# frozen_string_literal: true

require 'spec_helper'
require 'git/status'
require 'git/repository'

RSpec.describe Git::Status::StatusFileFactory do
  describe '#construct_files' do
    subject(:result) { described_class.new(base).construct_files }

    context 'when base is a Git::Repository' do
      let(:base) { instance_double(Git::Repository) }

      before do
        allow(base).to receive(:ls_files).and_return({})
        allow(base).to receive(:untracked_files).and_return([])
        allow(base).to receive(:diff_files).and_return({})
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
  end
end
