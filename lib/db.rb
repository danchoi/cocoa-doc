require 'sequel'
require 'logger'

DB = Sequel.connect 'sqlite://cocoa.db'#, :logger => Logger.new(STDOUT)

# includes protocols
DB.create_table? :classes do 
  String :name
  String :description
  String :superclasses
  String :protocols
  String :framework
  Text :overview
  String :availability
  Text :companion_guides
  Text :related_sample_code
end

DB.create_table? :methods do 
  primary_key :id
  String :class_or_protocol
  String :name
  String :type
  String :declaration
  String :parameters
  String :return_value
  Text :abstract
  Text :discussion
  String :task
  String :availability
  Text :related_sample_code
  Text :see_also
  String :declared_in
end

DB.create_table? :functions do 
  primary_key :id
  String :page
  String :name
  String :declaration
  String :parameters
  String :return_value
  Text :abstract
  Text :discussion
  String :task
  String :availability
  Text :related_sample_code
  Text :see_also
  String :declared_in
end

DB.create_table? :constants do

end
