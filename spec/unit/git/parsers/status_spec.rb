# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/status'

RSpec.describe Git::Parsers::Status do
  describe '.parse' do
    subject(:result) { described_class.parse(stdout) }

    let(:sha_a) { '2bdf67abb163a4ffb2d7f3f0880c9fe5068ce782' }
    let(:sha_b) { 'ba2906d0666cf726c7eaadd2cd3db615dedfdf3a' }
    let(:sha_c) { 'e45c9c2666d44e0327c1f9c239a74c508336053e' }
    let(:zero_sha) { '0000000000000000000000000000000000000000' }
    let(:stdout) { '' }

    context 'with empty output' do
      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end

    context 'with an ordinary entry (1)' do
      let(:stdout) { "1 .M N... 100644 100644 100755 #{sha_a} #{sha_a} c.txt\0" }

      it 'returns one Git::StatusFileInfo with every porcelain v2 field' do
        expect(result.size).to eq(1)
        expect(result.first).to be_a(Git::StatusFileInfo)
        expect(result.first).to have_attributes(
          path: 'c.txt', index_status: '.', worktree_status: 'M', submodule: 'N...',
          mode_head: '100644', mode_index: '100644', mode_worktree: '100755',
          sha_head: sha_a, sha_index: sha_a,
          original_path: nil, rename_score: nil, unmerged_stages: nil
        )
      end

      it 'returns an entry whose string members are frozen' do
        expect(result.first.path).to be_frozen
        expect(result.first.sha_index).to be_frozen
        expect { result.first.path << 'x' }.to raise_error(FrozenError)
      end
    end

    context 'with a staged new file whose HEAD side is all zeros' do
      let(:stdout) { "1 A. N... 000000 100644 100644 #{zero_sha} #{sha_a} staged.txt\0" }

      it 'keeps the zero mode and SHA strings git emitted' do
        expect(result.first).to have_attributes(
          index_status: 'A', worktree_status: '.', mode_head: '000000', sha_head: zero_sha, sha_index: sha_a
        )
      end
    end

    context 'with a submodule entry' do
      let(:stdout) { "1 A. S... 000000 160000 160000 #{zero_sha} #{sha_a} submod\0" }

      it 'returns the submodule field as a String' do
        expect(result.first).to have_attributes(path: 'submod', submodule: 'S...', mode_index: '160000')
      end
    end

    context 'with a rename entry (2) followed by its original path as the next NUL token' do
      let(:stdout) { "2 R. N... 100644 100644 100644 #{sha_a} #{sha_a} R100 renamed.txt\0a.txt\0" }

      it 'returns one entry carrying the new path, the original path, and the score' do
        expect(result.size).to eq(1)
        expect(result.first).to have_attributes(
          path: 'renamed.txt', index_status: 'R', worktree_status: '.', submodule: 'N...',
          mode_head: '100644', mode_index: '100644', mode_worktree: '100644',
          sha_head: sha_a, sha_index: sha_a,
          original_path: 'a.txt', rename_score: 100, unmerged_stages: nil
        )
      end

      it 'reports the entry as renamed' do
        expect(result.first).to be_renamed
      end
    end

    context 'with a copy entry (2 with a C score)' do
      let(:stdout) { "2 C. N... 100644 100644 100644 #{sha_a} #{sha_a} C75 copy.txt\0a.txt\0" }

      it 'returns the original path and the copy score' do
        expect(result.first).to have_attributes(index_status: 'C', original_path: 'a.txt', rename_score: 75)
      end
    end

    context 'with an unmerged entry (u)' do
      let(:stdout) { "u UU N... 100644 100644 100755 100755 #{sha_a} #{sha_b} #{sha_c} c.txt\0" }

      it 'returns an entry whose stage 1, 2, and 3 modes and SHAs are kept' do
        expect(result.first).to have_attributes(
          path: 'c.txt', index_status: 'U', worktree_status: 'U', submodule: 'N...',
          mode_head: nil, mode_index: nil, mode_worktree: '100755', sha_head: nil, sha_index: nil,
          original_path: nil, rename_score: nil,
          unmerged_stages: {
            1 => { mode: '100644', sha: sha_a },
            2 => { mode: '100644', sha: sha_b },
            3 => { mode: '100755', sha: sha_c }
          }
        )
      end

      it 'freezes the unmerged stage data down to its mode and SHA strings' do
        stages = result.first.unmerged_stages
        expect(stages).to be_frozen
        expect(stages.values).to all(be_frozen)
        expect(stages.values.flat_map(&:values)).to all(be_frozen)
      end

      it 'reports the entry as unmerged' do
        expect(result.first).to be_unmerged
      end
    end

    context 'with an untracked entry (?)' do
      let(:stdout) { "? new.txt\0" }

      it 'returns an entry with ? status characters and nil metadata' do
        expect(result.first).to have_attributes(
          path: 'new.txt', index_status: '?', worktree_status: '?', submodule: nil,
          mode_head: nil, mode_index: nil, mode_worktree: nil, sha_head: nil, sha_index: nil,
          original_path: nil, rename_score: nil, unmerged_stages: nil
        )
      end

      it 'reports the entry as untracked' do
        expect(result.first).to be_untracked
      end
    end

    context 'with an ignored entry (!)' do
      let(:stdout) { "! ignored.txt\0" }

      it 'returns an entry with ! status characters and nil metadata' do
        expect(result.first).to have_attributes(
          path: 'ignored.txt', index_status: '!', worktree_status: '!', submodule: nil,
          mode_head: nil, mode_index: nil, mode_worktree: nil, sha_head: nil, sha_index: nil
        )
      end

      it 'reports the entry as ignored' do
        expect(result.first).to be_ignored
      end
    end

    context 'with header lines (#)' do
      let(:stdout) { "# branch.oid #{sha_a}\0# branch.head main\0? new.txt\0" }

      it 'skips the headers and returns only the file entries' do
        expect(result.map(&:path)).to eq(['new.txt'])
      end
    end

    context 'with paths containing spaces' do
      let(:stdout) do
        "1 .M N... 100644 100644 100644 #{sha_a} #{sha_a} dir name/file with space.txt\0" \
          "2 R. N... 100644 100644 100644 #{sha_a} #{sha_a} R100 new name.txt\0old name.txt\0" \
          "? untracked file.txt\0"
      end

      it 'keeps the whole path including its spaces' do
        expect(result.map(&:path)).to eq(['dir name/file with space.txt', 'new name.txt', 'untracked file.txt'])
        expect(result[1].original_path).to eq('old name.txt')
      end
    end

    context 'with several entries of different types' do
      let(:stdout) do
        "1 .M N... 100644 100644 100755 #{sha_a} #{sha_a} c.txt\0" \
          "1 D. N... 100644 000000 000000 #{sha_a} #{zero_sha} d.txt\0" \
          "2 R. N... 100644 100644 100644 #{sha_a} #{sha_a} R100 renamed.txt\0a.txt\0" \
          "1 A. N... 000000 100644 100644 #{zero_sha} #{sha_a} staged.txt\0" \
          "? new.txt\0" \
          "! ignored.txt\0"
      end

      it 'returns the entries in the order git listed them' do
        expect(result.map(&:path)).to eq(%w[c.txt d.txt renamed.txt staged.txt new.txt ignored.txt])
      end
    end

    context 'with a line whose entry type is not recognized' do
      let(:stdout) { "x something\0" }

      it 'raises Git::UnexpectedResultError naming the line' do
        expect { result }.to raise_error(Git::UnexpectedResultError, /x something/)
      end
    end

    context 'with an ordinary entry that has too few fields' do
      let(:stdout) { "1 .M N... 100644 100644 c.txt\0" }

      it 'raises Git::UnexpectedResultError naming the line' do
        expect { result }.to raise_error(Git::UnexpectedResultError, /1 \.M N\.\.\. 100644 100644 c\.txt/)
      end
    end

    context 'with a rename entry that has no original path token after it' do
      let(:stdout) { "2 R. N... 100644 100644 100644 #{sha_a} #{sha_a} R100 renamed.txt\0" }

      it 'raises Git::UnexpectedResultError naming the line' do
        expect { result }.to raise_error(Git::UnexpectedResultError, /renamed\.txt/)
      end
    end

    context 'with an unmerged entry that has too few fields' do
      let(:stdout) { "u UU N... 100644 100644 100755 #{sha_a} c.txt\0" }

      it 'raises Git::UnexpectedResultError naming the line' do
        expect { result }.to raise_error(Git::UnexpectedResultError, /u UU N\.\.\./)
      end
    end
  end
end
