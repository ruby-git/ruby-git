# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get_regexp'

RSpec.describe Git::Commands::ConfigOptionSyntax::GetRegexp, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('user\\..*')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns exit status 0 when entries match' do
        result = command.call('user\\..*')

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit status 1 when no entries match' do
        result = command.call('nonexistent\\..*')

        expect(result.status.exitstatus).to eq(1)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when --local is used outside a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call('user\\..*', local: true) }
          .to raise_error(Git::FailedError, /local/)
      end
    end
  end
end
