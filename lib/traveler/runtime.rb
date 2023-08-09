module Traveler
  class Runtime
    include Util
    BASENAME_FORMAT = 'traveling-ruby-%s-%s-%s'.freeze
    EXTENSION = '.tar.gz'.freeze

    def initialize platform
      @platform = platform
    end

    def install
      download
      extract
    end

    def basename
      BASENAME_FORMAT % [
        TRAVELING_RUBY_VERSION,
        EFFECTIVE_RUBY_VERSION,
        @platform
      ]
    end

    def name
      basename + EXTENSION
    end

    def dirname
      Traveler.rubydir(basename)
    end

    def url
      RELEASES_URL + 'rel-' + TRAVELING_RUBY_VERSION + '/' + name
    end

    def download
      return if File.exist?(name)
      sh('"%s" -L --fail -O "%s"' % [CURL, url])
    end

    def extract
      FileUtils.rm_rf(basename)
      FileUtils.mkdir(basename)
      sh('"%s" -C "%s" -xzf "%s"' % [TAR, basename, name])
    end
  end
end
