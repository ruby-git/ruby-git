# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/context_helpers'

# Integration-level coverage is provided by the underlying command integration
# tests. No facade integration spec is needed for this module: the helpers are
# pure path/context manipulations with no git-command delegation.

RSpec.describe Git::Repository::ContextHelpers do
  let(:git_dir) { '/repo/.git' }
  let(:work_dir) { '/repo' }
  let(:index_file) { '/repo/.git/index' }

  let(:execution_context) do
    instance_double(
      Git::ExecutionContext::Repository,
      git_dir: git_dir,
      git_work_dir: work_dir,
      git_index_file: index_file,
      binary_path: '/usr/bin/git',
      git_ssh: nil
    )
  end

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # Shared stub: any `dup_with` call on the execution_context double returns a
  # new double reflecting the requested overrides. Individual describe blocks
  # override this for tests that require specific assertions on the rebuilt context.
  before do
    allow(execution_context).to receive(:dup_with) do |**kwargs|
      rebuilt = instance_double(
        Git::ExecutionContext::Repository,
        git_dir: kwargs.fetch(:git_dir, git_dir),
        git_work_dir: kwargs.fetch(:git_work_dir, work_dir),
        git_index_file: kwargs.fetch(:git_index_file, index_file)
      )
      allow(rebuilt).to receive(:dup_with) do |**inner|
        instance_double(
          Git::ExecutionContext::Repository,
          git_dir: inner.fetch(:git_dir, git_dir),
          git_work_dir: inner.fetch(:git_work_dir, work_dir),
          git_index_file: inner.fetch(:git_index_file, index_file)
        )
      end
      rebuilt
    end
  end

  # ---------------------------------------------------------------------------
  # #chdir
  # ---------------------------------------------------------------------------

  describe '#chdir' do
    before do
      allow(Dir).to receive(:chdir).with(work_dir).and_yield
    end

    it 'yields the dir Pathname' do
      expect { |b| described_instance.chdir(&b) }.to yield_with_args(Pathname.new(work_dir))
    end

    it 'changes the process directory to the repository working directory' do
      expect(Dir).to receive(:chdir).with(work_dir).and_yield
      described_instance.chdir { nil }
    end

    it 'returns the value returned by the block' do
      result = described_instance.chdir { 42 }
      expect(result).to eq(42)
    end

    context 'when the repository is bare (no working directory)' do
      let(:execution_context) do
        instance_double(
          Git::ExecutionContext::Repository,
          git_dir: git_dir,
          git_work_dir: nil,
          git_index_file: index_file,
          binary_path: '/usr/bin/git',
          git_ssh: nil
        )
      end

      it 'raises ArgumentError with a clear message' do
        expect { described_instance.chdir { nil } }
          .to raise_error(ArgumentError, /bare repository/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #set_index
  # ---------------------------------------------------------------------------

  describe '#set_index' do
    let(:new_context) { instance_double(Git::ExecutionContext::Repository) }

    before do
      allow(execution_context).to receive(:dup_with).and_return(new_context)
    end

    it 'rebuilds the execution context via dup_with with the new index file' do
      expect(execution_context).to receive(:dup_with).with(
        git_index_file: File.expand_path('/repo/.git/new-index')
      ).and_return(new_context)
      described_instance.set_index('/repo/.git/new-index', must_exist: false)
    end

    it 'raises ArgumentError if must_exist: true and path does not exist' do
      expect do
        described_instance.set_index('/nonexistent/index', must_exist: true)
      end.to raise_error(ArgumentError, /path does not exist/)
    end

    it 'does not raise when must_exist: false and path does not exist' do
      expect do
        described_instance.set_index('/nonexistent/index', must_exist: false)
      end.not_to raise_error
    end

    it 'raises ArgumentError when path does not exist and must_exist is not given' do
      expect do
        described_instance.set_index('/nonexistent/index')
      end.to raise_error(ArgumentError, /path does not exist/)
    end

    it 'returns nil (void)' do
      expect(described_instance.set_index('/repo/.git/new-index', must_exist: false)).to be_nil
    end

    context 'signature compatibility (legacy-contract)' do
      it 'accepts a positional check argument with a deprecation warning' do
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_index('/nonexistent/index', false) }.not_to raise_error
      end

      it 'performs existence check when both check=true and must_exist: false are given (more restrictive wins)' do
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_index('/nonexistent/index', true, must_exist: false) }
          .to raise_error(ArgumentError, /path does not exist/)
      end

      it 'raises when both check=false and must_exist: true are given (more restrictive wins)' do
        # must_exist: true | check: false → true → raises
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_index('/nonexistent/index', false, must_exist: true) }
          .to raise_error(ArgumentError, /path does not exist/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #with_index
  # ---------------------------------------------------------------------------

  describe '#with_index' do
    let(:temp_context) { instance_double(Git::ExecutionContext::Repository) }

    before do
      allow(execution_context).to receive(:dup_with).and_return(temp_context)
      allow(temp_context).to receive(:git_index_file).and_return('/tmp/idx')
    end

    it 'yields self' do
      expect { |b| described_instance.with_index('/tmp/idx', &b) }
        .to yield_with_args(described_instance)
    end

    it 'returns the value returned by the block' do
      result = described_instance.with_index('/tmp/idx') { 'hello' }
      expect(result).to eq('hello')
    end

    it 'sets the index to the new value during the block' do
      entered_index = nil
      described_instance.with_index('/tmp/idx') { entered_index = described_instance.index }
      expect(entered_index).to eq(Pathname.new('/tmp/idx'))
    end

    it 'restores the original execution context after the block' do
      original_ctx = described_instance.execution_context
      described_instance.with_index('/tmp/idx') { nil }
      expect(described_instance.execution_context).to be(original_ctx)
    end

    it 'restores the original execution context even when the block raises' do
      original_ctx = described_instance.execution_context
      expect do
        described_instance.with_index('/tmp/idx') { raise 'boom' }
      end.to raise_error('boom')
      expect(described_instance.execution_context).to be(original_ctx)
    end
  end

  # ---------------------------------------------------------------------------
  # #with_temp_index
  # ---------------------------------------------------------------------------

  describe '#with_temp_index' do
    it 'yields self' do
      expect { |b| described_instance.with_temp_index(&b) }.to yield_with_args(described_instance)
    end

    it 'sets the index to a different temporary path during the block' do
      index_during_block = nil
      described_instance.with_temp_index { index_during_block = described_instance.index }
      expect(index_during_block).not_to eq(Pathname.new(index_file))
    end

    it 'restores the original execution context after the block' do
      original_ctx = described_instance.execution_context
      described_instance.with_temp_index { nil }
      expect(described_instance.execution_context).to be(original_ctx)
    end

    it 'cleans up the temporary directory after the block succeeds' do
      temp_dir = nil
      described_instance.with_temp_index do
        temp_dir = File.dirname(described_instance.index.to_s)
        FileUtils.touch(described_instance.index.to_s)
      end
      expect(temp_dir).not_to be_nil
      expect(Dir.exist?(temp_dir)).to be(false)
    end

    it 'cleans up the temporary directory even when the block raises' do
      temp_dir = nil
      expect do
        described_instance.with_temp_index do
          temp_dir = File.dirname(described_instance.index.to_s)
          FileUtils.touch(described_instance.index.to_s)
          raise 'block error'
        end
      end.to raise_error('block error')
      expect(temp_dir).not_to be_nil
      expect(Dir.exist?(temp_dir)).to be(false)
    end
  end

  # ---------------------------------------------------------------------------
  # #set_working
  # ---------------------------------------------------------------------------

  describe '#set_working' do
    let(:new_context) { instance_double(Git::ExecutionContext::Repository) }

    before do
      allow(execution_context).to receive(:dup_with).and_return(new_context)
    end

    it 'rebuilds the execution context via dup_with with the new working directory' do
      expect(execution_context).to receive(:dup_with).with(
        git_work_dir: File.expand_path('/other/dir')
      ).and_return(new_context)
      described_instance.set_working('/other/dir', must_exist: false)
    end

    it 'raises ArgumentError if must_exist: true and path does not exist' do
      expect do
        described_instance.set_working('/nonexistent/dir', must_exist: true)
      end.to raise_error(ArgumentError, /path does not exist/)
    end

    it 'does not raise when must_exist: false and path does not exist' do
      expect do
        described_instance.set_working('/nonexistent/dir', must_exist: false)
      end.not_to raise_error
    end

    it 'raises ArgumentError when path does not exist and must_exist is not given' do
      expect do
        described_instance.set_working('/nonexistent/dir')
      end.to raise_error(ArgumentError, /path does not exist/)
    end

    it 'returns nil (void)' do
      expect(described_instance.set_working('/other/dir', must_exist: false)).to be_nil
    end

    context 'signature compatibility (legacy-contract)' do
      it 'accepts a positional check argument with a deprecation warning' do
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_working('/nonexistent/dir', false) }.not_to raise_error
      end

      it 'performs existence check when both check=true and must_exist: false are given (more restrictive wins)' do
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_working('/nonexistent/dir', true, must_exist: false) }
          .to raise_error(ArgumentError, /path does not exist/)
      end

      it 'raises when both check=false and must_exist: true are given (more restrictive wins)' do
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_working('/nonexistent/dir', false, must_exist: true) }
          .to raise_error(ArgumentError, /path does not exist/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #with_working
  # ---------------------------------------------------------------------------

  describe '#with_working' do
    let(:real_work_dir) { Dir.mktmpdir('context-helpers-') }
    let(:expanded_work_dir) { File.expand_path(real_work_dir) }

    after { FileUtils.remove_entry(real_work_dir, true) }
    let(:temp_context) do
      instance_double(Git::ExecutionContext::Repository, git_work_dir: expanded_work_dir)
    end

    before do
      allow(execution_context).to receive(:dup_with).and_return(temp_context)
      allow(Dir).to receive(:chdir).with(expanded_work_dir).and_yield
    end

    it 'yields self' do
      expect { |b| described_instance.with_working(real_work_dir, &b) }
        .to yield_with_args(described_instance)
    end

    it 'returns the value returned by the block' do
      result = described_instance.with_working(real_work_dir) { 'result' }
      expect(result).to eq('result')
    end

    it 'changes the process directory to the expanded working directory during the block' do
      expect(Dir).to receive(:chdir).with(expanded_work_dir).and_yield
      described_instance.with_working(real_work_dir) { nil }
    end

    it 'restores the original execution context after the block' do
      original_ctx = described_instance.execution_context
      described_instance.with_working(real_work_dir) { nil }
      expect(described_instance.execution_context).to be(original_ctx)
    end

    it 'restores the original execution context even when the block raises' do
      original_ctx = described_instance.execution_context
      expect do
        described_instance.with_working(real_work_dir) { raise 'boom' }
      end.to raise_error('boom')
      expect(described_instance.execution_context).to be(original_ctx)
    end

    it 'raises ArgumentError when work_dir does not exist' do
      expect do
        described_instance.with_working('/nonexistent/path/for/test')
      end.to raise_error(ArgumentError, /path does not exist/)
    end
  end

  # ---------------------------------------------------------------------------
  # #with_temp_working
  # ---------------------------------------------------------------------------

  describe '#with_temp_working' do
    before do
      allow(Dir).to receive(:chdir).and_yield
    end

    it 'yields self' do
      expect { |b| described_instance.with_temp_working(&b) }.to yield_with_args(described_instance)
    end

    it 'restores the original execution context after the block' do
      original_ctx = described_instance.execution_context
      described_instance.with_temp_working { nil }
      expect(described_instance.execution_context).to be(original_ctx)
    end

    it 'cleans up the temporary directory after the block succeeds' do
      temp_dir = nil
      described_instance.with_temp_working { temp_dir = described_instance.dir.to_s }
      expect(temp_dir).not_to be_nil
      expect(Dir.exist?(temp_dir)).to be(false)
    end

    it 'cleans up the temporary directory even when the block raises' do
      temp_dir = nil
      expect do
        described_instance.with_temp_working do
          temp_dir = described_instance.dir.to_s
          raise 'block error'
        end
      end.to raise_error('block error')
      expect(temp_dir).not_to be_nil
      expect(Dir.exist?(temp_dir)).to be(false)
    end
  end

  # ---------------------------------------------------------------------------
  # Nesting: with_index inside with_working
  # ---------------------------------------------------------------------------

  describe 'nested context helpers' do
    it 'restores the original execution context after nested with_index inside with_working' do
      original_ctx = described_instance.execution_context
      allow(Dir).to receive(:chdir).and_yield

      Dir.mktmpdir do |outer_work|
        described_instance.with_working(outer_work) do
          described_instance.with_index('/tmp/inner_idx') { nil }
        end
      end

      expect(described_instance.execution_context).to be(original_ctx)
    end
  end
end
