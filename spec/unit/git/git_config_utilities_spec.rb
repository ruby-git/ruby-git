# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git do
  describe '.global_config' do
    let(:context) { instance_double(Git::ExecutionContext::Global) }

    before do
      allow(Git::ExecutionContext::Global).to receive(:new).and_return(context)
    end

    it 'lists global config values via execution context + command path (not Git::Lib)' do
      list_command = instance_double(Git::Commands::ConfigOptionSyntax::List)
      allow(Git::Commands::ConfigOptionSyntax::List).to receive(:new).with(context).and_return(list_command)

      expect(Git::Lib).not_to receive(:new)
      expect(list_command).to receive(:call).with(global: true).and_return(
        command_result("user.name=Alice\ncore.bare=false\nurl.value=https://a=b.example\nempty\n")
      )

      expect(described_class.global_config).to eq(
        'user.name' => 'Alice',
        'core.bare' => 'false',
        'url.value' => 'https://a=b.example',
        'empty' => ''
      )
    end

    it 'gets a global config value via execution context + command path (not Git::Lib)' do
      get_command = instance_double(Git::Commands::ConfigOptionSyntax::Get)
      allow(Git::Commands::ConfigOptionSyntax::Get).to receive(:new).with(context).and_return(get_command)

      expect(Git::Lib).not_to receive(:new)
      expect(get_command).to receive(:call).with('user.name', global: true).and_return(command_result('Alice'))

      expect(described_class.global_config('user.name')).to eq('Alice')
    end

    it 'sets a global config value via execution context + command path (not Git::Lib)' do
      set_command = instance_double(Git::Commands::ConfigOptionSyntax::Set)
      allow(Git::Commands::ConfigOptionSyntax::Set).to receive(:new).with(context).and_return(set_command)
      set_result = command_result

      expect(Git::Lib).not_to receive(:new)
      expect(set_command).to receive(:call).with('user.name', 'Alice', global: true).and_return(set_result)

      expect(described_class.global_config('user.name', 'Alice')).to be(set_result)
    end

    it 'raises Git::FailedError when get exits non-zero' do
      get_command = instance_double(Git::Commands::ConfigOptionSyntax::Get)
      allow(Git::Commands::ConfigOptionSyntax::Get).to receive(:new).with(context).and_return(get_command)
      result = command_result('', stderr: "error\n", exitstatus: 1)
      allow(get_command).to receive(:call).with('missing.key', global: true).and_return(result)

      expect { described_class.global_config('missing.key') }.to raise_error(Git::FailedError, /error/)
    end
  end

  describe '#config' do
    let(:instance) { Class.new { include Git }.new }
    let(:context) { instance_double(Git::ExecutionContext::Global) }

    before do
      allow(Git::ExecutionContext::Global).to receive(:new).and_return(context)
    end

    it 'lists config values via execution context + command path (not Git::Lib)' do
      list_command = instance_double(Git::Commands::ConfigOptionSyntax::List)
      allow(Git::Commands::ConfigOptionSyntax::List).to receive(:new).with(context).and_return(list_command)

      expect(Git::Lib).not_to receive(:new)
      expect(list_command).to receive(:call).with(no_args).and_return(
        command_result("user.name=Alice\ncore.bare=false\nurl.value=https://a=b.example\nempty\n")
      )

      expect(instance.config).to eq(
        'user.name' => 'Alice',
        'core.bare' => 'false',
        'url.value' => 'https://a=b.example',
        'empty' => ''
      )
    end

    it 'gets a config value via execution context + command path (not Git::Lib)' do
      get_command = instance_double(Git::Commands::ConfigOptionSyntax::Get)
      allow(Git::Commands::ConfigOptionSyntax::Get).to receive(:new).with(context).and_return(get_command)

      expect(Git::Lib).not_to receive(:new)
      expect(get_command).to receive(:call).with('user.name').and_return(command_result('Alice'))

      expect(instance.config('user.name')).to eq('Alice')
    end

    it 'sets a config value via execution context + command path (not Git::Lib)' do
      set_command = instance_double(Git::Commands::ConfigOptionSyntax::Set)
      allow(Git::Commands::ConfigOptionSyntax::Set).to receive(:new).with(context).and_return(set_command)
      set_result = command_result

      expect(Git::Lib).not_to receive(:new)
      expect(set_command).to receive(:call).with('user.name', 'Alice').and_return(set_result)

      expect(instance.config('user.name', 'Alice')).to be(set_result)
    end

    it 'raises Git::FailedError when get exits non-zero' do
      get_command = instance_double(Git::Commands::ConfigOptionSyntax::Get)
      allow(Git::Commands::ConfigOptionSyntax::Get).to receive(:new).with(context).and_return(get_command)
      result = command_result('', stderr: "error\n", exitstatus: 1)
      allow(get_command).to receive(:call).with('missing.key').and_return(result)

      expect { instance.config('missing.key') }.to raise_error(Git::FailedError, /error/)
    end
  end

  describe '#global_config' do
    let(:instance) { Class.new { include Git }.new }

    it 'delegates to Git.global_config' do
      expect(Git).to receive(:global_config).with('user.name', 'Alice').and_return(:ok)
      expect(instance.global_config('user.name', 'Alice')).to eq(:ok)
    end
  end
end
