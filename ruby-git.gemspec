spec = Gem::Specification.new do |s|
    s.platform  =   Gem::Platform::RUBY
    s.name      =   "git"
    s.version   =   "1.1.1"
    s.author    =   "Scott Chacon"
    s.email     =   "schacon@gmail.com"
    s.homepage  =   "http://github.com/schacon/ruby-git/tree/master"
    s.summary   =   "A package for using Git in Ruby code."
    s.files     =   ["lib/git", "lib/git/author.rb", "lib/git/base.rb", "lib/git/branch.rb", "lib/git/branches.rb", "lib/git/diff.rb", "lib/git/index.rb", "lib/git/lib.rb", "lib/git/log.rb", "lib/git/object.rb", "lib/git/path.rb", "lib/git/remote.rb", "lib/git/repository.rb", "lib/git/stash.rb", "lib/git/stashes.rb", "lib/git/status.rb", "lib/git/working_directory.rb", "lib/git.rb"]
    s.require_path  =   "lib"
    s.autorequire   =   "git"
    s.test_files = Dir.glob('tests/*.rb')
    s.has_rdoc  =   true
    s.extra_rdoc_files  =   ["README"]
end
