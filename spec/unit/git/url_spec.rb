# frozen_string_literal: true

require 'spec_helper'
require 'git/url'

RSpec.describe Git::URL do
  describe '.parse' do
    subject(:parsed) { described_class.parse(url) }

    context 'with an alternative SSH (scp-like) syntax URL' do
      context 'when a user is present' do
        let(:url) { 'user@host.xz:path/to/repo.git/' }

        it 'returns a Git::GitAltURI carrying the user, host, and path' do
          expect(parsed).to be_a(Git::GitAltURI).and have_attributes(
            scheme: 'git-alt', user: 'user', host: 'host.xz', path: '/path/to/repo.git/'
          )
        end
      end

      context 'when no user is present' do
        let(:url) { 'host.xz:path/to/repo.git/' }

        it 'returns a Git::GitAltURI with a nil user' do
          expect(parsed).to be_a(Git::GitAltURI).and have_attributes(
            scheme: 'git-alt', user: nil, host: 'host.xz', path: '/path/to/repo.git/'
          )
        end
      end
    end

    context 'with a file: URL that resembles the scp-like syntax' do
      # A `file:` URL contains a colon but must never be treated as alt-SSH.
      let(:url) { 'file:./relative-path/to/repo.git/' }

      it 'returns an Addressable::URI parsed as a file URL' do
        expect(parsed).to be_an(Addressable::URI).and have_attributes(
          scheme: 'file', path: './relative-path/to/repo.git/'
        )
      end
    end

    context 'with a standard scheme://host URL' do
      let(:url) { 'https://host.xz:4443/path/to/repo.git/' }

      it 'returns an Addressable::URI carrying the scheme, host, port, and path' do
        expect(parsed).to be_an(Addressable::URI).and have_attributes(
          scheme: 'https', host: 'host.xz', port: 4443, path: '/path/to/repo.git/'
        )
      end
    end

    context 'with a local filesystem path' do
      let(:url) { '/path/to/repo.git/' }

      it 'returns an Addressable::URI with only a path' do
        expect(parsed).to be_an(Addressable::URI).and have_attributes(
          scheme: nil, host: nil, path: '/path/to/repo.git/'
        )
      end
    end

    context 'with an invalid URL' do
      # The `:/` after the host prevents the alt-SSH match, so the string is
      # handed to Addressable, which rejects it as an invalid scheme.
      let(:url) { 'user@host.xz:/path/to/repo.git/' }

      it 'raises Addressable::URI::InvalidURIError' do
        expect { parsed }.to raise_error(Addressable::URI::InvalidURIError, /host\.xz/)
      end
    end

    # The full set of Git URL forms `git clone` accepts. Each must parse into a
    # known set of URI attributes and round-trip back to the original string via
    # #to_s, which is the documented guarantee of Git::URL.parse.
    git_url_cases = [
      { url: 'ssh://host.xz/path/to/repo.git/',
        attributes: { scheme: 'ssh', host: 'host.xz', path: '/path/to/repo.git/' } },
      { url: 'ssh://host.xz:4443/path/to/repo.git/',
        attributes: { scheme: 'ssh', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' } },
      { url: 'ssh:///path/to/repo.git/',
        attributes: { scheme: 'ssh', host: '', path: '/path/to/repo.git/' } },
      { url: 'user@host.xz:path/to/repo.git/',
        attributes: { scheme: 'git-alt', user: 'user', host: 'host.xz', path: '/path/to/repo.git/' } },
      { url: 'host.xz:path/to/repo.git/',
        attributes: { scheme: 'git-alt', host: 'host.xz', path: '/path/to/repo.git/' } },
      { url: 'git://host.xz:4443/path/to/repo.git/',
        attributes: { scheme: 'git', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' } },
      { url: 'git://user@host.xz:4443/path/to/repo.git/',
        attributes: { scheme: 'git', user: 'user', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' } },
      { url: 'https://host.xz/path/to/repo.git/',
        attributes: { scheme: 'https', host: 'host.xz', path: '/path/to/repo.git/' } },
      { url: 'https://host.xz:4443/path/to/repo.git/',
        attributes: { scheme: 'https', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' } },
      { url: 'ftps://host.xz:4443/path/to/repo.git/',
        attributes: { scheme: 'ftps', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' } },
      { url: 'file:./relative-path/to/repo.git/',
        attributes: { scheme: 'file', path: './relative-path/to/repo.git/' } },
      { url: 'file:///path/to/repo.git/',
        attributes: { scheme: 'file', host: '', path: '/path/to/repo.git/' } },
      { url: 'file:///path/to/repo.git',
        attributes: { scheme: 'file', host: '', path: '/path/to/repo.git' } },
      { url: 'file://host.xz/path/to/repo.git',
        attributes: { scheme: 'file', host: 'host.xz', path: '/path/to/repo.git' } },
      { url: '/path/to/repo.git/', attributes: { path: '/path/to/repo.git/' } },
      { url: '/path/to/bare-repo/.git', attributes: { path: '/path/to/bare-repo/.git' } },
      { url: 'relative-path/to/repo.git/', attributes: { path: 'relative-path/to/repo.git/' } },
      { url: './relative-path/to/repo.git/', attributes: { path: './relative-path/to/repo.git/' } },
      { url: '../ruby-git/.git', attributes: { path: '../ruby-git/.git' } }
    ]

    git_url_cases.each do |git_url_case|
      context "with the URL #{git_url_case[:url].inspect}" do
        let(:url) { git_url_case[:url] }

        it 'parses into the expected URI attributes' do
          expect(parsed.to_hash.compact).to eq(git_url_case[:attributes])
        end

        it 'round-trips back to the original URL via #to_s' do
          expect(parsed.to_s).to eq(git_url_case[:url])
        end
      end
    end
  end

  describe '.clone_to' do
    subject(:directory) { described_class.clone_to(url, **options) }

    let(:options) { {} }

    clone_to_cases = [
      { url: 'https://github.com/org/repo', full: 'repo', bare: 'repo.git' },
      { url: 'https://github.com/org/repo.git', full: 'repo', bare: 'repo.git' },
      { url: 'https://git.mydomain.com/org/repo/.git', full: 'repo', bare: 'repo.git' }
    ]

    clone_to_cases.each do |clone_to_case|
      context "with the URL #{clone_to_case[:url].inspect}" do
        let(:url) { clone_to_case[:url] }

        context 'without bare or mirror' do
          it "uses the directory #{clone_to_case[:full].inspect}" do
            expect(directory).to eq(clone_to_case[:full])
          end
        end

        context 'with bare: true' do
          let(:options) { { bare: true } }

          it "uses the directory #{clone_to_case[:bare].inspect}" do
            expect(directory).to eq(clone_to_case[:bare])
          end
        end

        context 'with mirror: true' do
          let(:options) { { mirror: true } }

          it "uses the directory #{clone_to_case[:bare].inspect}" do
            expect(directory).to eq(clone_to_case[:bare])
          end
        end
      end
    end
  end
end

RSpec.describe Git::GitAltURI do
  let(:described_instance) { described_class.new(user:, host: 'github.com', path: 'ruby-git/ruby-git.git') }
  let(:user) { 'james' }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores the alt-SSH scheme, user, host, and an absolute path' do
      expect(instance).to have_attributes(
        scheme: 'git-alt', user: 'james', host: 'github.com', path: '/ruby-git/ruby-git.git'
      )
    end
  end

  describe '#to_s' do
    subject(:string) { described_instance.to_s }

    context 'when a user is present' do
      let(:user) { 'james' }

      it 'returns the user@host:path form without the leading path slash' do
        expect(string).to eq('james@github.com:ruby-git/ruby-git.git')
      end
    end

    context 'when the user is nil' do
      let(:user) { nil }

      it 'returns the host:path form without the leading path slash' do
        expect(string).to eq('github.com:ruby-git/ruby-git.git')
      end
    end
  end
end
