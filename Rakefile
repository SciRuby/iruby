require "bundler/gem_helper"

base_dir = File.join(File.dirname(__FILE__))

helper = Bundler::GemHelper.new(base_dir)
helper.install

FileList['tasks/**.rake'].each {|f| load f }

desc "Run tests"
task :test do
  test_opts = ENV.fetch("TESTOPTS", "").split
  cd(base_dir) do
    ruby("test/run-test.rb", *test_opts)
  end
end

task default: 'test'
