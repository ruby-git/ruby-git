# frozen_string_literal: true

require 'spec_helper'
require 'git/worktree'

RSpec.describe Git::Worktree do
  # ---------------------------------------------------------------------------
  # Shared setup
  # ---------------------------------------------------------------------------

  let(:base) { instance_double(Git::Repository) }
  let(:dir)  { '/path/to/wt' }

  before do
    allow(base).to receive(:is_a?).with(Git::Base).and_return(false)
  end

  # ---------------------------------------------------------------------------
  # #initialize
  # ---------------------------------------------------------------------------

  describe '#initialize' do
    subject(:instance) { described_class.new(base, dir, gcommit) }

    let(:gcommit) { nil }

    context 'when gcommit is nil' do
      it 'sets both full and dir to the path' do
        expect(instance).to have_attributes(full: dir, dir: dir)
      end
    end

    context 'when gcommit is non-nil' do
      let(:gcommit) { 'abc123' }

      it 'sets full to "dir gcommit" and dir to the path' do
        expect(instance).to have_attributes(full: "#{dir} #{gcommit}", dir: dir)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #gcommit
  # ---------------------------------------------------------------------------

  describe '#gcommit' do
    subject(:result) { wt.gcommit }

    let(:gcommit) { nil }
    let(:wt) { described_class.new(base, dir, gcommit) }

    context 'when no gcommit was given at construction (nil)' do
      let(:commit_object) { instance_double(Git::Object::Commit) }

      before do
        allow(base).to receive(:gcommit).with(dir).and_return(commit_object)
      end

      it 'calls base.gcommit with the full descriptor' do
        expect(base).to receive(:gcommit).with(dir)
        wt.gcommit
      end

      it 'returns the result from base.gcommit' do
        expect(result).to eq(commit_object)
      end

      it 'memoizes the result so base.gcommit is not called on subsequent calls' do
        wt.gcommit
        expect(base).not_to receive(:gcommit)
        wt.gcommit
      end
    end

    context 'when a gcommit was given at construction' do
      let(:gcommit) { 'abc123' }

      it 'returns the pre-set gcommit' do
        expect(result).to eq(gcommit)
      end

      it 'does not call base.gcommit' do
        expect(base).not_to receive(:gcommit)
        wt.gcommit
      end
    end

    context 'when base is a Git::Base (legacy form) and no gcommit was given' do
      let(:facade_repo) { instance_double(Git::Repository) }
      let(:base) { instance_double(Git::Base) }
      let(:commit_object) { instance_double(Git::Object::Commit) }

      before do
        allow(base).to receive(:is_a?).with(Git::Base).and_return(true)
        allow(base).to receive(:facade_repository).and_return(facade_repo)
        allow(facade_repo).to receive(:gcommit).with(dir).and_return(commit_object)
      end

      it 'resolves facade_repository and calls gcommit on it with the full descriptor' do
        expect(facade_repo).to receive(:gcommit).with(dir)
        wt.gcommit
      end

      it 'returns the result from facade_repository.gcommit' do
        expect(result).to eq(commit_object)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #add
  # ---------------------------------------------------------------------------

  describe '#add' do
    let(:gcommit) { nil }
    let(:wt) { described_class.new(base, dir, gcommit) }

    context 'when base is a Git::Repository (new form)' do
      context 'when gcommit is nil' do
        it 'calls worktree_add on base directly with dir and nil' do
          expect(base).to receive(:worktree_add).with(dir, nil).and_return('output')
          wt.add
        end
      end

      context 'when gcommit is set' do
        let(:gcommit) { 'main' }

        it 'calls worktree_add on base directly with dir and the gcommit' do
          expect(base).to receive(:worktree_add).with(dir, gcommit).and_return('output')
          wt.add
        end
      end
    end

    context 'when base is a Git::Base (legacy form)' do
      let(:facade_repo) { instance_double(Git::Repository) }
      let(:base) { instance_double(Git::Base) }

      before do
        allow(base).to receive(:is_a?).with(Git::Base).and_return(true)
        allow(base).to receive(:facade_repository).and_return(facade_repo)
      end

      context 'when gcommit is nil' do
        it 'resolves facade_repository and calls worktree_add on it with dir and nil' do
          expect(facade_repo).to receive(:worktree_add).with(dir, nil).and_return('output')
          wt.add
        end
      end

      context 'when gcommit is set' do
        let(:gcommit) { 'main' }

        it 'resolves facade_repository and calls worktree_add on it with dir and gcommit' do
          expect(facade_repo).to receive(:worktree_add).with(dir, gcommit).and_return('output')
          wt.add
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #remove
  # ---------------------------------------------------------------------------

  describe '#remove' do
    let(:wt) { described_class.new(base, dir) }

    context 'when base is a Git::Repository (new form)' do
      it 'calls worktree_remove on base directly with dir' do
        expect(base).to receive(:worktree_remove).with(dir).and_return('')
        wt.remove
      end
    end

    context 'when base is a Git::Base (legacy form)' do
      let(:facade_repo) { instance_double(Git::Repository) }
      let(:base) { instance_double(Git::Base) }

      before do
        allow(base).to receive(:is_a?).with(Git::Base).and_return(true)
        allow(base).to receive(:facade_repository).and_return(facade_repo)
      end

      it 'resolves facade_repository and calls worktree_remove on it with dir' do
        expect(facade_repo).to receive(:worktree_remove).with(dir).and_return('')
        wt.remove
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #to_a
  # ---------------------------------------------------------------------------

  describe '#to_a' do
    subject(:result) { wt.to_a }

    let(:wt) { described_class.new(base, dir, gcommit) }
    let(:gcommit) { nil }

    it 'returns an array containing just the dir' do
      expect(result).to eq([dir])
    end

    context 'when gcommit is set' do
      let(:gcommit) { 'abc123' }

      it 'returns an array containing the full descriptor with gcommit appended' do
        expect(result).to eq(["#{dir} #{gcommit}"])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #to_s
  # ---------------------------------------------------------------------------

  describe '#to_s' do
    subject(:result) { wt.to_s }

    let(:wt) { described_class.new(base, dir, gcommit) }
    let(:gcommit) { nil }

    it 'returns the dir as the full descriptor' do
      expect(result).to eq(dir)
    end

    context 'when gcommit is set' do
      let(:gcommit) { 'abc123' }

      it 'returns "dir gcommit" as the full descriptor' do
        expect(result).to eq("#{dir} #{gcommit}")
      end
    end
  end
end
