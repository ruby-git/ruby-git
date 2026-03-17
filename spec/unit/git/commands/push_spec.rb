# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/push'

RSpec.describe Git::Commands::Push do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git push with no positional arguments' do
        expected_result = command_result
        expect_command_capturing('push').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a repository argument' do
      it 'adds the end-of-options separator before the repository operand' do
        expect_command_capturing('push', '--', 'origin').and_return(command_result)

        command.call('origin')
      end
    end

    context 'with a repository and refspec' do
      it 'adds -- and then repository and refspec' do
        expect_command_capturing('push', '--', 'origin', 'main').and_return(command_result)

        command.call('origin', 'main')
      end
    end

    context 'with a repository and multiple refspecs' do
      it 'adds -- and then repository and all refspecs' do
        expect_command_capturing('push', '--', 'origin', 'main', 'develop').and_return(command_result)

        command.call('origin', 'main', 'develop')
      end
    end

    context 'with the :verbose option' do
      it 'adds --verbose to the command line' do
        expect_command_capturing('push', '--verbose').and_return(command_result)

        command.call(verbose: true)
      end

      it 'supports the :v alias' do
        expect_command_capturing('push', '--verbose').and_return(command_result)

        command.call(v: true)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('push', '--quiet').and_return(command_result)

        command.call(quiet: true)
      end

      it 'supports the :q alias' do
        expect_command_capturing('push', '--quiet').and_return(command_result)

        command.call(q: true)
      end
    end

    context 'with the :all option' do
      it 'adds --all when true' do
        expect_command_capturing('push', '--all').and_return(command_result)

        command.call(all: true)
      end

      it 'supports the :branches alias' do
        expect_command_capturing('push', '--all').and_return(command_result)

        command.call(branches: true)
      end
    end

    context 'with the :prune option' do
      it 'adds --prune to the command line' do
        expect_command_capturing('push', '--prune').and_return(command_result)

        command.call(prune: true)
      end
    end

    context 'with the :mirror option' do
      it 'adds --mirror to the command line' do
        expect_command_capturing('push', '--mirror').and_return(command_result)

        command.call(mirror: true)
      end
    end

    context 'with the :delete option' do
      it 'adds --delete to the command line' do
        expect_command_capturing('push', '--delete').and_return(command_result)

        command.call(delete: true)
      end

      it 'supports the :d alias' do
        expect_command_capturing('push', '--delete').and_return(command_result)

        command.call(d: true)
      end
    end

    context 'with the :tags option' do
      it 'adds --tags to the command line' do
        expect_command_capturing('push', '--tags').and_return(command_result)

        command.call(tags: true)
      end
    end

    context 'with the :follow_tags option' do
      it 'adds --follow-tags when true' do
        expect_command_capturing('push', '--follow-tags').and_return(command_result)

        command.call(follow_tags: true)
      end

      it 'adds --no-follow-tags when false' do
        expect_command_capturing('push', '--no-follow-tags').and_return(command_result)

        command.call(follow_tags: false)
      end
    end

    context 'with the :atomic option' do
      it 'adds --atomic when true' do
        expect_command_capturing('push', '--atomic').and_return(command_result)

        command.call(atomic: true)
      end

      it 'adds --no-atomic when false' do
        expect_command_capturing('push', '--no-atomic').and_return(command_result)

        command.call(atomic: false)
      end
    end

    context 'with the :force option' do
      it 'adds --force to the command line' do
        expect_command_capturing('push', '--force').and_return(command_result)

        command.call(force: true)
      end

      it 'supports the :f alias' do
        expect_command_capturing('push', '--force').and_return(command_result)

        command.call(f: true)
      end
    end

    context 'with the :force_with_lease option' do
      it 'adds --force-with-lease when true' do
        expect_command_capturing('push', '--force-with-lease').and_return(command_result)

        command.call(force_with_lease: true)
      end

      it 'adds --no-force-with-lease when false' do
        expect_command_capturing('push', '--no-force-with-lease').and_return(command_result)

        command.call(force_with_lease: false)
      end

      it 'adds --force-with-lease=<value> when given a string' do
        expect_command_capturing('push', '--force-with-lease=main:abc123').and_return(command_result)

        command.call(force_with_lease: 'main:abc123')
      end
    end

    context 'with the :force_if_includes option' do
      it 'adds --force-if-includes when true' do
        expect_command_capturing('push', '--force-if-includes').and_return(command_result)

        command.call(force_if_includes: true)
      end

      it 'adds --no-force-if-includes when false' do
        expect_command_capturing('push', '--no-force-if-includes').and_return(command_result)

        command.call(force_if_includes: false)
      end
    end

    context 'with the :set_upstream option' do
      it 'adds --set-upstream to the command line' do
        expect_command_capturing('push', '--set-upstream').and_return(command_result)

        command.call(set_upstream: true)
      end

      it 'supports the :u alias' do
        expect_command_capturing('push', '--set-upstream').and_return(command_result)

        command.call(u: true)
      end
    end

    context 'with the :receive_pack option' do
      it 'adds --receive-pack=<value> to the command line' do
        expect_command_capturing('push', '--receive-pack=git-receive-pack').and_return(command_result)

        command.call(receive_pack: 'git-receive-pack')
      end

      it 'supports the :exec alias' do
        expect_command_capturing('push', '--receive-pack=git-receive-pack').and_return(command_result)

        command.call(exec: 'git-receive-pack')
      end
    end

    context 'with the :repo option' do
      it 'adds --repo=<value> to the command line' do
        expect_command_capturing('push', '--repo=origin').and_return(command_result)

        command.call(repo: 'origin')
      end

      it 'includes both --repo and the positional repository when both are given' do
        expect_command_capturing('push', '--repo=upstream', '--', 'origin', 'main').and_return(command_result)

        command.call('origin', 'main', repo: 'upstream')
      end
    end

    context 'with the :recurse_submodules option' do
      it 'raises ArgumentError when true is passed' do
        expect { command.call(recurse_submodules: true) }
          .to raise_error(ArgumentError,
                          /The :recurse_submodules option must be a String or FalseClass, but was a TrueClass/)
      end

      it 'adds --no-recurse-submodules when false' do
        expect_command_capturing('push', '--no-recurse-submodules').and_return(command_result)

        command.call(recurse_submodules: false)
      end

      it 'adds --recurse-submodules=<value> when given a string' do
        expect_command_capturing('push', '--recurse-submodules=check').and_return(command_result)

        command.call(recurse_submodules: 'check')
      end
    end

    context 'with the :thin option' do
      it 'adds --thin when true' do
        expect_command_capturing('push', '--thin').and_return(command_result)

        command.call(thin: true)
      end

      it 'adds --no-thin when false' do
        expect_command_capturing('push', '--no-thin').and_return(command_result)

        command.call(thin: false)
      end
    end

    context 'with the :dry_run option' do
      it 'adds --dry-run to the command line' do
        expect_command_capturing('push', '--dry-run').and_return(command_result)

        command.call(dry_run: true)
      end

      it 'supports the :n alias' do
        expect_command_capturing('push', '--dry-run').and_return(command_result)

        command.call(n: true)
      end
    end

    context 'with the :porcelain option' do
      it 'adds --porcelain to the command line' do
        expect_command_capturing('push', '--porcelain').and_return(command_result)

        command.call(porcelain: true)
      end
    end

    context 'with the :progress option' do
      it 'adds --progress to the command line' do
        expect_command_capturing('push', '--progress').and_return(command_result)

        command.call(progress: true)
      end
    end

    context 'with the :verify option' do
      it 'adds --verify when true' do
        expect_command_capturing('push', '--verify').and_return(command_result)

        command.call(verify: true)
      end

      it 'adds --no-verify when false' do
        expect_command_capturing('push', '--no-verify').and_return(command_result)

        command.call(verify: false)
      end
    end

    context 'with the :signed option' do
      it 'adds --signed when true' do
        expect_command_capturing('push', '--signed').and_return(command_result)

        command.call(signed: true)
      end

      it 'adds --no-signed when false' do
        expect_command_capturing('push', '--no-signed').and_return(command_result)

        command.call(signed: false)
      end

      it 'adds --signed=<value> when given a string' do
        expect_command_capturing('push', '--signed=if-asked').and_return(command_result)

        command.call(signed: 'if-asked')
      end
    end

    context 'with the :push_option option' do
      it 'adds --push-option=<value> with a single value' do
        expect_command_capturing('push', '--push-option=ci.skip').and_return(command_result)

        command.call(push_option: 'ci.skip')
      end

      it 'repeats --push-option for multiple values' do
        expect_command_capturing(
          'push', '--push-option=foo', '--push-option=bar'
        ).and_return(command_result)

        command.call(push_option: %w[foo bar])
      end

      it 'supports the :o alias' do
        expect_command_capturing('push', '--push-option=ci.skip').and_return(command_result)

        command.call(o: 'ci.skip')
      end
    end

    context 'with the :ipv4 option' do
      it 'adds --ipv4 to the command line' do
        expect_command_capturing('push', '--ipv4').and_return(command_result)

        command.call(ipv4: true)
      end

      it 'supports the :"4" alias' do
        expect_command_capturing('push', '--ipv4').and_return(command_result)

        command.call('4': true)
      end
    end

    context 'with the :ipv6 option' do
      it 'adds --ipv6 to the command line' do
        expect_command_capturing('push', '--ipv6').and_return(command_result)

        command.call(ipv6: true)
      end

      it 'supports the :"6" alias' do
        expect_command_capturing('push', '--ipv6').and_return(command_result)

        command.call('6': true)
      end
    end

    context 'with combined options and operands' do
      it 'emits options before the end-of-options separator and then operands' do
        # Options render in DSL definition order: --tags is defined before --force
        expect_command_capturing(
          'push', '--tags', '--force', '--', 'origin', 'main'
        ).and_return(command_result)

        command.call('origin', 'main', force: true, tags: true)
      end
    end

    context 'with the :timeout execution option' do
      it 'passes timeout through to the execution context without emitting it as a CLI flag' do
        expect_command_capturing('push', '--', 'origin', timeout: 30).and_return(command_result)

        command.call('origin', timeout: 30)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(nonexistent_option: true) }
          .to raise_error(ArgumentError, /Unsupported options: :nonexistent_option/)
      end
    end
  end
end
