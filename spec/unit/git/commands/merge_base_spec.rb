# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge_base'

RSpec.describe Git::Commands::MergeBase do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with two commits' do
      it 'calls git merge-base with both commits' do
        expect(execution_context).to receive(:command).with('merge-base', 'main',
                                                            'feature').and_return(command_result("abc123\n"))
        result = command.call('main', 'feature')
        expect(result).to eq(['abc123'])
      end
    end

    context 'with multiple commits' do
      it 'calls git merge-base with all commits' do
        expect(execution_context).to receive(:command).with('merge-base', 'main', 'feature1',
                                                            'feature2').and_return(command_result("abc123\n"))
        result = command.call('main', 'feature1', 'feature2')
        expect(result).to eq(['abc123'])
      end
    end

    context 'with :octopus option' do
      it 'adds --octopus flag' do
        expect(execution_context).to receive(:command).with('merge-base', '--octopus', 'main', 'b1',
                                                            'b2').and_return(command_result("abc123\n"))
        result = command.call('main', 'b1', 'b2', octopus: true)
        expect(result).to eq(['abc123'])
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('merge-base', 'main',
                                                            'feature').and_return(command_result("abc123\n"))
        command.call('main', 'feature', octopus: false)
      end
    end

    context 'with :independent option' do
      it 'adds --independent flag' do
        expect(execution_context).to receive(:command).with('merge-base', '--independent', 'a', 'b',
                                                            'c').and_return(command_result("sha1\nsha2\n"))
        result = command.call('a', 'b', 'c', independent: true)
        expect(result).to eq(%w[sha1 sha2])
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('merge-base', 'main',
                                                            'feature').and_return(command_result("abc123\n"))
        command.call('main', 'feature', independent: false)
      end
    end

    context 'with :fork_point option' do
      it 'adds --fork-point flag' do
        expect(execution_context).to receive(:command).with('merge-base', '--fork-point', 'main',
                                                            'feature').and_return(command_result("abc123\n"))
        result = command.call('main', 'feature', fork_point: true)
        expect(result).to eq(['abc123'])
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('merge-base', 'main',
                                                            'feature').and_return(command_result("abc123\n"))
        command.call('main', 'feature', fork_point: false)
      end
    end

    context 'with :all option' do
      it 'adds --all flag' do
        expect(execution_context).to receive(:command).with('merge-base', '--all', 'main',
                                                            'feature').and_return(command_result("sha1\nsha2\n"))
        result = command.call('main', 'feature', all: true)
        expect(result).to eq(%w[sha1 sha2])
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('merge-base', 'main',
                                                            'feature').and_return(command_result("abc123\n"))
        command.call('main', 'feature', all: false)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect(execution_context).to receive(:command).with(
          'merge-base', '--octopus', '--all', 'main', 'b1', 'b2'
        ).and_return(command_result("sha1\nsha2\n"))
        result = command.call('main', 'b1', 'b2', octopus: true, all: true)
        expect(result).to eq(%w[sha1 sha2])
      end
    end

    context 'with no commits provided' do
      it 'raises an error' do
        expect { command.call }.to raise_error(ArgumentError)
      end
    end

    context 'return value parsing' do
      it 'returns empty array when no output' do
        expect(execution_context).to receive(:command).with('merge-base', 'main',
                                                            'feature').and_return(command_result(''))
        result = command.call('main', 'feature')
        expect(result).to eq([])
      end

      it 'strips whitespace from each SHA' do
        expect(execution_context).to receive(:command).with('merge-base', '--all', 'main', 'feature')
                                                      .and_return(command_result("  sha1  \n  sha2  \n"))
        result = command.call('main', 'feature', all: true)
        expect(result).to eq(%w[sha1 sha2])
      end

      it 'filters out empty lines' do
        expect(execution_context).to receive(:command).with('merge-base', 'main',
                                                            'feature').and_return(command_result("sha1\n\nsha2\n\n"))
        result = command.call('main', 'feature')
        expect(result).to eq(%w[sha1 sha2])
      end
    end
  end
end
