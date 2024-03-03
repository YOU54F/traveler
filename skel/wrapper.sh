#!/usr/bin/env bash
{{signature}}
set -e
cd "$(cd $(dirname "$0") && pwd)"

if [[ `uname -s` =~ inux ]]; then
  if [[ `uname -m` == aarch64 ]]; then
  TRAVELING_RUBY_PLATFORM="linux-arm64"
  else
  TRAVELING_RUBY_PLATFORM="linux-$(uname -m)"
  fi
else
  TRAVELING_RUBY_PLATFORM="osx-$(uname -m)"
fi

TRAVELING_RUBY_ROOT="{{folder_name}}/traveling-ruby-{{traveling_ruby_version}}-{{wrapper_ruby_version}}-$TRAVELING_RUBY_PLATFORM/"

export BUNDLE_GEMFILE="$TRAVELING_RUBY_ROOT/vendor/Gemfile"
unset  BUNDLE_IGNORE_CONFIG

exec "$TRAVELING_RUBY_ROOT/bin/ruby" -r bundler/setup {{cmd_or_file}}
