require 'yaml'
require 'iconv'
require 'db'
# Builds the database of Cocoa methods, functions, etc.

require 'nokogiri'
require 'common_methods'
require 'class_parser'
require 'others_parser'

html = ARGV.first ? File.read(ARGV.first) : STDIN.read
html = Iconv.conv("US-ASCII//translit//ignore", "UTF-8", html)
doc = Nokogiri::HTML.parse html

case doc.at('title').inner_text
when /Class|Protocol/
  ClassParser.new(doc).parse
else
  OthersParser.new(doc).parse
end
