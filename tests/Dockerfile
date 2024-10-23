FROM ruby

WORKDIR /ruby-git


ADD Gemfile git.gemspec .git* ./
ADD lib/git/version.rb ./lib/git/version.rb
RUN bundle install

ADD . .

ENTRYPOINT ["bundle", "exec"]
CMD ["bin/test"]
