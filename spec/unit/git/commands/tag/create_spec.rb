# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/create'
require 'git/tag_info'

RSpec.describe Git::Commands::Tag::Create do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Helper method to create a mock tag list
  let(:mock_tag_list) do
    [
      Git::TagInfo.new(
        name: 'v1.0.0',
        sha: 'abc123',
        objecttype: 'commit',
        tagger_name: nil,
        tagger_email: nil,
        tagger_date: nil,
        message: nil
      )
    ]
  end

  describe '#call' do
    context 'with tag name only (lightweight tag)' do
      it 'calls git tag with the tag name' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0')
        expect(result).to be_a(Git::TagInfo)
        expect(result.name).to eq('v1.0.0')
      end
    end

    context 'with commit target' do
      it 'adds the commit after the tag name' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0', 'abc123')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', 'abc123')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'accepts a branch as target' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0', 'main')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', 'main')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'accepts HEAD as target' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0', 'HEAD')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', 'HEAD')
        expect(result).to be_a(Git::TagInfo)
      end
    end

    context 'with :annotate option' do
      it 'adds -a flag' do
        expect(execution_context).to receive(:command).with('tag', '-a', '--message=Release', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', annotate: true, message: 'Release')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'accepts :a alias' do
        expect(execution_context).to receive(:command).with('tag', '-a', '--message=Release', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', a: true, message: 'Release')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', annotate: false)
        expect(result).to be_a(Git::TagInfo)
      end
    end

    context 'with :sign option' do
      it 'adds -s flag' do
        expect(execution_context).to receive(:command).with('tag', '-s', '--message=Release', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', sign: true, message: 'Release')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'accepts :s alias' do
        expect(execution_context).to receive(:command).with('tag', '-s', '--message=Release', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', s: true, message: 'Release')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', sign: false)
        expect(result).to be_a(Git::TagInfo)
      end
    end

    context 'with :no_sign option' do
      it 'adds --no-sign flag to override tag.gpgSign config' do
        expect(execution_context).to receive(:command).with('tag', '--no-sign', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', no_sign: true)
        expect(result).to be_a(Git::TagInfo)
      end
    end

    context 'with :local_user option' do
      it 'adds -u <key-id> flag for signing with specific key' do
        expect(execution_context).to receive(:command).with(
          'tag', '--local-user=ABCD1234', '--message=Release', 'v1.0.0'
        )
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', local_user: 'ABCD1234', message: 'Release')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'accepts :u alias' do
        expect(execution_context).to receive(:command).with(
          'tag', '--local-user=ABCD1234', '--message=Release', 'v1.0.0'
        )
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', u: 'ABCD1234', message: 'Release')
        expect(result).to be_a(Git::TagInfo)
      end
    end

    context 'with :force option' do
      it 'adds -f flag to replace existing tag' do
        expect(execution_context).to receive(:command).with('tag', '-f', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', force: true)
        expect(result).to be_a(Git::TagInfo)
      end

      it 'accepts :f alias' do
        expect(execution_context).to receive(:command).with('tag', '-f', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', f: true)
        expect(result).to be_a(Git::TagInfo)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', force: false)
        expect(result).to be_a(Git::TagInfo)
      end
    end

    context 'with :message option' do
      it 'adds -m flag with message' do
        expect(execution_context).to receive(:command).with('tag', '--message=Release version 1.0.0', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', message: 'Release version 1.0.0')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'accepts :m alias' do
        expect(execution_context).to receive(:command).with('tag', '--message=Release', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', m: 'Release')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'handles message with special characters' do
        expect(execution_context).to receive(:command).with('tag', '--message=Release "quoted"', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', message: 'Release "quoted"')
        expect(result).to be_a(Git::TagInfo)
      end
    end

    context 'with :file option' do
      it 'adds -F flag with file path' do
        expect(execution_context).to receive(:command).with('tag', '--file=/path/to/message.txt', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', file: '/path/to/message.txt')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'accepts :F alias' do
        expect(execution_context).to receive(:command).with('tag', '--file=/path/to/message.txt', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', F: '/path/to/message.txt')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'supports reading from stdin with -' do
        expect(execution_context).to receive(:command).with('tag', '--file=-', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', file: '-')
        expect(result).to be_a(Git::TagInfo)
      end
    end

    context 'with :create_reflog option' do
      it 'adds --create-reflog flag' do
        expect(execution_context).to receive(:command).with('tag', '--create-reflog', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', create_reflog: true)
        expect(result).to be_a(Git::TagInfo)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('tag', 'v1.0.0')
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', create_reflog: false)
        expect(result).to be_a(Git::TagInfo)
      end
    end

    context 'with multiple options combined' do
      it 'creates an annotated tag with message and force' do
        expect(execution_context).to receive(:command).with(
          'tag', '-a', '-f', '--message=Release', 'v1.0.0'
        )
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', annotate: true, force: true, message: 'Release')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'creates a signed tag at specific commit' do
        expect(execution_context).to receive(:command).with(
          'tag', '-s', '--message=Signed release', 'v1.0.0', 'abc123'
        )
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', 'abc123', sign: true, message: 'Signed release')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'creates tag with custom signing key at specific commit' do
        expect(execution_context).to receive(:command).with(
          'tag', '--local-user=KEY123', '--message=Release', 'v1.0.0', 'main'
        )
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', 'main', local_user: 'KEY123', message: 'Release')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'combines create_reflog with annotated tag' do
        expect(execution_context).to receive(:command).with(
          'tag', '-a', '--create-reflog', '--message=Release', 'v1.0.0'
        )
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', annotate: true, create_reflog: true, message: 'Release')
        expect(result).to be_a(Git::TagInfo)
      end

      it 'allows annotate with file instead of message' do
        expect(execution_context).to receive(:command).with(
          'tag', '-a', '--file=/path/to/msg.txt', 'v1.0.0'
        )
        allow(Git::Commands::Tag::List).to receive(:new).and_return(double(call: mock_tag_list))
        result = command.call('v1.0.0', annotate: true, file: '/path/to/msg.txt')
        expect(result).to be_a(Git::TagInfo)
      end
    end
  end
end
