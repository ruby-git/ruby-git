# frozen_string_literal: true

require 'spec_helper'
require 'git/status'
require 'git/repository'

RSpec.describe Git::Status do
  let(:base)               { instance_double(Git::Repository) }
  let(:factory)            { instance_double(Git::Status::StatusFileFactory, construct_files: files) }
  let(:files)              { {} }
  let(:described_instance) { described_class.new(base) }

  before do
    allow(Git::Status::StatusFileFactory).to receive(:new).with(base).and_return(factory)
  end

  describe '#added' do
    subject(:result) { described_instance.added }

    context 'when newly staged files exist alongside modified files' do
      let(:added_file)    { instance_double(Git::Status::StatusFile, type: 'A', untracked: nil) }
      let(:modified_file) { instance_double(Git::Status::StatusFile, type: 'M', untracked: nil) }
      let(:files) { { 'file3.rb' => added_file, 'file2.rb' => modified_file } }

      it 'returns only files with type A' do
        expect(result.keys).to eq(['file3.rb'])
      end
    end

    context 'when staged files include dotfiles' do
      let(:dotfile)      { instance_double(Git::Status::StatusFile, type: 'A', untracked: nil) }
      let(:regular_file) { instance_double(Git::Status::StatusFile, type: 'A', untracked: nil) }
      let(:files) { { '.dotfile' => dotfile, 'regular.rb' => regular_file } }

      it 'includes dotfile paths in the result' do
        expect(result.keys).to include('.dotfile')
      end
    end

    context 'when all staged files have type nil (no-commit repo without diff_index data)' do
      let(:staged_file) { instance_double(Git::Status::StatusFile, type: nil, untracked: nil) }
      let(:files) { { 'file1.rb' => staged_file } }

      it 'returns an empty hash' do
        expect(result).to eq({})
      end
    end

    context 'when file paths contain multibyte characters' do
      let(:multibyte_path) { "\u30DE\u30EB\u30C1_added.txt" }
      let(:multibyte_file) { instance_double(Git::Status::StatusFile, type: 'A', untracked: nil) }
      let(:files) { { multibyte_path => multibyte_file } }

      it 'preserves multibyte path keys in the result' do
        expect(result.keys).to eq([multibyte_path])
      end
    end
  end

  describe '#changed' do
    subject(:result) { described_instance.changed }

    context 'when modified files exist' do
      let(:modified_file) { instance_double(Git::Status::StatusFile, type: 'M', untracked: nil) }
      let(:added_file)    { instance_double(Git::Status::StatusFile, type: 'A', untracked: nil) }
      let(:files) { { 'modified.rb' => modified_file, 'added.rb' => added_file } }

      it 'returns only files with type M' do
        expect(result.keys).to eq(['modified.rb'])
      end
    end

    context 'when file paths contain multibyte characters' do
      let(:multibyte_path) { "\u30DE\u30EB\u30C1_changed.txt" }
      let(:multibyte_file) { instance_double(Git::Status::StatusFile, type: 'M', untracked: nil) }
      let(:files) { { multibyte_path => multibyte_file } }

      it 'preserves multibyte path keys in the result' do
        expect(result.keys).to eq([multibyte_path])
      end
    end
  end

  describe '#deleted' do
    subject(:result) { described_instance.deleted }

    context 'when deleted files exist' do
      let(:deleted_file)  { instance_double(Git::Status::StatusFile, type: 'D', untracked: nil) }
      let(:modified_file) { instance_double(Git::Status::StatusFile, type: 'M', untracked: nil) }
      let(:files) { { 'deleted.rb' => deleted_file, 'modified.rb' => modified_file } }

      it 'returns only files with type D' do
        expect(result.keys).to eq(['deleted.rb'])
      end
    end

    context 'when file paths contain multibyte characters' do
      let(:multibyte_path) { "\u30DE\u30EB\u30C1_deleted.txt" }
      let(:multibyte_file) { instance_double(Git::Status::StatusFile, type: 'D', untracked: nil) }
      let(:files) { { multibyte_path => multibyte_file } }

      it 'preserves multibyte path keys in the result' do
        expect(result.keys).to eq([multibyte_path])
      end
    end
  end

  describe '#untracked' do
    subject(:result) { described_instance.untracked }

    context 'when untracked files exist alongside tracked files' do
      let(:untracked_root)   { instance_double(Git::Status::StatusFile, type: nil, untracked: true) }
      let(:untracked_subdir) { instance_double(Git::Status::StatusFile, type: nil, untracked: true) }
      let(:tracked_file)     { instance_double(Git::Status::StatusFile, type: nil, untracked: nil) }
      let(:files) do
        {
          'file2.rb' => untracked_root,
          'subdir/file4.rb' => untracked_subdir,
          'file1.rb' => tracked_file
        }
      end

      it 'returns only the untracked files' do
        expect(result.keys).to contain_exactly('file2.rb', 'subdir/file4.rb')
      end
    end

    context 'when all files are tracked' do
      let(:tracked_file) { instance_double(Git::Status::StatusFile, type: nil, untracked: nil) }
      let(:files) { { 'file1.rb' => tracked_file } }

      it 'returns an empty hash' do
        expect(result).to eq({})
      end
    end

    context 'when file paths contain multibyte characters' do
      let(:multibyte_path) { "\u30DE\u30EB\u30C1_untracked.txt" }
      let(:multibyte_file) { instance_double(Git::Status::StatusFile, type: nil, untracked: true) }
      let(:files) { { multibyte_path => multibyte_file } }

      it 'preserves multibyte path keys in the result' do
        expect(result.keys).to eq([multibyte_path])
      end
    end
  end

  describe '#pretty' do
    subject(:result) { described_instance.pretty }

    let(:sha_index)   { 'e76778b73006b0dda0dd56e9257c5bf6b6dd3373' }
    let(:status_file) do
      instance_double(
        Git::Status::StatusFile,
        path: 'lib/foo.rb',
        sha_repo: nil,
        mode_repo: nil,
        sha_index: sha_index,
        mode_index: '100644',
        type: nil,
        stage: '0',
        untracked: nil
      )
    end
    let(:files) { { 'lib/foo.rb' => status_file } }

    it 'formats each file as a multi-line indented block with path, sha, mode, type, stage, and untracked' do
      expect(result).to eq(
        "lib/foo.rb\n\tsha(r)  \n\tsha(i) #{sha_index} 100644\n\ttype   \n\tstage  0\n\tuntrac \n\n"
      )
    end
  end
end

RSpec.describe Git::Status::StatusFile do
  let(:base) { instance_double(Git::Repository) }
  let(:sha)  { 'abc1234567890abcdef1234567890abcdef1234' }
  let(:described_instance) do
    described_class.new(base, { path: 'foo.rb', sha_index: sha, sha_repo: sha })
  end

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores all constructor arguments as readable attributes' do
      instance_with_all = described_class.new(
        base,
        path: 'lib/foo.rb', type: 'M', stage: '0',
        mode_index: '100644', mode_repo: '100644',
        sha_index: sha, sha_repo: sha, untracked: nil
      )
      expect(instance_with_all).to have_attributes(
        path: 'lib/foo.rb', type: 'M', stage: '0',
        mode_index: '100644', mode_repo: '100644',
        sha_index: sha, sha_repo: sha, untracked: nil
      )
    end
  end

  describe '#blob' do
    subject(:result) { described_instance.blob }

    context 'when type is :index (default) and sha_index is set' do
      it 'returns the blob for sha_index' do
        blob = instance_double(Git::Object::Blob)
        expect(base).to receive(:object).with(sha).and_return(blob)
        expect(result).to eq(blob)
      end
    end

    context 'when type is :repo' do
      subject(:result) { described_instance.blob(:repo) }

      it 'returns the blob for sha_repo' do
        blob = instance_double(Git::Object::Blob)
        expect(base).to receive(:object).with(sha).and_return(blob)
        expect(result).to eq(blob)
      end
    end

    context 'when sha_index is nil and sha_repo is set' do
      let(:described_instance) do
        described_class.new(base, { path: 'foo.rb', sha_index: nil, sha_repo: sha })
      end

      it 'falls back to sha_repo' do
        blob = instance_double(Git::Object::Blob)
        expect(base).to receive(:object).with(sha).and_return(blob)
        expect(result).to eq(blob)
      end
    end

    context 'when both sha_index and sha_repo are nil' do
      let(:described_instance) do
        described_class.new(base, { path: 'foo.rb', sha_index: nil, sha_repo: nil })
      end

      it 'returns nil without calling base.object' do
        expect(base).not_to receive(:object)
        expect(result).to be_nil
      end
    end
  end
end

RSpec.describe Git::Status::StatusFileFactory do
  describe '#construct_files' do
    subject(:result) { described_class.new(base).construct_files }

    context 'when base is a Git::Repository' do
      let(:base)        { instance_double(Git::Repository) }
      let(:sha1)        { '1111111111111111111111111111111111111111' }
      let(:sha2)        { '2222222222222222222222222222222222222222' }
      let(:sha1_staged) { '3333333333333333333333333333333333333333' }
      let(:zeros_sha)   { '0000000000000000000000000000000000000000' }

      before do
        allow(base).to receive(:ls_files).and_return({})
        allow(base).to receive(:untracked_files).and_return([])
        allow(base).to receive(:diff_files).and_return({})
        allow(base).to receive(:diff_index).and_return({})
      end

      context 'when no_commits? returns true (repository has no commits)' do
        before do
          allow(base).to receive(:no_commits?).and_return(true)
        end

        it 'does not call diff_index' do
          # not_to receive overrides the outer allow for this example
          expect(base).not_to receive(:diff_index)
          result
        end

        it 'returns an empty hash when no files are present' do
          expect(result).to eq({})
        end
      end

      context 'when no_commits? returns false (repository has commits)' do
        before do
          allow(base).to receive(:no_commits?).and_return(false)
          # Override outer allow to verify HEAD is passed
          allow(base).to receive(:diff_index).with('HEAD').and_return({})
        end

        it 'calls diff_index with HEAD' do
          expect(base).to receive(:diff_index).with('HEAD').and_return({})
          result
        end

        it 'returns an empty hash when all data is empty' do
          expect(result).to eq({})
        end
      end

      context 'when provider methods return non-empty data and no_commits? is false' do
        let(:sha_index) { 'aaaa1234567890abcdef1234567890abcdef1234' }
        let(:sha_repo)  { 'bbbb1234567890abcdef1234567890abcdef1234' }

        before do
          allow(base).to receive(:ls_files).and_return(
            'a.rb' => { path: 'a.rb', mode_index: '100644', sha_index: sha_index, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return(['new.rb'])
          allow(base).to receive(:diff_files).and_return(
            'a.rb' => { path: 'a.rb', type: 'M', mode_index: '100644', mode_repo: '100644',
                        sha_index: sha_index, sha_repo: sha_repo }
          )
          allow(base).to receive(:no_commits?).and_return(false)
          allow(base).to receive(:diff_index).with('HEAD').and_return(
            'b.rb' => { path: 'b.rb', type: 'A', mode_index: '100644', mode_repo: '000000',
                        sha_index: sha_repo, sha_repo: nil }
          )
        end

        it 'returns a hash whose values are all StatusFile instances' do
          expect(result.values).to all(be_a(Git::Status::StatusFile))
        end

        it 'includes the untracked file with untracked: true' do
          expect(result['new.rb']).to be_a(Git::Status::StatusFile)
          expect(result['new.rb'].untracked).to be(true)
        end

        it 'merges diff_files data into files from ls_files' do
          expect(result['a.rb'].type).to eq('M')
        end

        it 'merges diff_index data for files not already in ls_files' do
          expect(result['b.rb']).to be_a(Git::Status::StatusFile)
          expect(result['b.rb'].type).to eq('A')
        end
      end

      context 'when no diffs exist (clean working tree with committed files)' do
        before do
          allow(base).to receive(:ls_files).and_return(
            'file1' => { path: 'file1', mode_index: '100644', sha_index: sha1, stage: '0' },
            'file2' => { path: 'file2', mode_index: '100755', sha_index: sha2, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return([])
          allow(base).to receive(:diff_files).and_return({})
          allow(base).to receive(:no_commits?).and_return(false)
          allow(base).to receive(:diff_index).with('HEAD').and_return({})
        end

        it 'preserves ls_files attributes with nil type and nil diff fields' do
          expect(result['file1']).to have_attributes(
            path: 'file1', type: nil, stage: '0', untracked: nil,
            mode_index: '100644', sha_index: sha1, mode_repo: nil, sha_repo: nil
          )
          expect(result['file2']).to have_attributes(
            path: 'file2', type: nil, stage: '0', untracked: nil,
            mode_index: '100755', sha_index: sha2, mode_repo: nil, sha_repo: nil
          )
        end
      end

      context 'when diff_files reports a tracked file deleted from the working tree' do
        before do
          allow(base).to receive(:ls_files).and_return(
            'file1' => { path: 'file1', mode_index: '100644', sha_index: sha1, stage: '0' },
            'file2' => { path: 'file2', mode_index: '100755', sha_index: sha2, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return([])
          allow(base).to receive(:diff_files).and_return(
            'file1' => { path: 'file1', type: 'D', mode_index: '000000', mode_repo: '100644',
                         sha_index: zeros_sha, sha_repo: sha1 }
          )
          allow(base).to receive(:no_commits?).and_return(false)
          allow(base).to receive(:diff_index).with('HEAD').and_return(
            'file1' => { path: 'file1', type: 'D', mode_index: '000000', mode_repo: '100644',
                         sha_index: zeros_sha, sha_repo: sha1 }
          )
        end

        it 'sets type to D and zeros out the index mode and sha for the deleted file' do
          expect(result['file1']).to have_attributes(
            type: 'D', mode_index: '000000', sha_index: zeros_sha,
            mode_repo: '100644', sha_repo: sha1, stage: '0'
          )
        end

        it 'does not affect other tracked files' do
          expect(result['file2']).to have_attributes(type: nil, mode_index: '100755', sha_index: sha2)
        end
      end

      context 'when diff_index introduces a deleted file not present in ls_files (git rm)' do
        before do
          allow(base).to receive(:ls_files).and_return(
            'file2' => { path: 'file2', mode_index: '100755', sha_index: sha2, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return([])
          allow(base).to receive(:diff_files).and_return({})
          allow(base).to receive(:no_commits?).and_return(false)
          allow(base).to receive(:diff_index).with('HEAD').and_return(
            'file1' => { path: 'file1', type: 'D', mode_index: '000000', mode_repo: '100644',
                         sha_index: zeros_sha, sha_repo: sha1 }
          )
        end

        it 'adds the deleted file from diff_index with type D and nil stage' do
          expect(result['file1']).to have_attributes(
            type: 'D', mode_index: '000000', sha_index: zeros_sha,
            mode_repo: '100644', sha_repo: sha1, stage: nil
          )
        end
      end

      context 'when a file appears in both untracked_files and diff_index (git rm + worktree recreate)' do
        before do
          allow(base).to receive(:ls_files).and_return(
            'file2' => { path: 'file2', mode_index: '100755', sha_index: sha2, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return(['file1'])
          allow(base).to receive(:diff_files).and_return({})
          allow(base).to receive(:no_commits?).and_return(false)
          allow(base).to receive(:diff_index).with('HEAD').and_return(
            'file1' => { path: 'file1', type: 'D', mode_index: '000000', mode_repo: '100644',
                         sha_index: zeros_sha, sha_repo: sha1 }
          )
        end

        it 'preserves untracked: true while merging type and mode/sha from diff_index' do
          expect(result['file1']).to have_attributes(
            untracked: true, type: 'D', mode_index: '000000',
            sha_index: zeros_sha, mode_repo: '100644', sha_repo: sha1
          )
        end
      end

      context 'when a file is modified in the working tree but not staged' do
        before do
          allow(base).to receive(:ls_files).and_return(
            'file1' => { path: 'file1', mode_index: '100644', sha_index: sha1, stage: '0' },
            'file2' => { path: 'file2', mode_index: '100755', sha_index: sha2, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return([])
          allow(base).to receive(:diff_files).and_return(
            'file1' => { path: 'file1', type: 'M', mode_index: '100644', mode_repo: '100644',
                         sha_index: zeros_sha, sha_repo: sha1 }
          )
          allow(base).to receive(:no_commits?).and_return(false)
          allow(base).to receive(:diff_index).with('HEAD').and_return(
            'file1' => { path: 'file1', type: 'M', mode_index: '100644', mode_repo: '100644',
                         sha_index: zeros_sha, sha_repo: sha1 }
          )
        end

        it 'sets type to M and replaces sha_index with zeros from diff data' do
          expect(result['file1']).to have_attributes(
            type: 'M', mode_index: '100644', sha_index: zeros_sha,
            mode_repo: '100644', sha_repo: sha1, stage: '0'
          )
        end
      end

      context 'when a working tree modification is staged (diff_files empty, diff_index has M)' do
        before do
          allow(base).to receive(:ls_files).and_return(
            'file1' => { path: 'file1', mode_index: '100644', sha_index: sha1_staged, stage: '0' },
            'file2' => { path: 'file2', mode_index: '100755', sha_index: sha2, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return([])
          allow(base).to receive(:diff_files).and_return({})
          allow(base).to receive(:no_commits?).and_return(false)
          allow(base).to receive(:diff_index).with('HEAD').and_return(
            'file1' => { path: 'file1', type: 'M', mode_index: '100644', mode_repo: '100644',
                         sha_index: sha1_staged, sha_repo: sha1 }
          )
        end

        it 'sets type to M, preserves the staged sha_index, and adds sha_repo from HEAD' do
          expect(result['file1']).to have_attributes(
            type: 'M', stage: '0', mode_index: '100644', sha_index: sha1_staged,
            mode_repo: '100644', sha_repo: sha1
          )
        end
      end

      context 'when a staged modification is further modified in the working tree' do
        before do
          allow(base).to receive(:ls_files).and_return(
            'file1' => { path: 'file1', mode_index: '100644', sha_index: sha1_staged, stage: '0' },
            'file2' => { path: 'file2', mode_index: '100755', sha_index: sha2, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return([])
          # diff_files: index vs worktree shows file1 modified again (sha_repo is staged sha)
          allow(base).to receive(:diff_files).and_return(
            'file1' => { path: 'file1', type: 'M', mode_index: '100644', mode_repo: '100644',
                         sha_index: zeros_sha, sha_repo: sha1_staged }
          )
          allow(base).to receive(:no_commits?).and_return(false)
          # diff_index: HEAD vs worktree shows file1 modified (sha_repo is HEAD sha)
          allow(base).to receive(:diff_index).with('HEAD').and_return(
            'file1' => { path: 'file1', type: 'M', mode_index: '100644', mode_repo: '100644',
                         sha_index: zeros_sha, sha_repo: sha1 }
          )
        end

        it 'uses sha_repo from diff_index (applied last), overwriting the diff_files sha_repo' do
          expect(result['file1']).to have_attributes(
            type: 'M', sha_index: zeros_sha, mode_repo: '100644', sha_repo: sha1
          )
        end
      end

      context 'when a staged modification is deleted from the working tree' do
        before do
          allow(base).to receive(:ls_files).and_return(
            'file1' => { path: 'file1', mode_index: '100644', sha_index: sha1_staged, stage: '0' },
            'file2' => { path: 'file2', mode_index: '100755', sha_index: sha2, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return([])
          # diff_files: index vs worktree — worktree deleted; sha_repo is the staged sha
          allow(base).to receive(:diff_files).and_return(
            'file1' => { path: 'file1', type: 'D', mode_index: '000000', mode_repo: '100644',
                         sha_index: zeros_sha, sha_repo: sha1_staged }
          )
          allow(base).to receive(:no_commits?).and_return(false)
          # diff_index: HEAD vs worktree — worktree deleted; sha_repo is the HEAD sha
          allow(base).to receive(:diff_index).with('HEAD').and_return(
            'file1' => { path: 'file1', type: 'D', mode_index: '000000', mode_repo: '100644',
                         sha_index: zeros_sha, sha_repo: sha1 }
          )
        end

        it 'sets type to D and uses sha_repo from diff_index (HEAD sha), overwriting diff_files sha_repo' do
          expect(result['file1']).to have_attributes(
            type: 'D', mode_index: '000000', sha_index: zeros_sha,
            mode_repo: '100644', sha_repo: sha1, stage: '0'
          )
        end
      end

      context 'when a new untracked file is added to the working tree only' do
        before do
          allow(base).to receive(:ls_files).and_return(
            'file1' => { path: 'file1', mode_index: '100644', sha_index: sha1, stage: '0' },
            'file2' => { path: 'file2', mode_index: '100755', sha_index: sha2, stage: '0' }
          )
          allow(base).to receive(:untracked_files).and_return(['file3'])
          allow(base).to receive(:diff_files).and_return({})
          allow(base).to receive(:no_commits?).and_return(false)
          allow(base).to receive(:diff_index).with('HEAD').and_return({})
        end

        it 'adds the untracked file with the correct path, untracked: true and nil mode/sha/type/stage' do
          expect(result['file3']).to have_attributes(
            path: 'file3', type: nil, stage: nil, untracked: true,
            mode_index: nil, sha_index: nil, mode_repo: nil, sha_repo: nil
          )
        end

        it 'preserves existing tracked files alongside the new untracked file' do
          expect(result.size).to eq(3)
          expect(result['file1']).to have_attributes(type: nil, sha_index: sha1)
          expect(result['file2']).to have_attributes(type: nil, sha_index: sha2)
        end
      end
    end
  end
end
