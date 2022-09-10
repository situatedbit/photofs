#!/usr/bin/env ruby

require 'photofs/config'
require 'photofs/fuse'

PhotoFS::Fuse.mount(PhotoFS::Config.load)
