# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/create'

RSpec.describe Git::Commands::Tag::Create do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with tag name only (lightweight tag)' do
      it 'calls git tag with the tag name' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0')
        command.call('v1.0.0')
      end
    end

    context 'with commit target' do
      it 'adds the commit after the tag name' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0', 'abc123')
        command.call('v1.0.0', 'abc123')
      end

      it 'accepts a branch as target' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0', 'main')
        command.call('v1.0.0', 'main')
      end

      it 'accepts HEAD as target' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0', 'HEAD')
        command.call('v1.0.0', 'HEAD')
      end
    end

    context 'with :annotate option' do
      it 'adds -a flag' do
        expect(execution_context).to receive(:command).with('tag', '-a', '--message=Release', 'v1.0.0')
        command.call('v1.0.0', annotate: true, message: 'Release')
      end

      it 'accepts :a alias' do
        expect(execution_context).to receive(:command).with('tag', '-a', '--message=Release', 'v1.0.0')
        command.call('v1.0.0', a: true, message: 'Release')
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0')
        command.call('v1.0.0', annotate: false)
      end
    end

    context 'with :sign option' do
      it 'adds -s flag' do
        expect(execution_context).to receive(:command).with('tag', '-s', '--message=Release', 'v1.0.0')
        command.call('v1.0.0', sign: true, message: 'Release')
      end

      it 'accepts :s alias' do
        expect(execution_context).to receive(:command).with('tag', '-s', '--message=Release', 'v1.0.0')
        command.call('v1.0.0', s: true, message: 'Release')
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0')
        command.call('v1.0.0', sign: false)
      end
    end

    context 'with :no_sign option' do
      it 'adds --no-sign flag to override tag.gpgSign config' do
        expect(execution_context).to receive(:command).with('tag', '--no-sign', 'v1.0.0')
        command.call('v1.0.0', no_sign: true)
      end
    end

    context 'with :local_user option' do
      it 'adds -u <key-id> flag for signing with specific key' do
        expect(execution_context).to receive(:command).with(
          'tag', '--local-user=ABCD1234', '--message=Release', 'v1.0.0'
        )
        command.call('v1.0.0', local_user: 'ABCD1234', message: 'Release')
      end

      it 'accepts :u alias' do
        expect(execution_context).to receive(:command).with(
          'tag', '--local-user=ABCD1234', '--message=Release', 'v1.0.0'
        )
        command.call('v1.0.0', u: 'ABCD1234', message: 'Release')
      end
    end

    context 'with :force option' do
      it 'adds -f flag to replace existing tag' do
        expect(execution_context).to receive(:command).with('tag', '-f', 'v1.0.0')
        command.call('v1.0.0', force: true)
      end

      it 'accepts :f alias' do
        expect(execution_context).to receive(:command).with('tag', '-f', 'v1.0.0')
        command.call('v1.0.0', f: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0')
        command.call('v1.0.0', force: false)
      end
    end

    context 'with :message option' do
      it 'adds -m flag with message' do
        expect(execution_context).to receive(:command).with('tag', '--message=Release version 1.0.0', 'v1.0.0')
        command.call('v1.0.0', message: 'Release version 1.0.0')
      end

      it 'accepts :m alias' do
        expect(execution_context).to receive(:command).with('tag', '--message=Release', 'v1.0.0')
        command.call('v1.0.0', m: 'Release')
      end

      it 'handles message with special characters' do
        expect(execution_context).to receive(:command).with('tag', '--message=Release "quoted"', 'v1.0.0')
        command.call('v1.0.0', message: 'Release "quoted"')
      end
    end

    context 'with :file option' do
      it 'adds -F flag with file path' do
        expect(execution_context).to receive(:command).with('tag', '--file=/path/to/message.txt', 'v1.0.0')
        command.call('v1.0.0', file: '/path/to/message.txt')
      end

      it 'accepts :F alias' do
        expect(execution_context).to receive(:command).with('tag', '--file=/path/to/message.txt', 'v1.0.0')
        command.call('v1.0.0', F: '/path/to/message.txt')
      end

      it 'supports reading from stdin with -' do
        expect(execution_context).to receive(:command).with('tag', '--file=-', 'v1.0.0')
        command.call('v1.0.0', file: '-')
      end
    end

    context 'with :create_reflog option' do
      it 'adds --create-reflog flag' do
        expect(execution_context).to receive(:command).with('tag', '--create-reflog', 'v1.0.0')
        command.call('v1.0.0', create_reflog: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0')
        command.call('v1.0.0', create_reflog: false)
      end
    end

    context 'with multiple options combined' do
      it 'creates an annotated tag with message and force' do
        expect(execution_context).to receive(:command).with(
          'tag', '-a', '-f', '--message=Release', 'v1.0.0'
        )
        command.call('v1.0.0', annotate: true, force: true, message: 'Release')
      end

      it 'creates a signed tag at specific commit' do
        expect(execution_context).to receive(:command).with(
          'tag', '-s', '--message=Signed release', 'v1.0.0', 'abc123'
        )
        command.call('v1.0.0', 'abc123', sign: true, message: 'Signed release')
      end

      it 'creates tag with custom signing key at specific commit' do
        expect(execution_context).to receive(:command).with(
          'tag', '--local-user=KEY123', '--message=Release', 'v1.0.0', 'main'
        )
        command.call('v1.0.0', 'main', local_user: 'KEY123', message: 'Release')
      end

      it 'combines create_reflog with annotated tag' do
        expect(execution_context).to receive(:command).with(
          'tag', '-a', '--create-reflog', '--message=Release', 'v1.0.0'
        )
        command.call('v1.0.0', annotate: true, create_reflog: true, message: 'Release')
      end

      it 'allows annotate with file instead of message' do
        expect(execution_context).to receive(:command).with(
          'tag', '-a', '--file=/path/to/msg.txt', 'v1.0.0'
        )
        command.call('v1.0.0', annotate: true, file: '/path/to/msg.txt')
      end
    end

    context 'validation' do
      it 'raises ArgumentError when annotate is true without message' do
        expect { command.call('v1.0.0', annotate: true) }
          .to raise_error(ArgumentError, 'Cannot create an annotated tag without a message.')
      end

      it 'raises ArgumentError when :a is true without message' do
        expect { command.call('v1.0.0', a: true) }
          .to raise_error(ArgumentError, 'Cannot create an annotated tag without a message.')
      end

      it 'raises ArgumentError when sign is true without message' do
        expect { command.call('v1.0.0', sign: true) }
          .to raise_error(ArgumentError, 'Cannot create an annotated tag without a message.')
      end

      it 'raises ArgumentError when :s is true without message' do
        expect { command.call('v1.0.0', s: true) }
          .to raise_error(ArgumentError, 'Cannot create an annotated tag without a message.')
      end

      it 'raises ArgumentError when local_user is set without message' do
        expect { command.call('v1.0.0', local_user: 'KEY123') }
          .to raise_error(ArgumentError, 'Cannot create an annotated tag without a message.')
      end

      it 'raises ArgumentError when :u is set without message' do
        expect { command.call('v1.0.0', u: 'KEY123') }
          .to raise_error(ArgumentError, 'Cannot create an annotated tag without a message.')
      end

      it 'does not raise when annotate is true with message' do
        expect(execution_context).to receive(:command)
        expect { command.call('v1.0.0', annotate: true, message: 'Release') }.not_to raise_error
      end

      it 'does not raise when sign is true with file' do
        expect(execution_context).to receive(:command)
        expect { command.call('v1.0.0', sign: true, file: '/path/to/msg.txt') }.not_to raise_error
      end

      it 'does not raise for lightweight tags without message' do
        expect(execution_context).to receive(:command)
        expect { command.call('v1.0.0') }.not_to raise_error
      end

      it 'raises ArgumentError when message is an empty string' do
        expect { command.call('v1.0.0', annotate: true, message: '') }
          .to raise_error(ArgumentError, 'Cannot create an annotated tag without a message.')
      end

      it 'raises ArgumentError when file is an empty string' do
        expect { command.call('v1.0.0', sign: true, file: '') }
          .to raise_error(ArgumentError, 'Cannot create an annotated tag without a message.')
      end
    end
  end
end
