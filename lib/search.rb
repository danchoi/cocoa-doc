require 'sequel'
db = Sequel.connect 'sqlite://cocoa.db'

query = "%#{ARGV.first}%"
db['select name, "class" as type from classes_and_protocols where name like ? UNION
select name, "method" as type from methods where name like ?  UNION
select name, "other" as type from others where name like ? 
', query, query,query].each do |x|
  puts x.inspect
end
exit

#db[:classes_and_protocols].each {|x| puts x[:name] }
db[:methods].each {|x| puts "%.20s %.30s %s" % [x[:class_or_protocol], x[:name], x[:file]] }
exit

puts db[:methods].count
puts db[:classes_and_protocols].count
puts db[:others].count
puts db[:others].filter("type = 'constantName'").count
puts db[:others].filter("type = 'function'").count
puts db[:others].filter("type = 'typeDef'").count


exit
db[:methods].each do |row|
  p row
end
