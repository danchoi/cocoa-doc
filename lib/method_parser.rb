
class MethodFunctionParser
  attr_accessor :taskmap, :page

  def initialize(page, taskmap)
    @page = page
    @taskmap = taskmap
  end

  def parse(n)
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
    end.to_yaml
    return_value = (x = n.at("div[@class=return_value]/p")) && x.inner_text
    abstract = (x = n.at("p[@class=abstract]")) && x.inner_text
    availability = (x = n.at("div[@class='api availability']/ul/li")) && x.inner_text
    seealso = (x = n.at("div[@class$=seeAlso]")) && x.search("li").map(&:inner_text).map {|z| ascii(z).strip}.to_yaml
    related_sample_code = (x = n.css('.relatedSampleCode li')) && x.map {|li| li.inner_text}.join(', ')

    data = {name: methodname,
     type: type,
     page: page[:page],
     declaration: declaration,
     parameters: parameters,
     return_value: return_value,
     abstract: abstract,
     discussion: discussion,
     group: taskmap[methodname],
     availability: availability,
     see_also: seealso,
     related_sample_code: related_sample_code
    }
    begin
      DB[:api].insert(data)
    rescue
      puts data.to_yaml
      raise
    end
  end

  FUNCTION_FIELDS = %w(
    abstract
    declaration
    parameters
    return_value
    discussion
    availability
    seeAlso
    relatedSampleCode
    declaredIn
  )

  def parse_function(n) # n is the first h3 node in the function section
    name = n.inner_text
    elems = [n]
    m = n.next_element
    begin
      while !m.nil? && FUNCTION_FIELDS.detect {|f| m[:class] =~ /#{f}/}
        elems << m
        m = m.next_element
      end 
    rescue
      puts n.inner_html
      raise
    end
    frag = "<div class='blah function'>#{elems.map {|e| e.to_html}.join("\n")}</div>"
    new_node = Nokogiri::HTML.parse(frag).at("div")
    parse_method(new_node, taskmap)
  end
end

