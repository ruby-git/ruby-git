# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Git::VERSION' do
  it 'is a semantic version string' do
    expect(Git::VERSION).to be_a(String)
    expect(Git::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end
end

RSpec.describe Git::Version do
  describe '.new' do
    it 'creates a version with major, minor, and patch components' do
      version = described_class.new(2, 42, 1)

      expect(version.major).to eq(2)
      expect(version.minor).to eq(42)
      expect(version.patch).to eq(1)
    end
  end

  describe '.parse' do
    context 'with a standard version string' do
      it 'parses "2.42.1"' do
        version = described_class.parse('2.42.1')

        expect(version).to eq(described_class.new(2, 42, 1))
      end

      it 'parses "2.28.0"' do
        version = described_class.parse('2.28.0')

        expect(version).to eq(described_class.new(2, 28, 0))
      end
    end

    context 'with git version command output' do
      it 'parses "git version 2.42.1"' do
        version = described_class.parse('git version 2.42.1')

        expect(version).to eq(described_class.new(2, 42, 1))
      end

      it 'parses "git version 2.39.2 (Apple Git-143)"' do
        version = described_class.parse('git version 2.39.2 (Apple Git-143)')

        expect(version).to eq(described_class.new(2, 39, 2))
      end
    end

    context 'with platform suffixes' do
      it 'strips Windows suffix from "2.42.0.windows.1"' do
        version = described_class.parse('2.42.0.windows.1')

        expect(version).to eq(described_class.new(2, 42, 0))
      end

      it 'strips VFS suffix from "2.42.0.vfs.0"' do
        version = described_class.parse('2.42.0.vfs.0')

        expect(version).to eq(described_class.new(2, 42, 0))
      end
    end

    context 'with two-segment versions' do
      it 'pads "2.42" to "2.42.0"' do
        version = described_class.parse('2.42')

        expect(version).to eq(described_class.new(2, 42, 0))
      end
    end

    context 'with invalid input' do
      it 'raises Git::UnexpectedResultError for nil' do
        expect { described_class.parse(nil) }.to raise_error(Git::UnexpectedResultError, /Invalid version/)
      end

      it 'raises Git::UnexpectedResultError for empty string' do
        expect { described_class.parse('') }.to raise_error(Git::UnexpectedResultError, /Invalid version/)
      end

      it 'raises Git::UnexpectedResultError for non-version string' do
        expect { described_class.parse('not a version') }.to raise_error(Git::UnexpectedResultError, /Invalid version/)
      end

      it 'raises Git::UnexpectedResultError for single segment' do
        expect { described_class.parse('2') }.to raise_error(Git::UnexpectedResultError, /Invalid version/)
      end
    end
  end

  describe 'Comparable' do
    it 'compares versions correctly' do
      v1 = described_class.new(2, 28, 0)
      v2 = described_class.new(2, 42, 1)
      v3 = described_class.new(2, 42, 1)

      expect(v1).to be < v2
      expect(v2).to be > v1
      expect(v2).to eq(v3)
    end

    it 'compares by major version first' do
      expect(described_class.new(3, 0, 0)).to be > described_class.new(2, 99, 99)
    end

    it 'compares by minor version second' do
      expect(described_class.new(2, 50, 0)).to be > described_class.new(2, 49, 99)
    end

    it 'compares by patch version last' do
      expect(described_class.new(2, 42, 2)).to be > described_class.new(2, 42, 1)
    end

    it 'supports >= and <= operators' do
      v1 = described_class.new(2, 28, 0)
      v2 = described_class.new(2, 28, 0)
      v3 = described_class.new(2, 30, 0)

      expect(v1).to be >= v2
      expect(v1).to be <= v2
      expect(v3).to be >= v1
      expect(v1).to be <= v3
    end
  end

  describe '#to_s' do
    it 'returns the version as a dotted string' do
      version = described_class.new(2, 42, 1)

      expect(version.to_s).to eq('2.42.1')
    end
  end

  describe '#inspect' do
    it 'returns a readable representation' do
      version = described_class.new(2, 42, 1)

      expect(version.inspect).to eq('#<Git::Version 2.42.1>')
    end
  end

  describe '#to_a' do
    it 'returns an array of [major, minor, patch]' do
      version = described_class.new(2, 42, 0)

      expect(version.to_a).to eq([2, 42, 0])
    end
  end
end
