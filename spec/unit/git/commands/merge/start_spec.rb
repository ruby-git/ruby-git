# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge/start'

RSpec.describe Git::Commands::Merge::Start do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with single branch to merge' do
      it 'calls git merge with the branch name' do
        expected_result = command_result
        expect_command_capturing('merge', '--', 'feature').and_return(expected_result)

        result = command.call('feature')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple branches (octopus merge)' do
      it 'merges multiple branches' do
        expect_command_capturing('merge', '--', 'branch1', 'branch2').and_return(command_result)
        command.call('branch1', 'branch2')
      end

      it 'merges three branches' do
        expect_command_capturing('merge', '--', 'a', 'b', 'c').and_return(command_result)
        command.call('a', 'b', 'c')
      end
    end

    context 'with :commit option' do
      context 'when true' do
        it 'adds --commit flag' do
          expect_command_capturing('merge', '--commit', '--', 'feature').and_return(command_result)
          command.call('feature', commit: true)
        end
      end

      context 'when false' do
        it 'adds --no-commit flag' do
          expect_command_capturing('merge', '--no-commit', '--', 'feature').and_return(command_result)
          command.call('feature', commit: false)
        end
      end
    end

    context 'with :edit option' do
      it 'adds --no-edit when edit is false' do
        expect_command_capturing('merge', '--no-edit', '--', 'feature').and_return(command_result)
        command.call('feature', edit: false)
      end

      it 'adds --edit when edit is true' do
        expect_command_capturing('merge', '--edit', '--', 'feature').and_return(command_result)
        command.call('feature', edit: true)
      end

      it 'omits --edit/--no-edit when edit is nil' do
        expect_command_capturing('merge', '--', 'feature').and_return(command_result)
        command.call('feature', edit: nil)
      end

      it 'supports the :e alias' do
        expect_command_capturing('merge', '--edit', '--', 'feature').and_return(command_result)
        command.call('feature', e: true)
      end
    end

    context 'with :cleanup option' do
      it 'adds --cleanup=<mode>' do
        expect_command_capturing('merge', '--cleanup=strip', '--', 'feature').and_return(command_result)
        command.call('feature', cleanup: 'strip')
      end
    end

    context 'with :ff options' do
      context 'with :ff option' do
        context 'when true' do
          it 'adds --ff flag' do
            expect_command_capturing('merge', '--ff', '--', 'feature').and_return(command_result)
            command.call('feature', ff: true)
          end
        end

        context 'when false' do
          it 'adds --no-ff flag' do
            expect_command_capturing('merge', '--no-ff', '--', 'feature').and_return(command_result)
            command.call('feature', ff: false)
          end
        end
      end

      context 'with :ff_only option' do
        it 'adds --ff-only flag' do
          expect_command_capturing('merge', '--ff-only', '--', 'feature').and_return(command_result)
          command.call('feature', ff_only: true)
        end

        it 'does not add flag when false' do
          expect_command_capturing('merge', '--', 'feature').and_return(command_result)
          command.call('feature', ff_only: false)
        end
      end
    end

    context 'with :gpg_sign option' do
      context 'when true' do
        it 'adds --gpg-sign flag' do
          expect_command_capturing('merge', '--gpg-sign', '--', 'feature').and_return(command_result)
          command.call('feature', gpg_sign: true)
        end
      end

      context 'when false' do
        it 'adds --no-gpg-sign flag' do
          expect_command_capturing('merge', '--no-gpg-sign', '--', 'feature').and_return(command_result)
          command.call('feature', gpg_sign: false)
        end
      end

      context 'when a key ID string' do
        it 'adds --gpg-sign=<keyid>' do
          expect_command_capturing('merge', '--gpg-sign=ABCDEF01', '--', 'feature').and_return(command_result)
          command.call('feature', gpg_sign: 'ABCDEF01')
        end
      end

      it 'supports the :S alias' do
        expect_command_capturing('merge', '--gpg-sign', '--', 'feature').and_return(command_result)
        command.call('feature', S: true)
      end
    end

    context 'with :log option' do
      context 'when true' do
        it 'adds --log flag' do
          expect_command_capturing('merge', '--log', '--', 'feature').and_return(command_result)
          command.call('feature', log: true)
        end
      end

      context 'when false' do
        it 'adds --no-log flag' do
          expect_command_capturing('merge', '--no-log', '--', 'feature').and_return(command_result)
          command.call('feature', log: false)
        end
      end

      context 'when an integer' do
        it 'adds --log=<n>' do
          expect_command_capturing('merge', '--log=10', '--', 'feature').and_return(command_result)
          command.call('feature', log: 10)
        end
      end
    end

    context 'with :signoff option' do
      context 'when true' do
        it 'adds --signoff flag' do
          expect_command_capturing('merge', '--signoff', '--', 'feature').and_return(command_result)
          command.call('feature', signoff: true)
        end
      end

      context 'when false' do
        it 'adds --no-signoff flag' do
          expect_command_capturing('merge', '--no-signoff', '--', 'feature').and_return(command_result)
          command.call('feature', signoff: false)
        end
      end
    end

    context 'with :stat option' do
      context 'when true' do
        it 'adds --stat flag' do
          expect_command_capturing('merge', '--stat', '--', 'feature').and_return(command_result)
          command.call('feature', stat: true)
        end
      end

      context 'when false' do
        it 'adds --no-stat flag' do
          expect_command_capturing('merge', '--no-stat', '--', 'feature').and_return(command_result)
          command.call('feature', stat: false)
        end
      end
    end

    context 'with :compact_summary option' do
      it 'adds --compact-summary flag' do
        expect_command_capturing('merge', '--compact-summary', '--', 'feature').and_return(command_result)
        command.call('feature', compact_summary: true)
      end

      it 'does not add flag when false' do
        expect_command_capturing('merge', '--', 'feature').and_return(command_result)
        command.call('feature', compact_summary: false)
      end
    end

    context 'with :squash option' do
      it 'adds --squash flag' do
        expect_command_capturing('merge', '--squash', '--', 'feature').and_return(command_result)
        command.call('feature', squash: true)
      end

      it 'does not add flag when false' do
        expect_command_capturing('merge', '--', 'feature').and_return(command_result)
        command.call('feature', squash: false)
      end
    end

    context 'with :verify option' do
      context 'when true' do
        it 'adds --verify flag' do
          expect_command_capturing('merge', '--verify', '--', 'feature').and_return(command_result)
          command.call('feature', verify: true)
        end
      end

      context 'when false' do
        it 'adds --no-verify flag' do
          expect_command_capturing('merge', '--no-verify', '--', 'feature').and_return(command_result)
          command.call('feature', verify: false)
        end
      end
    end

    context 'with :strategy option' do
      it 'adds --strategy=<name>' do
        expect_command_capturing('merge', '--strategy=ours', '--', 'feature').and_return(command_result)
        command.call('feature', strategy: 'ours')
      end

      it 'supports the :s alias' do
        expect_command_capturing('merge', '--strategy=recursive', '--', 'feature').and_return(command_result)
        command.call('feature', s: 'recursive')
      end
    end

    context 'with :strategy_option option' do
      it 'adds --strategy-option=<value>' do
        expect_command_capturing('merge', '--strategy-option=ours', '--', 'feature').and_return(command_result)
        command.call('feature', strategy_option: 'ours')
      end

      it 'supports the :X alias' do
        expect_command_capturing('merge', '--strategy-option=theirs', '--', 'feature').and_return(command_result)
        command.call('feature', X: 'theirs')
      end

      it 'supports multiple strategy options as an array' do
        expect_command_capturing(
          'merge', '--strategy-option=ours', '--strategy-option=patience', '--', 'feature'
        ).and_return(command_result)
        command.call('feature', strategy_option: %w[ours patience])
      end
    end

    context 'with :verify_signatures option' do
      context 'when true' do
        it 'adds --verify-signatures flag' do
          expect_command_capturing('merge', '--verify-signatures', '--', 'feature').and_return(command_result)
          command.call('feature', verify_signatures: true)
        end
      end

      context 'when false' do
        it 'adds --no-verify-signatures flag' do
          expect_command_capturing('merge', '--no-verify-signatures', '--', 'feature').and_return(command_result)
          command.call('feature', verify_signatures: false)
        end
      end
    end

    context 'with :quiet option' do
      it 'adds --quiet flag' do
        expect_command_capturing('merge', '--quiet', '--', 'feature').and_return(command_result)
        command.call('feature', quiet: true)
      end

      it 'supports the :q alias' do
        expect_command_capturing('merge', '--quiet', '--', 'feature').and_return(command_result)
        command.call('feature', q: true)
      end
    end

    context 'with :verbose option' do
      it 'adds --verbose flag' do
        expect_command_capturing('merge', '--verbose', '--', 'feature').and_return(command_result)
        command.call('feature', verbose: true)
      end

      it 'supports the :v alias' do
        expect_command_capturing('merge', '--verbose', '--', 'feature').and_return(command_result)
        command.call('feature', v: true)
      end
    end

    context 'with :progress option' do
      context 'when true' do
        it 'adds --progress flag' do
          expect_command_capturing('merge', '--progress', '--', 'feature').and_return(command_result)
          command.call('feature', progress: true)
        end
      end

      context 'when false' do
        it 'adds --no-progress flag' do
          expect_command_capturing('merge', '--no-progress', '--', 'feature').and_return(command_result)
          command.call('feature', progress: false)
        end
      end
    end

    context 'with :autostash option' do
      context 'when true' do
        it 'adds --autostash flag' do
          expect_command_capturing('merge', '--autostash', '--', 'feature').and_return(command_result)
          command.call('feature', autostash: true)
        end
      end

      context 'when false' do
        it 'adds --no-autostash flag' do
          expect_command_capturing('merge', '--no-autostash', '--', 'feature').and_return(command_result)
          command.call('feature', autostash: false)
        end
      end
    end

    context 'with :allow_unrelated_histories option' do
      context 'when true' do
        it 'adds --allow-unrelated-histories flag' do
          expect_command_capturing(
            'merge', '--allow-unrelated-histories', '--', 'feature'
          ).and_return(command_result)
          command.call('feature', allow_unrelated_histories: true)
        end
      end

      context 'when false' do
        it 'adds --no-allow-unrelated-histories flag' do
          expect_command_capturing(
            'merge', '--no-allow-unrelated-histories', '--', 'feature'
          ).and_return(command_result)
          command.call('feature', allow_unrelated_histories: false)
        end
      end
    end

    context 'with :m option' do
      it 'adds -m flag with message' do
        expect_command_capturing('merge', '-m', 'Merge feature', '--', 'feature').and_return(command_result)
        command.call('feature', m: 'Merge feature')
      end

      it 'raises ArgumentError for unsupported :message key' do
        expect { command.call('feature', message: 'Merge feature') }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end

    context 'with :into_name option' do
      it 'adds --into-name flag with value' do
        expect_command_capturing('merge', '--into-name', 'main', '--', 'feature').and_return(command_result)
        command.call('feature', into_name: 'main')
      end
    end

    context 'with :file option' do
      it 'adds --file=<path>' do
        expect_command_capturing('merge', '--file=/path/to/msg.txt', '--', 'feature').and_return(command_result)
        command.call('feature', file: '/path/to/msg.txt')
      end

      it 'supports the :F alias' do
        expect_command_capturing('merge', '--file=msg.txt', '--', 'feature').and_return(command_result)
        command.call('feature', F: 'msg.txt')
      end
    end

    context 'with :rerere_autoupdate option' do
      context 'when true' do
        it 'adds --rerere-autoupdate flag' do
          expect_command_capturing('merge', '--rerere-autoupdate', '--', 'feature').and_return(command_result)
          command.call('feature', rerere_autoupdate: true)
        end
      end

      context 'when false' do
        it 'adds --no-rerere-autoupdate flag' do
          expect_command_capturing('merge', '--no-rerere-autoupdate', '--', 'feature').and_return(command_result)
          command.call('feature', rerere_autoupdate: false)
        end
      end
    end

    context 'with :overwrite_ignore option' do
      context 'when true' do
        it 'adds --overwrite-ignore flag' do
          expect_command_capturing('merge', '--overwrite-ignore', '--', 'feature').and_return(command_result)
          command.call('feature', overwrite_ignore: true)
        end
      end

      context 'when false' do
        it 'adds --no-overwrite-ignore flag' do
          expect_command_capturing('merge', '--no-overwrite-ignore', '--', 'feature').and_return(command_result)
          command.call('feature', overwrite_ignore: false)
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct DSL order' do
        expect_command_capturing(
          'merge',
          '--no-commit', '--no-edit', '--no-ff',
          '--strategy=ort', '--strategy-option=theirs',
          '-m', 'Merge feature branch',
          '--', 'feature'
        ).and_return(command_result)
        command.call(
          'feature',
          edit: false,
          commit: false,
          ff: false,
          m: 'Merge feature branch',
          strategy: 'ort',
          strategy_option: 'theirs'
        )
      end

      it 'combines ff_only with allow_unrelated_histories' do
        expect_command_capturing(
          'merge', '--ff-only', '--allow-unrelated-histories', '--', 'feature'
        ).and_return(command_result)
        command.call('feature', ff_only: true, allow_unrelated_histories: true)
      end
    end

    context 'input validation' do
      it 'raises an error when no commits provided' do
        expect { command.call }.to raise_error(ArgumentError)
      end
    end
  end
end
