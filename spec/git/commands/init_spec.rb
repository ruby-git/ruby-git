# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/init'

RSpec.describe Git::Commands::Init do
  let(:execution_context) { instance_double(Git::Lib) }
  let(:init_command) { described_class.new(execution_context) }

  describe '#initialize' do
    it 'stores the execution context' do
      command = described_class.new(execution_context)
      expect(command.instance_variable_get(:@execution_context)).to eq(execution_context)
    end
  end

  describe '#call' do
    context 'with no options' do
      it 'executes git init with no flags' do
        expect(execution_context).to receive(:command).with('init').and_return('Initialized empty Git repository')
        result = init_command.call
        expect(result).to eq('Initialized empty Git repository')
      end
    end

    context 'with bare option' do
      it 'includes the --bare flag when true' do
        expect(execution_context).to receive(:command).with('init', '--bare').and_return('Initialized bare repository')
        init_command.call(bare: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('init').and_return('Initialized empty Git repository')
        init_command.call(bare: false)
      end
    end

    context 'with initial_branch option' do
      it 'includes the --initial-branch flag' do
        expect(execution_context).to receive(:command).with('init', '--initial-branch=main').and_return('Initialized repository')
        init_command.call(initial_branch: 'main')
      end

      it 'handles different branch names' do
        expect(execution_context).to receive(:command).with('init', '--initial-branch=develop').and_return('Initialized repository')
        init_command.call(initial_branch: 'develop')
      end
    end

    context 'with both options' do
      it 'includes all specified flags' do
        expect(execution_context).to receive(:command).with('init', '--bare', '--initial-branch=develop').and_return('Initialized repository')
        init_command.call(bare: true, initial_branch: 'develop')
      end
    end

    context 'with empty options hash' do
      it 'executes git init with no flags' do
        expect(execution_context).to receive(:command).with('init').and_return('Initialized empty Git repository')
        init_command.call({})
      end
    end
  end
end
