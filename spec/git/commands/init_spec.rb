# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/init'

RSpec.describe Git::Commands::Init do
  let(:execution_context) { instance_double(Git::Lib) }
  let(:init_command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no options' do
      it 'executes git init with no flags' do
        expect(execution_context).to receive(:command).with('init')
        init_command.call
      end
    end

    context 'with bare option' do
      it 'executes git init with --bare flag' do
        expect(execution_context).to receive(:command).with('init', '--bare')
        init_command.call(bare: true)
      end
    end

    context 'with initial_branch option' do
      it 'executes git init with --initial-branch flag' do
        expect(execution_context).to receive(:command).with('init', '--initial-branch=main')
        init_command.call(initial_branch: 'main')
      end
    end

    context 'with both options' do
      it 'executes git init with all flags' do
        expect(execution_context).to receive(:command).with('init', '--bare', '--initial-branch=develop')
        init_command.call(bare: true, initial_branch: 'develop')
      end
    end
  end
end
