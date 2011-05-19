
def parse_method(n, taskmap)
  type = n[:class].split(' ')[-1] 
  typeSymbol = case type
               when /instance/
                 '- '
               when /class/
                 '+ '
               else
                 ''
               end
                 
  methodname = typeSymbol + n.at('h3[@class*=jump]').inner_text
  declaration = (x = n.at("*[@class*='declaration']")) && x.inner_text.strip
  discussion = (x = n.at("*[@class*=discussion]")) && lynx(x)
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
  return_value = (x = n.at("div[@class=return_value]/p")) && x.inner_text
  abstract = (x = n.at("p[@class=abstract]")) && x.inner_text
  availability = (x = n.at("div[@class='api availability']/ul/li")) && x.inner_text
  seealso = (x = n.at("div[@class$=seeAlso]")) && x.search("li").map(&:inner_text).map {|z| ascii(z).strip}
  related_sample_code  = (x = n.css('.relatedSampleCode li').map {|li| li.inner_text}).empty? ? nil : x

  # TODO samplecode
  # TODO discussion
  {name: methodname,
   type: type,
   declaration: declaration,
   parameters: parameters,
   return_value: return_value,
   abstract: abstract,
   discussion: discussion,
   taskgroup: taskmap[methodname],
   availability: availability,
   seealso: seealso,
   related_sample_code: related_sample_code
  }
end

