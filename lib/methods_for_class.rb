#!/usr/bin/env ruby
require 'sequel'
classname = ARGV.first

DB = Sequel.connect 'sqlite://cocoa.db'

dataset = DB['select name, task from methods  where class_or_protocol =  ? order by task, name', classname]
dataset.each do |x|
  puts x.inspect
end


