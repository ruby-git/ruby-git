# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'spec_helper' do
  describe 'execution_context_double' do
    subject(:double_instance) { execution_context_double }

    it 'responds to git_version' do
      expect(double_instance).to respond_to(:git_version)
    end

    it 'returns Gem::Version 99.99.99 by default' do
      expect(double_instance.git_version).to eq(Gem::Version.new('99.99.99'))
    end
  end

  describe 'stub_git_version' do
    let(:context) { execution_context_double }

    it 'stubs the git_version to the specified version' do
      stub_git_version(context, '2.30.0')
      expect(context.git_version).to eq(Gem::Version.new('2.30.0'))
    end
  end
end
