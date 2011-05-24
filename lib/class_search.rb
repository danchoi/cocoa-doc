require 'sequel'
DB = Sequel.connect 'sqlite://cocoa.db'
DB["select name, framework from classes_and_protocols where name like ?", "%#{ARGV.first}%"].each do |x|
  puts x.inspect
end
