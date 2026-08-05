# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Git::CommandLineResult (deprecated)' do
  before do
    Git.send(:remove_const, :CommandLineResult) if Git.const_defined?(:CommandLineResult, false)
  end

  after do
    Git.send(:remove_const, :CommandLineResult) if Git.const_defined?(:CommandLineResult, false)
  end

  context 'when accessing Git::CommandLineResult' do
    it 'resolves to Git::CommandLine::Result' do
      allow(Git::Deprecation).to receive(:warn)
      expect(Git::CommandLineResult).to be(Git::CommandLine::Result)
    end

    it 'emits a deprecation warning when accessed' do
      expect(Git::Deprecation).to receive(:warn).with(/Git::CommandLineResult is deprecated/)
      Git::CommandLineResult
    end
  end

  context 'when accessing an unrelated missing constant' do
    it 'raises NameError instead of resolving it' do
      expect { Git::NotARealConstant }.to raise_error(NameError, /uninitialized constant Git::NotARealConstant/)
    end
  end
end
