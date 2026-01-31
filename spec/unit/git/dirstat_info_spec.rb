# frozen_string_literal: true

require 'spec_helper'
require 'git/dirstat_info'

RSpec.describe Git::DirstatEntry do
  describe '.new' do
    it 'creates an immutable value object with directory and percentage' do
      entry = described_class.new(directory: 'lib/', percentage: 45.2)

      expect(entry.directory).to eq('lib/')
      expect(entry.percentage).to eq(45.2)
    end

    it 'is immutable' do
      entry = described_class.new(directory: 'lib/', percentage: 45.2)

      expect(entry).to be_frozen
    end
  end
end

RSpec.describe Git::DirstatInfo do
  let(:entries) do
    [
      Git::DirstatEntry.new(directory: 'lib/commands/', percentage: 50.0),
      Git::DirstatEntry.new(directory: 'spec/unit/', percentage: 30.5),
      Git::DirstatEntry.new(directory: 'bin/', percentage: 19.5)
    ]
  end

  let(:dirstat) { described_class.new(entries: entries) }

  describe '.new' do
    it 'creates an immutable value object with entries' do
      expect(dirstat.entries).to eq(entries)
    end

    it 'is immutable' do
      expect(dirstat).to be_frozen
    end
  end

  describe '#[]' do
    it 'looks up percentage by directory path' do
      expect(dirstat['lib/commands/']).to eq(50.0)
      expect(dirstat['spec/unit/']).to eq(30.5)
    end

    it 'returns nil for unknown directory' do
      expect(dirstat['unknown/']).to be_nil
    end
  end

  describe '#to_h' do
    it 'converts to a Hash mapping directory to percentage' do
      expect(dirstat.to_h).to eq({
                                   'lib/commands/' => 50.0,
                                   'spec/unit/' => 30.5,
                                   'bin/' => 19.5
                                 })
    end
  end

  describe '#size' do
    it 'returns number of directories' do
      expect(dirstat.size).to eq(3)
    end
  end

  describe '#empty?' do
    it 'returns false when entries exist' do
      expect(dirstat.empty?).to be false
    end

    it 'returns true when no entries' do
      empty_dirstat = described_class.new(entries: [])
      expect(empty_dirstat.empty?).to be true
    end
  end

  describe '#each' do
    it 'iterates over entries' do
      directories = dirstat.map(&:directory)

      expect(directories).to eq(['lib/commands/', 'spec/unit/', 'bin/'])
    end

    it 'returns an Enumerator when no block given' do
      expect(dirstat.each).to be_a(Enumerator)
    end
  end

  describe 'Enumerable' do
    it 'supports #map' do
      directories = dirstat.map(&:directory)
      expect(directories).to eq(['lib/commands/', 'spec/unit/', 'bin/'])
    end

    it 'supports #select' do
      high_percentage = dirstat.select { |e| e.percentage > 25.0 }
      expect(high_percentage.size).to eq(2)
    end

    it 'supports #find' do
      entry = dirstat.find { |e| e.percentage.between?(30.4, 30.6) }
      expect(entry.directory).to eq('spec/unit/')
    end
  end
end
