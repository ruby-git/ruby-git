# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Branches, :integration do
  include_context 'in an empty repository'

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  # ---------------------------------------------------------------------------
  # Git::Repository constructor path: Git::Repository#branches passes self
  # (a Git::Repository) to Git::Branches.new
  # ---------------------------------------------------------------------------

  context 'when initialized via Git::Repository (Git::Repository passed to constructor)' do
    let(:execution_context) { repo.execution_context }
    let(:repository) { Git::Repository.new(execution_context: execution_context) }
    let(:branches) { repository.branches }

    describe '#local' do
      it 'includes the current local branch' do
        expect(branches.local.map(&:full)).to include('main')
      end
    end

    describe '#size' do
      it 'returns 1 after an initial commit with one branch' do
        expect(branches.size).to eq(1)
      end
    end
  end
end
