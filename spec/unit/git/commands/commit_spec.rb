# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/commit'

RSpec.describe Git::Commands::Commit do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git commit without any flags' do
        expected_result = command_result
        expect_command_capturing('commit').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    # Stage selection

    context 'with the :all option' do
      it 'includes --all when true' do
        expect_command_capturing('commit', '--all').and_return(command_result)

        command.call(all: true)
      end

      it 'accepts :a as an alias' do
        expect_command_capturing('commit', '--all').and_return(command_result)

        command.call(a: true)
      end
    end

    # Message source and editing

    context 'with the :edit option' do
      it 'includes --edit when true' do
        expect_command_capturing('commit', '--edit').and_return(command_result)

        command.call(edit: true)
      end

      it 'includes --no-edit when false' do
        expect_command_capturing('commit', '--no-edit').and_return(command_result)

        command.call(edit: false)
      end

      it 'accepts :e as an alias' do
        expect_command_capturing('commit', '--edit').and_return(command_result)

        command.call(e: true)
      end
    end

    context 'with the :amend option' do
      it 'includes --amend when true' do
        expect_command_capturing('commit', '--amend').and_return(command_result)

        command.call(amend: true)
      end
    end

    context 'with the :reuse_message option' do
      it 'includes --reuse-message=<commit>' do
        expect_command_capturing('commit', '--reuse-message=abc123').and_return(command_result)

        command.call(reuse_message: 'abc123')
      end

      it 'accepts :C as an alias' do
        expect_command_capturing('commit', '--reuse-message=abc123').and_return(command_result)

        command.call(C: 'abc123')
      end
    end

    context 'with the :fixup option' do
      it 'includes --fixup=<commit>' do
        expect_command_capturing('commit', '--fixup=abc123').and_return(command_result)

        command.call(fixup: 'abc123')
      end

      it 'supports the amend: prefix form' do
        expect_command_capturing('commit', '--fixup=amend:abc123').and_return(command_result)

        command.call(fixup: 'amend:abc123')
      end
    end

    context 'with the :squash option' do
      it 'includes --squash=<commit>' do
        expect_command_capturing('commit', '--squash=abc123').and_return(command_result)

        command.call(squash: 'abc123')
      end
    end

    context 'with the :message option' do
      it 'includes --message=<msg>' do
        expect_command_capturing('commit', '--message=Initial commit').and_return(command_result)

        command.call(message: 'Initial commit')
      end

      it 'accepts :m as an alias' do
        expect_command_capturing('commit', '--message=Fix bug').and_return(command_result)

        command.call(m: 'Fix bug')
      end

      it 'allows an empty message' do
        expect_command_capturing('commit', '--message=').and_return(command_result)

        command.call(message: '')
      end
    end

    context 'with the :file option' do
      it 'includes --file=<file>' do
        expect_command_capturing('commit', '--file=msg.txt').and_return(command_result)

        command.call(file: 'msg.txt')
      end

      it 'accepts :F as an alias' do
        expect_command_capturing('commit', '--file=msg.txt').and_return(command_result)

        command.call(F: 'msg.txt')
      end
    end

    context 'with the :template option' do
      it 'includes --template=<file>' do
        expect_command_capturing('commit', '--template=tmpl.txt').and_return(command_result)

        command.call(template: 'tmpl.txt')
      end

      it 'accepts :t as an alias' do
        expect_command_capturing('commit', '--template=tmpl.txt').and_return(command_result)

        command.call(t: 'tmpl.txt')
      end
    end

    # Author / date

    context 'with the :reset_author option' do
      it 'includes --reset-author when true' do
        expect_command_capturing('commit', '--reset-author').and_return(command_result)

        command.call(reset_author: true)
      end
    end

    context 'with the :author option' do
      it 'includes --author=<value>' do
        expect_command_capturing('commit', '--author=Jane <jane@example.com>').and_return(command_result)

        command.call(author: 'Jane <jane@example.com>')
      end
    end

    context 'with the :date option' do
      it 'includes --date=<value>' do
        expect_command_capturing('commit', '--date=2024-01-01T00:00:00').and_return(command_result)

        command.call(date: '2024-01-01T00:00:00')
      end
    end

    # Message cleanup and trailers

    context 'with the :cleanup option' do
      it 'includes --cleanup=<mode>' do
        expect_command_capturing('commit', '--cleanup=strip').and_return(command_result)

        command.call(cleanup: 'strip')
      end
    end

    context 'with the :trailer option' do
      it 'includes --trailer <value>' do
        expect_command_capturing('commit', '--trailer',
                                 'Signed-off-by: Dev <dev@example.com>').and_return(command_result)

        command.call(trailer: 'Signed-off-by: Dev <dev@example.com>')
      end

      it 'repeats --trailer for each value in an array' do
        expect_command_capturing(
          'commit',
          '--trailer', 'Signed-off-by: Dev <dev@example.com>',
          '--trailer', 'Reviewed-by: Rev <rev@example.com>'
        ).and_return(command_result)

        command.call(trailer: ['Signed-off-by: Dev <dev@example.com>', 'Reviewed-by: Rev <rev@example.com>'])
      end
    end

    # Hooks

    context 'with the :verify option' do
      it 'includes --no-verify when false' do
        expect_command_capturing('commit', '--no-verify').and_return(command_result)

        command.call(verify: false)
      end

      it 'includes --verify when true' do
        expect_command_capturing('commit', '--verify').and_return(command_result)

        command.call(verify: true)
      end

      it 'accepts :n as an alias' do
        expect_command_capturing('commit', '--verify').and_return(command_result)

        command.call(n: true)
      end
    end

    # Behavior

    context 'with the :allow_empty option' do
      it 'includes --allow-empty when true' do
        expect_command_capturing('commit', '--allow-empty').and_return(command_result)

        command.call(allow_empty: true)
      end
    end

    context 'with the :allow_empty_message option' do
      it 'includes --allow-empty-message when true' do
        expect_command_capturing('commit', '--allow-empty-message').and_return(command_result)

        command.call(allow_empty_message: true)
      end
    end

    context 'with the :no_post_rewrite option' do
      it 'includes --no-post-rewrite when true' do
        expect_command_capturing('commit', '--no-post-rewrite').and_return(command_result)

        command.call(no_post_rewrite: true)
      end
    end

    context 'with the :include option' do
      it 'includes --include when true' do
        expect_command_capturing('commit', '--include').and_return(command_result)

        command.call(include: true)
      end

      it 'accepts :i as an alias' do
        expect_command_capturing('commit', '--include').and_return(command_result)

        command.call(i: true)
      end
    end

    context 'with the :only option' do
      it 'includes --only when true' do
        expect_command_capturing('commit', '--only').and_return(command_result)

        command.call(only: true)
      end

      it 'accepts :o as an alias' do
        expect_command_capturing('commit', '--only').and_return(command_result)

        command.call(o: true)
      end
    end

    # Output / dry-run

    context 'with the :dry_run option' do
      it 'includes --dry-run when true' do
        expect_command_capturing('commit', '--dry-run').and_return(command_result)

        command.call(dry_run: true)
      end
    end

    context 'with the :short option' do
      it 'includes --short when true' do
        expect_command_capturing('commit', '--short').and_return(command_result)

        command.call(short: true)
      end
    end

    context 'with the :branch option' do
      it 'includes --branch when true' do
        expect_command_capturing('commit', '--branch').and_return(command_result)

        command.call(branch: true)
      end
    end

    context 'with the :porcelain option' do
      it 'includes --porcelain when true' do
        expect_command_capturing('commit', '--porcelain').and_return(command_result)

        command.call(porcelain: true)
      end
    end

    context 'with the :long option' do
      it 'includes --long when true' do
        expect_command_capturing('commit', '--long').and_return(command_result)

        command.call(long: true)
      end
    end

    context 'with the :null option' do
      it 'includes --null when true' do
        expect_command_capturing('commit', '--null').and_return(command_result)

        command.call(null: true)
      end

      it 'accepts :z as an alias' do
        expect_command_capturing('commit', '--null').and_return(command_result)

        command.call(z: true)
      end
    end

    context 'with the :verbose option' do
      it 'includes --verbose once when true' do
        expect_command_capturing('commit', '--verbose').and_return(command_result)

        command.call(verbose: true)
      end

      it 'includes --verbose twice when given 2' do
        expect_command_capturing('commit', '--verbose', '--verbose').and_return(command_result)

        command.call(verbose: 2)
      end

      it 'accepts :v as an alias' do
        expect_command_capturing('commit', '--verbose').and_return(command_result)

        command.call(v: true)
      end
    end

    context 'with the :quiet option' do
      it 'includes --quiet when true' do
        expect_command_capturing('commit', '--quiet').and_return(command_result)

        command.call(quiet: true)
      end

      it 'accepts :q as an alias' do
        expect_command_capturing('commit', '--quiet').and_return(command_result)

        command.call(q: true)
      end
    end

    context 'with the :status option' do
      it 'includes --status when true' do
        expect_command_capturing('commit', '--status').and_return(command_result)

        command.call(status: true)
      end

      it 'includes --no-status when false' do
        expect_command_capturing('commit', '--no-status').and_return(command_result)

        command.call(status: false)
      end
    end

    # Verbose diff options

    context 'with the :unified option' do
      it 'includes --unified=<n>' do
        expect_command_capturing('commit', '--unified=5').and_return(command_result)

        command.call(unified: 5)
      end

      it 'accepts :U as an alias' do
        expect_command_capturing('commit', '--unified=5').and_return(command_result)

        command.call(U: 5)
      end
    end

    context 'with the :inter_hunk_context option' do
      it 'includes --inter-hunk-context=<n>' do
        expect_command_capturing('commit', '--inter-hunk-context=3').and_return(command_result)

        command.call(inter_hunk_context: 3)
      end
    end

    # Signoff

    context 'with the :signoff option' do
      it 'includes --signoff when true' do
        expect_command_capturing('commit', '--signoff').and_return(command_result)

        command.call(signoff: true)
      end

      it 'includes --no-signoff when false' do
        expect_command_capturing('commit', '--no-signoff').and_return(command_result)

        command.call(signoff: false)
      end

      it 'accepts :s as an alias' do
        expect_command_capturing('commit', '--signoff').and_return(command_result)

        command.call(s: true)
      end
    end

    # GPG signing

    context 'with the :gpg_sign option' do
      it 'includes --gpg-sign when true' do
        expect_command_capturing('commit', '--gpg-sign').and_return(command_result)

        command.call(gpg_sign: true)
      end

      it 'includes --gpg-sign=<keyid> when a String' do
        expect_command_capturing('commit', '--gpg-sign=DEADBEEF').and_return(command_result)

        command.call(gpg_sign: 'DEADBEEF')
      end

      it 'includes --no-gpg-sign when false' do
        expect_command_capturing('commit', '--no-gpg-sign').and_return(command_result)

        command.call(gpg_sign: false)
      end

      it 'accepts :S as an alias' do
        expect_command_capturing('commit', '--gpg-sign').and_return(command_result)

        command.call(S: true)
      end
    end

    # Untracked files

    context 'with the :untracked_files option' do
      it 'includes --untracked-files when true' do
        expect_command_capturing('commit', '--untracked-files').and_return(command_result)

        command.call(untracked_files: true)
      end

      it 'includes --untracked-files=<mode> when a String' do
        expect_command_capturing('commit', '--untracked-files=no').and_return(command_result)

        command.call(untracked_files: 'no')
      end

      it 'accepts :u as an alias' do
        expect_command_capturing('commit', '--untracked-files').and_return(command_result)

        command.call(u: true)
      end
    end

    # Pathspec from file

    context 'with the :pathspec_from_file option' do
      it 'includes --pathspec-from-file=<file>' do
        expect_command_capturing('commit', '--pathspec-from-file=paths.txt').and_return(command_result)

        command.call(pathspec_from_file: 'paths.txt')
      end
    end

    context 'with the :pathspec_file_nul option' do
      it 'includes --pathspec-file-nul when true' do
        expect_command_capturing(
          'commit',
          '--pathspec-from-file=paths.txt',
          '--pathspec-file-nul'
        ).and_return(command_result)

        command.call(pathspec_from_file: 'paths.txt', pathspec_file_nul: true)
      end
    end

    # Path selection (positional pathspec operand)

    context 'with pathspec positional arguments' do
      it 'appends -- and a single path' do
        expect_command_capturing('commit', '--', 'src/foo.rb').and_return(command_result)

        command.call('src/foo.rb')
      end

      it 'appends -- and multiple paths' do
        expect_command_capturing('commit', '--', 'src/foo.rb', 'src/bar.rb').and_return(command_result)

        command.call('src/foo.rb', 'src/bar.rb')
      end

      it 'omits -- when no paths are given' do
        expect_command_capturing('commit').and_return(command_result)

        command.call
      end
    end

    # Combined options

    context 'with multiple options combined' do
      it 'includes all specified flags in DSL order' do
        expect_command_capturing(
          'commit',
          '--all',
          '--amend',
          '--message=Fix typo',
          '--no-verify'
        ).and_return(command_result)

        command.call(all: true, amend: true, message: 'Fix typo', verify: false)
      end
    end

    context 'with options and pathspec combined' do
      it 'places flags before -- and paths after' do
        expect_command_capturing(
          'commit',
          '--message=Targeted commit',
          '--',
          'src/foo.rb'
        ).and_return(command_result)

        command.call('src/foo.rb', message: 'Targeted commit')
      end
    end

    # Input validation

    context 'input validation' do
      it 'raises ArgumentError when :date is not a String' do
        expect { command.call(date: Time.now) }.to(
          raise_error(ArgumentError, /The :date option must be a String, but was a Time/)
        )
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call(invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end
    end
  end
end
