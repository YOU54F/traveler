module Traveler
  class Wrapper
    include Util

    def initialize file, cmd_or_file, ruby_version
      @file, @cmd_or_file, @ruby_version = file, cmd_or_file, ruby_version
      write if writeable?
    end

    def write
      File.open(@file, 'w') {|f| f << render}
      FileUtils.chmod('+x', @file)
    end

    def writeable?
      if File.exist?(@file) && File.read(@file) !~ /#{SIGNATURE}/m
        puts warn('
          "%s" file exists and is not a Traveler wrapper.
          If you still want to use it as a Traveler wrapper
          please delete it and rerun `traveler`' % @file, '')
        return false
      end
      true
    end

    def wrapper
      File.read(skeldir('wrapper.sh'))
    end

    def locals
      {
        signature: SIGNATURE,
        folder_name: FOLDER_NAME,
        traveling_ruby_version: TRAVELING_RUBY_VERSION,
        wrapper_ruby_version: @ruby_version,
        cmd_or_file: @cmd_or_file
      }
    end

    def render
      Mustache.render(wrapper, locals)
    end
  end
end
