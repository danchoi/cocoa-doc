require 'yaml'
require 'iconv'
require 'db'
# Builds the database of Cocoa methods.
# STDIN input should a Reference.html.

require 'nokogiri'
require 'common_methods'
require 'class_parser'
require 'functions_parser'

html = STDIN.read
html = Iconv.conv("US-ASCII//translit//ignore", "UTF-8", html)
doc = Nokogiri::HTML.parse html

case doc.at('title').inner_text
when /Class|Protocol/
  ClassParser.new(doc).parse
when /Function/
  FunctionsParser.new(doc).parse_functions
end
