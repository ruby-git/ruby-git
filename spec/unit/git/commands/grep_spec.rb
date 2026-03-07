# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/grep'

RSpec.describe Git::Commands::Grep do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a tree operand' do
      it 'runs git grep with -e <pattern> <tree> and passes the result through' do
        expected_result = command_result('HEAD:file.txt:5:to search')
        expect_command_capturing('grep', '--no-color', '-e', 'search', 'HEAD')
          .and_return(expected_result)

        result = command.call('HEAD', pattern: 'search')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple tree operands' do
      it 'passes all trees to the command' do
        expect_command_capturing('grep', '--no-color', '-e', 'search', 'main', 'feature')
          .and_return(command_result('main:file.txt:1:search'))

        command.call('main', 'feature', pattern: 'search')
      end
    end

    context 'without a tree operand' do
      it 'runs git grep with -e <pattern> only' do
        expect_command_capturing('grep', '--no-color', '-e', 'search')
          .and_return(command_result('HEAD:file.txt:5:to search'))

        command.call(pattern: 'search')
      end
    end

    context 'with :ignore_case option' do
      it 'includes --ignore-case flag' do
        expect_command_capturing('grep', '--no-color', '--ignore-case', '-e', 'SEARCH', 'HEAD')
          .and_return(command_result('HEAD:file.txt:5:to search'))

        command.call('HEAD', pattern: 'SEARCH', ignore_case: true)
      end
    end

    context 'with :i alias' do
      it 'accepts :i as alias for :ignore_case' do
        expect_command_capturing('grep', '--no-color', '--ignore-case', '-e', 'SEARCH', 'HEAD')
          .and_return(command_result('HEAD:file.txt:5:to search'))

        command.call('HEAD', pattern: 'SEARCH', i: true)
      end
    end

    context 'with :invert_match option' do
      it 'includes --invert-match flag' do
        expect_command_capturing('grep', '--no-color', '--invert-match', '-e', 'search', 'HEAD')
          .and_return(command_result('HEAD:file.txt:1:other line'))

        command.call('HEAD', pattern: 'search', invert_match: true)
      end
    end

    context 'with :v alias' do
      it 'accepts :v as alias for :invert_match' do
        expect_command_capturing('grep', '--no-color', '--invert-match', '-e', 'search', 'HEAD')
          .and_return(command_result('HEAD:file.txt:1:other line'))

        command.call('HEAD', pattern: 'search', v: true)
      end
    end

    context 'with :extended_regexp option' do
      it 'includes --extended-regexp flag' do
        expect_command_capturing('grep', '--no-color', '--extended-regexp', '-e', 'foo|bar', 'HEAD')
          .and_return(command_result('HEAD:file.txt:1:foo'))

        command.call('HEAD', pattern: 'foo|bar', extended_regexp: true)
      end
    end

    context 'with :E alias' do
      it 'accepts :E as alias for :extended_regexp' do
        expect_command_capturing('grep', '--no-color', '--extended-regexp', '-e', 'foo|bar', 'HEAD')
          .and_return(command_result('HEAD:file.txt:1:foo'))

        command.call('HEAD', pattern: 'foo|bar', E: true)
      end
    end

    # Encoding and binary handling

    context 'with :text option' do
      it 'includes --text flag' do
        expect_command_capturing('grep', '--no-color', '--text', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', text: true)
      end
    end

    context 'with :a alias' do
      it 'accepts :a as alias for :text' do
        expect_command_capturing('grep', '--no-color', '--text', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', a: true)
      end
    end

    context 'with :I option' do
      it 'includes -I flag' do
        expect_command_capturing('grep', '--no-color', '-I', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', I: true)
      end
    end

    context 'with :textconv option' do
      it 'includes --textconv flag' do
        expect_command_capturing('grep', '--no-color', '--textconv', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', textconv: true)
      end
    end

    context 'with :textconv false' do
      it 'includes --no-textconv flag' do
        expect_command_capturing('grep', '--no-color', '--no-textconv', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', textconv: false)
      end
    end

    # Pattern matching behaviour

    context 'with :word_regexp option' do
      it 'includes --word-regexp flag' do
        expect_command_capturing('grep', '--no-color', '--word-regexp', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', word_regexp: true)
      end
    end

    context 'with :w alias' do
      it 'accepts :w as alias for :word_regexp' do
        expect_command_capturing('grep', '--no-color', '--word-regexp', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', w: true)
      end
    end

    context 'with :full_name option' do
      it 'includes --full-name flag' do
        expect_command_capturing('grep', '--no-color', '--full-name', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', full_name: true)
      end
    end

    # Regexp flavour

    context 'with :basic_regexp option' do
      it 'includes --basic-regexp flag' do
        expect_command_capturing('grep', '--no-color', '--basic-regexp', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', basic_regexp: true)
      end
    end

    context 'with :G alias' do
      it 'accepts :G as alias for :basic_regexp' do
        expect_command_capturing('grep', '--no-color', '--basic-regexp', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', G: true)
      end
    end

    context 'with :perl_regexp option' do
      it 'includes --perl-regexp flag' do
        expect_command_capturing('grep', '--no-color', '--perl-regexp', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', perl_regexp: true)
      end
    end

    context 'with :P alias' do
      it 'accepts :P as alias for :perl_regexp' do
        expect_command_capturing('grep', '--no-color', '--perl-regexp', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', P: true)
      end
    end

    context 'with :fixed_strings option' do
      it 'includes --fixed-strings flag' do
        expect_command_capturing('grep', '--no-color', '--fixed-strings', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', fixed_strings: true)
      end
    end

    context 'with :F alias' do
      it 'accepts :F as alias for :fixed_strings' do
        expect_command_capturing('grep', '--no-color', '--fixed-strings', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', F: true)
      end
    end

    # Output format

    context 'with :line_number option' do
      it 'includes --line-number flag' do
        expect_command_capturing('grep', '--no-color', '--line-number', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', line_number: true)
      end
    end

    context 'with :n alias' do
      it 'accepts :n as alias for :line_number' do
        expect_command_capturing('grep', '--no-color', '--line-number', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', n: true)
      end
    end

    context 'with :H option' do
      it 'includes -H flag' do
        expect_command_capturing('grep', '--no-color', '-H', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', H: true)
      end
    end

    context 'with :h option' do
      it 'includes -h flag' do
        expect_command_capturing('grep', '--no-color', '-h', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', h: true)
      end
    end

    context 'with :column option' do
      it 'includes --column flag' do
        expect_command_capturing('grep', '--no-color', '--column', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', column: true)
      end
    end

    context 'with :break option' do
      it 'includes --break flag' do
        expect_command_capturing('grep', '--no-color', '--break', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', break: true)
      end
    end

    context 'with :heading option' do
      it 'includes --heading flag' do
        expect_command_capturing('grep', '--no-color', '--heading', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', heading: true)
      end
    end

    context 'with :files_with_matches option' do
      it 'includes --files-with-matches flag' do
        expect_command_capturing('grep', '--no-color', '--files-with-matches', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', files_with_matches: true)
      end
    end

    context 'with :name_only alias' do
      it 'accepts :name_only as alias for :files_with_matches' do
        expect_command_capturing('grep', '--no-color', '--files-with-matches', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', name_only: true)
      end
    end

    context 'with :l alias' do
      it 'accepts :l as alias for :files_with_matches' do
        expect_command_capturing('grep', '--no-color', '--files-with-matches', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', l: true)
      end
    end

    context 'with :files_without_match option' do
      it 'includes --files-without-match flag' do
        expect_command_capturing('grep', '--no-color', '--files-without-match', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', files_without_match: true)
      end
    end

    context 'with :L alias' do
      it 'accepts :L as alias for :files_without_match' do
        expect_command_capturing('grep', '--no-color', '--files-without-match', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', L: true)
      end
    end

    context 'with :only_matching option' do
      it 'includes --only-matching flag' do
        expect_command_capturing('grep', '--no-color', '--only-matching', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', only_matching: true)
      end
    end

    context 'with :o alias' do
      it 'accepts :o as alias for :only_matching' do
        expect_command_capturing('grep', '--no-color', '--only-matching', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', o: true)
      end
    end

    context 'with :count option' do
      it 'includes --count flag' do
        expect_command_capturing('grep', '--no-color', '--count', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', count: true)
      end
    end

    context 'with :c alias' do
      it 'accepts :c as alias for :count' do
        expect_command_capturing('grep', '--no-color', '--count', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', c: true)
      end
    end

    context 'with :all_match option' do
      it 'includes --all-match flag' do
        expect_command_capturing('grep', '--no-color', '--all-match', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', all_match: true)
      end
    end

    context 'with :quiet option' do
      it 'includes --quiet flag' do
        expect_command_capturing('grep', '--no-color', '--quiet', '-e', 'search', 'HEAD')
          .and_return(command_result('', exitstatus: 1))

        command.call('HEAD', pattern: 'search', quiet: true)
      end
    end

    context 'with :q alias' do
      it 'accepts :q as alias for :quiet' do
        expect_command_capturing('grep', '--no-color', '--quiet', '-e', 'search', 'HEAD')
          .and_return(command_result('', exitstatus: 1))

        command.call('HEAD', pattern: 'search', q: true)
      end
    end

    # Depth and recursion

    context 'with :max_depth option' do
      it 'includes --max-depth with the given value' do
        expect_command_capturing('grep', '--no-color', '--max-depth', '3', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', max_depth: '3')
      end
    end

    context 'with :recursive option' do
      it 'includes --recursive flag' do
        expect_command_capturing('grep', '--no-color', '--recursive', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', recursive: true)
      end
    end

    context 'with :recursive false' do
      it 'includes --no-recursive flag' do
        expect_command_capturing('grep', '--no-color', '--no-recursive', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', recursive: false)
      end
    end

    context 'with :r alias' do
      it 'accepts :r as alias for :recursive' do
        expect_command_capturing('grep', '--no-color', '--recursive', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', r: true)
      end
    end

    # Display

    context 'with :show_function option' do
      it 'includes --show-function flag' do
        expect_command_capturing('grep', '--no-color', '--show-function', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', show_function: true)
      end
    end

    context 'with :p alias' do
      it 'accepts :p as alias for :show_function' do
        expect_command_capturing('grep', '--no-color', '--show-function', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', p: true)
      end
    end

    # Context lines

    context 'with :after_context option' do
      it 'includes --after-context=<n> with the given value' do
        expect_command_capturing('grep', '--no-color', '--after-context=3', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', after_context: '3')
      end
    end

    context 'with :A alias' do
      it 'accepts :A as alias for :after_context' do
        expect_command_capturing('grep', '--no-color', '--after-context=3', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', A: '3')
      end
    end

    context 'with :before_context option' do
      it 'includes --before-context=<n> with the given value' do
        expect_command_capturing('grep', '--no-color', '--before-context=3', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', before_context: '3')
      end
    end

    context 'with :B alias' do
      it 'accepts :B as alias for :before_context' do
        expect_command_capturing('grep', '--no-color', '--before-context=3', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', B: '3')
      end
    end

    context 'with :context option' do
      it 'includes --context=<n> with the given value' do
        expect_command_capturing('grep', '--no-color', '--context=3', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', context: '3')
      end
    end

    context 'with :C alias' do
      it 'accepts :C as alias for :context' do
        expect_command_capturing('grep', '--no-color', '--context=3', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', C: '3')
      end
    end

    context 'with :function_context option' do
      it 'includes --function-context flag' do
        expect_command_capturing('grep', '--no-color', '--function-context', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', function_context: true)
      end
    end

    context 'with :W alias' do
      it 'accepts :W as alias for :function_context' do
        expect_command_capturing('grep', '--no-color', '--function-context', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', W: true)
      end
    end

    # Limits and performance

    context 'with :max_count option' do
      it 'includes --max-count with the given value' do
        expect_command_capturing('grep', '--no-color', '--max-count', '10', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', max_count: '10')
      end
    end

    context 'with :m alias' do
      it 'accepts :m as alias for :max_count' do
        expect_command_capturing('grep', '--no-color', '--max-count', '10', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', m: '10')
      end
    end

    context 'with :threads option' do
      it 'includes --threads with the given value' do
        expect_command_capturing('grep', '--no-color', '--threads', '4', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', threads: '4')
      end
    end

    # Source selection

    context 'with :recurse_submodules option' do
      it 'includes --recurse-submodules flag' do
        expect_command_capturing('grep', '--no-color', '--recurse-submodules', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', recurse_submodules: true)
      end
    end

    context 'with :exclude_standard option' do
      it 'includes --exclude-standard flag' do
        expect_command_capturing('grep', '--no-color', '--exclude-standard', '--untracked', '-e', 'search')
          .and_return(command_result(''))

        command.call(pattern: 'search', exclude_standard: true, untracked: true)
      end
    end

    context 'with :exclude_standard false' do
      it 'includes --no-exclude-standard flag' do
        expect_command_capturing('grep', '--no-color', '--no-exclude-standard', '--no-index', '-e', 'search')
          .and_return(command_result(''))

        command.call(pattern: 'search', exclude_standard: false, no_index: true)
      end
    end

    context 'with :cached option' do
      it 'includes --cached flag' do
        expect_command_capturing('grep', '--no-color', '--cached', '-e', 'search')
          .and_return(command_result(''))

        command.call(pattern: 'search', cached: true)
      end
    end

    context 'with :untracked option' do
      it 'includes --untracked flag' do
        expect_command_capturing('grep', '--no-color', '--untracked', '-e', 'search')
          .and_return(command_result(''))

        command.call(pattern: 'search', untracked: true)
      end
    end

    context 'with :no_index option' do
      it 'includes --no-index flag' do
        expect_command_capturing('grep', '--no-color', '--no-index', '-e', 'search')
          .and_return(command_result(''))

        command.call(pattern: 'search', no_index: true)
      end
    end

    # Pattern input (file-based)

    context 'with :f option' do
      it 'includes -f with the given file path' do
        expect_command_capturing('grep', '--no-color', '-f', 'patterns.txt', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', f: 'patterns.txt')
      end

      it 'repeats -f for each file when given an array' do
        expect_command_capturing('grep', '--no-color', '-f', 'a.txt', '-f', 'b.txt', '-e', 'search',
                                 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', f: ['a.txt', 'b.txt'])
      end
    end

    context 'with multiple boolean flags combined' do
      it 'includes all flags in definition order' do
        expect_command_capturing(
          'grep',
          '--no-color',
          '--ignore-case',
          '--invert-match',
          '--extended-regexp',
          '-e', 'pattern',
          'HEAD'
        ).and_return(command_result(''))

        command.call('HEAD', pattern: 'pattern', ignore_case: true, invert_match: true, extended_regexp: true)
      end
    end

    context 'with :pathspec option' do
      it 'appends -- and the pathspec after the tree operand' do
        expect_command_capturing('grep', '--no-color', '-e', 'search', 'HEAD', '--', 'lib/**')
          .and_return(command_result('HEAD:lib/file.rb:3:search'))

        command.call('HEAD', pattern: 'search', pathspec: 'lib/**')
      end

      it 'appends -- and multiple pathspecs when given an array' do
        expect_command_capturing('grep', '--no-color', '-e', 'search', 'HEAD', '--', 'lib/**',
                                 'spec/**')
          .and_return(command_result('HEAD:lib/file.rb:3:search'))

        command.call('HEAD', pattern: 'search', pathspec: ['lib/**', 'spec/**'])
      end

      it 'omits -- separator when pathspec is nil' do
        expect_command_capturing('grep', '--no-color', '-e', 'search', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pattern: 'search', pathspec: nil)
      end
    end

    context 'exit code handling' do
      it 'returns the result without raising when exit status is 1 (no matches)' do
        no_match_result = command_result('', exitstatus: 1)
        expect_command_capturing('grep', '--no-color', '-e', 'search', 'HEAD')
          .and_return(no_match_result)

        result = command.call('HEAD', pattern: 'search')

        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises Git::FailedError when exit status is 2' do
        expect_command_capturing('grep', '--no-color', '-e', 'search', 'HEAD')
          .and_return(command_result('', stderr: 'fatal: bad object', exitstatus: 2))

        expect { command.call('HEAD', pattern: 'search') }.to raise_error(Git::FailedError)
      end

      it 'raises Git::FailedError when exit status is 128' do
        expect_command_capturing('grep', '--no-color', '-e', 'search', 'HEAD')
          .and_return(command_result('', stderr: 'fatal: not a git repository', exitstatus: 128))

        expect { command.call('HEAD', pattern: 'search') }.to raise_error(Git::FailedError)
      end
    end

    context 'with an Array pattern (raw args passthrough)' do
      it 'passes the array elements directly as CLI arguments' do
        expect_command_capturing('grep', '--no-color', '-e', 'foo', '--and', '-e', 'bar', 'HEAD')
          .and_return(command_result('HEAD:file.txt:1:foo bar'))

        command.call('HEAD', pattern: ['-e', 'foo', '--and', '-e', 'bar'])
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when pattern is missing' do
        expect { command.call('HEAD') }.to raise_error(ArgumentError, /pattern/)
      end

      it 'raises ArgumentError when pattern is nil' do
        expect { command.call('HEAD', pattern: nil) }.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when pattern is an unsupported type' do
        expect { command.call('HEAD', pattern: 123) }
          .to raise_error(ArgumentError, /must be a String or Array/)
      end

      it 'raises ArgumentError when unknown options are provided' do
        expect { command.call('HEAD', pattern: 'search', unknown_opt: true) }
          .to raise_error(ArgumentError)
      end
    end

    context 'conflicting options' do
      it 'raises ArgumentError when conflicting regexp flavour options are combined' do
        expect { command.call('HEAD', pattern: 'x', extended_regexp: true, basic_regexp: true) }
          .to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when :no_index and :cached are both provided' do
        expect { command.call('HEAD', pattern: 'x', no_index: true, cached: true) }
          .to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when :no_index and :untracked are both provided' do
        expect { command.call('HEAD', pattern: 'x', no_index: true, untracked: true) }
          .to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when :cached and a tree operand are both provided' do
        expect { command.call('HEAD', pattern: 'x', cached: true) }
          .to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when :untracked and a tree operand are both provided' do
        expect { command.call('HEAD', pattern: 'x', untracked: true) }
          .to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when :no_index and a tree operand are both provided' do
        expect { command.call('HEAD', pattern: 'x', no_index: true) }
          .to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when :exclude_standard is given without :untracked or :no_index' do
        expect { command.call(pattern: 'x', exclude_standard: true) }
          .to raise_error(ArgumentError)
      end

      it 'allows :exclude_standard with :untracked' do
        expect_command_capturing('grep', '--no-color', '--exclude-standard', '--untracked', '-e', 'x')
          .and_return(command_result(''))

        command.call(pattern: 'x', exclude_standard: true, untracked: true)
      end

      it 'allows :exclude_standard with :no_index' do
        expect_command_capturing('grep', '--no-color', '--no-exclude-standard', '--no-index', '-e', 'x')
          .and_return(command_result(''))

        command.call(pattern: 'x', exclude_standard: false, no_index: true)
      end
    end
  end
end
