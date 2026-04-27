# frozen_string_literal: true

require 'spec_helper'
require 'git/execution_context/global'

RSpec.describe Git::ExecutionContext::Global do
  describe 'inheritance' do
    it 'is a Git::ExecutionContext' do
      expect(described_class.new).to be_a(Git::ExecutionContext)
    end
  end

  describe '#initialize' do
    it 'can be created with no arguments' do
      expect { described_class.new }.not_to raise_error
    end

    it 'accepts an optional logger' do
      logger = double('logger')
      expect { described_class.new(logger: logger) }.not_to raise_error
    end

    it 'accepts an optional git_ssh path' do
      expect { described_class.new(git_ssh: '/usr/bin/ssh') }.not_to raise_error
    end

    it 'accepts an optional binary_path' do
      expect { described_class.new(binary_path: '/usr/local/bin/git') }.not_to raise_error
    end
  end

  describe 'binary_path resolution' do
    it 'delegates to Git::Base.config by default' do
      allow(Git::Base).to receive_message_chain(:config, :binary_path).and_return('/global/git')
      expect(described_class.new.binary_path).to eq('/global/git')
    end

    it 'returns an explicit path when provided' do
      expect(described_class.new(binary_path: '/usr/local/bin/git').binary_path).to eq('/usr/local/bin/git')
    end

    it 'raises ArgumentError when explicitly passed nil' do
      expect { described_class.new(binary_path: nil) }.to raise_error(ArgumentError, /binary_path/)
    end
  end

  describe 'accessor methods' do
    let(:context) { described_class.new(git_ssh: nil) }

    it 'returns nil for git_dir' do
      expect(context.git_dir).to be_nil
    end

    it 'returns nil for git_work_dir' do
      expect(context.git_work_dir).to be_nil
    end

    it 'returns nil for git_index_file' do
      expect(context.git_index_file).to be_nil
    end
  end

  describe 'git_ssh resolution' do
    it 'delegates to Git::Base.config by default' do
      allow(Git::Base).to receive_message_chain(:config, :git_ssh).and_return('/global/ssh')
      expect(described_class.new.git_ssh).to eq('/global/ssh')
    end

    it 'returns nil when explicitly passed nil' do
      expect(described_class.new(git_ssh: nil).git_ssh).to be_nil
    end

    it 'returns a literal path when provided' do
      expect(described_class.new(git_ssh: '/usr/bin/ssh').git_ssh).to eq('/usr/bin/ssh')
    end
  end

  describe 'env_overrides (via #send)' do
    let(:context) { described_class.new(git_ssh: nil) }

    it 'explicitly unsets GIT_DIR' do
      expect(context.send(:env_overrides)['GIT_DIR']).to be_nil
    end

    it 'explicitly unsets GIT_WORK_TREE' do
      expect(context.send(:env_overrides)['GIT_WORK_TREE']).to be_nil
    end

    it 'explicitly unsets GIT_INDEX_FILE' do
      expect(context.send(:env_overrides)['GIT_INDEX_FILE']).to be_nil
    end

    it 'explicitly unsets GIT_SSH when git_ssh is nil' do
      expect(context.send(:env_overrides)['GIT_SSH']).to be_nil
    end

    it 'sets GIT_EDITOR to "true" (no-op editor)' do
      expect(context.send(:env_overrides)['GIT_EDITOR']).to eq('true')
    end

    it 'sets LC_ALL to "en_US.UTF-8"' do
      expect(context.send(:env_overrides)['LC_ALL']).to eq('en_US.UTF-8')
    end

    it 'merges caller-supplied additional overrides' do
      env = context.send(:env_overrides, 'MY_VAR' => 'val')
      expect(env['MY_VAR']).to eq('val')
    end
  end

  describe 'global_opts (via #send)' do
    let(:context) { described_class.new }

    it 'does not include --git-dir' do
      expect(context.send(:global_opts).grep(/\A--git-dir/)).to be_empty
    end

    it 'does not include --work-tree' do
      expect(context.send(:global_opts).grep(/\A--work-tree/)).to be_empty
    end

    it 'includes the static global opts' do
      expect(context.send(:global_opts)).to include('-c', 'core.quotePath=true')
    end
  end

  describe '#command_capturing' do
    let(:context) { described_class.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Capturing) }
    let(:result) { command_result('git version 2.40.0') }

    before do
      allow(context).to receive(:command_line_capturing).and_return(command_line_double)
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(nil)
    end

    it 'delegates to command_line_capturing.run' do
      expect(command_line_double).to receive(:run)
        .with('version', hash_including(raise_on_failure: true, normalize: true))
        .and_return(result)
      context.command_capturing('version')
    end
  end

  describe '#command_streaming' do
    let(:context) { described_class.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Streaming) }
    let(:result) { command_result('') }
    let(:out_io) { StringIO.new }

    before do
      allow(context).to receive(:command_line_streaming).and_return(command_line_double)
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(nil)
    end

    it 'delegates to command_line_streaming.run' do
      expect(command_line_double).to receive(:run)
        .with('clone', hash_including(out: out_io, raise_on_failure: true, timeout: nil))
        .and_return(result)
      context.command_streaming('clone', out: out_io)
    end
  end
end
