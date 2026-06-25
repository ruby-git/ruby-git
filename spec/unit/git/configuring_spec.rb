# frozen_string_literal: true

require 'spec_helper'
require 'git/configuring'

RSpec.describe Git::Configuring do
  # A minimal host class that mixes in Git::Configuring.
  # Provides the two required private collaborators so each example can focus
  # on the behavior being tested rather than the host class.
  let(:host_class) do
    Class.new do
      include Git::Configuring

      def initialize(ctx)
        @execution_context = ctx
      end

      private

      attr_reader :execution_context

      def assert_valid_scope!(**) = nil
    end
  end

  let(:execution_context) { instance_double('Git::ExecutionContext::Repository') }
  let(:host) { host_class.new(execution_context) }

  # ---------------------------------------------------------------------------
  # READ OPERATIONS
  # ---------------------------------------------------------------------------

  describe '#config_get' do
    let(:get_command) { instance_double(Git::Commands::ConfigOptionSyntax::Get) }
    let(:raw_result) { command_result("local\0file:.git/config\0Alice\0") }
    let(:entry) { Git::ConfigEntryInfo.new(scope: 'local', origin: 'file:.git/config', key: 'user.name', value: 'Alice') }

    before do
      allow(Git::Commands::ConfigOptionSyntax::Get)
        .to receive(:new).with(execution_context).and_return(get_command)
    end

    it 'delegates to the Get command with show_scope, show_origin, and null options' do
      expect(get_command).to receive(:call)
        .with('user.name', nil, show_scope: true, show_origin: true, null: true)
        .and_return(raw_result)

      host.config_get('user.name')
    end

    it 'returns a ConfigEntryInfo parsed from the output' do
      allow(get_command).to receive(:call).and_return(raw_result)
      allow(Git::Parsers::ConfigEntry).to receive(:parse_get)
        .with('user.name', raw_result.stdout)
        .and_return(entry)

      expect(host.config_get('user.name')).to eq(entry)
    end

    it 'returns nil when the key is not found' do
      allow(get_command).to receive(:call).and_return(command_result(''))
      expect(host.config_get('user.name')).to be_nil
    end

    it 'returns a ConfigEntryInfo with command scope when a default value is used for a missing key' do
      default_raw = command_result("command\0command line:\0fallback\0")
      allow(get_command).to receive(:call)
        .with('user.bogus', nil, default: 'fallback', show_scope: true, show_origin: true, null: true)
        .and_return(default_raw)

      result = host.config_get('user.bogus', default: 'fallback')

      expect(result).to be_a(Git::ConfigEntryInfo)
      expect(result.scope).to eq('command')
      expect(result.origin).to eq('command line:')
      expect(result.value).to eq('fallback')
    end

    it 'forwards a value_regex to the command' do
      expect(get_command).to receive(:call)
        .with('remote.origin.url', 'github', show_scope: true, show_origin: true, null: true)
        .and_return(raw_result)

      host.config_get('remote.origin.url', 'github')
    end

    it 'forwards scope and filter options to the command' do
      expect(get_command).to receive(:call)
        .with('user.name', nil, global: true, show_scope: true, show_origin: true, null: true)
        .and_return(raw_result)

      host.config_get('user.name', global: true)
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_get('user.name', bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end

    it 'calls assert_valid_scope! before running the command' do
      allow(get_command).to receive(:call).and_return(raw_result)
      expect(host).to receive(:assert_valid_scope!).with(no_args)

      host.config_get('user.name')
    end
  end

  describe '#config_get_all' do
    let(:get_all_command) { instance_double(Git::Commands::ConfigOptionSyntax::GetAll) }
    let(:raw_result) do
      command_result(
        "local\0file:.git/config\0https://github.com/ruby-git/ruby-git\0" \
        "local\0file:.git/config\0git@github.com:ruby-git/ruby-git.git\0"
      )
    end

    before do
      allow(Git::Commands::ConfigOptionSyntax::GetAll)
        .to receive(:new).with(execution_context).and_return(get_all_command)
    end

    it 'delegates to the GetAll command' do
      expect(get_all_command).to receive(:call)
        .with('remote.origin.url', nil, show_scope: true, show_origin: true, null: true)
        .and_return(raw_result)

      host.config_get_all('remote.origin.url')
    end

    it 'returns an array of ConfigEntryInfo objects' do
      allow(get_all_command).to receive(:call).and_return(raw_result)

      result = host.config_get_all('remote.origin.url')

      expect(result).to all(be_a(Git::ConfigEntryInfo))
      expect(result.size).to eq(2)
    end

    it 'returns an empty array when the key has no values' do
      allow(get_all_command).to receive(:call).and_return(command_result(''))

      expect(host.config_get_all('user.name')).to eq([])
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_get_all('user.name', bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe '#config_get_colorbool' do
    let(:colorbool_command) { instance_double(Git::Commands::ConfigOptionSyntax::GetColorBool) }

    before do
      allow(Git::Commands::ConfigOptionSyntax::GetColorBool)
        .to receive(:new).with(execution_context).and_return(colorbool_command)
    end

    it 'delegates to the GetColorBool command' do
      expect(colorbool_command).to receive(:call)
        .with('color.ui', nil)
        .and_return(command_result("true\n"))

      host.config_get_colorbool('color.ui')
    end

    it 'returns a chomped string' do
      allow(colorbool_command).to receive(:call).and_return(command_result("false\n"))

      expect(host.config_get_colorbool('color.ui')).to eq('false')
    end

    it 'forwards stdout_is_tty to the command' do
      expect(colorbool_command).to receive(:call)
        .with('color.ui', true)
        .and_return(command_result("true\n"))

      host.config_get_colorbool('color.ui', true)
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_get_colorbool('color.ui', nil, bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe '#config_get_regexp' do
    let(:get_regexp_command) { instance_double(Git::Commands::ConfigOptionSyntax::GetRegexp) }
    let(:raw_result) { command_result("local\0file:.git/config\0remote.origin.url\nhttps://github.com\0") }

    before do
      allow(Git::Commands::ConfigOptionSyntax::GetRegexp)
        .to receive(:new).with(execution_context).and_return(get_regexp_command)
    end

    it 'delegates to the GetRegexp command' do
      expect(get_regexp_command).to receive(:call)
        .with('remote\..*\.url', nil, show_scope: true, show_origin: true, null: true)
        .and_return(raw_result)

      host.config_get_regexp('remote\..*\.url')
    end

    it 'returns an array of ConfigEntryInfo objects' do
      allow(get_regexp_command).to receive(:call).and_return(raw_result)

      result = host.config_get_regexp('remote\..*\.url')

      expect(result).to all(be_a(Git::ConfigEntryInfo))
      expect(result.size).to eq(1)
      expect(result[0].value).to eq('https://github.com')
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_get_regexp('user\..*', bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe '#config_get_urlmatch' do
    let(:get_urlmatch_command) { instance_double(Git::Commands::ConfigOptionSyntax::GetUrlmatch) }
    let(:raw_result) { command_result("local\0http.sslVerify\ntrue\0") }

    before do
      allow(Git::Commands::ConfigOptionSyntax::GetUrlmatch)
        .to receive(:new).with(execution_context).and_return(get_urlmatch_command)
    end

    it 'delegates to the GetUrlmatch command without show_origin (unsupported by git)' do
      expect(get_urlmatch_command).to receive(:call)
        .with('http', 'https://example.com', show_scope: true, null: true)
        .and_return(raw_result)

      host.config_get_urlmatch('http', 'https://example.com')
    end

    it 'returns an array of ConfigEntryInfo objects' do
      allow(get_urlmatch_command).to receive(:call).and_return(raw_result)

      result = host.config_get_urlmatch('http', 'https://example.com')

      expect(result).to all(be_a(Git::ConfigEntryInfo))
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_get_urlmatch('http', 'https://example.com', bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe '#config_list' do
    let(:list_command) { instance_double(Git::Commands::ConfigOptionSyntax::List) }
    let(:raw_result) do
      command_result(
        "local\0file:.git/config\0user.name\nAlice\0" \
        "local\0file:.git/config\0core.bare\nfalse\0"
      )
    end

    before do
      allow(Git::Commands::ConfigOptionSyntax::List)
        .to receive(:new).with(execution_context).and_return(list_command)
    end

    it 'delegates to the List command with show_scope, show_origin, and null options' do
      expect(list_command).to receive(:call)
        .with(show_scope: true, show_origin: true, null: true)
        .and_return(raw_result)

      host.config_list
    end

    it 'returns an array of ConfigEntryInfo objects' do
      allow(list_command).to receive(:call).and_return(raw_result)

      result = host.config_list

      expect(result).to all(be_a(Git::ConfigEntryInfo))
      expect(result.size).to eq(2)
    end

    it 'returns an empty array when there are no config entries' do
      allow(list_command).to receive(:call).and_return(command_result(''))

      expect(host.config_list).to eq([])
    end

    it 'forwards scope options to the command' do
      expect(list_command).to receive(:call)
        .with(global: true, show_scope: true, show_origin: true, null: true)
        .and_return(raw_result)

      host.config_list(global: true)
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_list(bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  # ---------------------------------------------------------------------------
  # WRITE OPERATIONS
  # ---------------------------------------------------------------------------

  describe '#config_add' do
    let(:add_command) { instance_double(Git::Commands::ConfigOptionSyntax::Add) }

    before do
      allow(Git::Commands::ConfigOptionSyntax::Add)
        .to receive(:new).with(execution_context).and_return(add_command)
      allow(add_command).to receive(:call)
    end

    it 'delegates to the Add command' do
      expect(add_command).to receive(:call).with('remote.origin.url', 'https://github.com/ruby-git/ruby-git')

      host.config_add('remote.origin.url', 'https://github.com/ruby-git/ruby-git')
    end

    it 'returns nil' do
      expect(host.config_add('user.name', 'Alice')).to be_nil
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_add('user.name', 'Alice', bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe '#config_remove_section' do
    let(:remove_section_command) { instance_double(Git::Commands::ConfigOptionSyntax::RemoveSection) }

    before do
      allow(Git::Commands::ConfigOptionSyntax::RemoveSection)
        .to receive(:new).with(execution_context).and_return(remove_section_command)
      allow(remove_section_command).to receive(:call)
    end

    it 'delegates to the RemoveSection command' do
      expect(remove_section_command).to receive(:call).with('remote.origin')

      host.config_remove_section('remote.origin')
    end

    it 'returns nil' do
      expect(host.config_remove_section('remote.origin')).to be_nil
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_remove_section('remote.origin', bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe '#config_rename_section' do
    let(:rename_section_command) { instance_double(Git::Commands::ConfigOptionSyntax::RenameSection) }

    before do
      allow(Git::Commands::ConfigOptionSyntax::RenameSection)
        .to receive(:new).with(execution_context).and_return(rename_section_command)
      allow(rename_section_command).to receive(:call)
    end

    it 'delegates to the RenameSection command' do
      expect(rename_section_command).to receive(:call).with('remote.old', 'remote.new')

      host.config_rename_section('remote.old', 'remote.new')
    end

    it 'returns nil' do
      expect(host.config_rename_section('remote.old', 'remote.new')).to be_nil
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_rename_section('remote.old', 'remote.new', bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe '#config_replace_all' do
    let(:replace_all_command) { instance_double(Git::Commands::ConfigOptionSyntax::ReplaceAll) }

    before do
      allow(Git::Commands::ConfigOptionSyntax::ReplaceAll)
        .to receive(:new).with(execution_context).and_return(replace_all_command)
      allow(replace_all_command).to receive(:call)
    end

    it 'delegates to the ReplaceAll command' do
      expect(replace_all_command).to receive(:call)
        .with('remote.origin.url', 'https://github.com/ruby-git/ruby-git', nil)

      host.config_replace_all('remote.origin.url', 'https://github.com/ruby-git/ruby-git')
    end

    it 'forwards a value_regex to the command' do
      expect(replace_all_command).to receive(:call)
        .with('remote.origin.url', 'https://github.com/ruby-git/ruby-git', 'github')

      host.config_replace_all('remote.origin.url', 'https://github.com/ruby-git/ruby-git', 'github')
    end

    it 'returns nil' do
      expect(host.config_replace_all('user.name', 'Alice')).to be_nil
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_replace_all('user.name', 'Alice', nil, bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe '#config_set' do
    let(:set_command) { instance_double(Git::Commands::ConfigOptionSyntax::Set) }

    before do
      allow(Git::Commands::ConfigOptionSyntax::Set)
        .to receive(:new).with(execution_context).and_return(set_command)
      allow(set_command).to receive(:call)
    end

    it 'delegates to the Set command' do
      expect(set_command).to receive(:call).with('user.name', 'Alice')

      host.config_set('user.name', 'Alice')
    end

    it 'returns nil' do
      expect(host.config_set('user.name', 'Alice')).to be_nil
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_set('user.name', 'Alice', bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe '#config_unset' do
    let(:unset_command) { instance_double(Git::Commands::ConfigOptionSyntax::Unset) }

    before do
      allow(Git::Commands::ConfigOptionSyntax::Unset)
        .to receive(:new).with(execution_context).and_return(unset_command)
      allow(unset_command).to receive(:call)
    end

    it 'delegates to the Unset command' do
      expect(unset_command).to receive(:call).with('user.name', nil)

      host.config_unset('user.name')
    end

    it 'forwards a value_regex to the command' do
      expect(unset_command).to receive(:call).with('user.name', 'Alice')

      host.config_unset('user.name', 'Alice')
    end

    it 'returns nil' do
      expect(host.config_unset('user.name')).to be_nil
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_unset('user.name', nil, bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe '#config_unset_all' do
    let(:unset_all_command) { instance_double(Git::Commands::ConfigOptionSyntax::UnsetAll) }

    before do
      allow(Git::Commands::ConfigOptionSyntax::UnsetAll)
        .to receive(:new).with(execution_context).and_return(unset_all_command)
      allow(unset_all_command).to receive(:call)
    end

    it 'delegates to the UnsetAll command' do
      expect(unset_all_command).to receive(:call).with('user.name', nil)

      host.config_unset_all('user.name')
    end

    it 'returns nil' do
      expect(host.config_unset_all('user.name')).to be_nil
    end

    it 'raises ArgumentError for an unknown option' do
      expect { host.config_unset_all('user.name', nil, bogus: true) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  # ---------------------------------------------------------------------------
  # ABSTRACT METHOD CONTRACTS
  # ---------------------------------------------------------------------------

  describe 'abstract method contracts' do
    let(:bare_class) { Class.new { include Git::Configuring } }
    let(:bare_instance) { bare_class.new }

    it 'raises NotImplementedError when execution_context is not implemented' do
      allow(bare_instance).to receive(:assert_valid_scope!)
      expect { bare_instance.config_list }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError when assert_valid_scope! is not implemented' do
      # Need a class that has execution_context but not assert_valid_scope!
      klass = Class.new do
        include Git::Configuring

        private

        def execution_context = nil
      end

      expect { klass.new.config_list }.to raise_error(NotImplementedError)
    end
  end
end
