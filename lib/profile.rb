class Profile
  attr_accessor :iruby_name

  NAME_PREFIX = "iruby_"
  IPYTHON_PROFILE_PATH = File.join(Dir.home, '.config', 'ipython')

  # FIXME These should be stored as ERB files
  PROFILE_CONFIG = {}
  PROFILE_CONFIG['ipython_notebook_config.py'] = <<-PYTHON
  ## IRuby custom configuration
  iruby_kernel_path = '#{File.absolute_path(File.join(File.dirname(__FILE__), 'kernel.rb'))}'
  c.KernelManager.kernel_cmd = ['ruby', iruby_kernel_path, '{connection_file}']
  c.Session.key = ''
  PYTHON

  def initialize(iruby_name='default')
    @iruby_name = iruby_name
  end

  def name
    "#{NAME_PREFIX}#{@iruby_name}"
  end

  def path
    File.join(IPYTHON_PROFILE_PATH, "profile_#{name}")
  end

  def create!
    run_ipython_create_profile!
    apply_patches!
    create_static_symlink!
  end

private
  def run_ipython_create_profile!
    cmd = "ipython profile create '#{name}'"
    puts "=> Run #{cmd}"
    `#{cmd}`
  end

  def apply_patches!
    # TODO only append if needed!
    PROFILE_CONFIG.each do |file, config|
      file_path = File.join(path, file)
      puts "=> Append extra configuration to #{file_path}"
      File.open(file_path, 'a') do |f|
        f.write("\n#{config}\n")
      end
    end
  end

  def create_static_symlink!
    puts "TODO: symbolic link to static files"
    #File.symlink(
  end
end
