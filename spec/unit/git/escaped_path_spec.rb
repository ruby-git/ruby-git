# frozen_string_literal: true

require 'spec_helper'
require 'git/escaped_path'

RSpec.describe Git::EscapedPath do
  let(:described_instance) { described_class.new(path) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    let(:path) { 'my_file' }

    it 'stores the path' do
      expect(instance).to have_attributes(path: 'my_file')
    end
  end

  describe '#unescape' do
    subject(:result) { described_instance.unescape }

    context 'when the path contains no escape sequences' do
      let(:path) { 'my_other_file' }

      it 'returns the path unchanged' do
        expect(result).to eq('my_other_file')
      end
    end

    context 'when the path contains single-character escape sequences' do
      Git::EscapedPath::UNESCAPES.each_pair do |escape_char, byte_value|
        context "when the escape sequence is \\#{escape_char}" do
          let(:path) { "\\#{escape_char}" }

          it "unescapes to the character with byte value #{byte_value}" do
            expect(result).to eq(byte_value.chr)
          end
        end
      end
    end

    context 'when the path contains a compound escape sequence (octal bytes and char escape)' do
      let(:path) { 'my_other_file_"\\342\\230\\240\\n"' }

      it 'unescapes both the multi-byte octal sequence and the char escape' do
        expect(result).to eq("my_other_file_\"☠\n\"")
      end
    end

    context 'when the path contains multi-byte octal escape sequences (UTF-8)' do
      let(:path) { 'my_other_file_\\342\\230\\240' }

      it 'returns a UTF-8 string with the decoded character' do
        expect(result).to eq("my_other_file_\u2620")
      end
    end
  end
end
