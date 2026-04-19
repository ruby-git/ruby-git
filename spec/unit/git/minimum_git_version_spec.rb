# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Git module' do
  describe 'MINIMUM_GIT_VERSION' do
    # Change detector: ensures intentional updates when bumping minimum version
    it 'is defined as Git::Version 2.28.0' do
      expect(Git::MINIMUM_GIT_VERSION).to eq(Git::Version.new(2, 28, 0))
    end
  end
end
