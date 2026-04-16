# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/fetch'

RSpec.describe Git::Commands::Fetch do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments (fetches from default remote configured by git)' do
      it 'runs git fetch with no positional arguments' do
        expected_result = command_result
        expect_command_capturing('fetch').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a repository argument' do
      it 'adds -- and the repository after options' do
        expected_result = command_result
        expect_command_capturing('fetch', '--', 'origin').and_return(expected_result)

        result = command.call('origin')

        expect(result).to eq(expected_result)
      end
    end

    context 'with a repository and refspec' do
      it 'adds -- and then repository and refspec' do
        expected_result = command_result
        expect_command_capturing('fetch', '--', 'origin', 'main').and_return(expected_result)

        result = command.call('origin', 'main')

        expect(result).to eq(expected_result)
      end
    end

    context 'with a repository and multiple refspecs' do
      it 'adds -- and then repository and all refspecs' do
        expected_result = command_result
        expect_command_capturing('fetch', '--', 'origin', 'main', 'develop').and_return(expected_result)

        result = command.call('origin', 'main', 'develop')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :all option' do
      it 'adds --all to the command line' do
        expect_command_capturing('fetch', '--all').and_return(command_result)

        command.call(all: true)
      end
    end

    context 'with the :all option negated' do
      it 'adds --no-all to the command line' do
        expect_command_capturing('fetch', '--no-all').and_return(command_result)

        command.call(all: false)
      end
    end

    context 'with the :append option' do
      it 'adds --append to the command line' do
        expect_command_capturing('fetch', '--append').and_return(command_result)

        command.call(append: true)
      end

      it 'supports the :a alias' do
        expect_command_capturing('fetch', '--append').and_return(command_result)

        command.call(a: true)
      end
    end

    context 'with the :atomic option' do
      it 'adds --atomic to the command line' do
        expect_command_capturing('fetch', '--atomic').and_return(command_result)

        command.call(atomic: true)
      end
    end

    context 'with the :depth option' do
      it 'adds --depth=<n> to the command line' do
        expect_command_capturing('fetch', '--depth=5').and_return(command_result)

        command.call(depth: '5')
      end
    end

    context 'with the :deepen option' do
      it 'adds --deepen=<n> to the command line' do
        expect_command_capturing('fetch', '--deepen=3').and_return(command_result)

        command.call(deepen: '3')
      end
    end

    context 'with the :shallow_since option' do
      it 'adds --shallow-since=<date> to the command line' do
        expect_command_capturing('fetch', '--shallow-since=2024-01-01').and_return(command_result)

        command.call(shallow_since: '2024-01-01')
      end
    end

    context 'with the :shallow_exclude option' do
      it 'adds --shallow-exclude=<ref> to the command line' do
        expect_command_capturing('fetch', '--shallow-exclude=origin/main').and_return(command_result)

        command.call(shallow_exclude: 'origin/main')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'fetch', '--shallow-exclude=origin/main', '--shallow-exclude=origin/dev'
        ).and_return(command_result)

        command.call(shallow_exclude: %w[origin/main origin/dev])
      end
    end

    context 'with the :unshallow option' do
      it 'adds --unshallow to the command line' do
        expect_command_capturing('fetch', '--unshallow').and_return(command_result)

        command.call(unshallow: true)
      end
    end

    context 'with the :update_shallow option' do
      it 'adds --update-shallow to the command line' do
        expect_command_capturing('fetch', '--update-shallow').and_return(command_result)

        command.call(update_shallow: true)
      end
    end

    context 'with the :dry_run option' do
      it 'adds --dry-run to the command line' do
        expect_command_capturing('fetch', '--dry-run').and_return(command_result)

        command.call(dry_run: true)
      end
    end

    context 'with the :write_fetch_head option' do
      it 'adds --write-fetch-head when true' do
        expect_command_capturing('fetch', '--write-fetch-head').and_return(command_result)

        command.call(write_fetch_head: true)
      end

      it 'adds --no-write-fetch-head when false' do
        expect_command_capturing('fetch', '--no-write-fetch-head').and_return(command_result)

        command.call(write_fetch_head: false)
      end
    end

    context 'with the :refetch option' do
      it 'adds --refetch to the command line' do
        expect_command_capturing('fetch', '--refetch').and_return(command_result)

        command.call(refetch: true)
      end
    end

    context 'with the :prefetch option' do
      it 'adds --prefetch to the command line' do
        expect_command_capturing('fetch', '--prefetch').and_return(command_result)

        command.call(prefetch: true)
      end
    end

    context 'with the :force option' do
      it 'adds --force to the command line' do
        expect_command_capturing('fetch', '--force').and_return(command_result)

        command.call(force: true)
      end

      it 'supports the :f alias' do
        expect_command_capturing('fetch', '--force').and_return(command_result)

        command.call(f: true)
      end
    end

    context 'with the :keep option' do
      it 'adds --keep to the command line' do
        expect_command_capturing('fetch', '--keep').and_return(command_result)

        command.call(keep: true)
      end

      it 'supports the :k alias' do
        expect_command_capturing('fetch', '--keep').and_return(command_result)

        command.call(k: true)
      end
    end

    context 'with the :multiple option' do
      it 'adds --multiple to the command line' do
        expect_command_capturing('fetch', '--multiple').and_return(command_result)

        command.call(multiple: true)
      end
    end

    context 'with the :prune option' do
      it 'adds --prune to the command line' do
        expect_command_capturing('fetch', '--prune').and_return(command_result)

        command.call(prune: true)
      end

      it 'supports the :p alias' do
        expect_command_capturing('fetch', '--prune').and_return(command_result)

        command.call(p: true)
      end
    end

    context 'with the :prune_tags option' do
      it 'adds --prune-tags to the command line' do
        expect_command_capturing('fetch', '--prune-tags').and_return(command_result)

        command.call(prune_tags: true)
      end

      it 'supports the :P alias' do
        expect_command_capturing('fetch', '--prune-tags').and_return(command_result)

        command.call(P: true)
      end
    end

    context 'with the :tags option' do
      it 'adds --tags to the command line' do
        expect_command_capturing('fetch', '--tags').and_return(command_result)

        command.call(tags: true)
      end

      it 'supports the :t alias' do
        expect_command_capturing('fetch', '--tags').and_return(command_result)

        command.call(t: true)
      end

      it 'adds --no-tags when false' do
        expect_command_capturing('fetch', '--no-tags').and_return(command_result)

        command.call(tags: false)
      end
    end

    context 'with the :recurse_submodules option' do
      it 'adds --recurse-submodules when true' do
        expect_command_capturing('fetch', '--recurse-submodules').and_return(command_result)

        command.call(recurse_submodules: true)
      end

      it 'adds --recurse-submodules=yes when a string is given' do
        expect_command_capturing('fetch', '--recurse-submodules=yes').and_return(command_result)

        command.call(recurse_submodules: 'yes')
      end

      it 'adds --no-recurse-submodules when false' do
        expect_command_capturing('fetch', '--no-recurse-submodules').and_return(command_result)

        command.call(recurse_submodules: false)
      end
    end

    context 'with the :jobs option' do
      it 'adds --jobs=<n> to the command line' do
        expect_command_capturing('fetch', '--jobs=4').and_return(command_result)

        command.call(jobs: '4')
      end

      it 'supports the :j alias' do
        expect_command_capturing('fetch', '--jobs=2').and_return(command_result)

        command.call(j: '2')
      end
    end

    context 'with the :set_upstream option' do
      it 'adds --set-upstream to the command line' do
        expect_command_capturing('fetch', '--set-upstream').and_return(command_result)

        command.call(set_upstream: true)
      end
    end

    context 'with the :update_head_ok option' do
      it 'adds --update-head-ok to the command line' do
        expect_command_capturing('fetch', '--update-head-ok').and_return(command_result)

        command.call(update_head_ok: true)
      end

      it 'supports the :u alias' do
        expect_command_capturing('fetch', '--update-head-ok').and_return(command_result)

        command.call(u: true)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('fetch', '--quiet').and_return(command_result)

        command.call(quiet: true)
      end

      it 'supports the :q alias' do
        expect_command_capturing('fetch', '--quiet').and_return(command_result)

        command.call(q: true)
      end
    end

    context 'with the :verbose option' do
      it 'adds --verbose to the command line' do
        expect_command_capturing('fetch', '--verbose').and_return(command_result)

        command.call(verbose: true)
      end

      it 'supports the :v alias' do
        expect_command_capturing('fetch', '--verbose').and_return(command_result)

        command.call(v: true)
      end
    end

    context 'with the :progress option' do
      it 'adds --progress to the command line' do
        expect_command_capturing('fetch', '--progress').and_return(command_result)

        command.call(progress: true)
      end
    end

    context 'with the :server_option option' do
      it 'adds --server-option=<opt> to the command line' do
        expect_command_capturing('fetch', '--server-option=protocol-v2').and_return(command_result)

        command.call(server_option: 'protocol-v2')
      end

      it 'supports the :o alias' do
        expect_command_capturing('fetch', '--server-option=protocol-v2').and_return(command_result)

        command.call(o: 'protocol-v2')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'fetch', '--server-option=opt1', '--server-option=opt2'
        ).and_return(command_result)

        command.call(server_option: %w[opt1 opt2])
      end
    end

    context 'with the :show_forced_updates option' do
      it 'adds --show-forced-updates when true' do
        expect_command_capturing('fetch', '--show-forced-updates').and_return(command_result)

        command.call(show_forced_updates: true)
      end

      it 'adds --no-show-forced-updates when false' do
        expect_command_capturing('fetch', '--no-show-forced-updates').and_return(command_result)

        command.call(show_forced_updates: false)
      end
    end

    context 'with the :ipv4 option' do
      it 'adds --ipv4 to the command line' do
        expect_command_capturing('fetch', '--ipv4').and_return(command_result)

        command.call(ipv4: true)
      end

      it 'supports the :"4" alias' do
        expect_command_capturing('fetch', '--ipv4').and_return(command_result)

        command.call('4': true)
      end
    end

    context 'with the :ipv6 option' do
      it 'adds --ipv6 to the command line' do
        expect_command_capturing('fetch', '--ipv6').and_return(command_result)

        command.call(ipv6: true)
      end

      it 'supports the :"6" alias' do
        expect_command_capturing('fetch', '--ipv6').and_return(command_result)

        command.call('6': true)
      end
    end

    context 'with the :negotiation_tip option' do
      it 'adds --negotiation-tip=<ref> to the command line' do
        expect_command_capturing('fetch', '--negotiation-tip=refs/heads/main').and_return(command_result)

        command.call(negotiation_tip: 'refs/heads/main')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'fetch', '--negotiation-tip=refs/heads/main', '--negotiation-tip=refs/heads/dev'
        ).and_return(command_result)

        command.call(negotiation_tip: %w[refs/heads/main refs/heads/dev])
      end
    end

    context 'with the :negotiate_only option' do
      it 'adds --negotiate-only to the command line' do
        expect_command_capturing('fetch', '--negotiate-only').and_return(command_result)

        command.call(negotiate_only: true)
      end
    end

    context 'with the :porcelain option' do
      it 'adds --porcelain to the command line' do
        expect_command_capturing('fetch', '--porcelain').and_return(command_result)

        command.call(porcelain: true)
      end
    end

    context 'with the :auto_maintenance option' do
      it 'adds --auto-maintenance when true' do
        expect_command_capturing('fetch', '--auto-maintenance').and_return(command_result)

        command.call(auto_maintenance: true)
      end

      it 'adds --no-auto-maintenance when false' do
        expect_command_capturing('fetch', '--no-auto-maintenance').and_return(command_result)

        command.call(auto_maintenance: false)
      end
    end

    context 'with the :auto_gc option' do
      it 'adds --auto-gc when true' do
        expect_command_capturing('fetch', '--auto-gc').and_return(command_result)

        command.call(auto_gc: true)
      end

      it 'adds --no-auto-gc when false' do
        expect_command_capturing('fetch', '--no-auto-gc').and_return(command_result)

        command.call(auto_gc: false)
      end
    end

    context 'with the :write_commit_graph option' do
      it 'adds --write-commit-graph when true' do
        expect_command_capturing('fetch', '--write-commit-graph').and_return(command_result)

        command.call(write_commit_graph: true)
      end

      it 'adds --no-write-commit-graph when false' do
        expect_command_capturing('fetch', '--no-write-commit-graph').and_return(command_result)

        command.call(write_commit_graph: false)
      end
    end

    context 'with the :refmap option' do
      it 'adds --refmap=<refspec> to the command line' do
        expect_command_capturing('fetch', '--refmap=+refs/heads/*:refs/remotes/origin/*').and_return(command_result)

        command.call(refmap: '+refs/heads/*:refs/remotes/origin/*')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'fetch', '--refmap=rs1', '--refmap=rs2'
        ).and_return(command_result)

        command.call(refmap: %w[rs1 rs2])
      end
    end

    context 'with the :submodule_prefix option' do
      it 'adds --submodule-prefix=<path> to the command line' do
        expect_command_capturing('fetch', '--submodule-prefix=libs/foo').and_return(command_result)

        command.call(submodule_prefix: 'libs/foo')
      end
    end

    context 'with the :recurse_submodules_default option' do
      it 'adds --recurse-submodules-default=<value> to the command line' do
        expect_command_capturing('fetch', '--recurse-submodules-default=on-demand').and_return(command_result)

        command.call(recurse_submodules_default: 'on-demand')
      end
    end

    context 'with the :upload_pack option' do
      it 'adds --upload-pack <path> to the command line' do
        expect_command_capturing('fetch', '--upload-pack', '/usr/lib/git/git-upload-pack').and_return(command_result)

        command.call(upload_pack: '/usr/lib/git/git-upload-pack')
      end
    end

    context 'with the :stdin option' do
      it 'adds --stdin to the command line' do
        expect_command_capturing('fetch', '--stdin').and_return(command_result)

        command.call(stdin: true)
      end
    end

    context 'with the :timeout execution option' do
      it 'passes timeout to the execution context' do
        expect_command_capturing('fetch', '--', 'origin', timeout: 30).and_return(command_result)

        command.call('origin', timeout: 30)
      end
    end

    context 'with the :merge execution option' do
      it 'passes merge: true to the execution context to capture stderr output' do
        expect_command_capturing('fetch', '--', 'origin', merge: true).and_return(command_result)

        command.call('origin', merge: true)
      end
    end

    context 'with options and repository combined' do
      it 'places flags before -- and repository (in DSL definition order)' do
        expect_command_capturing('fetch', '--depth=2', '--force', '--', 'origin').and_return(command_result)

        command.call('origin', force: true, depth: '2')
      end
    end

    context 'with options, repository, and refspec combined' do
      it 'places all parts correctly' do
        expect_command_capturing('fetch', '--tags', '--', 'origin', 'refs/heads/main').and_return(command_result)

        command.call('origin', 'refs/heads/main', tags: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unknown_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options/)
        )
      end
    end
  end
end
