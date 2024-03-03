module Traveler
  class Gem
    include Util
    URL_FORMAT = 'traveling-ruby-gems-%s-%s-%s-%s'.freeze
    EXTENSION = '.tar.gz'.freeze

    def initialize platform, name, version
      @platform, @name, @version = platform, name, version
    end

    def install
      Dir.chdir 'vendor/ruby' do
        download
        extract
        clean
      end
    end

    def name
      [@name, @version].join('-') + EXTENSION
    end

    def url
      RELEASES_URL + 'rel-' + TRAVELING_RUBY_VERSION + '/' + URL_FORMAT % [
        TRAVELING_RUBY_VERSION,
        EFFECTIVE_RUBY_VERSION,
        @platform,
        name
      ]
    end

    private
    def download
      sh('"%s" -L --fail -O "%s"' % [CURL, url])
    end

    def extract
      sh('"%s" -xzf "%s"' % [TAR, URL_FORMAT % [
        TRAVELING_RUBY_VERSION,
        EFFECTIVE_RUBY_VERSION,
        @platform,
        name
      ]])
    end

    def clean
      sh('"%s" -f "%s"' % [RM, name])
    end
  end
end
