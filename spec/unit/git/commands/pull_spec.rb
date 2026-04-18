# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/pull'

RSpec.describe Git::Commands::Pull do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git pull with no positional arguments' do
        expected_result = command_result
        expect_command_capturing('pull').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a repository argument' do
      it 'adds the end-of-options separator before the repository operand' do
        expect_command_capturing('pull', '--', 'origin').and_return(command_result)

        command.call('origin')
      end
    end

    context 'with a repository and refspec' do
      it 'adds -- and then repository and refspec' do
        expect_command_capturing('pull', '--', 'origin', 'main').and_return(command_result)

        command.call('origin', 'main')
      end
    end

    context 'with a repository and multiple refspecs' do
      it 'adds -- and then repository and all refspecs' do
        expect_command_capturing('pull', '--', 'origin', 'main', 'develop').and_return(command_result)

        command.call('origin', 'main', 'develop')
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('pull', '--quiet').and_return(command_result)

        command.call(quiet: true)
      end

      it 'supports the :q alias' do
        expect_command_capturing('pull', '--quiet').and_return(command_result)

        command.call(q: true)
      end
    end

    context 'with the :verbose option' do
      it 'adds --verbose to the command line' do
        expect_command_capturing('pull', '--verbose').and_return(command_result)

        command.call(verbose: true)
      end

      it 'supports the :v alias' do
        expect_command_capturing('pull', '--verbose').and_return(command_result)

        command.call(v: true)
      end
    end

    context 'with the :progress option' do
      it 'adds --progress to the command line' do
        expect_command_capturing('pull', '--progress').and_return(command_result)

        command.call(progress: true)
      end

      it 'adds --no-progress when false' do
        expect_command_capturing('pull', '--no-progress').and_return(command_result)

        command.call(progress: false)
      end
    end

    context 'with the :recurse_submodules option' do
      it 'adds --recurse-submodules when true' do
        expect_command_capturing('pull', '--recurse-submodules').and_return(command_result)

        command.call(recurse_submodules: true)
      end

      it 'adds --no-recurse-submodules when false' do
        expect_command_capturing('pull', '--no-recurse-submodules').and_return(command_result)

        command.call(recurse_submodules: false)
      end

      it 'adds --recurse-submodules=<value> when given a string' do
        expect_command_capturing('pull', '--recurse-submodules=on-demand').and_return(command_result)

        command.call(recurse_submodules: 'on-demand')
      end
    end

    context 'with the :commit option' do
      it 'adds --commit when true' do
        expect_command_capturing('pull', '--commit').and_return(command_result)

        command.call(commit: true)
      end

      it 'adds --no-commit when false' do
        expect_command_capturing('pull', '--no-commit').and_return(command_result)

        command.call(commit: false)
      end
    end

    context 'with the :cleanup option' do
      it 'adds --cleanup=<mode> to the command line' do
        expect_command_capturing('pull', '--cleanup=strip').and_return(command_result)

        command.call(cleanup: 'strip')
      end
    end

    context 'with the :ff option' do
      it 'adds --ff when true' do
        expect_command_capturing('pull', '--ff').and_return(command_result)

        command.call(ff: true)
      end

      it 'adds --no-ff when false' do
        expect_command_capturing('pull', '--no-ff').and_return(command_result)

        command.call(ff: false)
      end
    end

    context 'with the :ff_only option' do
      it 'adds --ff-only to the command line' do
        expect_command_capturing('pull', '--ff-only').and_return(command_result)

        command.call(ff_only: true)
      end
    end

    context 'with the :log option' do
      it 'adds --log when true' do
        expect_command_capturing('pull', '--log').and_return(command_result)

        command.call(log: true)
      end

      it 'adds --no-log when false' do
        expect_command_capturing('pull', '--no-log').and_return(command_result)

        command.call(log: false)
      end

      it 'adds --log=<n> when given an integer' do
        expect_command_capturing('pull', '--log=5').and_return(command_result)

        command.call(log: 5)
      end
    end

    context 'with the :squash option' do
      it 'adds --squash when true' do
        expect_command_capturing('pull', '--squash').and_return(command_result)

        command.call(squash: true)
      end

      it 'adds --no-squash when false' do
        expect_command_capturing('pull', '--no-squash').and_return(command_result)

        command.call(squash: false)
      end
    end

    context 'with the :verify option' do
      it 'adds --verify when true' do
        expect_command_capturing('pull', '--verify').and_return(command_result)

        command.call(verify: true)
      end

      it 'adds --no-verify when false' do
        expect_command_capturing('pull', '--no-verify').and_return(command_result)

        command.call(verify: false)
      end
    end

    context 'with the :strategy option' do
      it 'adds --strategy=<name> to the command line' do
        expect_command_capturing('pull', '--strategy=ort').and_return(command_result)

        command.call(strategy: 'ort')
      end

      it 'supports the :s alias' do
        expect_command_capturing('pull', '--strategy=recursive').and_return(command_result)

        command.call(s: 'recursive')
      end
    end

    context 'with the :strategy_option option' do
      it 'adds --strategy-option=<option> to the command line' do
        expect_command_capturing('pull', '--strategy-option=theirs').and_return(command_result)

        command.call(strategy_option: 'theirs')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'pull', '--strategy-option=theirs', '--strategy-option=patience'
        ).and_return(command_result)

        command.call(strategy_option: %w[theirs patience])
      end

      it 'supports the :X alias' do
        expect_command_capturing('pull', '--strategy-option=ours').and_return(command_result)

        command.call(X: 'ours')
      end
    end

    context 'with the :verify_signatures option' do
      it 'adds --verify-signatures when true' do
        expect_command_capturing('pull', '--verify-signatures').and_return(command_result)

        command.call(verify_signatures: true)
      end

      it 'adds --no-verify-signatures when false' do
        expect_command_capturing('pull', '--no-verify-signatures').and_return(command_result)

        command.call(verify_signatures: false)
      end
    end

    context 'with the :summary option' do
      it 'adds --summary when true' do
        expect_command_capturing('pull', '--summary').and_return(command_result)

        command.call(summary: true)
      end

      it 'adds --no-summary when false' do
        expect_command_capturing('pull', '--no-summary').and_return(command_result)

        command.call(summary: false)
      end
    end

    context 'with the :allow_unrelated_histories option' do
      it 'adds --allow-unrelated-histories to the command line' do
        expect_command_capturing('pull', '--allow-unrelated-histories').and_return(command_result)

        command.call(allow_unrelated_histories: true)
      end
    end

    context 'with the :rebase option' do
      it 'adds --rebase when true' do
        expect_command_capturing('pull', '--rebase').and_return(command_result)

        command.call(rebase: true)
      end

      it 'adds --no-rebase when false' do
        expect_command_capturing('pull', '--no-rebase').and_return(command_result)

        command.call(rebase: false)
      end

      it 'adds --rebase=<mode> when given a string' do
        expect_command_capturing('pull', '--rebase=merges').and_return(command_result)

        command.call(rebase: 'merges')
      end

      it 'supports the :r alias' do
        expect_command_capturing('pull', '--rebase').and_return(command_result)

        command.call(r: true)
      end
    end

    context 'with the :autostash option' do
      it 'adds --autostash when true' do
        expect_command_capturing('pull', '--autostash').and_return(command_result)

        command.call(autostash: true)
      end

      it 'adds --no-autostash when false' do
        expect_command_capturing('pull', '--no-autostash').and_return(command_result)

        command.call(autostash: false)
      end
    end

    context 'with the :signoff option' do
      it 'adds --signoff when true' do
        expect_command_capturing('pull', '--signoff').and_return(command_result)

        command.call(signoff: true)
      end

      it 'adds --no-signoff when false' do
        expect_command_capturing('pull', '--no-signoff').and_return(command_result)

        command.call(signoff: false)
      end
    end

    context 'with the :stat option' do
      it 'adds --stat to the command line' do
        expect_command_capturing('pull', '--stat').and_return(command_result)

        command.call(stat: true)
      end
    end

    context 'with the :no_stat option' do
      it 'adds --no-stat to the command line' do
        expect_command_capturing('pull', '--no-stat').and_return(command_result)

        command.call(no_stat: true)
      end

      it 'supports the :n alias' do
        expect_command_capturing('pull', '--no-stat').and_return(command_result)

        command.call(n: true)
      end
    end

    context 'with the :gpg_sign option' do
      it 'adds --gpg-sign when true' do
        expect_command_capturing('pull', '--gpg-sign').and_return(command_result)

        command.call(gpg_sign: true)
      end

      it 'adds --no-gpg-sign when false' do
        expect_command_capturing('pull', '--no-gpg-sign').and_return(command_result)

        command.call(gpg_sign: false)
      end

      it 'adds --gpg-sign=<keyid> when given a string' do
        expect_command_capturing('pull', '--gpg-sign=ABCDEF').and_return(command_result)

        command.call(gpg_sign: 'ABCDEF')
      end

      it 'supports the :S alias' do
        expect_command_capturing('pull', '--gpg-sign').and_return(command_result)

        command.call(S: true)
      end
    end

    context 'with the :all option' do
      it 'adds --all to the command line' do
        expect_command_capturing('pull', '--all').and_return(command_result)

        command.call(all: true)
      end

      it 'adds --no-all when false' do
        expect_command_capturing('pull', '--no-all').and_return(command_result)

        command.call(all: false)
      end
    end

    context 'with the :append option' do
      it 'adds --append to the command line' do
        expect_command_capturing('pull', '--append').and_return(command_result)

        command.call(append: true)
      end

      it 'supports the :a alias' do
        expect_command_capturing('pull', '--append').and_return(command_result)

        command.call(a: true)
      end
    end

    context 'with the :atomic option' do
      it 'adds --atomic to the command line' do
        expect_command_capturing('pull', '--atomic').and_return(command_result)

        command.call(atomic: true)
      end
    end

    context 'with the :depth option' do
      it 'adds --depth=<n> to the command line' do
        expect_command_capturing('pull', '--depth=5').and_return(command_result)

        command.call(depth: '5')
      end
    end

    context 'with the :deepen option' do
      it 'adds --deepen=<n> to the command line' do
        expect_command_capturing('pull', '--deepen=3').and_return(command_result)

        command.call(deepen: '3')
      end
    end

    context 'with the :shallow_since option' do
      it 'adds --shallow-since=<date> to the command line' do
        expect_command_capturing('pull', '--shallow-since=2024-01-01').and_return(command_result)

        command.call(shallow_since: '2024-01-01')
      end
    end

    context 'with the :shallow_exclude option' do
      it 'adds --shallow-exclude=<ref> to the command line' do
        expect_command_capturing('pull', '--shallow-exclude=origin/main').and_return(command_result)

        command.call(shallow_exclude: 'origin/main')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'pull', '--shallow-exclude=origin/main', '--shallow-exclude=origin/dev'
        ).and_return(command_result)

        command.call(shallow_exclude: %w[origin/main origin/dev])
      end
    end

    context 'with the :unshallow option' do
      it 'adds --unshallow to the command line' do
        expect_command_capturing('pull', '--unshallow').and_return(command_result)

        command.call(unshallow: true)
      end
    end

    context 'with the :update_shallow option' do
      it 'adds --update-shallow to the command line' do
        expect_command_capturing('pull', '--update-shallow').and_return(command_result)

        command.call(update_shallow: true)
      end
    end

    context 'with the :negotiation_tip option' do
      it 'adds --negotiation-tip=<commit> to the command line' do
        expect_command_capturing('pull', '--negotiation-tip=abc1234').and_return(command_result)

        command.call(negotiation_tip: 'abc1234')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'pull', '--negotiation-tip=abc1234', '--negotiation-tip=def5678'
        ).and_return(command_result)

        command.call(negotiation_tip: %w[abc1234 def5678])
      end
    end

    context 'with the :negotiate_only option' do
      it 'adds --negotiate-only to the command line' do
        expect_command_capturing('pull', '--negotiate-only').and_return(command_result)

        command.call(negotiate_only: true)
      end
    end

    context 'with the :dry_run option' do
      it 'adds --dry-run to the command line' do
        expect_command_capturing('pull', '--dry-run').and_return(command_result)

        command.call(dry_run: true)
      end
    end

    context 'with the :prefetch option' do
      it 'adds --prefetch to the command line' do
        expect_command_capturing('pull', '--prefetch').and_return(command_result)

        command.call(prefetch: true)
      end
    end

    context 'with the :force option' do
      it 'adds --force to the command line' do
        expect_command_capturing('pull', '--force').and_return(command_result)

        command.call(force: true)
      end

      it 'supports the :f alias' do
        expect_command_capturing('pull', '--force').and_return(command_result)

        command.call(f: true)
      end
    end

    context 'with the :keep option' do
      it 'adds --keep to the command line' do
        expect_command_capturing('pull', '--keep').and_return(command_result)

        command.call(keep: true)
      end

      it 'supports the :k alias' do
        expect_command_capturing('pull', '--keep').and_return(command_result)

        command.call(k: true)
      end
    end

    context 'with the :prune option' do
      it 'adds --prune to the command line' do
        expect_command_capturing('pull', '--prune').and_return(command_result)

        command.call(prune: true)
      end

      it 'supports the :p alias' do
        expect_command_capturing('pull', '--prune').and_return(command_result)

        command.call(p: true)
      end
    end

    context 'with the :tags option' do
      it 'adds --tags when true' do
        expect_command_capturing('pull', '--tags').and_return(command_result)

        command.call(tags: true)
      end

      it 'adds --no-tags when false' do
        expect_command_capturing('pull', '--no-tags').and_return(command_result)

        command.call(tags: false)
      end

      it 'supports the :t alias' do
        expect_command_capturing('pull', '--tags').and_return(command_result)

        command.call(t: true)
      end
    end

    context 'with the :jobs option' do
      it 'adds --jobs=<n> to the command line' do
        expect_command_capturing('pull', '--jobs=4').and_return(command_result)

        command.call(jobs: '4')
      end

      it 'supports the :j alias' do
        expect_command_capturing('pull', '--jobs=2').and_return(command_result)

        command.call(j: '2')
      end
    end

    context 'with the :set_upstream option' do
      it 'adds --set-upstream to the command line' do
        expect_command_capturing('pull', '--set-upstream').and_return(command_result)

        command.call(set_upstream: true)
      end
    end

    context 'with the :upload_pack option' do
      it 'adds --upload-pack <path> to the command line' do
        expect_command_capturing(
          'pull', '--upload-pack', 'custom/git-upload-pack'
        ).and_return(command_result)

        command.call(upload_pack: 'custom/git-upload-pack')
      end
    end

    context 'with the :server_option option' do
      it 'adds --server-option=<value> to the command line' do
        expect_command_capturing('pull', '--server-option=custom').and_return(command_result)

        command.call(server_option: 'custom')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'pull', '--server-option=option1', '--server-option=option2'
        ).and_return(command_result)

        command.call(server_option: %w[option1 option2])
      end

      it 'supports the :o alias' do
        expect_command_capturing('pull', '--server-option=custom').and_return(command_result)

        command.call(o: 'custom')
      end
    end

    context 'with the :show_forced_updates option' do
      it 'adds --show-forced-updates when true' do
        expect_command_capturing('pull', '--show-forced-updates').and_return(command_result)

        command.call(show_forced_updates: true)
      end

      it 'adds --no-show-forced-updates when false' do
        expect_command_capturing('pull', '--no-show-forced-updates').and_return(command_result)

        command.call(show_forced_updates: false)
      end
    end

    context 'with the :refmap option' do
      it 'adds --refmap=<refspec> to the command line' do
        expect_command_capturing(
          'pull', '--refmap=+refs/heads/*:refs/remotes/origin/*'
        ).and_return(command_result)

        command.call(refmap: '+refs/heads/*:refs/remotes/origin/*')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'pull', '--refmap=+refs/heads/*:refs/remotes/origin/*',
          '--refmap=+refs/tags/*:refs/tags/*'
        ).and_return(command_result)

        command.call(refmap: ['+refs/heads/*:refs/remotes/origin/*', '+refs/tags/*:refs/tags/*'])
      end
    end

    context 'with the :ipv4 option' do
      it 'adds --ipv4 to the command line' do
        expect_command_capturing('pull', '--ipv4').and_return(command_result)

        command.call(ipv4: true)
      end

      it "supports the :'4' alias" do
        expect_command_capturing('pull', '--ipv4').and_return(command_result)

        command.call('4': true)
      end
    end

    context 'with the :ipv6 option' do
      it 'adds --ipv6 to the command line' do
        expect_command_capturing('pull', '--ipv6').and_return(command_result)

        command.call(ipv6: true)
      end

      it "supports the :'6' alias" do
        expect_command_capturing('pull', '--ipv6').and_return(command_result)

        command.call('6': true)
      end
    end

    context 'with the :timeout execution option' do
      it 'passes the timeout to command_capturing' do
        expect_command_capturing('pull', timeout: 30).and_return(command_result)

        command.call(timeout: 30)
      end
    end

    context 'with the :edit option' do
      it 'adds --edit when true' do
        expect_command_capturing('pull', '--edit').and_return(command_result)

        command.call(edit: true)
      end

      it 'adds --no-edit when false' do
        expect_command_capturing('pull', '--no-edit').and_return(command_result)

        command.call(edit: false)
      end

      it 'supports the :e alias' do
        expect_command_capturing('pull', '--edit').and_return(command_result)

        command.call(e: true)
      end
    end

    context 'with the :compact_summary option' do
      it 'adds --compact-summary to the command line' do
        expect_command_capturing('pull', '--compact-summary').and_return(command_result)

        command.call(compact_summary: true)
      end
    end

    context 'with the :porcelain option' do
      it 'adds --porcelain to the command line' do
        expect_command_capturing('pull', '--porcelain').and_return(command_result)

        command.call(porcelain: true)
      end
    end

    context 'with combined options and positional arguments' do
      it 'places flags before -- and positional args after' do
        expect_command_capturing(
          'pull', '--allow-unrelated-histories', '--', 'origin', 'feature'
        ).and_return(command_result)

        command.call('origin', 'feature', allow_unrelated_histories: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(bogus_option: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
