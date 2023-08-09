module Traveler
  class CLI < Thor
    include Util

    desc 'init', "Generating #{CONFIGFILE} and #{GEMFILE} files if ones does exists"
    def init
      bootstrap_gemfile    unless gemfile_exists?
      bootstrap_configfile unless configfile_exists?
      if gemfile_exists? && configfile_exists?
        puts success(:ok.icon, '  Awesome! All files in place. You can run `traveler build` now!')
      end
    end

    desc 'build', "Build runtime for platforms specified in #{CONFIGFILE}"
    def build
      require 'traveler/build'
      build_world
      generate_wrappers
      puts '', bold_success(SUCCESS_ICONS.sample, '  All Done! You are ready to rock!')
    end

    private
    def build_world
      FileUtils.mkdir_p(Traveler.rubydir)
      Dir.chdir Traveler.rubydir do
        OPTED_PLATFORMS.each do |platform|
          runtime = Runtime.new(platform)
          puts '', :package.icon << bold_warn('  ', runtime.basename)
          runtime.install
          Dir.chdir runtime.basename do
            within_sandbox do
              bundler = Bundler.new(platform)
              bundler.install_into(runtime.dirname)
            end
          end
        end
      end
    end

    def generate_wrappers
      return if WRAPPERS.empty?

      puts '', warn(:wrapping.icon, '  Wrapping...')
      Dir.chdir Traveler.appdir do
        WRAPPERS.each_pair do |name,(cmd_or_file,ruby_version)|
          Wrapper.new(name, cmd_or_file, ruby_version)
        end
      end
    end

    def within_sandbox
      return unless block_given?
      sandbox = '__traveler_sandbox__'
      FileUtils.rm_rf(sandbox)
      FileUtils.mkdir_p(sandbox)
      Dir.chdir(sandbox) {yield}
    ensure
      FileUtils.rm_rf(sandbox) if File.exist?(sandbox)
    end

    def bootstrap_configfile
      puts info(:seeding.icon, '  Bootstrapping %s...' % CONFIGFILE)
      FileUtils.cp(CONFIGFILE_SKEL, CONFIGFILE_PATH)
    end

    def bootstrap_gemfile
      puts info(:seeding.icon, '  Bootstrapping %s...' % GEMFILE)
      FileUtils.cp(GEMFILE_SKEL, GEMFILE_PATH)
    end

    def gemfile_exists?
      File.exist?(GEMFILE_PATH)
    end

    def configfile_exists?
      File.exist?(CONFIGFILE_PATH)
    end
  end
end
Traveler::CLI.start(ARGV)
