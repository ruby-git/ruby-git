# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/list'

RSpec.describe Git::Commands::Branch::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when there are no branches' do
      it 'returns an empty array' do
        result = command.call
        expect(result).to eq([])
      end
    end

    context 'when there are branches' do
      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature-branch').create
      end

      it 'loads all branches' do
        result = command.call
        expect(result.map(&:refname)).to contain_exactly('main', 'feature-branch')
      end

      it 'identifies the current branch' do
        result = command.call
        expect(result.find(&:current).refname).to eq('main')
      end
    end

    context 'with branch names containing special characters' do
      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature/with-slash').create
        repo.branch('feature/日本語').create
      end

      it 'parses branch names with slashes' do
        result = command.call
        expect(result.map(&:refname)).to include('feature/with-slash')
      end

      it 'parses branch names with unicode' do
        result = command.call
        expect(result.map(&:refname)).to include('feature/日本語')
      end
    end
  end
end
