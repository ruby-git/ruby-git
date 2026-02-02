# frozen_string_literal: true

require 'git/branch_info'
require 'git/branch_delete_failure'

module Git
  # Represents the result of a branch delete operation
  #
  # This is an immutable data object returned by {Git::Commands::Branch::Delete#call}.
  # It contains information about which branches were successfully deleted and which
  # failed to be deleted, along with the reason for each failure.
  #
  # Git's `git branch -d` command uses "best effort" semantics - it deletes as many
  # branches as possible and reports errors for those that couldn't be deleted. This
  # result object reflects that behavior, allowing callers to inspect both
  # successes and failures.
  #
  # @example Successful deletion of all branches
  #   result = branch_delete.call('feature-1', 'feature-2')
  #   result.success?            #=> true
  #   result.deleted.map(&:name) #=> ['feature-1', 'feature-2']
  #   result.not_deleted         #=> []
  #
  # @example Partial failure (some branches deleted, some not found)
  #   result = branch_delete.call('feature-1', 'nonexistent', 'feature-2')
  #   result.success?                    #=> false
  #   result.deleted.map(&:name)         #=> ['feature-1', 'feature-2']
  #   result.not_deleted.first.name          #=> 'nonexistent'
  #   result.not_deleted.first.error_message #=> "branch 'nonexistent' not found."
  #
  # @see Git::BranchInfo
  # @see Git::BranchDeleteFailure
  # @see Git::Commands::Branch::Delete
  #
  # @api public
  #
  # @!attribute [r] deleted
  #   Branches that were successfully deleted
  #   @return [Array<Git::BranchInfo>]
  #
  # @!attribute [r] not_deleted
  #   Branches that could not be deleted, with the reason for each failure
  #   @return [Array<Git::BranchDeleteFailure>]
  #
  BranchDeleteResult = Data.define(:deleted, :not_deleted) do
    # Returns true if all requested branches were successfully deleted
    #
    # @return [Boolean] true if no branches failed to delete, false otherwise
    #
    # @example
    #   result = branch_delete.call('feature-branch')
    #   if result.success?
    #     puts "All branches deleted successfully"
    #   else
    #     puts "Some branches could not be deleted:"
    #     result.not_deleted.each { |f| puts "  #{f.name}: #{f.error_message}" }
    #   end
    #
    def success?
      not_deleted.empty?
    end
  end
end
