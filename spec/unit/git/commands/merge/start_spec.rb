# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge/start'

RSpec.describe Git::Commands::Merge::Start do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      allow(execution_context).to receive(:command).and_return(command_result)
    end

    context 'with single branch to merge' do
      it 'calls git merge with --no-edit and the branch name' do
        expected_result = command_result
        expect_command('merge', '--no-edit', 'feature').and_return(expected_result)

        result = command.call('feature')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple branches (octopus merge)' do
      it 'merges multiple branches' do
        expect_command('merge', '--no-edit', 'branch1', 'branch2')
        command.call('branch1', 'branch2')
      end

      it 'merges three branches' do
        expect_command('merge', '--no-edit', 'a', 'b', 'c')
        command.call('a', 'b', 'c')
      end
    end

    context 'with :commit option' do
      context 'when true' do
        it 'adds --commit flag' do
          expect_command('merge', '--no-edit', '--commit', 'feature')
          command.call('feature', commit: true)
        end
      end

      context 'when false' do
        it 'adds --no-commit flag' do
          expect_command('merge', '--no-edit', '--no-commit', 'feature')
          command.call('feature', commit: false)
        end
      end
    end

    context 'with :squash option' do
      it 'adds --squash flag' do
        expect_command('merge', '--no-edit', '--squash', 'feature')
        command.call('feature', squash: true)
      end

      it 'does not add flag when false' do
        expect_command('merge', '--no-edit', 'feature')
        command.call('feature', squash: false)
      end
    end

    context 'with :ff option (fast-forward)' do
      context 'when true' do
        it 'adds --ff flag' do
          expect_command('merge', '--no-edit', '--ff', 'feature')
          command.call('feature', ff: true)
        end
      end

      context 'when false' do
        it 'adds --no-ff flag' do
          expect_command('merge', '--no-edit', '--no-ff', 'feature')
          command.call('feature', ff: false)
        end
      end
    end

    context 'with :ff_only option' do
      it 'adds --ff-only flag' do
        expect_command('merge', '--no-edit', '--ff-only', 'feature')
        command.call('feature', ff_only: true)
      end

      it 'does not add flag when false' do
        expect_command('merge', '--no-edit', 'feature')
        command.call('feature', ff_only: false)
      end
    end

    context 'with :m option' do
      it 'adds -m flag with message' do
        expect_command('merge', '--no-edit', '-m', 'Merge feature', 'feature')
        command.call('feature', m: 'Merge feature')
      end

      it 'raises ArgumentError for unsupported :message key' do
        expect { command.call('feature', message: 'Merge feature') }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end

    context 'with :file option' do
      it 'adds --file flag with file path' do
        expect_command('merge', '--no-edit', '--file', '/path/to/msg.txt', 'feature')
        command.call('feature', file: '/path/to/msg.txt')
      end

      it 'works with :F alias' do
        expect_command('merge', '--no-edit', '--file', 'msg.txt', 'feature')
        command.call('feature', F: 'msg.txt')
      end
    end

    context 'with :into_name option' do
      it 'adds --into-name flag with value' do
        expect_command('merge', '--no-edit', '--into-name=main', 'feature')
        command.call('feature', into_name: 'main')
      end
    end

    context 'with :strategy option' do
      it 'adds --strategy flag with strategy name' do
        expect_command('merge', '--no-edit', '--strategy', 'ours', 'feature')
        command.call('feature', strategy: 'ours')
      end

      it 'works with :s alias' do
        expect_command('merge', '--no-edit', '--strategy', 'recursive', 'feature')
        command.call('feature', s: 'recursive')
      end
    end

    context 'with :strategy_option option' do
      it 'adds --strategy-option flag with strategy option' do
        expect_command('merge', '--no-edit', '--strategy-option', 'ours', 'feature')
        command.call('feature', strategy_option: 'ours')
      end

      it 'works with :X alias' do
        expect_command('merge', '--no-edit', '--strategy-option', 'theirs', 'feature')
        command.call('feature', X: 'theirs')
      end

      it 'supports multiple strategy options' do
        expect_command(
          'merge', '--no-edit', '--strategy-option', 'ours', '--strategy-option', 'patience', 'feature'
        )
        command.call('feature', strategy_option: %w[ours patience])
      end
    end

    context 'with :verify option' do
      context 'when true' do
        it 'adds --verify flag' do
          expect_command('merge', '--no-edit', '--verify', 'feature')
          command.call('feature', verify: true)
        end
      end

      context 'when false' do
        it 'adds --no-verify flag' do
          expect_command('merge', '--no-edit', '--no-verify', 'feature')
          command.call('feature', verify: false)
        end
      end
    end

    context 'with :verify_signatures option' do
      context 'when true' do
        it 'adds --verify-signatures flag' do
          expect_command('merge', '--no-edit', '--verify-signatures', 'feature')
          command.call('feature', verify_signatures: true)
        end
      end

      context 'when false' do
        it 'adds --no-verify-signatures flag' do
          expect_command(
            'merge', '--no-edit', '--no-verify-signatures', 'feature'
          )
          command.call('feature', verify_signatures: false)
        end
      end
    end

    context 'with :gpg_sign option' do
      context 'when true' do
        it 'adds --gpg-sign flag' do
          expect_command('merge', '--no-edit', '--gpg-sign', 'feature')
          command.call('feature', gpg_sign: true)
        end
      end

      context 'when false' do
        it 'adds --no-gpg-sign flag' do
          expect_command('merge', '--no-edit', '--no-gpg-sign', 'feature')
          command.call('feature', gpg_sign: false)
        end
      end
    end

    context 'with :allow_unrelated_histories option' do
      context 'when true' do
        it 'adds --allow-unrelated-histories flag' do
          expect_command(
            'merge', '--no-edit', '--allow-unrelated-histories', 'feature'
          )
          command.call('feature', allow_unrelated_histories: true)
        end
      end

      context 'when false' do
        it 'adds --no-allow-unrelated-histories flag' do
          expect_command(
            'merge', '--no-edit', '--no-allow-unrelated-histories', 'feature'
          )
          command.call('feature', allow_unrelated_histories: false)
        end
      end
    end

    context 'with :rerere_autoupdate option' do
      context 'when true' do
        it 'adds --rerere-autoupdate flag' do
          expect_command('merge', '--no-edit', '--rerere-autoupdate', 'feature')
          command.call('feature', rerere_autoupdate: true)
        end
      end

      context 'when false' do
        it 'adds --no-rerere-autoupdate flag' do
          expect_command(
            'merge', '--no-edit', '--no-rerere-autoupdate', 'feature'
          )
          command.call('feature', rerere_autoupdate: false)
        end
      end
    end

    context 'with :autostash option' do
      context 'when true' do
        it 'adds --autostash flag' do
          expect_command('merge', '--no-edit', '--autostash', 'feature')
          command.call('feature', autostash: true)
        end
      end

      context 'when false' do
        it 'adds --no-autostash flag' do
          expect_command('merge', '--no-edit', '--no-autostash', 'feature')
          command.call('feature', autostash: false)
        end
      end
    end

    context 'with :signoff option' do
      context 'when true' do
        it 'adds --signoff flag' do
          expect_command('merge', '--no-edit', '--signoff', 'feature')
          command.call('feature', signoff: true)
        end
      end

      context 'when false' do
        it 'adds --no-signoff flag' do
          expect_command('merge', '--no-edit', '--no-signoff', 'feature')
          command.call('feature', signoff: false)
        end
      end
    end

    context 'with :log option' do
      context 'when true' do
        it 'adds --log flag' do
          expect_command('merge', '--no-edit', '--log', 'feature')
          command.call('feature', log: true)
        end
      end

      context 'when false' do
        it 'adds --no-log flag' do
          expect_command('merge', '--no-edit', '--no-log', 'feature')
          command.call('feature', log: false)
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect_command(
          'merge', '--no-edit', '--no-commit', '--no-ff',
          '-m', 'Merge feature branch',
          '--strategy', 'ort',
          '--strategy-option', 'theirs',
          'feature'
        )
        command.call(
          'feature',
          commit: false,
          ff: false,
          m: 'Merge feature branch',
          strategy: 'ort',
          strategy_option: 'theirs'
        )
      end

      it 'combines squash with no-commit behavior' do
        expect_command('merge', '--no-edit', '--squash', 'feature')
        command.call('feature', squash: true)
      end

      it 'combines ff_only with allow_unrelated_histories' do
        expect_command(
          'merge', '--no-edit', '--ff-only', '--allow-unrelated-histories', 'feature'
        )
        command.call('feature', ff_only: true, allow_unrelated_histories: true)
      end
    end

    context 'input validation' do
      it 'raises an error when no commits provided' do
        expect { command.call }.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when both ff and ff_only are provided' do
        expect { command.call('feature', ff: true, ff_only: true) }
          .to raise_error(ArgumentError, /cannot specify :ff and :ff_only/)
      end
    end
  end
end
