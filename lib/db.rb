require 'sequel'
require 'logger'

#DB = Sequel.connect 'sqlite://cocoa.db', :logger => Logger.new(STDOUT)
DB = Sequel.connect 'sqlite://cocoa.db'

# includes protocols
DB.create_table? :classes_and_protocols do 
  String :name
  String :description
  String :superclasses
  String :protocols
  String :framework
  Text :overview
  String :availability
  Text :companion_guides
  Text :related_sample_code
  String :file
  index [:framework, :name], :unique => true
end

DB.create_table? :methods do 
  primary_key :id
  String :class_or_protocol
  String :name
  String :type
  String :declaration
  String :parameters
  String :return_value
  Boolean :required
  Text :abstract
  Text :discussion
  String :task
  String :availability
  Text :related_sample_code
  Text :see_also
  String :declared_in
  String :file
  index [:class_or_protocol, :type, :name], :unique => true
end

DB.create_table? :others do 
  primary_key :id
  String :name
  String :type # function constant database
  String :page
  String :framework
  String :declaration
  String :parameters
  String :return_value
  Text :abstract
  Text :discussion
  Text :special_considerations
  String :task_or_group
  String :availability
  Text :related_sample_code
  Text :see_also
  String :declared_in
  String :file
  index [:page, :type, :name], :unique => true
end

