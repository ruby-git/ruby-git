# frozen_string_literal: true

require 'spec_helper'
require 'git/command_line_result'

RSpec.describe 'Git::CommandLineResult (deprecated)' do
  before do
    Git.send(:remove_const, :CommandLineResult) if Git.const_defined?(:CommandLineResult, false)
  end

  after do
    Git.send(:remove_const, :CommandLineResult) if Git.const_defined?(:CommandLineResult, false)
  end

  it 'resolves to Git::CommandLine::Result' do
    allow(Git::Deprecation).to receive(:warn)
    expect(Git::CommandLineResult).to be(Git::CommandLine::Result)
  end

  it 'emits a deprecation warning when accessed' do
    expect(Git::Deprecation).to receive(:warn).with(/Git::CommandLineResult is deprecated/)
    Git::CommandLineResult
  end
end
