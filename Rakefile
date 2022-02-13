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

namespace :docker do
  def root_dir
    @root_dir ||= File.expand_path("..", __FILE__)
  end

  task :build do
    container_name = "iruby_build"
    image_name = "mrkn/iruby"
    sh "docker", "run",
       "--name", container_name,
       "-v", "#{root_dir}:/tmp/iruby",
       "rubylang/ruby", "/bin/bash", "/tmp/iruby/docker/setup.sh"
    sh "docker", "commit", container_name, image_name
    sh "docker", "rm", container_name
  end

  task :test do
    root_dir = File.expand_path("..", __FILE__)
    sh "docker", "run", "-it", "--rm",
       "-v", "#{root_dir}:/tmp/iruby",
       "mrkn/iruby", "/bin/bash", "/tmp/iruby/docker/test.sh"
  end
end
