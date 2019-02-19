namespace :ci do
  namespace :docker do
    def ruby_version
      @ruby_version ||= ENV['ruby_version']
    end

    def ruby_image_name
      @ruby_image_name ||= "rubylang/ruby:#{ruby_version}-bionic"
    end

    def iruby_test_base_image_name
      @iruby_test_base_image_name ||= "iruby-test-base:ruby-#{ruby_version}"
    end

    def iruby_test_image_name
      @docker_image_name ||= begin
                               "sciruby/iruby-test:ruby-#{ruby_version}"
                             end
    end

    def docker_image_found?(image_name)
      image_id = `docker images -q #{image_name}`.chomp
      image_id.length > 0
    end

    directory 'tmp'

    desc "Build iruby-test-base docker image"
    task :build_test_base_image => 'tmp' do
      unless docker_image_found?(iruby_test_base_image_name)
        require 'erb'
        dockerfile_content = ERB.new(File.read('ci/Dockerfile.base.erb')).result(binding)
        File.write('tmp/Dockerfile', dockerfile_content)
        sh 'docker', 'build', '-t', iruby_test_base_image_name, '-f', 'tmp/Dockerfile', '.'
      end
    end

    desc "Pull docker image of ruby"
    task :pull_ruby_image do
      sh 'docker', 'pull', ruby_image_name
    end

    desc "Build iruby-test docker image"
    task :build_test_image => 'tmp' do
      require 'erb'
      dockerfile_content = ERB.new(File.read('ci/Dockerfile.main.erb')).result(binding)
      File.write('tmp/Dockerfile', dockerfile_content)
      sh 'docker', 'build', '-t', iruby_test_image_name, '-f', 'tmp/Dockerfile', '.'
    end

    desc 'before_install script for CI with Docker'
    task :before_install => :pull_ruby_image
    task :before_install => :build_test_base_image

    desc 'install script for CI with Docker'
    task :install => :build_test_image

    desc 'main script for CI with Docker'
    task :script do
      volumes = ['-v', "#{Dir.pwd}:/iruby"] if ENV['attach_pwd']
      sh 'docker', 'run', '--rm', '-it', *volumes,
         iruby_test_image_name, 'bash', 'run-test.sh'
    end
  end
end
