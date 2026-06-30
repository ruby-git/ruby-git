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
      let(:base) { instance_double(Git::Repository) }

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
    end
  end
end
