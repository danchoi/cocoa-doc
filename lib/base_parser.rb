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

def lynx(s)
  script = "lynx -stdin -dump -nonumbers"
  IO.popen(script, "r+") do |pipe|
    pipe.puts s
    pipe.close_write
    pipe.read
  end.gsub(/^file:\/\/.*$/, '').strip_leading_whitespace
end

