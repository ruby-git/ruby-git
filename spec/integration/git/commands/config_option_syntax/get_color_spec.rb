# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get_color'

RSpec.describe Git::Commands::ConfigOptionSyntax::GetColor, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      before do
        repo.config_set('color.test.slot', 'red')
      end

      it 'returns a CommandLineResult' do
        result = command.call('color.test.slot')

        expect(result).to be_a(Git::CommandLine::Result)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when --local is used outside a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call('color.test', local: true) }
          .to raise_error(Git::FailedError)
      end
    end
  end
end
