
class OthersParser
  attr_accessor :taskmap, :doc

  def initialize(doc, file)
    @doc = doc
    @framework = (x = tr_with_text(doc, 'Framework')) && x.at('td/div').inner_text.strip
    @page = doc.at('title').inner_text
    @file = file
  end

  def parse
    parse_functions
    parse_constant_groups
    parse_constants
    parse_datatypes
  end

  CONST_GROUP_CLASSES = ['abstract', 'declaration']
  def parse_constant_groups
    doc.xpath("//h3[@class='constantGroup']").each {|x|
      elems = [x] + x.xpath("following-sibling::*").take_while {|e| CONST_GROUP_CLASSES.include?(e[:class])}
      fragment = Nokogiri::HTML(elems.map(&:to_html).join)
      data = {
        name: x.inner_text,
        type: 'constantGroup',
        framework: @framework,
        page: @page,
        abstract: (y = fragment.at("p.abstract")) && y.inner_text.strip,
        declaration: (y = fragment.at(".declaration")) && y.inner_text.strip,
        file: @file
      }
      begin
        DB[:others].insert data
      rescue Sequel::DatabaseError
        puts $!
        puts "Tried to insert: %s %s %s" % [ data[:framework],
          data[:type],
          data[:name] ]
      end

    }

  end

  def parse_constants
    constants = doc.xpath("//dt[code/@class='jump constantName']").map {|x|
      constant_name = x.inner_text
      description, availability, declared_in = *x.xpath("following-sibling::dd")[0].search('p').map(&:inner_text)
      constant_group = x.parent.xpath("preceding-sibling::h3[contains(@class, 'constantGroup')]").reverse[0]  || 
        x.parent.xpath("preceding-sibling::a[contains(@name, 'constant_group')]").reverse[0] 
      constant_group = constant_group ? constant_group.inner_text : nil

      data = {
        name: constant_name,
        type: 'constantName',
        framework: @framework,
        page: @page,
        abstract: description,
        availability: availability,
        declared_in: declared_in,
        task_or_group: constant_group,
        file: @file
      }
      DB[:others].insert data
    }
  end

  DATATYPE_FIELDS = ['abstract', 'declaration', 'termdef', 'tight', 'api discussion', 'api availability', 'api declaredIn']
  def parse_datatypes
    structs = doc.xpath("//h3[@class='tight jump struct']")
    type_defs = doc.xpath("//h3[@class='tight jump typeDef']")
    (structs + type_defs).each {|n|
      elems = [n] + n.xpath('following-sibling::*').take_while {|m| DATATYPE_FIELDS.include?(m[:class])}

      frag = "<div class='blah datatype'>#{elems.map {|e| e.to_html}.join("\n")}</div>"
      new_node = Nokogiri::HTML.parse(frag).at("div")
      parse_datatype(new_node)
    }
  end

  def parse_datatype(n)
    data = parse2 n
    DB[:others].insert data 
  end

  def parse_functions
    tasks = doc.xpath("//h3[@class='tasks']").map do |h|
      title = h.inner_text
      ul = h.xpath("following-sibling::ul")[0]
      mytasks = ul.search("li").select {|li|
        li.at("a")
      }.map {|li| 
        ascii(li.at("a").inner_text)
      }
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
    data = parse2(new_node)
    DB[:others].insert data
  end

  def parse2(n)
    functionname = n.at('h3[@class*=jump]').inner_text
    declaration = (x = n.at("*[@class*='declaration']")) && x.inner_text.strip
    discussion = (x = n.at("*[@class*=discussion]")) && lynx(x)
    special_considerations = (x = n.at("*[@class*=specialConsiderations]")) && lynx(x)
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
     type: n.at('h3[@class*=jump]')[:class].split(/\s+/)[-1],
     page: @page, 
     framework: @framework,
     declaration: declaration,
     parameters: to_yaml_or_nil(parameters),
     return_value: return_value,
     abstract: abstract,
     discussion: discussion,
     special_considerations: special_considerations,
     task_or_group: taskmap[functionname],
     availability: availability,
     see_also: seealso,
     related_sample_code: related_sample_code,
     declared_in: declared_in,
     file: @file
    }
    data
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

