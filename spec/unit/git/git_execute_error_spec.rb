# frozen_string_literal: true

require 'spec_helper'
require 'git/errors'

# The subject is a string, not the constant: Git::GitExecuteError is a
# DeprecatedConstantProxy, and naming it in RSpec.describe calls `to_s` on the
# proxy at load time, which emits the deprecation warning before the suite's
# before(:suite) hook sets the raise behavior and renames the group to
# Git::Error. Under the default behavior that warning goes to stderr and nothing
# fails, so the renamed group would pass unnoticed.
RSpec.describe 'Git::GitExecuteError' do
  let(:warning) do
    /Git::GitExecuteError is deprecated and will be removed in a future major release\. Use Git::Error instead\./
  end

  it 'is Git::Error' do
    Git::Deprecation.silence { expect(Git::GitExecuteError).to be(Git::Error) }
  end

  it 'emits a deprecation warning naming the constant, the future major removal, and the replacement' do
    expect { Git::GitExecuteError.new('git failed') }.to raise_error(ActiveSupport::DeprecationException, warning)
  end

  it 'emits the deprecation warning when a rescue clause matches it' do
    expect do
      raise Git::Error, 'git failed'
    rescue Git::GitExecuteError
      nil
    end.to raise_error(ActiveSupport::DeprecationException, warning)
  end
end
