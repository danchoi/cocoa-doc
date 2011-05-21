
class FunctionsParser
  attr_accessor :taskmap, :doc

  def initialize(doc)
    @doc = doc
  end

  def parse_functions
    tasks = doc.xpath("//h3[@class='tasks']").map do |h|
      title = h.inner_text
      ul = h.xpath("following-sibling::ul")[0]
      mytasks = ul.search("li").map {|a| ascii(a.at("a").inner_text)}
      {title: title, tasks: mytasks}
    end

    @taskmap = tasks.inject({}) do |taskmap, taskgroup|
      group_title = taskgroup[:title]
      taskgroup[:tasks].each do |task|
        taskmap[task] = group_title
      end
      taskmap
    end
    function_headers = doc.xpath("//h3[@class='tight jump function']") 
    function_headers.map {|n| parse_function(n)}
  end

  def parse_function(n) # n is the first h3 node in the function section
    name = n.inner_text
    elems = [n] + n.xpath('following-sibling::*').take_while {|m| FUNCTION_FIELDS.detect{|f| /#{f}/ =~ m['class']}}
    frag = "<div class='blah function'>#{elems.map {|e| e.to_html}.join("\n")}</div>"
    new_node = Nokogiri::HTML.parse(frag).at("div")
    data = parse(new_node)
    puts data.inspect
    DB[:functions].insert data
  end

  def parse(n)
    functionname = n.at('h3[@class*=jump]').inner_text
    declaration = (x = n.at("*[@class*='declaration']")) && x.inner_text.strip
    discussion = (x = n.at("*[@class*=discussion]")) && lynx(x)
    parameters = if (x = n.at("div[@class='api parameters']"))
      x.search("dl/dt").map do |dt|
        name = dt.inner_text
        definition = lynx(dt.xpath("following-sibling::dd").first)
        { name => definition.strip }
      end
    else
      nil
    end
    return_value = (x = n.at("div[@class=return_value]/p")) && x.inner_text
    abstract = (x = n.at("p[@class=abstract]")) && x.inner_text
    availability = (x = n.at("div[@class='api availability']/ul/li")) && x.inner_text
    seealso = (x = n.at("div[@class$=seeAlso]")) && x.search("li").map(&:inner_text).map {|z| ascii(z).strip}.join(', ')
    related_sample_code = (x = n.css('.relatedSampleCode li')) && x.map {|li| li.inner_text}.join(', ')
    declared_in = (x = n.at("div[@class*='declaredIn']/code")) && x.inner_text

    data = {name: functionname,
     page: doc.at('title').inner_text,
     declaration: declaration,
     parameters: to_yaml_or_nil(parameters),
     return_value: return_value,
     abstract: abstract,
     discussion: discussion,
     task: taskmap[functionname],
     availability: availability,
     see_also: seealso,
     related_sample_code: related_sample_code,
     declared_in: declared_in
    }
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

end

