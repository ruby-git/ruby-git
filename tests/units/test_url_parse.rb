# frozen_string_literal: true

require 'test/unit'

# Tests Git::URL.parse
#
class TestURLParse < Test::Unit::TestCase
  def test_parse_with_invalid_url
    url = 'user@host.xz:/path/to/repo.git/'
    assert_raise(Addressable::URI::InvalidURIError) do
      Git::URL.parse(url)
    end
  end

  def test_parse
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      expected_uri = url_data[:expected_uri]
      actual_uri = Git::URL.parse(url).to_hash.delete_if { |_key, value| value.nil? }
      assert_equal(expected_uri, actual_uri, "Failed to parse URL '#{url}' correctly")
    end
  end

  # For any URL, #to_s should return the url passed to Git::URL.parse(url)
  def test_to_s
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      to_s = Git::URL.parse(url).to_s
      assert_equal(url, to_s, "Parsed URI#to_s does not return the original URL '#{url}' correctly")
    end
  end

  GIT_URLS = [
    {
      url: 'ssh://host.xz/path/to/repo.git/',
      expected_uri: { scheme: 'ssh', host: 'host.xz', path: '/path/to/repo.git/' }
    },
    {
      url: 'ssh://host.xz:4443/path/to/repo.git/',
      expected_uri: { scheme: 'ssh', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' }
    },
    {
      url: 'ssh:///path/to/repo.git/',
      expected_uri: { scheme: 'ssh', host: '', path: '/path/to/repo.git/' }
    },
    {
      url: 'user@host.xz:path/to/repo.git/',
      expected_uri: { scheme: 'git-alt', user: 'user', host: 'host.xz', path: '/path/to/repo.git/' }
    },
    {
      url: 'host.xz:path/to/repo.git/',
      expected_uri: { scheme: 'git-alt', host: 'host.xz', path: '/path/to/repo.git/' }
    },
    {
      url: 'git://host.xz:4443/path/to/repo.git/',
      expected_uri: { scheme: 'git', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' }
    },
    {
      url: 'git://user@host.xz:4443/path/to/repo.git/',
      expected_uri: { scheme: 'git', user: 'user', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' }
    },
    {
      url: 'https://host.xz/path/to/repo.git/',
      expected_uri: { scheme: 'https', host: 'host.xz', path: '/path/to/repo.git/' }
    },
    {
      url: 'https://host.xz:4443/path/to/repo.git/',
      expected_uri: { scheme: 'https', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' }
    },
    {
      url: 'ftps://host.xz:4443/path/to/repo.git/',
      expected_uri: { scheme: 'ftps', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' }
    },
    {
      url: 'ftps://host.xz:4443/path/to/repo.git/',
      expected_uri: { scheme: 'ftps', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' }
    },
    {
      url: 'file:./relative-path/to/repo.git/',
      expected_uri: { scheme: 'file', path: './relative-path/to/repo.git/' }
    },
    {
      url: 'file:///path/to/repo.git/',
      expected_uri: { scheme: 'file', host: '', path: '/path/to/repo.git/' }
    },
    {
      url: 'file:///path/to/repo.git',
      expected_uri: { scheme: 'file', host: '', path: '/path/to/repo.git' }
    },
    {
      url: 'file://host.xz/path/to/repo.git',
      expected_uri: { scheme: 'file', host: 'host.xz', path: '/path/to/repo.git' }
    },
    { url: '/path/to/repo.git/', expected_uri: { path: '/path/to/repo.git/' } },
    { url: '/path/to/bare-repo/.git', expected_uri: { path: '/path/to/bare-repo/.git' } },
    { url: 'relative-path/to/repo.git/', expected_uri: { path: 'relative-path/to/repo.git/' } },
    { url: './relative-path/to/repo.git/', expected_uri: { path: './relative-path/to/repo.git/' } },
    { url: '../ruby-git/.git', expected_uri: { path: '../ruby-git/.git' } }
  ].freeze
end
