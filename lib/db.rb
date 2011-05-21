require 'sequel'
DB = Sequel.connect 'sqlite://cocoa.db'
DB.create_table? :api do 
  primary_key :id
  String :name
  String :type
  String :page
  String :superclasses
  String :protocols
  String :framework
  String :declaration
  String :parameters
  String :return_value
  Text :abstract
  Text :discussion
  String :group
  String :availability
  Text :companion_guides
  Text :related_sample_code
end
