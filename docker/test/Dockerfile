FROM ruby

WORKDIR /ruby-git


ADD Gemfile git.gemspec ./
ADD lib/git/version.rb ./lib/git/version.rb

# `git.gemspec`'s `spec.files` shells out to `git ls-files`, which Bundler
# evaluates below via the Gemfile's `gemspec` directive. Rather than relying
# on the host's `.git` (which, for a build context copied from a linked git
# worktree, is a file pointing at an absolute host path that doesn't exist
# in the image — breaking every git command with "fatal: not a git
# repository"), always initialize a throwaway repo scoped to the image. This
# also keeps the image self-contained and avoids ever copying the
# (potentially large) host `.git` directory in (see `.dockerignore`). A
# second commit is added below once the full source tree is present, so the
# final file list is complete.
RUN git init -q && \
    git -c user.email=docker@example.com -c user.name=docker add -A && \
    git -c user.email=docker@example.com -c user.name=docker commit -q -m 'Throwaway repo for Docker test run'

RUN bundle install

ADD . .

# Refresh the throwaway repo now that the full source tree is present, so
# `git ls-files` reflects every file for `rake build`'s `spec.files`.
RUN git -c user.email=docker@example.com -c user.name=docker add -A && \
    git -c user.email=docker@example.com -c user.name=docker commit -q -m 'Add full source' --allow-empty

ENTRYPOINT ["bundle", "exec", "rake", "default"]
