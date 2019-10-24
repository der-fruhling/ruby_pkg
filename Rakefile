require "bundler/gem_tasks"
task :default => :spec

task :spec do
    system 'bundle'
    system 'gem build ruby_pkg.gemspec'
end

task :install do
    system 'rm -rf *.gem'
    system 'rake'
    system 'sudo gem install ruby_pkg-*.gem'
end

task :publish do
    system 'rm -rf *.gem'
    system 'rake'
    system "gem push --key github --host https://rubygems.pkg.github.com/LiamCoal ruby_pkg-*.gem"
end