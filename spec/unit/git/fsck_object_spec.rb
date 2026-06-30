# frozen_string_literal: true

require 'spec_helper'
require 'git/fsck_object'

RSpec.describe Git::FsckObject do
  let(:type) { :commit }
  let(:oid) { 'abc123def456789012345678901234567890abcd' }
  let(:message) { 'badTimezone: invalid author/committer line' }
  let(:name) { 'HEAD~2^2:src/' }
  let(:described_instance) { described_class.new(type: type, oid: oid, message: message, name: name) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores all constructor arguments' do
      expect(instance).to have_attributes(
        type: type,
        oid: oid,
        message: message,
        name: name
      )
    end

    context 'when optional keyword arguments are omitted' do
      let(:described_instance) { described_class.new(type: :tree, oid: oid) }

      it 'defaults message to nil' do
        expect(described_instance.message).to be_nil
      end

      it 'defaults name to nil' do
        expect(described_instance.name).to be_nil
      end
    end
  end

  describe '#to_s' do
    subject(:result) { described_instance.to_s }

    it 'returns the oid' do
      expect(result).to eq(oid)
    end
  end
end
