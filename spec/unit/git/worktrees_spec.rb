# frozen_string_literal: true

require 'spec_helper'
require 'git/worktrees'

RSpec.describe Git::Worktrees do
  # ---------------------------------------------------------------------------
  # Shared setup — always a Git::Repository so worktrees_all can be stubbed
  # ---------------------------------------------------------------------------

  let(:wt_main)   { instance_double(Git::Worktree, to_s: '/repo',        full: '/repo abc123') }
  let(:wt_linked) { instance_double(Git::Worktree, to_s: '/repo/linked', full: '/repo/linked def456') }

  # Named repo_base (not base) so #initialize contexts can define their own base
  # without interfering with these top-level stubs.
  let(:repo_base) { instance_double(Git::Repository) }
  let(:described_instance) { described_class.new(repo_base) }

  before do
    allow(repo_base).to receive(:is_a?).with(Git::Base).and_return(false)
    allow(repo_base).to receive(:worktrees_all).and_return([
                                                             ['/repo',        'abc123'],
                                                             ['/repo/linked', 'def456']
                                                           ])
    allow(Git::Worktree).to receive(:new).with(repo_base, '/repo',        'abc123').and_return(wt_main)
    allow(Git::Worktree).to receive(:new).with(repo_base, '/repo/linked', 'def456').and_return(wt_linked)
  end

  # ---------------------------------------------------------------------------
  # #initialize
  # ---------------------------------------------------------------------------

  describe '#initialize' do
    context 'when base is a Git::Repository (new form)' do
      let(:base) { instance_double(Git::Repository) }

      before do
        allow(base).to receive(:is_a?).with(Git::Base).and_return(false)
        allow(base).to receive(:worktrees_all).and_return([
                                                            ['/repo',        'abc123'],
                                                            ['/repo/linked', 'def456']
                                                          ])
        allow(Git::Worktree).to receive(:new).with(base, '/repo',        'abc123').and_return(wt_main)
        allow(Git::Worktree).to receive(:new).with(base, '/repo/linked', 'def456').and_return(wt_linked)
      end

      it 'calls worktrees_all on base directly' do
        expect(base).to receive(:worktrees_all).and_return([])
        described_class.new(base)
      end

      it 'builds Git::Worktree children with the original base' do
        expect(Git::Worktree).to receive(:new).with(base, '/repo',        'abc123').and_return(wt_main)
        expect(Git::Worktree).to receive(:new).with(base, '/repo/linked', 'def456').and_return(wt_linked)
        described_class.new(base)
      end

      it 'populates the collection with both worktrees' do
        expect(described_class.new(base).size).to eq(2)
      end
    end

    context 'when base is a Git::Base (legacy form)' do
      let(:facade_repo) { instance_double(Git::Repository) }
      let(:base)        { instance_double(Git::Base) }

      before do
        allow(base).to receive(:is_a?).with(Git::Base).and_return(true)
        allow(base).to receive(:facade_repository).and_return(facade_repo)
        allow(facade_repo).to receive(:worktrees_all).and_return([
                                                                   ['/repo',        'abc123'],
                                                                   ['/repo/linked', 'def456']
                                                                 ])
        allow(Git::Worktree).to receive(:new).with(base, '/repo',        'abc123').and_return(wt_main)
        allow(Git::Worktree).to receive(:new).with(base, '/repo/linked', 'def456').and_return(wt_linked)
      end

      it 'resolves facade_repository and calls worktrees_all on it' do
        expect(facade_repo).to receive(:worktrees_all).and_return([])
        described_class.new(base)
      end

      it 'passes the original base (not facade_repo) to Git::Worktree children' do
        expect(Git::Worktree).to receive(:new).with(base, '/repo',        'abc123').and_return(wt_main)
        expect(Git::Worktree).to receive(:new).with(base, '/repo/linked', 'def456').and_return(wt_linked)
        described_class.new(base)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #size
  # ---------------------------------------------------------------------------

  describe '#size' do
    subject(:result) { described_instance.size }

    it 'returns the number of worktrees in the collection' do
      expect(result).to eq(2)
    end
  end

  # ---------------------------------------------------------------------------
  # #each
  # ---------------------------------------------------------------------------

  describe '#each' do
    subject(:result) { described_instance.each }

    it 'returns an Enumerator when called without a block' do
      expect(result).to be_an(Enumerator)
    end

    it 'yields each worktree in insertion order' do
      expect(result.to_a).to eq([wt_main, wt_linked])
    end
  end

  # ---------------------------------------------------------------------------
  # #[]
  # ---------------------------------------------------------------------------

  describe '#[]' do
    subject(:result) { described_instance[worktree_name] }

    let(:worktree_name) { '/repo' }

    context 'when looked up by directory path' do
      it 'returns the main worktree' do
        expect(result).to eq(wt_main)
      end

      context 'with the linked worktree path' do
        let(:worktree_name) { '/repo/linked' }

        it 'returns the linked worktree' do
          expect(result).to eq(wt_linked)
        end
      end
    end

    context 'when looked up by full descriptor (path + commitish)' do
      let(:worktree_name) { '/repo abc123' }

      it 'returns the main worktree via lazy aliasing on its full descriptor' do
        expect(result).to eq(wt_main)
      end
    end

    context 'when the key does not match any worktree' do
      let(:worktree_name) { '/nonexistent' }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #to_s
  # ---------------------------------------------------------------------------

  describe '#to_s' do
    subject(:result) { described_instance.to_s }

    it 'returns a newline-terminated string of worktree descriptors' do
      expect(result).to eq("/repo\n/repo/linked\n")
    end
  end

  # ---------------------------------------------------------------------------
  # #prune
  # ---------------------------------------------------------------------------

  describe '#prune' do
    context 'when base is a Git::Repository (new form)' do
      it 'calls worktree_prune on base directly' do
        expect(repo_base).to receive(:worktree_prune).and_return('')
        described_instance.prune
      end

      it 'returns the result from worktree_prune' do
        allow(repo_base).to receive(:worktree_prune).and_return('pruned output')
        expect(described_instance.prune).to eq('pruned output')
      end
    end

    context 'when base is a Git::Base (legacy form)' do
      subject(:collection) { described_class.new(base) }

      let(:facade_repo) { instance_double(Git::Repository) }
      let(:base)        { instance_double(Git::Base) }

      before do
        allow(base).to receive(:is_a?).with(Git::Base).and_return(true)
        allow(base).to receive(:facade_repository).and_return(facade_repo)
        allow(facade_repo).to receive(:worktrees_all).and_return([])
        allow(Git::Worktree).to receive(:new)
      end

      it 'resolves facade_repository and calls worktree_prune on it' do
        expect(facade_repo).to receive(:worktree_prune).and_return('')
        collection.prune
      end
    end
  end
end
