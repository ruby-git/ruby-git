# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::ExecutionContext do
  describe 'delegation to Git::Lib' do
    let(:base) { instance_double(Git::Base) }
    let(:lib) { instance_double(Git::Lib, branches_all: %w[main develop]) }
    let(:context) { described_class.new(base) }

    before do
      allow(Git::Lib).to receive(:new).with(base).and_return(lib)
    end

    it 'delegates methods to Git::Lib' do
      expect(context.branches_all).to eq(%w[main develop])
    end

    it 'responds to methods that Git::Lib responds to' do
      allow(lib).to receive(:respond_to?).with(:branches_all, false).and_return(true)

      expect(context.respond_to?(:branches_all)).to be true
    end
  end
end
