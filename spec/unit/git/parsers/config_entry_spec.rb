# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/config_entry'

RSpec.describe Git::Parsers::ConfigEntry do
  describe '.parse_get' do
    context 'with a non-empty output string' do
      it 'returns a ConfigEntryInfo with the parsed scope, origin, and value' do
        output = "local\0file:.git/config\0https://github.com/ruby-git/ruby-git\0"

        result = described_class.parse_get('remote.origin.url', output)

        expect(result).to be_a(Git::ConfigEntryInfo)
        expect(result.scope).to eq('local')
        expect(result.origin).to eq('file:.git/config')
        expect(result.key).to eq('remote.origin.url')
        expect(result.value).to eq('https://github.com/ruby-git/ruby-git')
      end

      it 'uses the supplied key name (not present in get output)' do
        output = "global\0file:/home/user/.gitconfig\0Alice\0"

        result = described_class.parse_get('user.name', output)

        expect(result.key).to eq('user.name')
      end
    end

    context 'with an empty output string' do
      it 'returns nil' do
        expect(described_class.parse_get('user.name', '')).to be_nil
      end
    end
  end

  describe '.parse_get_all' do
    context 'with a single entry' do
      it 'returns an array with one ConfigEntryInfo' do
        output = "local\0file:.git/config\0git@github.com:ruby-git/ruby-git.git\0"

        result = described_class.parse_get_all('remote.origin.url', output)

        expect(result.size).to eq(1)
        expect(result[0].scope).to eq('local')
        expect(result[0].origin).to eq('file:.git/config')
        expect(result[0].key).to eq('remote.origin.url')
        expect(result[0].value).to eq('git@github.com:ruby-git/ruby-git.git')
      end
    end

    context 'with multiple entries' do
      it 'returns one ConfigEntryInfo per entry' do
        output =
          "local\0file:.git/config\0https://github.com/ruby-git/ruby-git\0" \
          "local\0file:.git/config\0git@github.com:ruby-git/ruby-git.git\0"

        result = described_class.parse_get_all('remote.origin.url', output)

        expect(result.size).to eq(2)
        expect(result[0].value).to eq('https://github.com/ruby-git/ruby-git')
        expect(result[1].value).to eq('git@github.com:ruby-git/ruby-git.git')
      end
    end

    context 'with output that does not have a trailing NUL terminator' do
      it 'returns the entries without error' do
        output = "local\0file:.git/config\0git@github.com:ruby-git/ruby-git.git"

        result = described_class.parse_get_all('remote.origin.url', output)

        expect(result.size).to eq(1)
        expect(result[0].value).to eq('git@github.com:ruby-git/ruby-git.git')
      end
    end

    context 'with an empty output string' do
      it 'returns an empty array' do
        expect(described_class.parse_get_all('user.name', '')).to eq([])
      end
    end
  end

  describe '.parse_list' do
    context 'with a single entry' do
      it 'returns an array with one ConfigEntryInfo' do
        output = "local\0file:.git/config\0user.name\nAlice\0"

        result = described_class.parse_list(output)

        expect(result.size).to eq(1)
        expect(result[0].scope).to eq('local')
        expect(result[0].origin).to eq('file:.git/config')
        expect(result[0].key).to eq('user.name')
        expect(result[0].value).to eq('Alice')
      end
    end

    context 'with multiple entries' do
      it 'returns one ConfigEntryInfo per entry' do
        output =
          "local\0file:.git/config\0user.name\nAlice\0" \
          "global\0file:/home/user/.gitconfig\0user.email\nalice@example.com\0"

        result = described_class.parse_list(output)

        expect(result.size).to eq(2)
        expect(result[0].key).to eq('user.name')
        expect(result[0].value).to eq('Alice')
        expect(result[1].key).to eq('user.email')
        expect(result[1].value).to eq('alice@example.com')
        expect(result[1].scope).to eq('global')
      end
    end

    context 'with a value that contains an embedded newline' do
      it 'assigns everything after the first newline as the value' do
        output = "local\0file:.git/config\0core.message\nline1\nline2\0"

        result = described_class.parse_list(output)

        expect(result[0].key).to eq('core.message')
        expect(result[0].value).to eq("line1\nline2")
      end
    end

    context 'with a key that has no value (empty string)' do
      it 'returns an empty string for value' do
        output = "local\0file:.git/config\0core.novalue\n\0"

        result = described_class.parse_list(output)

        expect(result[0].value).to eq('')
      end
    end

    context 'with output that does not have a trailing NUL terminator' do
      it 'returns the entries without error' do
        output = "local\0file:.git/config\0user.name\nAlice"

        result = described_class.parse_list(output)

        expect(result.size).to eq(1)
        expect(result[0].key).to eq('user.name')
        expect(result[0].value).to eq('Alice')
      end
    end

    context 'with a key_value token that has no embedded newline' do
      it 'returns an empty string for value' do
        output = "local\0file:.git/config\0core.flag\0"

        result = described_class.parse_list(output)

        expect(result[0].key).to eq('core.flag')
        expect(result[0].value).to eq('')
      end
    end

    context 'with an empty output string' do
      it 'returns an empty array' do
        expect(described_class.parse_list('')).to eq([])
      end
    end
  end

  describe '.parse_urlmatch' do
    context 'with a single entry' do
      it 'returns an array with one ConfigEntryInfo with scope, key, and value' do
        output = "local\0http.https://example.com.proxy\nhttp://proxy.example.com\0"

        result = described_class.parse_urlmatch(output)

        expect(result.size).to eq(1)
        expect(result[0].scope).to eq('local')
        expect(result[0].origin).to be_nil
        expect(result[0].key).to eq('http.https://example.com.proxy')
        expect(result[0].value).to eq('http://proxy.example.com')
      end
    end

    context 'with multiple entries' do
      it 'returns one ConfigEntryInfo per entry' do
        output =
          "local\0http.https://example.com.proxy\nhttp://proxy.example.com\0" \
          "local\0http.https://example.com.sslverify\nfalse\0"

        result = described_class.parse_urlmatch(output)

        expect(result.size).to eq(2)
        expect(result[0].key).to eq('http.https://example.com.proxy')
        expect(result[0].value).to eq('http://proxy.example.com')
        expect(result[1].key).to eq('http.https://example.com.sslverify')
        expect(result[1].value).to eq('false')
      end
    end

    context 'with output that does not have a trailing NUL terminator' do
      it 'returns the entries without error' do
        output = "local\0http.https://example.com.proxy\nhttp://proxy.example.com"

        result = described_class.parse_urlmatch(output)

        expect(result.size).to eq(1)
        expect(result[0].value).to eq('http://proxy.example.com')
      end
    end

    context 'with an empty output string' do
      it 'returns an empty array' do
        expect(described_class.parse_urlmatch('')).to eq([])
      end
    end
  end
end
