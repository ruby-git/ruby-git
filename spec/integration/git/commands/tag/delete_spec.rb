# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/delete'

RSpec.describe Git::Commands::Tag::Delete, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when deleting a single tag' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0')
      end

      it 'successfully deletes the tag' do
        result = command.call('v1.0.0')

        expect(result.success?).to be true
        expect(result.deleted.map(&:name)).to eq(['v1.0.0'])
        expect(result.not_deleted).to be_empty
      end

      it 'removes the tag from the repository' do
        command.call('v1.0.0')

        tag_list = repo.tags.map(&:name)
        expect(tag_list).not_to include('v1.0.0')
      end

      it 'returns TagInfo with full metadata for deleted tag' do
        result = command.call('v1.0.0')

        deleted_tag = result.deleted.first
        expect(deleted_tag).to be_a(Git::TagInfo)
        expect(deleted_tag.name).to eq('v1.0.0')
        expect(deleted_tag.target_oid).to match(/^[0-9a-f]{40}$/)
        expect(deleted_tag.objecttype).to eq('commit')
        # Lightweight tags have no tagger metadata
        expect(deleted_tag.tagger_name).to be_nil
        expect(deleted_tag.tagger_email).to be_nil
        expect(deleted_tag.tagger_date).to be_nil
        expect(deleted_tag.message).to be_nil
      end
    end

    context 'when deleting multiple tags' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0')
        repo.add_tag('v2.0.0')
        repo.add_tag('v3.0.0')
      end

      it 'deletes all specified tags' do
        result = command.call('v1.0.0', 'v2.0.0', 'v3.0.0')

        expect(result.success?).to be true
        expect(result.deleted.map(&:name)).to contain_exactly('v1.0.0', 'v2.0.0', 'v3.0.0')
        expect(result.not_deleted).to be_empty
      end

      it 'removes all tags from the repository' do
        command.call('v1.0.0', 'v2.0.0', 'v3.0.0')

        expect(repo.tags).to be_empty
      end
    end

    context 'when some tags do not exist (partial failure)' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0')
        repo.add_tag('v2.0.0')
      end

      it 'deletes existing tags and reports missing ones' do
        result = command.call('v1.0.0', 'nonexistent', 'v2.0.0')

        expect(result.success?).to be false
        expect(result.deleted.map(&:name)).to contain_exactly('v1.0.0', 'v2.0.0')
        expect(result.not_deleted.size).to eq(1)
        expect(result.not_deleted.first.name).to eq('nonexistent')
        expect(result.not_deleted.first.error_message)
          .to match(/tag 'nonexistent'.*not found|tag 'nonexistent' could not be deleted/)
      end

      it 'removes only the existing tags' do
        command.call('v1.0.0', 'nonexistent', 'v2.0.0')

        tag_list = repo.tags.map(&:name)
        expect(tag_list).to be_empty
      end
    end

    context 'when all specified tags do not exist' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'reports all tags as not deleted' do
        result = command.call('nonexistent1', 'nonexistent2')

        expect(result.success?).to be false
        expect(result.deleted).to be_empty
        expect(result.not_deleted.map(&:name)).to contain_exactly('nonexistent1', 'nonexistent2')
      end

      it 'includes error messages for each failed tag' do
        result = command.call('nonexistent1', 'nonexistent2')

        result.not_deleted.each do |failure|
          expect(failure.error_message)
            .to match(/tag '#{failure.name}'.*not found|tag '#{failure.name}' could not be deleted/)
        end
      end
    end

    context 'with annotated tags' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0', annotate: true, message: 'Release 1.0.0')
      end

      it 'successfully deletes annotated tags' do
        result = command.call('v1.0.0')

        expect(result.success?).to be true
        expect(result.deleted.map(&:name)).to eq(['v1.0.0'])
      end

      it 'returns TagInfo with full metadata for deleted annotated tag' do
        result = command.call('v1.0.0')

        deleted_tag = result.deleted.first
        expect(deleted_tag.name).to eq('v1.0.0')
        expect(deleted_tag.oid).to match(/^[0-9a-f]{40}$/)
        expect(deleted_tag.objecttype).to eq('tag')
        # Annotated tags have tagger metadata
        expect(deleted_tag.tagger_name).not_to be_nil
        expect(deleted_tag.tagger_email).not_to be_nil
        expect(deleted_tag.tagger_date).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}([+-]\d{2}:\d{2}|Z)$/)
        expect(deleted_tag.message).to eq('Release 1.0.0')
      end
    end

    context 'with tags containing special characters' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'deletes tags with slashes' do
        repo.add_tag('release/v1.0')
        result = command.call('release/v1.0')

        expect(result.success?).to be true
        expect(result.deleted.first.name).to eq('release/v1.0')
      end

      it 'deletes tags with hyphens and underscores' do
        repo.add_tag('feature-1_test')
        result = command.call('feature-1_test')

        expect(result.success?).to be true
        expect(result.deleted.first.name).to eq('feature-1_test')
      end

      it 'deletes tags with unicode characters' do
        repo.add_tag('タグ名')
        result = command.call('タグ名')

        expect(result.success?).to be true
        expect(result.deleted.first.name).to eq('タグ名')
      end
    end

    context 'with mixed lightweight and annotated tags' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('lightweight')
        repo.add_tag('annotated', annotate: true, message: 'Annotated tag')
      end

      it 'deletes both types of tags' do
        result = command.call('lightweight', 'annotated')

        expect(result.success?).to be true
        expect(result.deleted.map(&:name)).to contain_exactly('lightweight', 'annotated')
        expect(repo.tags).to be_empty
      end
    end
  end
end
