require 'rake/testtask'

begin
  require 'bundler/gem_tasks'
rescue Exception
end

Rake::TestTask.new('test') do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end
