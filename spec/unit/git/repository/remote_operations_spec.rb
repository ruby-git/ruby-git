# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/remote_operations'

# Integration-level coverage for Git::Repository::RemoteOperations is provided by
# spec/integration/git/repository/remote_operations_spec.rb.
# The unit specs below cover the facade's own orchestration (argument pre-processing,
# option whitelisting, delegation contracts).

RSpec.describe Git::Repository::RemoteOperations do
  let(:base_object) { instance_double(Git::Base) }
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository, base_object: base_object) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # ---------------------------------------------------------------------------
  # #fetch
  # ---------------------------------------------------------------------------

  describe '#fetch' do
    let(:fetch_command) { instance_double(Git::Commands::Fetch) }
    let(:fetch_result) { command_result('') }

    before do
      allow(Git::Commands::Fetch)
        .to receive(:new).with(execution_context).and_return(fetch_command)
    end

    # --- Default invocation --------------------------------------------------

    context 'with default arguments' do
      subject(:result) { described_instance.fetch }

      it 'delegates to Git::Commands::Fetch.new with the execution_context' do
        expect(Git::Commands::Fetch).to receive(:new).with(execution_context).and_return(fetch_command)
        allow(fetch_command).to receive(:call).and_return(fetch_result)
        result
      end

      it 'calls Fetch#call with the default remote and merge: true' do
        expect(fetch_command)
          .to receive(:call).with('origin', merge: true).and_return(fetch_result)
        result
      end

      it 'returns the command stdout as a String' do
        allow(fetch_command).to receive(:call).and_return(command_result("From origin\n"))
        expect(result).to eq("From origin\n")
      end
    end

    # --- Named remote --------------------------------------------------------

    context 'with an explicit remote name' do
      subject(:result) { described_instance.fetch('upstream') }

      it 'passes the remote as the first positional argument' do
        expect(fetch_command)
          .to receive(:call).with('upstream', merge: true).and_return(fetch_result)
        result
      end
    end

    # --- Hash as first argument (opts only, no remote) -----------------------

    context 'when the first argument is a Hash (opts-only form)' do
      subject(:result) { described_instance.fetch(prune: true) }

      it 'treats the Hash as opts and omits the remote positional argument' do
        expect(fetch_command)
          .to receive(:call).with(prune: true, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- :all option (fetch all remotes) -------------------------------------

    context 'with all: true' do
      subject(:result) { described_instance.fetch('origin', all: true) }

      it 'forwards :all to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', all: true, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- :ref option (positional refspecs) -----------------------------------

    context 'with a single :ref value' do
      subject(:result) { described_instance.fetch('origin', ref: 'refs/heads/main') }

      it 'appends the refspec as a positional argument after the remote' do
        expect(fetch_command)
          .to receive(:call).with('origin', 'refs/heads/main', merge: true).and_return(fetch_result)
        result
      end
    end

    context 'with an Array :ref value' do
      subject(:result) { described_instance.fetch('origin', ref: %w[refs/heads/main refs/heads/develop]) }

      it 'appends each refspec as a separate positional argument' do
        expect(fetch_command)
          .to receive(:call).with('origin', 'refs/heads/main', 'refs/heads/develop', merge: true)
          .and_return(fetch_result)
        result
      end
    end

    context 'with :ref and no remote (Hash form)' do
      subject(:result) { described_instance.fetch(ref: 'refs/heads/main') }

      it 'raises ArgumentError instead of promoting the refspec to the :repository slot' do
        expect(Git::Commands::Fetch).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, /:ref requires an explicit remote/)
      end
    end

    # --- Key normalization ---------------------------------------------------

    context "with the legacy dash-style key :'update-head-ok'" do
      subject(:result) { described_instance.fetch('origin', 'update-head-ok': true) }

      it "normalizes :'update-head-ok' to :update_head_ok" do
        expect(fetch_command)
          .to receive(:call).with('origin', update_head_ok: true, merge: true).and_return(fetch_result)
        result
      end
    end

    context "with the legacy dash-style key :'prune-tags'" do
      subject(:result) { described_instance.fetch('origin', 'prune-tags': true) }

      it "normalizes :'prune-tags' to :prune_tags" do
        expect(fetch_command)
          .to receive(:call).with('origin', prune_tags: true, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- Option whitelisting -------------------------------------------------

    context 'with an unknown option key' do
      it 'raises ArgumentError before calling the command' do
        expect(fetch_command).not_to receive(:call)
        expect { described_instance.fetch('origin', unknown_opt: true) }
          .to raise_error(ArgumentError, /unknown_opt/)
      end
    end

    # --- Short-form aliases --------------------------------------------------

    context 'with the :p alias for :prune' do
      subject(:result) { described_instance.fetch('origin', p: true) }

      it 'passes :p directly to the command (the DSL handles the alias)' do
        expect(fetch_command)
          .to receive(:call).with('origin', p: true, merge: true).and_return(fetch_result)
        result
      end
    end

    context 'with the :t alias for :tags' do
      subject(:result) { described_instance.fetch('origin', t: true) }

      it 'passes :t directly to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', t: true, merge: true).and_return(fetch_result)
        result
      end
    end

    context 'with the :f alias for :force' do
      subject(:result) { described_instance.fetch('origin', f: true) }

      it 'passes :f directly to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', f: true, merge: true).and_return(fetch_result)
        result
      end
    end

    context 'with the :u alias for :update_head_ok' do
      subject(:result) { described_instance.fetch('origin', u: true) }

      it 'passes :u directly to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', u: true, merge: true).and_return(fetch_result)
        result
      end
    end

    context 'with the :P alias for :prune_tags' do
      subject(:result) { described_instance.fetch('origin', P: true) }

      it 'passes :P directly to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', P: true, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- :depth option -------------------------------------------------------

    context 'with :depth option' do
      subject(:result) { described_instance.fetch('origin', depth: 5) }

      it 'forwards :depth to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', depth: 5, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- :unshallow option ---------------------------------------------------

    context 'with :unshallow option' do
      subject(:result) { described_instance.fetch('origin', unshallow: true) }

      it 'forwards :unshallow to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', unshallow: true, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- opts hash mutation guard --------------------------------------------

    context 'when opts contains :ref' do
      it 'does not mutate the caller-provided opts hash' do
        opts = { ref: 'refs/heads/main' }
        allow(fetch_command).to receive(:call).and_return(fetch_result)
        described_instance.fetch('origin', opts)
        expect(opts).to eq(ref: 'refs/heads/main')
      end
    end
  end

  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # #pull
  # ---------------------------------------------------------------------------

  describe '#pull' do
    let(:pull_command) { instance_double(Git::Commands::Pull) }
    let(:pull_result) { command_result('') }

    before do
      allow(Git::Commands::Pull)
        .to receive(:new).with(execution_context).and_return(pull_command)
    end

    # --- Default invocation --------------------------------------------------

    context 'with default arguments' do
      subject(:result) { described_instance.pull }

      it 'delegates to Git::Commands::Pull.new with the execution_context' do
        expect(Git::Commands::Pull).to receive(:new).with(execution_context).and_return(pull_command)
        allow(pull_command).to receive(:call).and_return(pull_result)
        result
      end

      it 'calls Pull#call with no positional args and policy options' do
        expect(pull_command)
          .to receive(:call).with(no_edit: true, no_progress: true).and_return(pull_result)
        result
      end

      it 'returns the command stdout as a String' do
        allow(pull_command).to receive(:call).and_return(command_result("From origin\n * branch HEAD -> FETCH_HEAD\n"))
        expect(result).to eq("From origin\n * branch HEAD -> FETCH_HEAD\n")
      end
    end

    # --- Named remote --------------------------------------------------------

    context 'with an explicit remote name' do
      subject(:result) { described_instance.pull('upstream') }

      it 'passes the remote as the first positional argument' do
        expect(pull_command)
          .to receive(:call).with('upstream', no_edit: true, no_progress: true).and_return(pull_result)
        result
      end
    end

    # --- Remote and branch ---------------------------------------------------

    context 'with a remote and a branch' do
      subject(:result) { described_instance.pull('origin', 'main') }

      it 'passes remote and branch as positional arguments' do
        expect(pull_command)
          .to receive(:call).with('origin', 'main', no_edit: true, no_progress: true).and_return(pull_result)
        result
      end
    end

    # --- Branch without remote ----------------------------------------------

    context 'when branch is specified without a remote' do
      it 'raises ArgumentError before calling the command' do
        expect(pull_command).not_to receive(:call)
        expect { described_instance.pull(nil, 'main') }
          .to raise_error(ArgumentError, /You must specify a remote if a branch is specified/)
      end
    end

    # --- :allow_unrelated_histories option ----------------------------------

    context 'with allow_unrelated_histories: true' do
      subject(:result) { described_instance.pull('origin', 'main', allow_unrelated_histories: true) }

      it 'forwards the option to the command' do
        expect(pull_command)
          .to receive(:call)
          .with('origin', 'main', no_edit: true, no_progress: true, allow_unrelated_histories: true)
          .and_return(pull_result)
        result
      end
    end

    # --- Option whitelisting -------------------------------------------------

    context 'with an unknown option key' do
      it 'raises ArgumentError before calling the command' do
        expect(pull_command).not_to receive(:call)
        expect { described_instance.pull('origin', nil, unknown_opt: true) }
          .to raise_error(ArgumentError, /unknown_opt/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #push
  # ---------------------------------------------------------------------------

  describe '#push' do
    let(:push_command) { instance_double(Git::Commands::Push) }
    let(:push_result) { command_result('') }

    before do
      allow(Git::Commands::Push)
        .to receive(:new).with(execution_context).and_return(push_command)
    end

    # --- Default invocation (no args) ---------------------------------------

    context 'with no arguments' do
      subject(:result) { described_instance.push }

      it 'delegates to Git::Commands::Push.new with the execution_context' do
        expect(Git::Commands::Push).to receive(:new).with(execution_context).and_return(push_command)
        allow(push_command).to receive(:call).and_return(push_result)
        result
      end

      it 'calls Push#call with no positional args and no options' do
        expect(push_command).to receive(:call).with(no_args).and_return(push_result)
        result
      end

      it 'returns the command stdout as a String' do
        allow(push_command).to receive(:call).and_return(command_result("To origin\n"))
        expect(result).to eq("To origin\n")
      end
    end

    # --- Named remote only ---------------------------------------------------

    context 'with an explicit remote name' do
      subject(:result) { described_instance.push('upstream') }

      it 'passes the remote as the first positional argument' do
        expect(push_command).to receive(:call).with('upstream').and_return(push_result)
        result
      end
    end

    # --- Named remote + branch ----------------------------------------------

    context 'with a remote and branch' do
      subject(:result) { described_instance.push('origin', 'main') }

      it 'passes both remote and branch as positional arguments' do
        expect(push_command).to receive(:call).with('origin', 'main').and_return(push_result)
        result
      end
    end

    # --- Hash as first argument (opts-only, no remote) ----------------------

    context 'when the first argument is a Hash (opts-only form)' do
      subject(:result) { described_instance.push(force: true) }

      it 'treats the Hash as opts and omits the remote positional argument' do
        expect(push_command).to receive(:call).with(force: true).and_return(push_result)
        result
      end
    end

    # --- Hash as second argument (remote + opts form) -----------------------

    context 'when the second argument is a Hash (remote + opts form)' do
      subject(:result) { described_instance.push('origin', force: true) }

      it 'treats the Hash as opts and passes only the remote positionally' do
        expect(push_command).to receive(:call).with('origin', force: true).and_return(push_result)
        result
      end
    end

    # --- :tags option (two-push orchestration) ------------------------------

    context 'with tags: true' do
      let(:first_result) { command_result('first push') }
      let(:second_result) { command_result('tags push') }

      it 'issues two Git::Commands::Push calls' do
        expect(push_command).to receive(:call).with('origin', 'main').and_return(first_result)
        expect(push_command).to receive(:call).with('origin', tags: true).and_return(second_result)
        described_instance.push('origin', 'main', tags: true)
      end

      it 'returns the stdout from the tags push (second call)' do
        allow(push_command).to receive(:call).with('origin', 'main').and_return(first_result)
        allow(push_command).to receive(:call).with('origin', tags: true).and_return(second_result)
        expect(described_instance.push('origin', 'main', tags: true)).to eq('tags push')
      end
    end

    # --- :mirror + :tags (single-push, tags suppressed) ---------------------

    context 'with mirror: true and tags: true' do
      let(:mirror_result) { command_result('mirror push') }

      it 'issues only one Git::Commands::Push call (mirror subsumes tags)' do
        expect(push_command).to receive(:call).once.with('origin', 'main', mirror: true).and_return(mirror_result)
        described_instance.push('origin', 'main', mirror: true, tags: true)
      end

      it 'returns the stdout from the single mirror push' do
        allow(push_command).to receive(:call).with('origin', 'main', mirror: true).and_return(mirror_result)
        expect(described_instance.push('origin', 'main', mirror: true, tags: true)).to eq('mirror push')
      end
    end

    # --- :all + :tags (two-push orchestration) ------------------------------

    context 'with all: true and tags: true' do
      let(:all_result) { command_result('all push') }
      let(:all_tags_result) { command_result('all tags push') }

      it 'issues two Git::Commands::Push calls' do
        expect(push_command).to receive(:call).with('origin', all: true).and_return(all_result)
        expect(push_command).to receive(:call).with('origin', all: true, tags: true).and_return(all_tags_result)
        described_instance.push('origin', all: true, tags: true)
      end

      it 'returns the stdout from the tags push (second call)' do
        allow(push_command).to receive(:call).with('origin', all: true).and_return(all_result)
        allow(push_command).to receive(:call).with('origin', all: true, tags: true).and_return(all_tags_result)
        expect(described_instance.push('origin', all: true, tags: true)).to eq('all tags push')
      end
    end

    # --- Legacy Boolean shorthand (backward compatibility) ------------------

    context 'with Boolean true as third argument (legacy shorthand)' do
      let(:refs_result) { command_result('refs') }
      let(:tags_result) { command_result('tags') }

      it 'converts the Boolean to tags: true and issues two calls' do
        expect(push_command).to receive(:call).with('origin', 'main').and_return(refs_result)
        expect(push_command).to receive(:call).with('origin', tags: true).and_return(tags_result)
        described_instance.push('origin', 'main', true)
      end
    end

    context 'with Boolean false as third argument (legacy shorthand)' do
      it 'converts the Boolean to tags: false and issues one call (no tags)' do
        expect(push_command).to receive(:call).once.with('origin', 'main').and_return(push_result)
        described_instance.push('origin', 'main', false)
      end
    end

    # --- :force option -------------------------------------------------------

    context 'with force: true' do
      it 'forwards :force to the Push command' do
        expect(push_command)
          .to receive(:call).with('origin', 'main', force: true).and_return(push_result)
        described_instance.push('origin', 'main', force: true)
      end
    end

    # --- :f alias ------------------------------------------------------------

    context 'with f: true (alias for :force)' do
      it 'forwards :f to the Push command' do
        expect(push_command)
          .to receive(:call).with('origin', 'main', f: true).and_return(push_result)
        described_instance.push('origin', 'main', f: true)
      end
    end

    # --- :delete option ------------------------------------------------------

    context 'with delete: true' do
      it 'forwards :delete to the Push command' do
        expect(push_command)
          .to receive(:call).with('origin', 'main', delete: true).and_return(push_result)
        described_instance.push('origin', 'main', delete: true)
      end
    end

    # --- :push_option --------------------------------------------------------

    context 'with a single :push_option value' do
      it 'forwards :push_option to the Push command' do
        expect(push_command)
          .to receive(:call).with('origin', push_option: 'ci.skip').and_return(push_result)
        described_instance.push('origin', push_option: 'ci.skip')
      end
    end

    context 'with an Array :push_option value' do
      it 'forwards the full Array to the Push command' do
        expect(push_command)
          .to receive(:call).with('origin', push_option: %w[foo bar]).and_return(push_result)
        described_instance.push('origin', push_option: %w[foo bar])
      end
    end

    # --- branch without remote raises ---------------------------------------

    context 'when branch is given without a remote' do
      it 'raises ArgumentError before calling the command' do
        expect(push_command).not_to receive(:call)
        expect { described_instance.push(nil, 'main') }
          .to raise_error(ArgumentError, /remote is required/)
      end
    end

    # --- Option whitelisting -------------------------------------------------

    context 'with an unknown option key' do
      it 'raises ArgumentError before calling the command' do
        expect(push_command).not_to receive(:call)
        expect { described_instance.push('origin', unknown_key: true) }
          .to raise_error(ArgumentError, /unknown_key/)
      end
    end

    context 'with :branches option (supported by command but not 4.x facade)' do
      it 'raises ArgumentError' do
        expect(push_command).not_to receive(:call)
        expect { described_instance.push('origin', branches: true) }
          .to raise_error(ArgumentError, /branches/)
      end
    end

    context 'with :timeout option (supported by command but not 4.x facade)' do
      it 'raises ArgumentError' do
        expect(push_command).not_to receive(:call)
        expect { described_instance.push('origin', timeout: 30) }
          .to raise_error(ArgumentError, /timeout/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #add_remote
  # ---------------------------------------------------------------------------

  describe '#add_remote' do
    let(:add_remote_command) { instance_double(Git::Commands::Remote::Add) }
    let(:add_remote_result) { command_result('') }
    let(:remote_object) { instance_double(Git::Remote) }

    before do
      allow(Git::Commands::Remote::Add)
        .to receive(:new).with(execution_context).and_return(add_remote_command)
      allow(add_remote_command).to receive(:call).and_return(add_remote_result)
      allow(Git::Remote).to receive(:new).and_return(remote_object)
    end

    # --- Default invocation --------------------------------------------------

    context 'with name and url only' do
      subject(:result) { described_instance.add_remote('upstream', 'https://example.com/repo.git') }

      it 'delegates to Git::Commands::Remote::Add.new with the execution_context' do
        expect(Git::Commands::Remote::Add).to receive(:new).with(execution_context).and_return(add_remote_command)
        result
      end

      it 'calls Add#call with name and url' do
        expect(add_remote_command)
          .to receive(:call).with('upstream', 'https://example.com/repo.git').and_return(add_remote_result)
        result
      end

      it 'returns Git::Remote' do
        expect(Git::Remote).to receive(:new).with(described_instance, 'upstream').and_return(remote_object)
        expect(result).to eq(remote_object)
      end
    end

    context 'with url as Git::Base' do
      let(:url_base) do
        Object.new.tap do |obj|
          def obj.repo
            Pathname.new('/tmp/source.git')
          end

          def obj.is_a?(klass)
            klass == Git::Base || super
          end
        end
      end

      subject(:result) { described_instance.add_remote('upstream', url_base) }

      it 'normalizes url to repo.to_s before calling the command' do
        expect(add_remote_command)
          .to receive(:call).with('upstream', '/tmp/source.git').and_return(add_remote_result)
        result
      end
    end

    # --- :fetch option -------------------------------------------------------

    context 'with fetch: true' do
      subject(:result) { described_instance.add_remote('upstream', 'https://example.com/repo.git', fetch: true) }

      it 'forwards :fetch to the command' do
        expect(add_remote_command)
          .to receive(:call).with('upstream', 'https://example.com/repo.git', fetch: true)
          .and_return(add_remote_result)
        result
      end
    end

    # --- :track option -------------------------------------------------------

    context 'with track: "main"' do
      subject(:result) { described_instance.add_remote('upstream', 'https://example.com/repo.git', track: 'main') }

      it 'forwards :track to the command' do
        expect(add_remote_command)
          .to receive(:call).with('upstream', 'https://example.com/repo.git', track: 'main')
          .and_return(add_remote_result)
        result
      end
    end

    # --- :with_fetch alias (deprecated) --------------------------------------

    context 'with the deprecated :with_fetch alias' do
      subject(:result) { described_instance.add_remote('upstream', 'https://example.com/repo.git', with_fetch: true) }

      it 'normalizes :with_fetch to :fetch before calling the command' do
        expect(add_remote_command)
          .to receive(:call).with('upstream', 'https://example.com/repo.git', fetch: true)
          .and_return(add_remote_result)
        result
      end
    end

    # --- Option whitelisting -------------------------------------------------

    context 'with an unknown option key' do
      it 'raises ArgumentError before calling the command' do
        expect(add_remote_command).not_to receive(:call)
        expect { described_instance.add_remote('upstream', 'https://example.com/repo.git', unknown_opt: true) }
          .to raise_error(ArgumentError, /unknown_opt/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #remove_remote
  # ---------------------------------------------------------------------------

  describe '#remove_remote' do
    subject(:result) { described_instance.remove_remote('upstream') }

    let(:remove_command) { instance_double(Git::Commands::Remote::Remove) }
    let(:remove_result) { command_result('') }

    before do
      allow(Git::Commands::Remote::Remove)
        .to receive(:new).with(execution_context).and_return(remove_command)
    end

    it 'delegates to Git::Commands::Remote::Remove.new with the execution_context' do
      expect(Git::Commands::Remote::Remove)
        .to receive(:new).with(execution_context).and_return(remove_command)
      allow(remove_command).to receive(:call).and_return(remove_result)
      result
    end

    it 'calls Remove#call with the remote name' do
      expect(remove_command).to receive(:call).with('upstream').and_return(remove_result)
      result
    end

    it 'returns the Git::CommandLineResult' do
      allow(remove_command).to receive(:call).and_return(remove_result)
      expect(result).to be(remove_result)
    end
  end

  # ---------------------------------------------------------------------------
  # #config_remote
  # ---------------------------------------------------------------------------

  describe '#config_remote' do
    let(:list_command) { instance_double(Git::Commands::ConfigOptionSyntax::List) }
    let(:list_result) { command_result('') }

    before do
      allow(Git::Commands::ConfigOptionSyntax::List)
        .to receive(:new).with(execution_context).and_return(list_command)
      allow(list_command).to receive(:call).and_return(list_result)
    end

    context 'when the remote has entries in git config' do
      subject(:result) { described_instance.config_remote('origin') }

      let(:config_stdout) do
        "remote.origin.url=https://github.com/user/repo.git\n" \
          "remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*\n" \
          "core.bare=false\n"
      end
      let(:list_result) { command_result(config_stdout) }

      it 'returns a Hash' do
        expect(result).to be_a(Hash)
      end

      it 'strips the remote.<name>. prefix and returns only matching entries' do
        expect(result).to eq(
          'url' => 'https://github.com/user/repo.git',
          'fetch' => '+refs/heads/*:refs/remotes/origin/*'
        )
      end

      it 'delegates to Git::Commands::ConfigOptionSyntax::List.new with the execution_context' do
        expect(Git::Commands::ConfigOptionSyntax::List)
          .to receive(:new).with(execution_context).and_return(list_command)
        result
      end
    end

    context 'when no entries exist for the named remote' do
      let(:list_result) { command_result("core.bare=false\n") }

      it 'returns an empty hash' do
        expect(described_instance.config_remote('nonexistent')).to eq({})
      end
    end

    context 'when a config value itself contains an equals sign' do
      let(:list_result) { command_result("remote.origin.custom=key=value\n") }

      it 'preserves the full value including the extra equals sign' do
        result = described_instance.config_remote('origin')
        expect(result['custom']).to eq('key=value')
      end
    end

    context 'when a config line has no value (no equals sign)' do
      let(:list_result) { command_result("remote.origin.novalue\n") }

      it 'defaults the value to an empty string' do
        result = described_instance.config_remote('origin')
        expect(result['novalue']).to eq('')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #remote
  # ---------------------------------------------------------------------------

  describe '#remote' do
    let(:config_list_command) { instance_double(Git::Commands::ConfigOptionSyntax::List) }
    let(:config_stdout) do
      "remote.origin.url=https://github.com/user/repo.git\n" \
        "remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*\n"
    end

    before do
      allow(Git::Commands::ConfigOptionSyntax::List)
        .to receive(:new).with(execution_context).and_return(config_list_command)
      allow(config_list_command).to receive(:call).and_return(command_result(config_stdout))
    end

    context 'with an explicit remote name' do
      subject(:result) { described_instance.remote('upstream') }

      it 'returns a Git::Remote for the given name' do
        expect(result).to be_a(Git::Remote)
      end

      it 'sets the name attribute to the given remote name' do
        expect(result.name).to eq('upstream')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #set_remote_url
  # ---------------------------------------------------------------------------

  describe '#set_remote_url' do
    let(:set_url_command) { instance_double(Git::Commands::Remote::SetUrl) }
    let(:set_url_result) { command_result('') }
    let(:remote_object) { instance_double(Git::Remote) }

    before do
      allow(Git::Commands::Remote::SetUrl)
        .to receive(:new).with(execution_context).and_return(set_url_command)
      allow(set_url_command).to receive(:call).and_return(set_url_result)
      allow(Git::Remote).to receive(:new).and_return(remote_object)
    end

    context 'with a string url' do
      subject(:result) { described_instance.set_remote_url('origin', 'https://example.com/repo.git') }

      it 'delegates to Git::Commands::Remote::SetUrl.new with the execution_context' do
        expect(Git::Commands::Remote::SetUrl)
          .to receive(:new).with(execution_context).and_return(set_url_command)
        result
      end

      it 'calls SetUrl#call with the name and url' do
        expect(set_url_command)
          .to receive(:call).with('origin', 'https://example.com/repo.git').and_return(set_url_result)
        result
      end

      it 'returns the Git::Remote for the updated name' do
        expect(Git::Remote).to receive(:new).with(described_instance, 'origin').and_return(remote_object)
        expect(result).to eq(remote_object)
      end
    end

    context 'with url as a Git::Base' do
      let(:url_base) do
        Object.new.tap do |obj|
          def obj.repo
            Pathname.new('/tmp/source.git')
          end

          def obj.is_a?(klass)
            klass == Git::Base || super
          end
        end
      end

      subject(:result) { described_instance.set_remote_url('origin', url_base) }

      it 'normalizes the url to repo.to_s before calling the command' do
        expect(set_url_command)
          .to receive(:call).with('origin', '/tmp/source.git').and_return(set_url_result)
        result
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #remote_set_branches
  # ---------------------------------------------------------------------------

  describe '#remote_set_branches' do
    let(:set_branches_command) { instance_double(Git::Commands::Remote::SetBranches) }
    let(:set_branches_result) { command_result('') }

    before do
      allow(Git::Commands::Remote::SetBranches)
        .to receive(:new).with(execution_context).and_return(set_branches_command)
      allow(set_branches_command).to receive(:call).and_return(set_branches_result)
    end

    context 'with a single branch' do
      subject(:result) { described_instance.remote_set_branches('origin', 'main') }

      it 'delegates to Git::Commands::Remote::SetBranches.new with the execution_context' do
        expect(Git::Commands::Remote::SetBranches)
          .to receive(:new).with(execution_context).and_return(set_branches_command)
        result
      end

      it 'calls SetBranches#call with the name, branch, and add: false' do
        expect(set_branches_command)
          .to receive(:call).with('origin', 'main', add: false).and_return(set_branches_result)
        result
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'with multiple branches' do
      subject(:result) { described_instance.remote_set_branches('origin', 'main', 'develop') }

      it 'forwards each branch to the command' do
        expect(set_branches_command)
          .to receive(:call).with('origin', 'main', 'develop', add: false).and_return(set_branches_result)
        result
      end
    end

    context 'with a nested array of branches' do
      subject(:result) { described_instance.remote_set_branches('origin', %w[main develop]) }

      it 'flattens the branches before calling the command' do
        expect(set_branches_command)
          .to receive(:call).with('origin', 'main', 'develop', add: false).and_return(set_branches_result)
        result
      end
    end

    context 'with add: true' do
      subject(:result) { described_instance.remote_set_branches('origin', 'release/*', add: true) }

      it 'forwards add: true to the command' do
        expect(set_branches_command)
          .to receive(:call).with('origin', 'release/*', add: true).and_return(set_branches_result)
        result
      end
    end

    context 'with no branches' do
      it 'raises ArgumentError before calling the command' do
        expect(set_branches_command).not_to receive(:call)
        expect { described_instance.remote_set_branches('origin') }
          .to raise_error(ArgumentError, /branches are required/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #remotes
  # ---------------------------------------------------------------------------

  describe '#remotes' do
    let(:list_command) { instance_double(Git::Commands::Remote::List) }

    before do
      allow(Git::Commands::Remote::List)
        .to receive(:new).with(execution_context).and_return(list_command)
      allow(list_command).to receive(:call).and_return(command_result("origin\nupstream\n"))
      allow(Git::Remote).to receive(:new) { |_base, name| instance_double(Git::Remote, name: name) }
    end

    it 'delegates to Git::Commands::Remote::List.new with the execution_context' do
      expect(Git::Commands::Remote::List)
        .to receive(:new).with(execution_context).and_return(list_command)
      described_instance.remotes
    end

    it 'returns a Git::Remote for each configured remote' do
      expect(described_instance.remotes.map(&:name)).to eq(%w[origin upstream])
    end

    it 'builds each Git::Remote with the repository and remote name' do
      expect(Git::Remote).to receive(:new).with(described_instance, 'origin')
      expect(Git::Remote).to receive(:new).with(described_instance, 'upstream')
      described_instance.remotes
    end

    context 'when no remotes are configured' do
      before do
        allow(list_command).to receive(:call).and_return(command_result(''))
      end

      it 'returns an empty array' do
        expect(described_instance.remotes).to eq([])
      end
    end
  end
end
