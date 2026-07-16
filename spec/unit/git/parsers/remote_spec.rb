# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/remote'

RSpec.describe Git::Parsers::Remote do
  # Helper to build a ConfigEntryInfo for a remote config key
  def entry(remote_name, variable, value, scope: 'local', origin: 'file:.git/config')
    Git::ConfigEntryInfo.new(
      scope: scope,
      origin: origin,
      key: "remote.#{remote_name}.#{variable}",
      value: value
    )
  end

  # ---------------------------------------------------------------------------
  # .parse_list
  # ---------------------------------------------------------------------------

  describe '.parse_list' do
    context 'with an empty array' do
      subject(:result) { described_class.parse_list([]) }

      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end

    context 'with a single remote that has only a URL' do
      subject(:result) do
        entries = [entry('origin', 'url', 'https://github.com/ruby-git/ruby-git.git')]
        described_class.parse_list(entries)
      end

      it 'returns one RemoteInfo' do
        expect(result.size).to eq(1)
      end

      it 'sets the remote name' do
        expect(result[0].name).to eq('origin')
      end

      it 'sets the url array' do
        expect(result[0].url).to eq(['https://github.com/ruby-git/ruby-git.git'])
      end

      it 'leaves other array fields empty' do
        expect(result[0].push_url).to eq([])
        expect(result[0].fetch).to eq([])
        expect(result[0].push).to eq([])
      end

      it 'leaves nilable fields as nil' do
        expect(result[0].mirror).to be_nil
        expect(result[0].prune).to be_nil
        expect(result[0].tag_opt).to be_nil
      end
    end

    context 'with a remote that has multiple URLs and fetch refspecs' do
      subject(:result) do
        entries = [
          entry('origin', 'url', 'https://github.com/ruby-git/ruby-git.git'),
          entry('origin', 'url', 'git@github.com:ruby-git/ruby-git.git'),
          entry('origin', 'fetch', '+refs/heads/*:refs/remotes/origin/*'),
          entry('origin', 'fetch', '+refs/tags/*:refs/tags/*')
        ]
        described_class.parse_list(entries)
      end

      it 'returns one RemoteInfo' do
        expect(result.size).to eq(1)
      end

      it 'collects all urls into the url array' do
        expect(result[0].url).to eq([
                                      'https://github.com/ruby-git/ruby-git.git',
                                      'git@github.com:ruby-git/ruby-git.git'
                                    ])
      end

      it 'collects all fetch refspecs into the fetch array' do
        expect(result[0].fetch).to eq([
                                        '+refs/heads/*:refs/remotes/origin/*',
                                        '+refs/tags/*:refs/tags/*'
                                      ])
      end
    end

    context 'with a remote that has push URLs' do
      subject(:result) do
        entries = [
          entry('origin', 'url', 'https://github.com/ruby-git/ruby-git.git'),
          entry('origin', 'pushurl', 'git@github.com:ruby-git/ruby-git.git'),
          entry('origin', 'push', 'refs/heads/main:refs/heads/main')
        ]
        described_class.parse_list(entries)
      end

      it 'sets push_url from pushurl config key' do
        expect(result[0].push_url).to eq(['git@github.com:ruby-git/ruby-git.git'])
      end

      it 'sets push from push config key' do
        expect(result[0].push).to eq(['refs/heads/main:refs/heads/main'])
      end
    end

    context 'with multiple remotes' do
      subject(:result) do
        entries = [
          entry('origin', 'url', 'https://github.com/ruby-git/ruby-git.git'),
          entry('origin', 'fetch', '+refs/heads/*:refs/remotes/origin/*'),
          entry('upstream', 'url', 'https://github.com/upstream/ruby-git.git'),
          entry('upstream', 'fetch', '+refs/heads/*:refs/remotes/upstream/*')
        ]
        described_class.parse_list(entries)
      end

      it 'returns two RemoteInfo objects' do
        expect(result.size).to eq(2)
      end

      it 'sets origin correctly' do
        origin = result.find { |r| r.name == 'origin' }
        expect(origin.url).to eq(['https://github.com/ruby-git/ruby-git.git'])
        expect(origin.fetch).to eq(['+refs/heads/*:refs/remotes/origin/*'])
      end

      it 'sets upstream correctly' do
        upstream = result.find { |r| r.name == 'upstream' }
        expect(upstream.url).to eq(['https://github.com/upstream/ruby-git.git'])
        expect(upstream.fetch).to eq(['+refs/heads/*:refs/remotes/upstream/*'])
      end
    end

    context 'with entries that are not remote config' do
      subject(:result) do
        entries = [
          entry('origin', 'url', 'https://github.com/ruby-git/ruby-git.git'),
          Git::ConfigEntryInfo.new(scope: 'local', origin: 'file:.git/config',
                                   key: 'core.bare', value: 'false'),
          Git::ConfigEntryInfo.new(scope: 'local', origin: 'file:.git/config',
                                   key: 'branch.main.remote', value: 'origin')
        ]
        described_class.parse_list(entries)
      end

      it 'ignores non-remote entries' do
        expect(result.size).to eq(1)
        expect(result[0].name).to eq('origin')
      end
    end

    context 'with a remote name that contains dots' do
      subject(:result) do
        entries = [
          entry('foo.bar', 'url', 'https://github.com/example/repo.git'),
          entry('foo.bar', 'fetch', '+refs/heads/*:refs/remotes/foo.bar/*')
        ]
        described_class.parse_list(entries)
      end

      it 'returns one RemoteInfo' do
        expect(result.size).to eq(1)
      end

      it 'sets the dotted remote name correctly' do
        expect(result[0].name).to eq('foo.bar')
      end

      it 'sets the url array' do
        expect(result[0].url).to eq(['https://github.com/example/repo.git'])
      end

      it 'sets the fetch refspec' do
        expect(result[0].fetch).to eq(['+refs/heads/*:refs/remotes/foo.bar/*'])
      end
    end

    context 'with boolean field coercion' do
      context 'when a boolean field is "true"' do
        subject(:result) do
          described_class.parse_list([entry('origin', 'mirror', 'true')])
        end

        it 'coerces to true' do
          expect(result[0].mirror).to be true
        end
      end

      context 'when a boolean field is "yes"' do
        subject(:result) do
          described_class.parse_list([entry('origin', 'prune', 'yes')])
        end

        it 'coerces to true' do
          expect(result[0].prune).to be true
        end
      end

      context 'when a boolean field is "on"' do
        subject(:result) do
          described_class.parse_list([entry('origin', 'prune', 'on')])
        end

        it 'coerces to true' do
          expect(result[0].prune).to be true
        end
      end

      context 'when a boolean field is "1"' do
        subject(:result) do
          described_class.parse_list([entry('origin', 'prune', '1')])
        end

        it 'coerces to true' do
          expect(result[0].prune).to be true
        end
      end

      context 'when a boolean field is "" (present without a value)' do
        subject(:result) do
          described_class.parse_list([entry('origin', 'mirror', '')])
        end

        it 'coerces to true' do
          expect(result[0].mirror).to be true
        end
      end

      context 'when a boolean field is "false"' do
        subject(:result) do
          described_class.parse_list([entry('origin', 'prune', 'false')])
        end

        it 'coerces to false' do
          expect(result[0].prune).to be false
        end
      end

      context 'when a boolean field is "no"' do
        subject(:result) do
          described_class.parse_list([entry('origin', 'prune', 'no')])
        end

        it 'coerces to false' do
          expect(result[0].prune).to be false
        end
      end

      context 'when a boolean field is "off"' do
        subject(:result) do
          described_class.parse_list([entry('origin', 'prune', 'off')])
        end

        it 'coerces to false' do
          expect(result[0].prune).to be false
        end
      end

      context 'when a boolean field is "0"' do
        subject(:result) do
          described_class.parse_list([entry('origin', 'prune', '0')])
        end

        it 'coerces to false' do
          expect(result[0].prune).to be false
        end
      end

      context 'when a boolean field is absent' do
        subject(:result) do
          described_class.parse_list([entry('origin', 'url', 'https://example.com')])
        end

        it 'remains nil for prune' do
          expect(result[0].prune).to be_nil
        end

        it 'remains nil for prune_tags' do
          expect(result[0].prune_tags).to be_nil
        end

        it 'remains nil for mirror' do
          expect(result[0].mirror).to be_nil
        end
      end

      context 'when a boolean field has an unrecognized value' do
        it 'raises ArgumentError' do
          entries = [entry('origin', 'mirror', 'maybe')]
          expect { described_class.parse_list(entries) }.to raise_error(
            ArgumentError, /unrecognized boolean value/i
          )
        end
      end
    end

    context 'with key name mappings' do
      subject(:result) do
        # Variable names are lowercase as git config --list always lowercases them
        entries = [
          entry('origin', 'tagopt', '--no-tags'),
          entry('origin', 'partialclonefilter', 'blob:none'),
          entry('origin', 'skipdefaultupdate', 'true'),
          entry('origin', 'prunetags', 'true'),
          entry('origin', 'promisor', 'true'),
          entry('origin', 'receivepack', 'git-receive-pack'),
          entry('origin', 'uploadpack', 'git-upload-pack'),
          entry('origin', 'vcs', 'svn')
        ]
        described_class.parse_list(entries)
      end

      it 'maps tagopt to tag_opt' do
        expect(result[0].tag_opt).to eq('--no-tags')
      end

      it 'maps partialclonefilter to partial_clone_filter' do
        expect(result[0].partial_clone_filter).to eq('blob:none')
      end

      it 'maps skipdefaultupdate to skip_default_update' do
        expect(result[0].skip_default_update).to be true
      end

      it 'maps prunetags to prune_tags' do
        expect(result[0].prune_tags).to be true
      end

      it 'maps promisor to promisor' do
        expect(result[0].promisor).to be true
      end

      it 'maps receivepack to receivepack' do
        expect(result[0].receivepack).to eq('git-receive-pack')
      end

      it 'maps uploadpack to uploadpack' do
        expect(result[0].uploadpack).to eq('git-upload-pack')
      end

      it 'maps vcs to vcs' do
        expect(result[0].vcs).to eq('svn')
      end
    end
  end
end
