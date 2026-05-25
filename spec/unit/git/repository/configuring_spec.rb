# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/configuring'

RSpec.describe Git::Repository::Configuring do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#config' do
    context 'when called with no arguments' do
      subject(:result) { described_instance.config }

      let(:list_command) { instance_double(Git::Commands::ConfigOptionSyntax::List) }
      let(:list_result) { command_result("user.name=Alice\ncore.bare=false") }

      before do
        allow(Git::Commands::ConfigOptionSyntax::List)
          .to receive(:new).with(execution_context).and_return(list_command)
      end

      it 'delegates to Git::Commands::ConfigOptionSyntax::List#call' do
        expect(list_command).to receive(:call).and_return(list_result)
        result
      end

      it 'returns a Hash of config entries keyed by dotted name' do
        allow(list_command).to receive(:call).and_return(list_result)
        expect(result).to eq({ 'user.name' => 'Alice', 'core.bare' => 'false' })
      end

      context 'when stdout contains = characters in values' do
        let(:list_result) { command_result('url.https://github.com/.insteadof=git://github.com/') }

        it 'parses values correctly, treating only the first = as the delimiter' do
          allow(list_command).to receive(:call).and_return(list_result)
          expect(result).to eq({ 'url.https://github.com/.insteadof' => 'git://github.com/' })
        end
      end

      context 'when a line has no = separator (valueless key)' do
        let(:list_result) { command_result('core.bare') }

        it 'returns an empty string value to match legacy Git::Lib behaviour' do
          allow(list_command).to receive(:call).and_return(list_result)
          expect(result).to eq({ 'core.bare' => '' })
        end
      end

      context 'when stdout is empty' do
        let(:list_result) { command_result('') }

        it 'returns an empty Hash' do
          allow(list_command).to receive(:call).and_return(list_result)
          expect(result).to eq({})
        end
      end
    end

    context 'when called with a name only' do
      subject(:result) { described_instance.config('user.name') }

      let(:get_command) { instance_double(Git::Commands::ConfigOptionSyntax::Get) }
      let(:get_result) { command_result('Alice') }

      before do
        allow(Git::Commands::ConfigOptionSyntax::Get)
          .to receive(:new).with(execution_context).and_return(get_command)
      end

      it 'delegates to Git::Commands::ConfigOptionSyntax::Get#call with the key name' do
        expect(get_command).to receive(:call).with('user.name').and_return(get_result)
        result
      end

      it 'returns the config value as a String' do
        allow(get_command).to receive(:call).with('user.name').and_return(get_result)
        expect(result).to eq('Alice')
      end

      context 'when the key is not found' do
        let(:get_result) { command_result('', exitstatus: 1) }

        it 'raises Git::FailedError' do
          allow(get_command).to receive(:call).with('user.name').and_return(get_result)
          expect { result }.to raise_error(Git::FailedError, /git/)
        end
      end
    end

    context 'when called with name and value' do
      subject(:result) { described_instance.config('user.name', 'Alice') }

      let(:set_command) { instance_double(Git::Commands::ConfigOptionSyntax::Set) }
      let(:set_result) { command_result('') }

      before do
        allow(Git::Commands::ConfigOptionSyntax::Set)
          .to receive(:new).with(execution_context).and_return(set_command)
      end

      it 'delegates to Git::Commands::ConfigOptionSyntax::Set#call with name and value' do
        expect(set_command).to receive(:call).with('user.name', 'Alice').and_return(set_result)
        result
      end

      it 'returns the Git::CommandLineResult from the set command' do
        allow(set_command).to receive(:call).with('user.name', 'Alice').and_return(set_result)
        expect(result).to eq(set_result)
      end

      context 'with the file: option' do
        subject(:result) { described_instance.config('user.name', 'Alice', file: '/path/to/config') }

        it 'forwards the file option to Git::Commands::ConfigOptionSyntax::Set#call' do
          expect(set_command)
            .to receive(:call).with('user.name', 'Alice', file: '/path/to/config').and_return(set_result)
          result
        end
      end

      context 'with an unknown option' do
        subject(:result) { described_instance.config('user.name', 'Alice', bogus: true) }

        it 'raises ArgumentError' do
          expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
        end

        it 'does not call Git::Commands::ConfigOptionSyntax::Set' do
          expect(set_command).not_to receive(:call)
          expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
        end
      end
    end
  end
end
