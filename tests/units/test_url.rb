require 'test/unit'

GIT_URLS = [
  {
    url: 'ssh://host.xz/path/to/repo.git/',
    expected_attributes: { scheme: 'ssh', host: 'host.xz', path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'ssh://host.xz:4443/path/to/repo.git/',
    expected_attributes: { scheme: 'ssh', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'ssh:///path/to/repo.git/',
    expected_attributes: { scheme: 'ssh', host: '', path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'user@host.xz:path/to/repo.git/',
    expected_attributes: { scheme: 'git-alt', user: 'user', host: 'host.xz', path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'host.xz:path/to/repo.git/',
    expected_attributes: { scheme: 'git-alt', host: 'host.xz', path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'git://host.xz:4443/path/to/repo.git/',
    expected_attributes: { scheme: 'git', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'git://user@host.xz:4443/path/to/repo.git/',
    expected_attributes: { scheme: 'git', user: 'user', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'https://host.xz/path/to/repo.git/',
    expected_attributes: { scheme: 'https', host: 'host.xz', path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'https://host.xz:4443/path/to/repo.git/',
    expected_attributes: { scheme: 'https', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'ftps://host.xz:4443/path/to/repo.git/',
    expected_attributes: { scheme: 'ftps', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'ftps://host.xz:4443/path/to/repo.git/',
    expected_attributes: { scheme: 'ftps', host: 'host.xz', port: 4443, path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'file:./relative-path/to/repo.git/',
    expected_attributes: { scheme: 'file', path: './relative-path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'file:///path/to/repo.git/',
    expected_attributes: { scheme: 'file', host: '', path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: 'file:///path/to/repo.git',
    expected_attributes: { scheme: 'file', host: '', path: '/path/to/repo.git' },
    expected_clone_to: 'repo'
  },
  {
    url: 'file://host.xz/path/to/repo.git',
    expected_attributes: { scheme: 'file', host: 'host.xz', path: '/path/to/repo.git' },
    expected_clone_to: 'repo'
  },
  {
    url: '/path/to/repo.git/',
    expected_attributes: { path: '/path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: '/path/to/bare-repo/.git',
    expected_attributes: { path: '/path/to/bare-repo/.git' },
    expected_clone_to: 'bare-repo'
  },
  {
    url: 'relative-path/to/repo.git/',
    expected_attributes: { path: 'relative-path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: './relative-path/to/repo.git/',
    expected_attributes: { path: './relative-path/to/repo.git/' },
    expected_clone_to: 'repo'
  },
  {
    url: '../ruby-git/.git',
    expected_attributes: { path: '../ruby-git/.git' },
    expected_clone_to: 'ruby-git'
  }
].freeze

# Tests for the Git::URL class
#
class TestURL < Test::Unit::TestCase
  def test_parse_with_invalid_url
    url = 'user@host.xz:/path/to/repo.git/'
    assert_raise(Addressable::URI::InvalidURIError) do
      Git::URL.parse(url)
    end
  end

  def test_parse
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      expected_attributes = url_data[:expected_attributes]
      actual_attributes = Git::URL.parse(url).to_hash.delete_if {| key, value | value.nil? }
      assert_equal(expected_attributes, actual_attributes, "Failed to parse URL '#{url}' correctly")
    end
  end

  def test_clone_to
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      expected_clone_to = url_data[:expected_clone_to]
      actual_repo_name = Git::URL.clone_to(url)
      assert_equal(
        expected_clone_to, actual_repo_name,
        "Failed to determine the repository directory for URL '#{url}' correctly"
      )
    end
  end

  def test_to_s
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      to_s = Git::URL.parse(url).to_s
      assert_equal(url, to_s, "Parsed URI#to_s does not return the original URL '#{url}' correctly")
    end
  end
end
