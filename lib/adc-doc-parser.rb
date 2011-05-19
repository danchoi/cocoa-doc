require 'yaml'
require 'iconv'

# Builds the database of Cocoa methods.
# STDIN input should a Reference.html.

require 'nokogiri'
require 'base_parser'
require 'method_parser'

html = STDIN.read
html = Iconv.conv("US-ASCII//translit//ignore", "UTF-8", html)

r = {} # result

doc = Nokogiri::HTML.parse html
r[:cocoa_class] = doc.at('a')[:title]

r[:superclasses] = (x = tr_with_text(doc, 'Inherits from')) && x.search('td/div/a').map(&:inner_text)

r[:protocols] = (x = tr_with_text(doc, 'Conforms to')) && x.search('td/div/span/a').map(&:inner_text)

r[:framework] = (x = tr_with_text(doc, 'Framework')) && x.at('td/div').inner_text.strip

r[:availability] = (x = tr_with_text(doc, 'Availability')) && x.at('td/div/div/text()').text.strip

x = tr_with_text(doc, 'Companion guides')
companion_guides = x && x.search("td/div/span/a").map {|a| a.inner_text.strip}
r[:companion_guides] = companion_guides
r[:related_sample_code] = (x = tr_with_text(doc, 'Related sample code')) && x.search('td/div/div/span').map {|a| a.inner_text.strip}

div = doc.at('//div[@id="Overview_section"]') 
if div.nil?
  div = doc.at("//h2[text()='Overview']").xpath('following-sibling::p')[0]
end

r[:overview] = fragment_text(div).strip#.strip_leading_whitespace

div = doc.at("#Tasks_section")
tasks = []
if div
  headers = div.search("h3")
  tasks = headers.map do |h|
    title = h.inner_text
    ul = h.xpath("following-sibling::ul")[0]
    mytasks = ul.search("li").map {|a| ascii(a.at("a").inner_text)}
    {title: title, tasks: mytasks}
  end
end

taskmap = {}
tasks.each do |taskgroup|
  title = taskgroup[:title]
  taskgroup[:tasks].each do |task|
    if taskmap[task]
      raise "Task #{task} already in map"
    end
    taskmap[task] = title
  end
end

class_methods = doc.xpath("//div[@class='api classMethod']")
names = class_methods.map {|div| div.at("h3").inner_text}
method_divs = doc.xpath("//div[@class='api classMethod']") + doc.xpath("//div[@class='api instanceMethod']") + doc.xpath("//div[@class='api propertyObjC']")

r[:methods] = method_divs.map {|n| parse_method(n, taskmap)}

puts r.to_yaml
