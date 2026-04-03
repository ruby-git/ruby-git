# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get_urlmatch'

RSpec.describe Git::Commands::ConfigOptionSyntax::GetUrlmatch, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      before do
        repo.config('http.https://example.com.proxy', 'http://proxy.example.com')
      end

      it 'returns a CommandLineResult' do
        result = command.call('http.proxy', 'https://example.com')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns exit code 1 when no URL match exists' do
        result = command.call('http.proxy', 'https://nomatch.example.com')

        expect(result.status.exitstatus).to eq(1)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid type argument' do
        expect { command.call('http.proxy', 'https://example.com', type: 'invalid_type') }
          .to raise_error(Git::FailedError, /invalid_type/)
      end
    end
  end
end
