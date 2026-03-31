# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/rev_parse'

RSpec.describe Git::Commands::RevParse, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult for --verify HEAD' do
        result = command.call('HEAD', verify: true)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'returns a CommandLineResult for --show-toplevel' do
        result = command.call(show_toplevel: true)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent ref with --verify' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call('nonexistent-ref', verify: true) }
          .to raise_error(Git::FailedError, /nonexistent-ref/)
      end
    end
  end
end
