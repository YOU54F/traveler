module Traveler
  class Bundler
    include Util

    def initialize platform
      @platform = platform
    end

    def install_into dst
      install
      clean
      config
      install_extensions
      copy_into(dst)
    end

    private
    def install
      puts GEMFILE_PATH
      FileUtils.rm_rf('vendor')
      FileUtils.cp(GEMFILE_PATH, '.')
      sh('"%s" config set --local path vendor' % BUNDLER)
      sh('"%s" config set --local without development' % BUNDLER)
      sh('"%s" install' % BUNDLER)
      sh('"%s" info ffi' % BUNDLER)
    end

    def clean
      return if no_local_gems # nothing to clean if no gems in Gemfile
      sh('"%s" -fr vendor/*/*/cache/*' % RM)
      sh('"%s" -fr vendor/ruby/*/extensions' % RM)
      sh('"%s" vendor/ruby/*/gems -name "*.so"     | xargs rm -f' % FIND)
      sh('"%s" vendor/ruby/*/gems -name "*.bundle" | xargs rm -f' % FIND)
      sh('"%s" vendor/ruby/*/gems -name "*.o"      | xargs rm -f' % FIND)
    end

    def install_extensions
      remote_gems = remote_gems()
      local_gems.each_pair do |name,version|
        next unless remote_gems[name]
        if remote_gems[name].include?(version)
          Gem.new(@platform, name, version).install
        else
          fail('Native extensions missing for "%s" version "%s".
            Please use %s in your %s.' % [
            name,
            version,
            remote_gems[name].map(&:inspect).join(" or "),
            GEMFILE
          ])
        end
      end
    end

    def local_gems
      Dir.chdir 'vendor' do
        scanner = /\*(.+)\((.+)\)/
        %x["#{BUNDLER}" list --no-color].split("\n").each_with_object({}) do |l,o|
          name, version = l.scan(scanner).flatten.map(&:strip).map(&:freeze)
          next unless name && version
          o[name] = version
        end
      end
    end

    def no_local_gems
      local_gems.keys.reject {|g| g == 'bundler'}.empty?
    end

    def remote_gems
      matcher = /traveling\-ruby\-gems\-#{TRAVELING_RUBY_VERSION}\-/
      replace = /.*#{matcher.source}|\.tar\.gz\Z/
      scanner = /\A([\d|\.]+)\-([^\/].+)\/(.+)\-([\d|\.]+)\Z/
      lines   = open(BUCKET_ROOT).read.scan(/<Key>([^<]+)<\/Key>/).flatten
      lines.select {|l| l =~ matcher}.each_with_object({}) do |line,o|
        line.gsub!(replace, '')
        ruby_version, platform, gem_name, gem_version = line.scan(scanner).flatten
        next unless ruby_version == EFFECTIVE_RUBY_VERSION
        next unless platform == @platform
        (o[gem_name] ||= []).push(gem_version)
      end
    end

    def config
      FileUtils.mkdir_p('vendor/.bundle')
      FileUtils.cp(skeldir('bundle.config'), 'vendor/.bundle/config')
    end

    def copy_into dst
      sh('"%s" %s %s.lock vendor' % [CP, GEMFILE, GEMFILE])
      sh('"%s" -a vendor "%s"' % [CP, dst])
    end
  end
end
