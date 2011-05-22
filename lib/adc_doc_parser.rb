require 'yaml'
require 'iconv'
require 'sqlite3'
require 'db'
# Builds the database of Cocoa methods, functions, etc.

require 'nokogiri'
require 'common_methods'
require 'class_parser'
require 'others_parser'

file = ARGV.first
html = File.read file
html = Iconv.conv("US-ASCII//translit//ignore", "UTF-8", html)
doc = Nokogiri::HTML.parse html

case doc.at('title').inner_text
when /Class|Protocol/
  ClassParser.new(doc, file).parse
else
  OthersParser.new(doc, file).parse
end

