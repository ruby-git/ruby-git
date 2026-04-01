# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/update_ref/delete'

RSpec.describe Git::Commands::UpdateRef::Delete, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', "content\n")
      repo.add('file.txt')
      repo.commit('Initial commit')
      repo.branch('doomed').create
    end

    context 'when the command succeeds' do
      it 'deletes a ref' do
        result = command.call('refs/heads/doomed')

        expect(result).to be_a(Git::CommandLineResult)
        expect { repo.rev_parse('refs/heads/doomed') }.to raise_error(Git::FailedError)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when oldvalue does not match' do
        expect { command.call('refs/heads/doomed', 'bad0' * 10) }
          .to raise_error(Git::FailedError, /bad0/)
      end
    end
  end
end
