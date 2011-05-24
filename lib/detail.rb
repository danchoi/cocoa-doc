require 'sequel'
require 'yaml'
DB = Sequel.connect 'sqlite://cocoa.db'
q = ARGV.first
r = DB['select * from methods where name = ?', q]
puts r.count
if r.count == 1
  puts r.first.to_yaml

end
