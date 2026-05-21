# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/grep'

RSpec.describe Git::Parsers::Grep do
  describe '.parse' do
    context 'with a single matching line' do
      subject(:result) { described_class.parse("HEAD:src/foo.rb#{nul}12#{nul}# TODO: fix this\n") }

      let(:nul) { "\0" }

      it 'returns a Hash keyed by treeish:filename' do
        expect(result.keys).to eq(['HEAD:src/foo.rb'])
      end

      it 'maps the key to an array containing [line_number, text]' do
        expect(result['HEAD:src/foo.rb']).to eq([[12, '# TODO: fix this']])
      end
    end

    context 'with multiple matches in the same file' do
      subject(:result) do
        described_class.parse(
          "HEAD:src/foo.rb#{nul}12#{nul}# TODO: fix this\n" \
          "HEAD:src/foo.rb#{nul}34#{nul}# TODO: also this\n"
        )
      end

      let(:nul) { "\0" }

      it 'groups both matches under the same key' do
        expect(result['HEAD:src/foo.rb']).to eq([
                                                  [12, '# TODO: fix this'],
                                                  [34, '# TODO: also this']
                                                ])
      end
    end

    context 'with a matching filename containing a colon-number-colon pattern' do
      subject(:result) do
        nul = "\0"
        described_class.parse("HEAD:src/foo:42:bar.rb#{nul}5#{nul}matched text\n")
      end

      it 'preserves the filename' do
        expect(result).to eq('HEAD:src/foo:42:bar.rb' => [[5, 'matched text']])
      end
    end

    context 'with matches in multiple files' do
      subject(:result) do
        described_class.parse(
          "HEAD:src/foo.rb#{nul}12#{nul}# TODO: fix this\n" \
          "HEAD:lib/bar.rb#{nul}5#{nul}# TODO: and this\n"
        )
      end

      let(:nul) { "\0" }

      it 'returns a Hash with one key per unique treeish:filename' do
        expect(result.keys).to contain_exactly('HEAD:src/foo.rb', 'HEAD:lib/bar.rb')
      end

      it 'maps each key to its own match array' do
        expect(result['HEAD:src/foo.rb']).to eq([[12, '# TODO: fix this']])
        expect(result['HEAD:lib/bar.rb']).to eq([[5, '# TODO: and this']])
      end
    end

    context 'with empty input' do
      subject(:result) { described_class.parse('') }

      it 'returns an empty Hash' do
        expect(result).to eq({})
      end
    end

    context 'with lines that do not match the expected format' do
      subject(:result) { described_class.parse("this line has no NUL delimiters\n") }

      it 'ignores non-matching lines and returns an empty Hash' do
        expect(result).to eq({})
      end
    end
  end
end
