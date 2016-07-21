Use:
  1. make gemset
  2. make rvm config files: e.g., rvm --ruby-version use 2.2.1@photofs-installation
  3. install bundler
  4. bundle install
  5. mount (see below)

To Mount:

  ruby mount.rb [virtual-path] -o source=[photo-source-path]

To Unmount

  fusermount -u [virtual-path]
