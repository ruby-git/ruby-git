# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    # @api private
    #
    # Base class for git command implementations.
    #
    # Provides default {#initialize} and {#call} methods so that simple commands
    # only need to declare their arguments:
    #
    #   class Add < Base
    #     arguments do
    #       literal 'add'
    #       flag_option :all
    #       flag_option :force
    #       operand :paths, repeatable: true, default: [], separator: '--'
    #     end
    #
    #     # Execute the git add command
    #     # ...YARD docs...
    #     def call(...) = super
    #   end
    #
    # Commands whose git process may exit with a non-zero status that is
    # *not* an error can declare the acceptable range of exit codes:
    #
    #   class Delete < Base
    #     arguments do
    #       literal 'branch'
    #       literal '--delete'
    #       operand :branch_names, repeatable: true, required: true
    #     end
    #
    #     allow_exit_status 0..1
    #
    #     # Execute the git branch --delete command
    #     # ...YARD docs...
    #     def call(...) = super
    #   end
    #
    # Commands with execution options (e.g., timeout) work with the default
    # `call` — execution options are extracted and forwarded automatically.
    class Base
      class << self
        # @return [Git::Commands::Arguments, nil] the frozen argument definition for this command
        attr_reader :args_definition

        # Define the command's arguments using the {Arguments} DSL.
        #
        # @yield the block passed to {Arguments.define}
        #
        # @raise [ArgumentError] if called more than once on the same class
        #
        # @return [void]
        def arguments(&)
          raise ArgumentError, "arguments already defined for #{name}" if @args_definition

          @args_definition = Arguments.define(&).freeze
        end

        # @return [Range, nil] range of exit status values accepted by this command
        attr_reader :allowed_exit_status_range

        # Declare the acceptable range of exit status values for this command.
        #
        # @example git-diff exits 1 when a diff is found (not an error)
        #   allow_exit_status 0..1
        #
        # @example git-fsck uses exit codes 0-7 as bit flags
        #   allow_exit_status 0..7
        #
        # @param range [Range] range of accepted exit status values
        #
        # @raise [ArgumentError] if range is invalid
        #
        # @return [void]
        def allow_exit_status(range)
          raise ArgumentError, 'allow_exit_status expects a Range' unless range.is_a?(Range)
          unless range.begin.is_a?(Integer) && range.end.is_a?(Integer)
            raise ArgumentError, 'allow_exit_status bounds must be Integers'
          end

          raise ArgumentError, 'allow_exit_status range must not be empty' if range.begin > range.end

          @allowed_exit_status_range = range
        end
      end

      # @param execution_context [Git::ExecutionContext, Git::Lib] context that provides {Git::Lib#command}
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git command.
      #
      # @overload call(*args, **kwargs)
      #   Bind arguments and execute the command.
      #
      #   Execution options (declared via `execution_option` in the Arguments
      #   DSL) are extracted from the bound arguments via
      #   {Git::Commands::Arguments::Bound#execution_options} and forwarded as
      #   keyword arguments to `@execution_context.command`.
      #
      #   @example
      #     # In a command subclass:
      #     # result = command.call('HEAD', timeout: 10)
      #
      #   @param args [Array] positional arguments forwarded to {Arguments#bind}
      #
      #   @param kwargs [Hash] keyword arguments forwarded to {Arguments#bind}
      #
      # @return [Git::CommandLineResult] the result of calling `git`
      #
      # @raise [ArgumentError] if no arguments definition is declared on the command class
      #
      # @raise [Git::FailedError] if git returns an exit code outside the allowed range
      def call(*, **)
        args = args_definition.bind(*, **)

        result = @execution_context.command(*args, **args.execution_options, raise_on_failure: false)
        validate_exit_status!(result)
        result
      end

      private

      def args_definition
        self.class.args_definition || raise(ArgumentError, "arguments not defined for #{self.class.name}")
      end

      def allowed_exit_status_range
        self.class.allowed_exit_status_range || (0..0)
      end

      def validate_exit_status!(result)
        raise Git::FailedError, result unless allowed_exit_status_range.include?(result.status.exitstatus)
      end
    end
  end
end
