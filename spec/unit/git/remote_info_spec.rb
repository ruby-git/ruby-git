# frozen_string_literal: true

require 'spec_helper'
require 'git/remote_info'

RSpec.describe Git::RemoteInfo do
  # ---------------------------------------------------------------------------
  # .new / #initialize
  # ---------------------------------------------------------------------------

  describe '#initialize' do
    context 'with only the required :name field' do
      subject(:info) do
        described_class.new(name: 'origin')
      end

      it 'sets name' do
        expect(info.name).to eq('origin')
      end

      it 'sets url to an empty array' do
        expect(info.url).to eq([])
      end

      it 'sets push_url to an empty array' do
        expect(info.push_url).to eq([])
      end

      it 'sets fetch to an empty array' do
        expect(info.fetch).to eq([])
      end

      it 'sets push to an empty array' do
        expect(info.push).to eq([])
      end

      it 'sets nilable fields to nil by default' do
        expect(info.mirror).to be_nil
        expect(info.skip_default_update).to be_nil
        expect(info.tag_opt).to be_nil
        expect(info.prune).to be_nil
        expect(info.prune_tags).to be_nil
        expect(info.receivepack).to be_nil
        expect(info.uploadpack).to be_nil
        expect(info.promisor).to be_nil
        expect(info.partial_clone_filter).to be_nil
        expect(info.vcs).to be_nil
      end
    end

    context 'with all fields provided' do
      subject(:info) do
        described_class.new(
          name: 'upstream',
          url: ['https://example.com/repo.git'],
          push_url: ['git@example.com:repo.git'],
          fetch: ['+refs/heads/*:refs/remotes/upstream/*'],
          push: ['refs/heads/main:refs/heads/main'],
          mirror: true,
          skip_default_update: false,
          tag_opt: '--no-tags',
          prune: true,
          prune_tags: false,
          receivepack: 'git-receive-pack',
          uploadpack: 'git-upload-pack',
          promisor: true,
          partial_clone_filter: 'blob:none',
          vcs: 'svn'
        )
      end

      it 'sets name' do
        expect(info.name).to eq('upstream')
      end

      it 'sets url' do
        expect(info.url).to eq(['https://example.com/repo.git'])
      end

      it 'sets push_url' do
        expect(info.push_url).to eq(['git@example.com:repo.git'])
      end

      it 'sets fetch' do
        expect(info.fetch).to eq(['+refs/heads/*:refs/remotes/upstream/*'])
      end

      it 'sets push' do
        expect(info.push).to eq(['refs/heads/main:refs/heads/main'])
      end

      it 'sets mirror' do
        expect(info.mirror).to be true
      end

      it 'sets skip_default_update' do
        expect(info.skip_default_update).to be false
      end

      it 'sets tag_opt' do
        expect(info.tag_opt).to eq('--no-tags')
      end

      it 'sets prune' do
        expect(info.prune).to be true
      end

      it 'sets prune_tags' do
        expect(info.prune_tags).to be false
      end

      it 'sets receivepack' do
        expect(info.receivepack).to eq('git-receive-pack')
      end

      it 'sets uploadpack' do
        expect(info.uploadpack).to eq('git-upload-pack')
      end

      it 'sets promisor' do
        expect(info.promisor).to be true
      end

      it 'sets partial_clone_filter' do
        expect(info.partial_clone_filter).to eq('blob:none')
      end

      it 'sets vcs' do
        expect(info.vcs).to eq('svn')
      end
    end

    context 'when multi-value fields are passed nil' do
      subject(:info) { described_class.new(name: 'origin', url: nil, push_url: nil, fetch: nil, push: nil) }

      it 'coerces url nil to an empty array' do
        expect(info.url).to eq([])
      end

      it 'coerces push_url nil to an empty array' do
        expect(info.push_url).to eq([])
      end

      it 'coerces fetch nil to an empty array' do
        expect(info.fetch).to eq([])
      end

      it 'coerces push nil to an empty array' do
        expect(info.push).to eq([])
      end
    end

    context 'when name is missing' do
      it 'raises an error' do
        expect do
          described_class.new(url: [], push_url: [], fetch: [], push: [])
        end.to raise_error(ArgumentError)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Immutability (Data.define)
  # ---------------------------------------------------------------------------

  describe 'immutability' do
    subject(:info) { described_class.new(name: 'origin', url: [], push_url: [], fetch: [], push: []) }

    it 'is frozen' do
      expect(info).to be_frozen
    end
  end
end
