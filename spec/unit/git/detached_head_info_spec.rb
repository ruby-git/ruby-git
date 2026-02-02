# frozen_string_literal: true

require 'spec_helper'
require 'git/detached_head_info'

RSpec.describe Git::DetachedHeadInfo do
  describe 'attributes' do
    subject(:detached_head) do
      described_class.new(target_oid: 'abc123def456789012345678901234567890abcd')
    end

    it 'exposes target_oid' do
      expect(detached_head.target_oid).to eq('abc123def456789012345678901234567890abcd')
    end
  end

  describe '#detached?' do
    it 'always returns true' do
      detached_head = described_class.new(target_oid: 'abc123')
      expect(detached_head.detached?).to be true
    end
  end

  describe '#unborn?' do
    it 'always returns false' do
      detached_head = described_class.new(target_oid: 'abc123')
      expect(detached_head.unborn?).to be false
    end
  end

  describe '#short_name' do
    it 'always returns HEAD' do
      detached_head = described_class.new(target_oid: 'abc123')
      expect(detached_head.short_name).to eq('HEAD')
    end
  end

  describe '#to_s' do
    it 'always returns HEAD' do
      detached_head = described_class.new(target_oid: 'abc123')
      expect(detached_head.to_s).to eq('HEAD')
    end
  end
end
