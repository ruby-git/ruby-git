# frozen_string_literal: true

require 'spec_helper'
require 'git/tag_info'

RSpec.describe Git::TagInfo do
  let(:tagger) do
    Git::AuthorInfo.new(
      name: 'John Doe',
      email: 'john@example.com',
      date: Time.iso8601('2024-01-15T10:30:00-08:00')
    )
  end

  let(:annotated_tag) do
    described_class.new(
      name: 'v1.0.0',
      oid: 'abc123def456',
      target_oid: 'def456abc789',
      objecttype: 'tag',
      tagger: tagger,
      message: 'Release version 1.0.0'
    )
  end

  let(:lightweight_tag) do
    described_class.new(
      name: 'v1.0.0-beta',
      oid: nil,
      target_oid: 'def456abc789',
      objecttype: 'commit',
      tagger: nil,
      message: nil
    )
  end

  describe '#initialize' do
    context 'with an annotated tag' do
      subject(:tag_info) { annotated_tag }

      it 'stores all members' do
        expect(tag_info).to have_attributes(
          name: 'v1.0.0',
          oid: 'abc123def456',
          target_oid: 'def456abc789',
          objecttype: 'tag',
          tagger: tagger,
          message: 'Release version 1.0.0'
        )
      end

      it 'exposes the tagger as a Git::AuthorInfo whose date is a Time' do
        expect(tag_info.tagger).to be_a(Git::AuthorInfo)
        expect(tag_info.tagger.date).to be_a(Time)
      end

      it 'creates an immutable object' do
        expect(tag_info).to be_frozen
      end
    end

    context 'with a lightweight tag' do
      subject(:tag_info) { lightweight_tag }

      it 'stores nil for the oid, tagger, and message' do
        expect(tag_info).to have_attributes(
          name: 'v1.0.0-beta',
          oid: nil,
          target_oid: 'def456abc789',
          objecttype: 'commit',
          tagger: nil,
          message: nil
        )
      end
    end
  end

  describe '#annotated?' do
    subject(:result) { tag_info.annotated? }

    context 'when oid is present (annotated tag)' do
      let(:tag_info) { annotated_tag }

      it { is_expected.to be true }
    end

    context 'when oid is nil (lightweight tag)' do
      let(:tag_info) { lightweight_tag }

      it { is_expected.to be false }
    end
  end

  describe '#lightweight?' do
    subject(:result) { tag_info.lightweight? }

    context 'when oid is nil (lightweight tag)' do
      let(:tag_info) { lightweight_tag }

      it { is_expected.to be true }
    end

    context 'when oid is present (annotated tag)' do
      let(:tag_info) { annotated_tag }

      it { is_expected.to be false }
    end
  end
end
