# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/ls_remote'

RSpec.describe Git::Parsers::LsRemote do
  describe '.parse_line' do
    subject(:result) { described_class.parse_line(line) }

    context 'with a valid <sha>\t<ref> line' do
      let(:line) { "abc123\tHEAD" }

      it 'returns [type, name, value]' do
        expect(result).to eq(['head', nil, { ref: 'HEAD', sha: 'abc123' }])
      end
    end

    context 'with a symref ref: line (e.g. --symref output)' do
      let(:line) { "ref: refs/heads/main\tHEAD" }

      it 'raises Git::UnexpectedResultError' do
        expect { result }.to raise_error(
          Git::UnexpectedResultError,
          %r{Unexpected ls-remote output line: "ref: refs/heads/main}
        )
      end
    end

    context 'with a line that has no tab character' do
      let(:line) { 'https://github.com/ruby-git/ruby-git' }

      it 'raises Git::UnexpectedResultError' do
        expect { result }.to raise_error(
          Git::UnexpectedResultError,
          %r{Unexpected ls-remote output line: "https://github\.com/ruby-git/ruby-git"}
        )
      end
    end
  end

  describe '.parse_default_branch' do
    subject { described_class.parse_default_branch(output) }

    context 'when output contains a refs/remotes/origin/HEAD symref' do
      let(:output) do
        "ref: refs/remotes/origin/main\trefs/remotes/origin/HEAD\n" \
          "abc123\trefs/remotes/origin/HEAD\n" \
          "abc123\trefs/remotes/origin/main\n"
      end

      it 'returns the default branch name' do
        expect(subject).to eq('main')
      end
    end

    context 'when output contains a refs/remotes/<remote>/HEAD symref for a non-origin remote' do
      let(:output) do
        "ref: refs/remotes/upstream/develop\trefs/remotes/upstream/HEAD\n" \
          "abc123\trefs/remotes/upstream/HEAD\n" \
          "abc123\trefs/remotes/upstream/develop\n"
      end

      it 'returns the default branch name regardless of the remote name' do
        expect(subject).to eq('develop')
      end
    end

    context 'when output contains only a refs/heads/HEAD symref' do
      let(:output) do
        "ref: refs/heads/main\tHEAD\n" \
          "abc123\tHEAD\n" \
          "abc123\trefs/heads/main\n"
      end

      it 'returns the default branch name' do
        expect(subject).to eq('main')
      end
    end

    context 'when output contains neither a remotes nor a heads symref' do
      let(:output) { "abc123\tHEAD\nabc123\trefs/heads/main\n" }

      it 'raises Git::UnexpectedResultError' do
        expect { subject }.to raise_error(
          Git::UnexpectedResultError,
          /Unable to determine the default branch/
        )
      end
    end
  end
end
