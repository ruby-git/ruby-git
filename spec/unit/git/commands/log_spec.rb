# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/log'

RSpec.describe Git::Commands::Log do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git log with no output-format flags by default' do
        expected_result = command_result
        expect_command_capturing('log').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with parser-contract options (no_color:, pretty:)' do
      it 'includes --no-color when no_color: true' do
        expect_command_capturing('log', '--no-color').and_return(command_result)

        command.call(no_color: true)
      end

      it 'includes --pretty=raw when pretty: "raw"' do
        expect_command_capturing('log', '--pretty=raw').and_return(command_result)

        command.call(pretty: 'raw')
      end

      it 'combines --no-color and --pretty=raw as the facade would' do
        expect_command_capturing('log', '--no-color', '--pretty=raw').and_return(command_result)

        command.call(no_color: true, pretty: 'raw')
      end
    end

    context 'with the :all option' do
      it 'includes the --all flag' do
        expect_command_capturing('log', '--all').and_return(command_result)

        command.call(all: true)
      end
    end

    context 'with the :branches option' do
      it 'includes the bare --branches flag when true' do
        expect_command_capturing('log', '--branches').and_return(command_result)

        command.call(branches: true)
      end

      it 'includes --branches=<pattern> when a pattern is given' do
        expect_command_capturing('log', '--branches=feature*').and_return(command_result)

        command.call(branches: 'feature*')
      end
    end

    context 'with the :tags option' do
      it 'includes the bare --tags flag when true' do
        expect_command_capturing('log', '--tags').and_return(command_result)

        command.call(tags: true)
      end

      it 'includes --tags=<pattern> when a pattern is given' do
        expect_command_capturing('log', '--tags=v*').and_return(command_result)

        command.call(tags: 'v*')
      end
    end

    context 'with the :remotes option' do
      it 'includes the bare --remotes flag when true' do
        expect_command_capturing('log', '--remotes').and_return(command_result)

        command.call(remotes: true)
      end

      it 'includes --remotes=<pattern> when a pattern is given' do
        expect_command_capturing('log', '--remotes=origin/*').and_return(command_result)

        command.call(remotes: 'origin/*')
      end
    end

    context 'with the :cherry option' do
      it 'includes the --cherry flag' do
        expect_command_capturing('log', '--cherry').and_return(command_result)

        command.call(cherry: true)
      end
    end

    context 'with the :cherry_mark option' do
      it 'includes the --cherry-mark flag' do
        expect_command_capturing('log', '--cherry-mark').and_return(command_result)

        command.call(cherry_mark: true)
      end
    end

    context 'with the :cherry_pick option' do
      it 'includes the --cherry-pick flag' do
        expect_command_capturing('log', '--cherry-pick').and_return(command_result)

        command.call(cherry_pick: true)
      end
    end

    context 'with the :left_right option' do
      it 'includes the --left-right flag' do
        expect_command_capturing('log', '--left-right').and_return(command_result)

        command.call(left_right: true)
      end
    end

    context 'with the :merges option' do
      it 'includes the --merges flag' do
        expect_command_capturing('log', '--merges').and_return(command_result)

        command.call(merges: true)
      end

      it 'includes the --no-merges flag when false' do
        expect_command_capturing('log', '--no-merges').and_return(command_result)

        command.call(merges: false)
      end
    end

    context 'with the :first_parent option' do
      it 'includes the --first-parent flag' do
        expect_command_capturing('log', '--first-parent').and_return(command_result)

        command.call(first_parent: true)
      end
    end

    context 'with the :min_parents option' do
      it 'includes --min-parents=<n>' do
        expect_command_capturing('log', '--min-parents=2').and_return(command_result)

        command.call(min_parents: 2)
      end
    end

    context 'with the :max_parents option' do
      it 'includes --max-parents=<n>' do
        expect_command_capturing('log', '--max-parents=1').and_return(command_result)

        command.call(max_parents: 1)
      end
    end

    context 'with the :since option' do
      it 'includes --since=<value>' do
        expect_command_capturing('log', '--since=1 week ago').and_return(command_result)

        command.call(since: '1 week ago')
      end
    end

    context 'with the :after option' do
      it 'includes --after=<value>' do
        expect_command_capturing('log', '--after=2024-01-01').and_return(command_result)

        command.call(after: '2024-01-01')
      end
    end

    context 'with the :until option' do
      it 'includes --until=<value>' do
        expect_command_capturing('log', '--until=2024-01-01').and_return(command_result)

        command.call(until: '2024-01-01')
      end
    end

    context 'with the :before option' do
      it 'includes --before=<value>' do
        expect_command_capturing('log', '--before=2024-06-01').and_return(command_result)

        command.call(before: '2024-06-01')
      end
    end

    context 'with the :grep option' do
      it 'includes --grep=<value>' do
        expect_command_capturing('log', '--grep=fix bug').and_return(command_result)

        command.call(grep: 'fix bug')
      end
    end

    context 'with the :author option' do
      it 'includes --author=<value>' do
        expect_command_capturing(
          'log', '--author=Jane Doe'
        ).and_return(command_result)

        command.call(author: 'Jane Doe')
      end
    end

    context 'with the :committer option' do
      it 'includes --committer=<value>' do
        expect_command_capturing(
          'log', '--committer=Jane Doe'
        ).and_return(command_result)

        command.call(committer: 'Jane Doe')
      end
    end

    context 'with the :max_count option' do
      it 'includes --max-count=<n>' do
        expect_command_capturing('log', '--max-count=10').and_return(command_result)

        command.call(max_count: 10)
      end
    end

    context 'with the :skip option' do
      it 'includes --skip=<n>' do
        expect_command_capturing('log', '--skip=5').and_return(command_result)

        command.call(skip: 5)
      end
    end

    context 'with the :full_history option' do
      it 'includes the --full-history flag' do
        expect_command_capturing('log', '--full-history').and_return(command_result)

        command.call(full_history: true)
      end
    end

    context 'with the :date_order option' do
      it 'includes the --date-order flag' do
        expect_command_capturing('log', '--date-order').and_return(command_result)

        command.call(date_order: true)
      end
    end

    context 'with the :author_date_order option' do
      it 'includes the --author-date-order flag' do
        expect_command_capturing('log', '--author-date-order').and_return(command_result)

        command.call(author_date_order: true)
      end
    end

    context 'with the :topo_order option' do
      it 'includes the --topo-order flag' do
        expect_command_capturing('log', '--topo-order').and_return(command_result)

        command.call(topo_order: true)
      end
    end

    context 'with the :reverse option' do
      it 'includes the --reverse flag' do
        expect_command_capturing('log', '--reverse').and_return(command_result)

        command.call(reverse: true)
      end
    end

    context 'with a :revision_range operand' do
      it 'appends a single revision range directly' do
        expect_command_capturing('log', 'v1.0..v2.0').and_return(command_result)

        command.call('v1.0..v2.0')
      end

      it 'appends multiple revision specifiers as separate arguments' do
        expect_command_capturing('log', 'v1.0', 'v2.0',
                                 '^v0.9').and_return(command_result)

        command.call('v1.0', 'v2.0', '^v0.9')
      end
    end

    context 'with a :path option' do
      it 'appends -- and the path(s)' do
        expect_command_capturing(
          'log', '--', 'lib/'
        ).and_return(command_result)

        command.call(path: ['lib/'])
      end

      it 'supports multiple paths' do
        expect_command_capturing(
          'log', '--', 'lib/', 'spec/'
        ).and_return(command_result)

        command.call(path: %w[lib/ spec/])
      end
    end

    context 'with combined options' do
      it 'includes all specified options in DSL order' do
        expect_command_capturing(
          'log',
          '--all', '--since=2 weeks ago', '--max-count=20',
          'v1.0', '--', 'lib/'
        ).and_return(command_result)

        command.call('v1.0', all: true, max_count: 20, since: '2 weeks ago', path: ['lib/'])
      end
    end

    context 'with regexp flag aliases' do
      it 'accepts :regexp_ignore_case for --regexp-ignore-case' do
        expect_command_capturing('log', '--regexp-ignore-case').and_return(command_result)

        command.call(regexp_ignore_case: true)
      end

      it 'accepts :i as an alias for :regexp_ignore_case' do
        expect_command_capturing('log', '--regexp-ignore-case').and_return(command_result)

        command.call(i: true)
      end

      it 'accepts :extended_regexp for --extended-regexp' do
        expect_command_capturing('log', '--extended-regexp').and_return(command_result)

        command.call(extended_regexp: true)
      end

      it 'accepts :E as an alias for :extended_regexp' do
        expect_command_capturing('log', '--extended-regexp').and_return(command_result)

        command.call(E: true)
      end

      it 'accepts :fixed_strings for --fixed-strings' do
        expect_command_capturing('log', '--fixed-strings').and_return(command_result)

        command.call(fixed_strings: true)
      end

      it 'accepts :F as an alias for :fixed_strings' do
        expect_command_capturing('log', '--fixed-strings').and_return(command_result)

        command.call(F: true)
      end

      it 'accepts :perl_regexp for --perl-regexp' do
        expect_command_capturing('log', '--perl-regexp').and_return(command_result)

        command.call(perl_regexp: true)
      end

      it 'accepts :P as an alias for :perl_regexp' do
        expect_command_capturing('log', '--perl-regexp').and_return(command_result)

        command.call(P: true)
      end
    end

    context 'with execution options' do
      it 'forwards the timeout option' do
        expect_command_capturing('log', timeout: 30).and_return(command_result)

        command.call(timeout: 30)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(bogus: true) }.to raise_error(ArgumentError)
      end
    end
  end
end
