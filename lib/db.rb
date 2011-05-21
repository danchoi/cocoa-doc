require 'sequel'
require 'logger'

DB = Sequel.connect 'sqlite://cocoa.db', :logger => Logger.new(STDOUT)
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
  String :subgroup
  String :availability
  Text :companion_guides
  Text :related_sample_code
  Text :see_also
end
