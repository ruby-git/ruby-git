# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'rbconfig'

RSpec.describe 'loading git' do
  let(:project_root) { File.expand_path('../../..', __dir__) }
  let(:lib_path) { File.join(project_root, 'lib') }

  subject(:load_git) do
    Open3.capture3(
      RbConfig.ruby,
      '-w',
      "-I#{lib_path}",
      '-rgit',
      '-e',
      'puts :ok',
      chdir: project_root
    )
  end

  it 'does not emit circular require warnings' do
    stdout, stderr, status = load_git

    expect(status).to be_success
    expect(stdout).to eq("ok\n")
    expect(stderr).not_to include('circular require considered harmful')
  end
end
