# frozen_string_literal: true

require 'spec_helper'
require 'git/tag_delete_result'
require 'git/tag_delete_failure'
require 'git/tag_info'

RSpec.describe Git::TagDeleteResult do
  let(:tag_v1) do
    Git::TagInfo.new(
      name: 'v1.0.0', oid: nil, target_oid: 'abc123', objecttype: 'commit',
      tagger_name: nil, tagger_email: nil, tagger_date: nil, message: nil
    )
  end
  let(:tag_v2) do
    Git::TagInfo.new(
      name: 'v2.0.0', oid: nil, target_oid: 'def456', objecttype: 'commit',
      tagger_name: nil, tagger_email: nil, tagger_date: nil, message: nil
    )
  end
  let(:failure1) { Git::TagDeleteFailure.new(name: 'nonexistent', error_message: "tag 'nonexistent' not found.") }
  let(:failure2) { Git::TagDeleteFailure.new(name: 'other', error_message: "tag 'other' not found.") }

  describe '.new' do
    it 'creates a TagDeleteResult with deleted and not_deleted arrays' do
      result = described_class.new(deleted: [tag_v1, tag_v2], not_deleted: [failure1])

      expect(result.deleted).to eq([tag_v1, tag_v2])
      expect(result.not_deleted).to eq([failure1])
    end
  end

  describe '#success?' do
    context 'when all tags were deleted' do
      it 'returns true' do
        result = described_class.new(deleted: [tag_v1, tag_v2], not_deleted: [])

        expect(result.success?).to be true
      end
    end

    context 'when some tags failed to delete' do
      it 'returns false' do
        result = described_class.new(deleted: [tag_v1], not_deleted: [failure1])

        expect(result.success?).to be false
      end
    end

    context 'when all tags failed to delete' do
      it 'returns false' do
        result = described_class.new(deleted: [], not_deleted: [failure1, failure2])

        expect(result.success?).to be false
      end
    end

    context 'when no tags were requested (edge case)' do
      it 'returns true with empty arrays' do
        result = described_class.new(deleted: [], not_deleted: [])

        expect(result.success?).to be true
      end
    end
  end

  describe 'immutability' do
    it 'is immutable (Data.define)' do
      result = described_class.new(deleted: [tag_v1], not_deleted: [])

      expect(result).to be_frozen
    end
  end

  describe 'equality' do
    it 'considers two results with same values as equal' do
      result1 = described_class.new(deleted: [tag_v1], not_deleted: [failure1])
      result2 = described_class.new(deleted: [tag_v1], not_deleted: [failure1])

      expect(result1).to eq(result2)
    end
  end
end
