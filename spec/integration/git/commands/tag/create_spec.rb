# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/create'

RSpec.describe Git::Commands::Tag::Create, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when creating a lightweight tag' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'creates the tag and returns TagInfo' do
        result = command.call('v1.0.0')

        expect(result).to be_a(Git::TagInfo)
        expect(result.name).to eq('v1.0.0')
        expect(result.sha).to match(/^[0-9a-f]{40}$/)
        expect(result.objecttype).to eq('commit')
      end

      it 'creates a lightweight tag with correct metadata' do
        result = command.call('v1.0.0')

        expect(result.lightweight?).to be true
        expect(result.annotated?).to be false
        expect(result.tagger_name).to be_nil
        expect(result.tagger_email).to be_nil
        expect(result.tagger_date).to be_nil
        expect(result.message).to be_nil
      end

      it 'makes the tag visible in the repository' do
        command.call('v1.0.0')

        tag_list = repo.tags.map(&:name)
        expect(tag_list).to include('v1.0.0')
      end

      it 'tags the current HEAD by default' do
        commit_sha = execution_context.command('rev-parse', 'HEAD').strip

        result = command.call('v1.0.0')

        expect(result.sha).to eq(commit_sha)
      end
    end

    context 'when creating an annotated tag' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'creates an annotated tag and returns TagInfo' do
        result = command.call('v2.0.0', annotate: true, message: 'Release version 2.0.0')

        expect(result).to be_a(Git::TagInfo)
        expect(result.name).to eq('v2.0.0')
        expect(result.sha).to match(/^[0-9a-f]{40}$/)
        expect(result.objecttype).to eq('tag')
      end

      it 'creates an annotated tag with correct metadata' do
        result = command.call('v2.0.0', annotate: true, message: 'Release version 2.0.0')

        expect(result.annotated?).to be true
        expect(result.lightweight?).to be false
        expect(result.message).to eq('Release version 2.0.0')
      end

      it 'includes tagger information' do
        result = command.call('v2.0.0', annotate: true, message: 'Release version 2.0.0')

        expect(result.tagger_name).not_to be_nil
        expect(result.tagger_email).not_to be_nil
        # iso8601-strict format: YYYY-MM-DDTHH:MM:SS±HH:MM or YYYY-MM-DDTHH:MM:SSZ
        expect(result.tagger_date).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}([-+]\d{2}:\d{2}|Z)$/)
      end

      it 'makes the tag visible in the repository' do
        command.call('v2.0.0', annotate: true, message: 'Release version 2.0.0')

        tag_list = repo.tags.map(&:name)
        expect(tag_list).to include('v2.0.0')
      end
    end

    context 'when creating a tag with :message option (implies annotate)' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'creates an annotated tag with the message' do
        result = command.call('v3.0.0', message: 'Version 3.0.0')

        expect(result).to be_a(Git::TagInfo)
        expect(result.annotated?).to be true
        expect(result.message).to eq('Version 3.0.0')
      end
    end

    context 'when tagging a specific commit' do
      let(:first_commit_sha) do
        write_file('file1.txt', 'content1')
        repo.add('file1.txt')
        repo.commit('First commit')
        execution_context.command('rev-parse', 'HEAD').strip
      end

      before do
        first_commit_sha # Create first commit

        write_file('file2.txt', 'content2')
        repo.add('file2.txt')
        repo.commit('Second commit')
      end

      it 'creates a tag pointing to the specified commit' do
        result = command.call('v1.0.0', first_commit_sha)

        expect(result).to be_a(Git::TagInfo)
        expect(result.name).to eq('v1.0.0')
        expect(result.sha).to eq(first_commit_sha)
      end

      it 'works with branch names' do
        execution_context.command('branch', 'test-branch', first_commit_sha)

        result = command.call('v1.0.0', 'test-branch')

        expect(result).to be_a(Git::TagInfo)
        expect(result.sha).to eq(first_commit_sha)
      end
    end

    context 'when using :force option to replace an existing tag' do
      before do
        write_file('file1.txt', 'content1')
        repo.add('file1.txt')
        repo.commit('First commit')
        repo.add_tag('v1.0.0')

        write_file('file2.txt', 'content2')
        repo.add('file2.txt')
        repo.commit('Second commit')
      end

      it 'replaces the existing tag' do
        new_commit_sha = execution_context.command('rev-parse', 'HEAD').strip

        result = command.call('v1.0.0', force: true)

        expect(result).to be_a(Git::TagInfo)
        expect(result.name).to eq('v1.0.0')
        expect(result.sha).to eq(new_commit_sha)
      end

      it 'does not create duplicate tags' do
        command.call('v1.0.0', force: true)

        tag_list = repo.tags.select { |t| t.name == 'v1.0.0' }
        expect(tag_list.size).to eq(1)
      end
    end

    context 'when the tag already exists without :force' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0')
      end

      it 'raises a Git::FailedError' do
        expect { command.call('v1.0.0') }.to raise_error(Git::FailedError, /already exists/)
      end
    end

    context 'when creating an annotated tag without a message' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'raises Git::FailedError when git cannot read message' do
        expect { command.call('v1.0.0', annotate: true) }
          .to raise_error(Git::FailedError)
      end
    end

    context 'when creating multiple tags' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'creates each tag successfully' do
        result1 = command.call('v1.0.0')
        result2 = command.call('v1.1.0')
        result3 = command.call('v2.0.0', annotate: true, message: 'Major release')

        expect(result1.name).to eq('v1.0.0')
        expect(result2.name).to eq('v1.1.0')
        expect(result3.name).to eq('v2.0.0')

        tag_list = repo.tags.map(&:name)
        expect(tag_list).to contain_exactly('v1.0.0', 'v1.1.0', 'v2.0.0')
      end
    end

    context 'with :create_reflog option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'creates a tag with reflog' do
        result = command.call('v1.0.0', create_reflog: true)

        expect(result).to be_a(Git::TagInfo)
        expect(result.name).to eq('v1.0.0')
      end
    end
  end
end
