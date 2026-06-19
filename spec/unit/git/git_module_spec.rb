# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git do
  describe '.global_config' do
    let(:execution_context) { instance_double(Git::ExecutionContext::Global) }

    before do
      allow(Git::ExecutionContext::Global).to receive(:new).and_return(execution_context)
    end

    context 'when called with no arguments (list mode)' do
      subject(:result) { described_class.global_config }

      let(:list_command) { instance_double(Git::Commands::ConfigOptionSyntax::List) }
      let(:list_result) { command_result("user.name=Alice\ncore.autocrlf=false") }

      before do
        allow(Git::Commands::ConfigOptionSyntax::List)
          .to receive(:new).with(execution_context).and_return(list_command)
      end

      it 'creates a Git::ExecutionContext::Global' do
        allow(list_command).to receive(:call).with(global: true).and_return(list_result)
        expect(Git::ExecutionContext::Global).to receive(:new).and_return(execution_context)
        result
      end

      it 'delegates to ConfigOptionSyntax::List#call with global: true' do
        expect(list_command).to receive(:call).with(global: true).and_return(list_result)
        result
      end

      it 'returns a Hash of global config entries keyed by dotted name' do
        allow(list_command).to receive(:call).with(global: true).and_return(list_result)
        expect(result).to eq({ 'user.name' => 'Alice', 'core.autocrlf' => 'false' })
      end

      context 'when stdout contains = in values' do
        let(:list_result) { command_result('url.https://github.com/.insteadof=git://github.com/') }

        it 'parses values correctly, treating only the first = as the delimiter' do
          allow(list_command).to receive(:call).with(global: true).and_return(list_result)
          expect(result).to eq({ 'url.https://github.com/.insteadof' => 'git://github.com/' })
        end
      end

      context 'when stdout contains an entry with no value' do
        let(:list_result) { command_result("user.name=Alice\nboolean.flag") }

        it 'maps the valueless entry to an empty string' do
          allow(list_command).to receive(:call).with(global: true).and_return(list_result)
          expect(result).to eq({ 'user.name' => 'Alice', 'boolean.flag' => '' })
        end
      end
    end

    context 'when called with a name only (get mode)' do
      subject(:result) { described_class.global_config('user.name') }

      let(:get_command) { instance_double(Git::Commands::ConfigOptionSyntax::Get) }
      let(:get_result) { command_result('Alice') }

      before do
        allow(Git::Commands::ConfigOptionSyntax::Get)
          .to receive(:new).with(execution_context).and_return(get_command)
      end

      it 'delegates to ConfigOptionSyntax::Get#call with the key name and global: true' do
        expect(get_command).to receive(:call).with('user.name', global: true).and_return(get_result)
        result
      end

      it 'returns the config value as a String' do
        allow(get_command).to receive(:call).with('user.name', global: true).and_return(get_result)
        expect(result).to eq('Alice')
      end

      context 'when the key is not found (exit status 1)' do
        let(:get_result) { command_result('', exitstatus: 1) }

        it 'raises Git::FailedError' do
          allow(get_command).to receive(:call).with('user.name', global: true).and_return(get_result)
          expect { result }.to raise_error(Git::FailedError)
        end
      end
    end

    context 'when called with name and value (set mode)' do
      subject(:result) { described_class.global_config('user.name', 'Bob') }

      let(:set_command) { instance_double(Git::Commands::ConfigOptionSyntax::Set) }
      let(:set_result) { command_result('') }

      before do
        allow(Git::Commands::ConfigOptionSyntax::Set)
          .to receive(:new).with(execution_context).and_return(set_command)
      end

      it 'delegates to ConfigOptionSyntax::Set#call with name, value, and global: true' do
        expect(set_command).to receive(:call).with('user.name', 'Bob', global: true).and_return(set_result)
        result
      end

      it 'returns the CommandLineResult from ConfigOptionSyntax::Set#call' do
        allow(set_command).to receive(:call).with('user.name', 'Bob', global: true).and_return(set_result)
        expect(result).to eq(set_result)
      end

      it 'routes global_config(name, false) to set mode, not get mode' do
        expect(set_command).to receive(:call).with('user.name', false, global: true).and_return(set_result)
        described_class.global_config('user.name', false)
      end
    end
  end

  describe '#config' do
    let(:git_class) do
      Class.new { include Git }
    end

    let(:described_instance) { git_class.new }
    let(:execution_context) { instance_double(Git::ExecutionContext::Global) }

    before do
      allow(Git::ExecutionContext::Global).to receive(:new).and_return(execution_context)
    end

    context 'when called with no arguments (list mode)' do
      subject(:result) { described_instance.config }

      let(:list_command) { instance_double(Git::Commands::ConfigOptionSyntax::List) }
      let(:list_result) { command_result("user.name=Alice\ncore.bare=false") }

      before do
        allow(Git::Commands::ConfigOptionSyntax::List)
          .to receive(:new).with(execution_context).and_return(list_command)
      end

      it 'creates a Git::ExecutionContext::Global' do
        allow(list_command).to receive(:call).with(no_args).and_return(list_result)
        expect(Git::ExecutionContext::Global).to receive(:new).and_return(execution_context)
        result
      end

      it 'delegates to ConfigOptionSyntax::List#call with no scope options' do
        expect(list_command).to receive(:call).with(no_args).and_return(list_result)
        result
      end

      it 'returns a Hash of config entries keyed by dotted name' do
        allow(list_command).to receive(:call).with(no_args).and_return(list_result)
        expect(result).to eq({ 'user.name' => 'Alice', 'core.bare' => 'false' })
      end
    end

    context 'when called with a name only (get mode)' do
      subject(:result) { described_instance.config('user.name') }

      let(:get_command) { instance_double(Git::Commands::ConfigOptionSyntax::Get) }
      let(:get_result) { command_result('Alice') }

      before do
        allow(Git::Commands::ConfigOptionSyntax::Get)
          .to receive(:new).with(execution_context).and_return(get_command)
      end

      it 'delegates to ConfigOptionSyntax::Get#call with the key name' do
        expect(get_command).to receive(:call).with('user.name').and_return(get_result)
        result
      end

      it 'returns the config value as a String' do
        allow(get_command).to receive(:call).with('user.name').and_return(get_result)
        expect(result).to eq('Alice')
      end

      context 'when the key is not found (exit status 1)' do
        let(:get_result) { command_result('', exitstatus: 1) }

        it 'raises Git::FailedError' do
          allow(get_command).to receive(:call).with('user.name').and_return(get_result)
          expect { result }.to raise_error(Git::FailedError)
        end
      end
    end

    context 'when called with name and value (set mode)' do
      subject(:result) { described_instance.config('user.name', 'Bob') }

      let(:set_command) { instance_double(Git::Commands::ConfigOptionSyntax::Set) }
      let(:set_result) { command_result('') }

      before do
        allow(Git::Commands::ConfigOptionSyntax::Set)
          .to receive(:new).with(execution_context).and_return(set_command)
      end

      it 'delegates to ConfigOptionSyntax::Set#call with name and value' do
        expect(set_command).to receive(:call).with('user.name', 'Bob').and_return(set_result)
        result
      end

      it 'returns the CommandLineResult from ConfigOptionSyntax::Set#call' do
        allow(set_command).to receive(:call).with('user.name', 'Bob').and_return(set_result)
        expect(result).to eq(set_result)
      end

      it 'routes config(name, false) to set mode, not get mode' do
        expect(set_command).to receive(:call).with('user.name', false).and_return(set_result)
        described_instance.config('user.name', false)
      end
    end
  end

  describe '#global_config' do
    let(:git_class) do
      Class.new { include Git }
    end

    let(:described_instance) { git_class.new }

    it 'delegates to Git.global_config' do
      expect(described_class).to receive(:global_config).with('user.name', nil)
      described_instance.global_config('user.name')
    end

    it 'delegates to Git.global_config with value' do
      expect(described_class).to receive(:global_config).with('user.name', 'Alice')
      described_instance.global_config('user.name', 'Alice')
    end
  end
end
