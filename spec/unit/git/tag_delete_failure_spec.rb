# frozen_string_literal: true

require 'spec_helper'
require 'git/tag_delete_failure'

RSpec.describe Git::TagDeleteFailure do
  describe '.new' do
    it 'creates a TagDeleteFailure with name and error_message' do
      failure = described_class.new(name: 'v1.0.0', error_message: "tag 'v1.0.0' not found.")

      expect(failure.name).to eq('v1.0.0')
      expect(failure.error_message).to eq("tag 'v1.0.0' not found.")
    end
  end

  describe 'immutability' do
    it 'is immutable (Data.define)' do
      failure = described_class.new(name: 'v1.0.0', error_message: 'error')

      expect(failure).to be_frozen
    end
  end

  describe 'equality' do
    it 'considers two failures with same values as equal' do
      failure1 = described_class.new(name: 'v1.0.0', error_message: 'error')
      failure2 = described_class.new(name: 'v1.0.0', error_message: 'error')

      expect(failure1).to eq(failure2)
    end
  end
end
