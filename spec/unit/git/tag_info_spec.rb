# frozen_string_literal: true

require 'spec_helper'
require 'git/tag_info'

RSpec.describe Git::TagInfo do
  describe 'attributes' do
    context 'for annotated tags' do
      subject(:tag_info) do
        described_class.new(
          name: 'v1.0.0',
          oid: 'abc123def456',
          target_oid: 'def456abc789',
          objecttype: 'tag',
          tagger_name: 'John Doe',
          tagger_email: '<john@example.com>',
          tagger_date: '2024-01-15T10:30:00-08:00',
          message: 'Release version 1.0.0'
        )
      end

      it 'has a name' do
        expect(tag_info.name).to eq('v1.0.0')
      end

      it 'has an oid (tag object ID)' do
        expect(tag_info.oid).to eq('abc123def456')
      end

      it 'has a target_oid (commit ID)' do
        expect(tag_info.target_oid).to eq('def456abc789')
      end

      it 'has an objecttype' do
        expect(tag_info.objecttype).to eq('tag')
      end

      it 'has tagger_name' do
        expect(tag_info.tagger_name).to eq('John Doe')
      end

      it 'has tagger_email' do
        expect(tag_info.tagger_email).to eq('<john@example.com>')
      end

      it 'has tagger_date' do
        expect(tag_info.tagger_date).to eq('2024-01-15T10:30:00-08:00')
      end

      it 'has a message' do
        expect(tag_info.message).to eq('Release version 1.0.0')
      end
    end

    context 'for lightweight tags' do
      subject(:tag_info) do
        described_class.new(
          name: 'v1.0.0-beta',
          oid: nil,
          target_oid: 'def456abc789',
          objecttype: 'commit',
          tagger_name: nil,
          tagger_email: nil,
          tagger_date: nil,
          message: nil
        )
      end

      it 'has nil oid' do
        expect(tag_info.oid).to be_nil
      end

      it 'has a target_oid (commit ID)' do
        expect(tag_info.target_oid).to eq('def456abc789')
      end
    end
  end

  describe '#annotated?' do
    context 'when oid is present (annotated tag)' do
      subject(:tag_info) do
        described_class.new(
          name: 'v1.0.0',
          oid: 'abc123',
          target_oid: 'def456',
          objecttype: 'tag',
          tagger_name: 'John Doe',
          tagger_email: '<john@example.com>',
          tagger_date: '2024-01-15T10:30:00-08:00',
          message: 'Release'
        )
      end

      it 'returns true' do
        expect(tag_info.annotated?).to be true
      end
    end

    context 'when oid is nil (lightweight tag)' do
      subject(:tag_info) do
        described_class.new(
          name: 'v1.0.0',
          oid: nil,
          target_oid: 'def456',
          objecttype: 'commit',
          tagger_name: nil,
          tagger_email: nil,
          tagger_date: nil,
          message: nil
        )
      end

      it 'returns false' do
        expect(tag_info.annotated?).to be false
      end
    end
  end

  describe '#lightweight?' do
    context 'when oid is nil (lightweight tag)' do
      subject(:tag_info) do
        described_class.new(
          name: 'v1.0.0',
          oid: nil,
          target_oid: 'def456',
          objecttype: 'commit',
          tagger_name: nil,
          tagger_email: nil,
          tagger_date: nil,
          message: nil
        )
      end

      it 'returns true' do
        expect(tag_info.lightweight?).to be true
      end
    end

    context 'when oid is present (annotated tag)' do
      subject(:tag_info) do
        described_class.new(
          name: 'v1.0.0',
          oid: 'abc123',
          target_oid: 'def456',
          objecttype: 'tag',
          tagger_name: 'John Doe',
          tagger_email: '<john@example.com>',
          tagger_date: '2024-01-15T10:30:00-08:00',
          message: 'Release'
        )
      end

      it 'returns false' do
        expect(tag_info.lightweight?).to be false
      end
    end
  end

  describe '#tagger' do
    context 'for annotated tags' do
      subject(:tag_info) do
        described_class.new(
          name: 'v1.0.0',
          oid: 'abc123',
          target_oid: 'def456',
          objecttype: 'tag',
          tagger_name: 'John Doe',
          tagger_email: '<john@example.com>',
          tagger_date: '2024-01-15T10:30:00-08:00',
          message: 'Release'
        )
      end

      it 'returns a Git::Author object' do
        expect(tag_info.tagger).to be_a(Git::Author)
      end

      it 'has the correct name' do
        expect(tag_info.tagger.name).to eq('John Doe')
      end

      it 'has the correct email' do
        expect(tag_info.tagger.email).to eq('john@example.com')
      end
    end

    context 'for lightweight tags' do
      subject(:tag_info) do
        described_class.new(
          name: 'v1.0.0',
          oid: nil,
          target_oid: 'def456',
          objecttype: 'commit',
          tagger_name: nil,
          tagger_email: nil,
          tagger_date: nil,
          message: nil
        )
      end

      it 'returns nil' do
        expect(tag_info.tagger).to be_nil
      end
    end
  end
end
