# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/ls_tree'

RSpec.describe Git::Parsers::LsTree do
  describe '.parse' do
    context 'with a blob entry' do
      subject(:result) do
        described_class.parse("100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391\tREADME.md\n")
      end

      it 'returns a Hash with blob, tree, and commit top-level keys' do
        expect(result.keys).to contain_exactly('blob', 'tree', 'commit')
      end

      it 'includes the blob entry keyed by filename' do
        expect(result['blob']['README.md']).to eq(
          { mode: '100644', sha: 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391' }
        )
      end

      it 'returns empty hashes for tree and commit' do
        expect(result['tree']).to eq({})
        expect(result['commit']).to eq({})
      end
    end

    context 'with a tree entry' do
      subject(:result) do
        described_class.parse("040000 tree abcdef0123456789abcdef0123456789abcdef01\tlib\n")
      end

      it 'includes the tree entry keyed by directory name' do
        expect(result['tree']['lib']).to eq(
          { mode: '040000', sha: 'abcdef0123456789abcdef0123456789abcdef01' }
        )
      end
    end

    context 'with a commit (submodule) entry' do
      subject(:result) do
        described_class.parse("160000 commit cafebabe0000000000000000000000000000cafe\tsubmodule\n")
      end

      it 'includes the commit entry keyed by submodule name' do
        expect(result['commit']['submodule']).to eq(
          { mode: '160000', sha: 'cafebabe0000000000000000000000000000cafe' }
        )
      end
    end

    context 'with a git-quoted (backslash-escaped) path' do
      subject(:result) do
        # Git quotes paths that contain special characters (e.g., spaces or
        # non-ASCII) by wrapping them in double quotes and backslash-escaping
        # internal characters.
        described_class.parse("100644 blob abc1234\t\"path with spaces\"\n")
      end

      it 'unescapes the path' do
        expect(result['blob'].keys).to eq(['path with spaces'])
      end
    end

    context 'with multiple entries of different types' do
      subject(:result) do
        output = <<~OUTPUT
          100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391\tREADME.md
          040000 tree abcdef0123456789abcdef0123456789abcdef01\tlib
        OUTPUT
        described_class.parse(output)
      end

      it 'groups blob and tree entries under their respective type keys' do
        expect(result['blob'].keys).to eq(['README.md'])
        expect(result['tree'].keys).to eq(['lib'])
      end
    end

    context 'with empty output' do
      subject(:result) { described_class.parse('') }

      it 'returns a Hash with empty sub-hashes for each object type' do
        expect(result).to eq({ 'blob' => {}, 'tree' => {}, 'commit' => {} })
      end
    end
  end
end
