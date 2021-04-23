module Fastlane
  module Actions
    module SharedValues
      HG_REPO_WAS_CLEAN_ON_START = :HG_REPO_WAS_CLEAN_ON_START
    end

    # Raises an exception and stop the lane execution if the repo is not in a clean state
    class HgEnsureCleanStatusAction < Action
      def self.run(params)
        repo_clean = `hg status`.empty?

        if repo_clean
          UI.success('Mercurial status is clean, all good! 😎')
          Actions.lane_context[SharedValues::HG_REPO_WAS_CLEAN_ON_START] = true
        else
          UI.user_error!('Mercurial repository is dirty! Please ensure the repo is in a clean state by committing/stashing/discarding all changes first.')
        end
      end

      def self.description
        "Raises an exception if there are uncommitted hg changes"
      end

      def self.details
        "Along the same lines as the [ensure_git_status_clean](https://docs.fastlane.tools/actions/ensure_git_status_clean/) action, this is a sanity check to ensure the working mercurial repo is clean. Especially useful to put at the beginning of your Fastfile in the `before_all` block."
      end

      def self.output
        [
          ['HG_REPO_WAS_CLEAN_ON_START', 'Stores the fact that the hg repo was clean at some point']
        ]
      end

      def self.author
        # credits to lmirosevic for original git version
        "sjrmanning"
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'hg_ensure_clean_status'
        ]
      end

      def self.category
        :source_control
      end
    end
  end
end
