# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/move'

RSpec.describe Git::Commands::Branch::Move, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')
    end

    describe 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('main-renamed')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError when target exists without force' do
        repo.branch('existing').create

        expect { command.call('existing') }.to raise_error(Git::FailedError)
      end
    end
  end
end
