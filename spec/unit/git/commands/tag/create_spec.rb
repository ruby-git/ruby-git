# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/create'

RSpec.describe Git::Commands::Tag::Create do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with tag name only (lightweight tag)' do
      it 'creates a lightweight tag' do
        expect_command('tag', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with commit target' do
      it 'adds the commit after the tag name' do
        expect_command('tag', 'v1.0.0', 'abc123').and_return(command_result)

        result = command.call('v1.0.0', 'abc123')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts a branch as target' do
        expect_command('tag', 'v1.0.0', 'main').and_return(command_result)

        result = command.call('v1.0.0', 'main')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts HEAD as target' do
        expect_command('tag', 'v1.0.0', 'HEAD').and_return(command_result)

        result = command.call('v1.0.0', 'HEAD')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :annotate option' do
      it 'includes --annotate flag' do
        expect_command('tag', '--annotate', '--message=Release', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', annotate: true, message: 'Release')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :a alias' do
        expect_command('tag', '--annotate', '--message=Release', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', a: true, message: 'Release')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'does not add flag when false' do
        expect_command('tag', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', annotate: false)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :sign option' do
      it 'includes --sign flag' do
        expect_command('tag', '--sign', '--message=Release', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', sign: true, message: 'Release')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :s alias' do
        expect_command('tag', '--sign', '--message=Release', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', s: true, message: 'Release')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes --no-sign flag when false' do
        expect_command('tag', '--no-sign', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', sign: false)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :local_user option' do
      it 'includes --local-user flag with key' do
        expect_command('tag', '--local-user=ABCD1234', '--message=Release', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', local_user: 'ABCD1234', message: 'Release')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :u alias' do
        expect_command('tag', '--local-user=ABCD1234', '--message=Release', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', u: 'ABCD1234', message: 'Release')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :force option' do
      it 'includes --force flag' do
        expect_command('tag', '--force', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', force: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :f alias' do
        expect_command('tag', '--force', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', f: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'does not add flag when false' do
        expect_command('tag', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', force: false)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :message option' do
      it 'includes --message flag with value' do
        expect_command('tag', '--message=Release version 1.0.0', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', message: 'Release version 1.0.0')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :m alias' do
        expect_command('tag', '--message=Release', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', m: 'Release')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'handles message with special characters' do
        expect_command('tag', '--message=Release "quoted"', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', message: 'Release "quoted"')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :file option' do
      it 'includes --file flag with path' do
        expect_command('tag', '--file=/path/to/message.txt', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', file: '/path/to/message.txt')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :F alias' do
        expect_command('tag', '--file=/path/to/message.txt', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', F: '/path/to/message.txt')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'supports reading from stdin with -' do
        expect_command('tag', '--file=-', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', file: '-')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :create_reflog option' do
      it 'includes --create-reflog flag' do
        expect_command('tag', '--create-reflog', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', create_reflog: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'does not add flag when false' do
        expect_command('tag', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', create_reflog: false)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with multiple options combined' do
      it 'creates an annotated tag with message and force' do
        expect_command('tag', '--annotate', '--force', '--message=Release', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', annotate: true, force: true, message: 'Release')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'creates a signed tag at specific commit' do
        expect_command('tag', '--sign', '--message=Signed release', 'v1.0.0', 'abc123')
          .and_return(command_result)

        result = command.call('v1.0.0', 'abc123', sign: true, message: 'Signed release')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'creates tag with custom signing key at specific commit' do
        expect_command('tag', '--local-user=KEY123', '--message=Release', 'v1.0.0', 'main')
          .and_return(command_result)

        result = command.call('v1.0.0', 'main', local_user: 'KEY123', message: 'Release')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'combines create_reflog with annotated tag' do
        expect_command('tag', '--annotate', '--create-reflog', '--message=Release', 'v1.0.0')
          .and_return(command_result)

        result = command.call('v1.0.0', annotate: true, create_reflog: true, message: 'Release')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'allows annotate with file instead of message' do
        expect_command('tag', '--annotate', '--file=/path/to/msg.txt', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', annotate: true, file: '/path/to/msg.txt')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :trailer option' do
      it 'includes trailers with key-value pairs' do
        expect_command('tag', '--message=Release', '--trailer', 'Signed-off-by: John Doe', 'v1.0.0')
          .and_return(command_result)

        result = command.call('v1.0.0', message: 'Release', trailer: { 'Signed-off-by' => 'John Doe' })

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes multiple trailers' do
        expect_command(
          'tag', '--message=Release',
          '--trailer', 'Signed-off-by: John Doe',
          '--trailer', 'Reviewed-by: Jane Smith',
          'v1.0.0'
        ).and_return(command_result)

        result = command.call('v1.0.0', message: 'Release', trailer: {
                                'Signed-off-by' => 'John Doe',
                                'Reviewed-by' => 'Jane Smith'
                              })

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes trailers with array of pairs' do
        expect_command(
          'tag', '--message=Release',
          '--trailer', 'Co-authored-by: Alice',
          '--trailer', 'Co-authored-by: Bob',
          'v1.0.0'
        ).and_return(command_result)

        result = command.call('v1.0.0', message: 'Release', trailer: [
                                %w[Co-authored-by Alice],
                                %w[Co-authored-by Bob]
                              ])

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :cleanup option' do
      it 'includes --cleanup=strip' do
        expect_command('tag', '--message=Release', '--cleanup=strip', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', message: 'Release', cleanup: 'strip')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes --cleanup=verbatim' do
        expect_command('tag', '--message=Release', '--cleanup=verbatim', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', message: 'Release', cleanup: 'verbatim')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes --cleanup=whitespace' do
        expect_command('tag', '--message=Release', '--cleanup=whitespace', 'v1.0.0').and_return(command_result)

        result = command.call('v1.0.0', message: 'Release', cleanup: 'whitespace')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'input validation' do
      it 'raises an error when both annotate and sign are provided' do
        expect { command.call('v1.0.0', annotate: true, sign: true, message: 'Release') }.to(
          raise_error(ArgumentError, /cannot specify :annotate and :sign/)
        )
      end

      it 'raises an error when both annotate and local_user are provided' do
        expect { command.call('v1.0.0', annotate: true, local_user: 'KEY', message: 'Release') }.to(
          raise_error(ArgumentError, /cannot specify :annotate and :local_user/)
        )
      end

      it 'raises an error when both sign and local_user are provided' do
        expect { command.call('v1.0.0', sign: true, local_user: 'KEY', message: 'Release') }.to(
          raise_error(ArgumentError, /cannot specify :sign and :local_user/)
        )
      end

      it 'raises an error when annotate, sign, and local_user are all provided' do
        expect { command.call('v1.0.0', annotate: true, sign: true, local_user: 'KEY', message: 'Release') }.to(
          raise_error(ArgumentError, /cannot specify/)
        )
      end

      it 'raises an error when both message and file are provided' do
        expect { command.call('v1.0.0', message: 'Release', file: '/path/to/file') }.to(
          raise_error(ArgumentError, /cannot specify :message and :file/)
        )
      end
    end
  end
end
