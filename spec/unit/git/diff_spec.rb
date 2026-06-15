# frozen_string_literal: true

require 'spec_helper'
require 'git/diff'
require 'git/repository'

RSpec.describe Git::Diff do
  let(:patch_text) do
    "diff --git a/lib/foo.rb b/lib/foo.rb\n--- a/lib/foo.rb\n+++ b/lib/foo.rb\n@@ -1 +1 @@\n-old\n+new\n"
  end

  let(:repository_base) { instance_double(Git::Repository) }

  before do
    allow(repository_base).to receive(:diff_full).and_return(patch_text)
  end

  let(:described_instance) { described_class.new(repository_base, 'HEAD~1', 'HEAD') }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores all constructor arguments as readable attributes' do
      expect(instance).to have_attributes(from: 'HEAD~1', to: 'HEAD')
    end
  end

  describe '#path' do
    subject(:result) { described_instance.path(*paths) }

    let(:paths) { [] }

    context 'when called with no arguments' do
      it 'returns self for chaining' do
        expect(result).to be(described_instance)
      end
    end

    context 'when called with a single path' do
      let(:paths) { ['lib/'] }

      it 'returns self for chaining' do
        expect(result).to be(described_instance)
      end
    end

    context 'when called with multiple paths' do
      let(:paths) { ['lib/', 'docs/'] }

      it 'returns self for chaining' do
        expect(result).to be(described_instance)
      end
    end

    context 'when an Array is passed as an argument' do
      let(:paths) { [['lib/', 'docs/']] }

      it 'raises ArgumentError explaining splatted argument usage' do
        expect { result }.to raise_error(ArgumentError, /path expects individual arguments/)
      end
    end
  end

  describe '#patch' do
    subject(:result) { described_class.new(repository_base, 'HEAD~1', 'HEAD').patch }

    it 'calls diff_full with from, to, and path_limiter: nil' do
      expect(repository_base).to receive(:diff_full)
        .with('HEAD~1', 'HEAD', path_limiter: nil)
        .and_return(patch_text)
      result
    end

    it 'returns the patch text' do
      expect(result).to eq(patch_text)
    end

    context 'when a path filter has been set' do
      it 'forwards the path to diff_full as path_limiter' do
        expect(repository_base).to receive(:diff_full)
          .with('HEAD~1', 'HEAD', path_limiter: 'lib/')
          .and_return(patch_text)
        described_class.new(repository_base, 'HEAD~1', 'HEAD').path('lib/').patch
      end
    end

    context 'when obj2 is nil' do
      it 'passes nil as the second positional argument to diff_full' do
        expect(repository_base).to receive(:diff_full)
          .with('HEAD', nil, path_limiter: nil)
          .and_return(patch_text)
        described_class.new(repository_base, 'HEAD', nil).patch
      end
    end
  end

  describe '#to_s' do
    subject(:result) { described_instance.to_s }

    it 'is an alias for patch' do
      expect(result).to eq(patch_text)
    end
  end
end
