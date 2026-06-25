# frozen_string_literal: true

require 'spec_helper'
require 'git/config_entry_info'

RSpec.describe Git::ConfigEntryInfo do
  let(:entry) do
    described_class.new(
      scope: 'local',
      origin: 'file:.git/config',
      key: 'remote.origin.url',
      value: 'https://github.com/ruby-git/ruby-git'
    )
  end

  describe '.new' do
    it 'stores scope, origin, key, and value' do
      expect(entry.scope).to eq('local')
      expect(entry.origin).to eq('file:.git/config')
      expect(entry.key).to eq('remote.origin.url')
      expect(entry.value).to eq('https://github.com/ruby-git/ruby-git')
    end

    it 'is frozen (Data semantics)' do
      expect(entry).to be_frozen
    end
  end

  describe '#section' do
    it 'returns everything before the first dot' do
      expect(entry.section).to eq('remote')
    end

    context 'when the key has no dot' do
      let(:entry) { described_class.new(scope: 'local', origin: 'file:.git/config', key: 'nodot', value: 'v') }

      it 'returns an empty string' do
        expect(entry.section).to eq('')
      end
    end
  end

  describe '#subsection' do
    it 'returns the part between the first and last dot' do
      expect(entry.subsection).to eq('origin')
    end

    context 'when the key has only one dot' do
      let(:entry) { described_class.new(scope: 'local', origin: 'file:.git/config', key: 'user.name', value: 'Alice') }

      it 'returns an empty string' do
        expect(entry.subsection).to eq('')
      end
    end

    context 'when the key has no dot' do
      let(:entry) { described_class.new(scope: 'local', origin: 'file:.git/config', key: 'nodot', value: 'v') }

      it 'returns an empty string' do
        expect(entry.subsection).to eq('')
      end
    end

    context 'when the subsection contains dots' do
      let(:entry) do
        described_class.new(scope: 'global', origin: 'file:~/.gitconfig', key: 'url.https://github.com/.insteadOf',
                            value: 'git@github.com:')
      end

      it 'returns everything between the first and last dot' do
        expect(entry.subsection).to eq('https://github.com/')
      end
    end
  end

  describe '#variable' do
    it 'returns everything after the last dot' do
      expect(entry.variable).to eq('url')
    end

    context 'when the key has no dot' do
      let(:entry) { described_class.new(scope: 'local', origin: 'file:.git/config', key: 'nodot', value: 'v') }

      it 'returns the full key' do
        expect(entry.variable).to eq('nodot')
      end
    end

    context 'when the key has only one dot' do
      let(:entry) { described_class.new(scope: 'local', origin: 'file:.git/config', key: 'user.name', value: 'Alice') }

      it 'returns everything after the dot' do
        expect(entry.variable).to eq('name')
      end
    end
  end
end
