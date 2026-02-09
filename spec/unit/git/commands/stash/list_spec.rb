# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/list'
require 'git/parsers/stash'

RSpec.describe Git::Commands::Stash::List do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  let(:stash_output) do
    "abc1234567890abcdef1234567890abcdef123456\x1fabc1234\x1fstash@{0}\x1f" \
      "WIP on main: abc1234 Initial commit\x1fTest Author\x1fauthor@test.com\x1f" \
      "2026-01-24T10:00:00-08:00\x1fTest Committer\x1fcommitter@test.com\x1f2026-01-24T10:00:00-08:00"
  end

  describe '#call' do
    it 'runs stash list with format and returns CommandLineResult' do
      format_arg = "--format=#{Git::Parsers::Stash::STASH_FORMAT}"

      expect(execution_context).to receive(:command)
        .with('stash', 'list', format_arg)
        .and_return(command_result(stash_output))

      result = command.call

      expect(result).to be_a(Git::CommandLineResult)
      expect(result.stdout).to eq(stash_output)
    end
  end
end
