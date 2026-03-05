# frozen_string_literal: true

require 'spec_helper'
require 'git/command_line_result'

RSpec.describe Git::CommandLineResult do
  it 'is a backward-compatible alias for Git::CommandLine::Result' do
    expect(described_class).to be(Git::CommandLine::Result)
  end
end
