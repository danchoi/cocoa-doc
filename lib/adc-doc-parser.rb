require 'yaml'
require 'iconv'
# Builds the database of Cocoa methods.
#
# STDIN input should a Reference.html.

require 'nokogiri'

def tr_with_text(doc, s)
  doc.at("//tr[td/strong//text()='#{s}']")
end

def mark_code(html)
  html.gsub(/<\/?code>/, "|")
end

class String
  def strip_leading_whitespace
    gsub(/^[\t ]+(?=\S)/, '')
  end
end

def lynx(s)
  script = "lynx -stdin -dump -nonumbers"
  IO.popen(script, "r+") do |pipe|
    pipe.puts s
    pipe.close_write
    pipe.read
  end.gsub(/^file:\/\/.*$/, '').strip_leading_whitespace
end

def fragment_text(node)
  text = Nokogiri::HTML.parse(mark_code(node.to_s))
  script = %Q@
  lynx -stdin -dump |
sed '/^$/{
N
/^\\n$/D
}
' | fmt
@
  script = "lynx -stdin -dump -nonumbers"
  IO.popen(script, "r+") do |pipe|
    pipe.puts text
    pipe.close_write
    pipe.read
  end.gsub(/^file:\/\/.*$/, '')
end

def ascii(s)
  Iconv.conv("ascii//translit", "UTF-8", s)
end

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

r[:methods] = method_divs.map {|n| 
  type = n[:class].split(' ')[-1] 
  typeSymbol = case type
               when /instance/
                 '- '
               when /class/
                 '+ '
               else
                 ''
               end
                 
  methodname = typeSymbol + n.at('h3[@class^=jump]').inner_text

  declaration = n.at("div[@class='declaration']").inner_text.strip

  parameters = if (x = n.at("div[@class='api parameters']"))
    x.search("dl/dt").map do |dt|
      name = dt.inner_text
      definition = dt.xpath("following-sibling::dd").first#.inner_text
      #definition = definition.gsub(/\n */, "\n").gsub(/\n{3,}/, "\n\n")
      definition = lynx(definition)
      {name: name, definition: definition.strip}
    end
  else
    nil
  end
  abstract = (x = n.at("p[@class=abstract]")) && x.inner_text
  availability = (x = n.at("div[@class='api availability']/ul/li")) && x.inner_text
  seealso = if (x = n.at("div[@class$=seeAlso]"))
    x.search("li").map(&:inner_text).map {|z| ascii(z).strip}
  end

  {name: methodname,
  type: type,
   declaration: declaration,
   parameters: parameters,
   abstract: abstract,
   taskgroup: taskmap[methodname],
   availability: availability,
   seealso: seealso
  }
}
puts r.to_yaml
