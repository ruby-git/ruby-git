# frozen_string_literal: true

require 'spec_helper'
require 'git/encoding_utils'

RSpec.describe Git::EncodingUtils do
  describe '.default_encoding' do
    it "returns this source file's encoding name" do
      expect(described_class.default_encoding).to eq(__ENCODING__.name)
    end
  end

  describe '.best_guess_encoding' do
    it 'returns UTF-8' do
      expect(described_class.best_guess_encoding).to eq('UTF-8')
    end
  end

  describe '.detected_encoding' do
    subject(:detected) { described_class.detected_encoding(str) }

    let(:str) { "caf\xE9".dup.force_encoding(Encoding::BINARY) }

    context 'when CharDet detects an encoding' do
      before { allow(CharDet).to receive(:detect).with(str).and_return({ 'encoding' => 'ISO-8859-1' }) }

      it 'returns the detected encoding name' do
        expect(detected).to eq('ISO-8859-1')
      end
    end

    context 'when CharDet cannot detect an encoding' do
      before { allow(CharDet).to receive(:detect).with(str).and_return({ 'encoding' => nil }) }

      it 'falls back to best_guess_encoding' do
        expect(detected).to eq('UTF-8')
      end
    end
  end

  describe '.encoding_options' do
    it 'replaces invalid and undefined bytes' do
      expect(described_class.encoding_options).to eq(invalid: :replace, undef: :replace)
    end
  end

  describe '.normalize_encoding' do
    subject(:normalized) { described_class.normalize_encoding(str) }

    context 'when the string is already in the default encoding' do
      let(:str) { 'already utf-8'.dup.force_encoding(described_class.default_encoding) }

      it 'returns the same string object unchanged' do
        expect(normalized).to be(str)
      end
    end

    context 'when the string has a valid but different encoding' do
      let(:str) { 'café'.encode(Encoding::ISO_8859_1) }

      it 'transcodes it to the default encoding without detection' do
        expect(CharDet).not_to receive(:detect)
        expect(normalized).to eq('café')
        expect(normalized.encoding.name).to eq(described_class.default_encoding)
      end
    end

    context 'when the string has an invalid encoding' do
      let(:str) { "caf\xE9".dup.force_encoding(Encoding::UTF_8) }

      before { allow(CharDet).to receive(:detect).with(str).and_return({ 'encoding' => 'ISO-8859-1' }) }

      it 'detects the encoding and transcodes it to the default encoding' do
        expect(normalized).to eq('café')
        expect(normalized.encoding.name).to eq(described_class.default_encoding)
      end
    end
  end
end
