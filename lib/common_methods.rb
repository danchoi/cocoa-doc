def tr_with_text(doc, s)
  doc.at("//tr[td/strong//text()='#{s}']")
end

def mark_code(html)
  return html
  html.gsub(/<\/?code>/, "|")
end

class String
  def strip_leading_whitespace
    gsub(/^[\t ]+(?=\S)/, '')
  end
end

def fragment_text(node)
  text = Nokogiri::HTML.parse(mark_code(node.to_s))
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

def lynx(s)
  script = "lynx -stdin -dump -nonumbers"
  IO.popen(script, "r+") do |pipe|
    pipe.puts s
    pipe.close_write
    pipe.read
  end.gsub(/^file:\/\/.*$/, '').
    strip_leading_whitespace.
    sub(/^Discussion\s*$/, '').
    strip
end

def to_yaml_or_nil(x)
  x ? x.to_yaml : nil
end
