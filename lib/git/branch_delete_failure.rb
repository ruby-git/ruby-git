# frozen_string_literal: true

module Git
  # Represents a branch that failed to be deleted
  #
  # This is an immutable data object returned as part of {Git::BranchDeleteResult}
  # when one or more branches could not be deleted.
  #
  # @example
  #   failure = Git::BranchDeleteFailure.new(
  #     name: 'nonexistent',
  #     error_message: "branch 'nonexistent' not found."
  #   )
  #   failure.name          #=> 'nonexistent'
  #   failure.error_message #=> "branch 'nonexistent' not found."
  #
  # @see Git::BranchDeleteResult
  # @see Git::Commands::Branch::Delete
  #
  # @api public
  #
  # @!attribute [r] name
  #   The name of the branch that failed to be deleted
  #   @return [String]
  #
  # @!attribute [r] error_message
  #   The error message from git explaining why the branch could not be deleted
  #   @return [String]
  #
  BranchDeleteFailure = Data.define(:name, :error_message)
end
