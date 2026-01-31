# frozen_string_literal: true

require 'spec_helper'
require 'git/file_ref'

RSpec.describe Git::FileRef do
  describe '.new' do
    it 'creates an immutable value object' do
      ref = described_class.new(mode: '100644', sha: 'abc1234', path: 'lib/foo.rb')

      expect(ref.mode).to eq('100644')
      expect(ref.sha).to eq('abc1234')
      expect(ref.path).to eq('lib/foo.rb')
    end

    it 'is immutable' do
      ref = described_class.new(mode: '100644', sha: 'abc1234', path: 'lib/foo.rb')

      expect(ref).to be_frozen
    end
  end

  describe '#regular_file?' do
    it 'returns true for regular file mode (100644)' do
      ref = described_class.new(mode: '100644', sha: 'abc1234', path: 'file.rb')
      expect(ref.regular_file?).to be true
    end

    it 'returns false for executable mode (100755)' do
      ref = described_class.new(mode: '100755', sha: 'abc1234', path: 'bin/run')
      expect(ref.regular_file?).to be false
    end

    it 'returns false for symlink mode (120000)' do
      ref = described_class.new(mode: '120000', sha: 'abc1234', path: 'link')
      expect(ref.regular_file?).to be false
    end

    it 'returns false for empty mode' do
      ref = described_class.new(mode: '', sha: 'abc1234', path: 'file.rb')
      expect(ref.regular_file?).to be false
    end
  end

  describe '#executable?' do
    it 'returns true for executable mode (100755)' do
      ref = described_class.new(mode: '100755', sha: 'abc1234', path: 'bin/run')
      expect(ref.executable?).to be true
    end

    it 'returns false for regular file mode (100644)' do
      ref = described_class.new(mode: '100644', sha: 'abc1234', path: 'file.rb')
      expect(ref.executable?).to be false
    end

    it 'returns false for symlink mode (120000)' do
      ref = described_class.new(mode: '120000', sha: 'abc1234', path: 'link')
      expect(ref.executable?).to be false
    end
  end

  describe '#symlink?' do
    it 'returns true for symlink mode (120000)' do
      ref = described_class.new(mode: '120000', sha: 'abc1234', path: 'link')
      expect(ref.symlink?).to be true
    end

    it 'returns false for regular file mode (100644)' do
      ref = described_class.new(mode: '100644', sha: 'abc1234', path: 'file.rb')
      expect(ref.symlink?).to be false
    end

    it 'returns false for executable mode (100755)' do
      ref = described_class.new(mode: '100755', sha: 'abc1234', path: 'bin/run')
      expect(ref.symlink?).to be false
    end
  end

  describe '#mode_bits' do
    it 'returns mode parsed as octal integer for regular file' do
      ref = described_class.new(mode: '100644', sha: 'abc1234', path: 'file.rb')
      expect(ref.mode_bits).to eq(0o100644)
      expect(ref.mode_bits).to eq(33_188) # decimal equivalent
    end

    it 'returns mode parsed as octal integer for executable' do
      ref = described_class.new(mode: '100755', sha: 'abc1234', path: 'bin/run')
      expect(ref.mode_bits).to eq(0o100755)
    end

    it 'returns mode parsed as octal integer for symlink' do
      ref = described_class.new(mode: '120000', sha: 'abc1234', path: 'link')
      expect(ref.mode_bits).to eq(0o120000)
    end

    it 'returns 0 for empty mode' do
      ref = described_class.new(mode: '', sha: 'abc1234', path: 'file.rb')
      expect(ref.mode_bits).to eq(0)
    end

    it 'can be used for permission bit operations' do
      ref = described_class.new(mode: '100644', sha: 'abc1234', path: 'file.rb')
      expect(ref.mode_bits & 0o777).to eq(0o644)
    end

    it 'can check group writable permission' do
      regular = described_class.new(mode: '100644', sha: 'abc1234', path: 'file.rb')
      group_writable = described_class.new(mode: '100664', sha: 'abc1234', path: 'shared.rb')

      expect(regular.mode_bits & 0o020).to eq(0)
      expect(group_writable.mode_bits & 0o020).not_to eq(0)
    end
  end

  describe 'equality' do
    it 'considers two FileRefs with same attributes equal' do
      ref1 = described_class.new(mode: '100644', sha: 'abc1234', path: 'file.rb')
      ref2 = described_class.new(mode: '100644', sha: 'abc1234', path: 'file.rb')

      expect(ref1).to eq(ref2)
      expect(ref1.hash).to eq(ref2.hash)
    end

    it 'considers FileRefs with different attributes not equal' do
      ref1 = described_class.new(mode: '100644', sha: 'abc1234', path: 'file.rb')
      ref2 = described_class.new(mode: '100644', sha: 'def5678', path: 'file.rb')

      expect(ref1).not_to eq(ref2)
    end
  end
end
