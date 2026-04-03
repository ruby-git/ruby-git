# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get_color_bool'

RSpec.describe Git::Commands::ConfigOptionSyntax::GetColorBool, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with exit status 0 when color is enabled' do
        repo.config('color.test', 'always')
        result = command.call('color.test')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit status 1 when color is disabled' do
        repo.config('color.test', 'never')
        result = command.call('color.test')

        expect(result.status.exitstatus).to eq(1)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when --local is used outside a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call('color.diff', local: true) }
          .to raise_error(Git::FailedError, /fatal/)
      end
    end
  end
end
