# frozen_string_literal: true

require 'spec_helper'
require 'git/url'

RSpec.describe Git::URL, :integration do
  include Git::IntegrationTestHelpers

  describe '.clone_to' do
    # Git::URL.clone_to predicts the directory `git clone` will create without
    # actually cloning. These examples verify that prediction against the
    # directory real git produces, which is the assumption clone_to is built on.
    around do |example|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          repo = init_test_repo('server/my_project')
          repo.commit('Initial commit', allow_empty: true)
          example.run
        end
      end
    end

    let(:source_url) { 'server/my_project' }

    context 'when cloning a working repository' do
      it 'predicts the directory git creates' do
        predicted = described_class.clone_to(source_url)
        system('git', 'clone', '--quiet', source_url, exception: true)
        expect(File).to be_directory(predicted)
      end
    end

    context 'when cloning a bare repository' do
      it 'predicts the directory git creates' do
        predicted = described_class.clone_to(source_url, bare: true)
        system('git', 'clone', '--quiet', '--bare', source_url, exception: true)
        expect(File).to be_directory(predicted)
      end
    end

    context 'when cloning a mirror repository' do
      it 'predicts the directory git creates' do
        predicted = described_class.clone_to(source_url, mirror: true)
        system('git', 'clone', '--quiet', '--mirror', source_url, exception: true)
        expect(File).to be_directory(predicted)
      end
    end
  end
end
