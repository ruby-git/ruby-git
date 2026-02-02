# frozen_string_literal: true

module Git
  # Value object representing a detached HEAD state
  #
  # When HEAD points directly to a commit rather than a branch reference,
  # the repository is in a "detached HEAD" state. This object captures
  # that state along with the commit SHA that HEAD points to.
  #
  # This class shares a minimal interface with {Git::BranchInfo} to allow
  # polymorphic usage where appropriate:
  # - `short_name` - returns 'HEAD'
  # - `target_oid` - returns the commit SHA
  # - `to_s` - returns 'HEAD'
  # - `detached?` - returns true
  #
  # @example Detecting detached HEAD state
  #   head = repo.show_current
  #   if head.detached?
  #     puts "HEAD detached at #{head.target_oid[0, 7]}"
  #   else
  #     puts "On branch #{head.short_name}"
  #   end
  #
  # @example Polymorphic usage
  #   head = repo.show_current
  #   puts "Checked out: #{head.short_name}"  # Works for both types
  #   system("git log #{head.short_name}")    # Works for both types
  #
  # @see Git::BranchInfo for the branch counterpart
  # @see Git::Commands::Branch::ShowCurrent for the command that produces this
  #
  # @api public
  #
  # @!attribute [r] target_oid
  #
  #   The commit object ID (SHA) that HEAD points to
  #
  #   @return [String] the full 40-character object ID
  #
  DetachedHeadInfo = Data.define(:target_oid) do
    # @return [Boolean] always true for DetachedHeadInfo
    def detached? = true

    # @return [Boolean] always false for DetachedHeadInfo (detached HEAD always has a commit)
    def unborn? = false

    # @return [String] always 'HEAD'
    def short_name = 'HEAD'

    # @return [String] always 'HEAD'
    def to_s = 'HEAD'
  end
end
