require 'method_parser'

class ClassParser

  attr :doc
  def initialize(doc)
    @doc = doc
  end

  def parse
    r = parse_page
    DB[:classes_and_protocols].insert(r)

    tasks = doc.xpath("//h3[@class='tasks']").map do |h|
      title = h.inner_text
      ul = h.xpath("following-sibling::ul")[0]
      mytasks = ul.search("li").map {|a| 
        { name: ascii(a.at("a").inner_text),
          required: !!((x = a.at("span")) && x.inner_text =~ /required method/) }
      }
      {title: title, tasks: mytasks}
    end

    taskmap = tasks.inject({}) do |taskmap, taskgroup|
      group_title = taskgroup[:title]
      taskgroup[:tasks].each do |task|
        taskmap[task[:name]] = {:taskgroup => taskgroup[:title], :required => task[:required]}
      end
      taskmap
    end
    method_parser = MethodParser.new(r, taskmap)
    method_and_property_divs = doc.xpath("//div[@class='api classMethod']") + 
      doc.xpath("//div[@class='api instanceMethod']") + 
      doc.xpath("//div[@class='api propertyObjC']")

    method_and_property_divs.map {|n| 
      method_parser.parse_method(n)
    }
  end

  def parse_page
    r = {} # result
    r[:name] = doc.at('a')[:title]
    #r[:page] = doc.at('title').inner_text
    r[:description] = doc.at("meta[@id=description]")[:content]
    r[:superclasses] = (x = tr_with_text(doc, 'Inherits from')) && x.search('td/div/a').map(&:inner_text).join(', ')
    r[:protocols] = (x = tr_with_text(doc, 'Conforms to')) && x.search('td/div/span/a').map(&:inner_text).join(', ')
    r[:framework] = (x = tr_with_text(doc, 'Framework')) && x.at('td/div').inner_text.strip
    r[:availability] = (x = tr_with_text(doc, 'Availability')) && x.at('td/div/div/text()').text.strip
    companion_guides = (x = tr_with_text(doc, 'Companion guides')) && x.search("td/div/span/a").map {|a| a.inner_text.strip}.join(', ')
    related_sample_code = (x = tr_with_text(doc, 'Related sample code')) && x.search('td/div/div/span').map {|a| a.inner_text.strip}.join(', ')
    overview = if x = doc.at('//div[@id="Overview_section"]') 
                 fragment_text(x).strip
               else 
                 xs = (doc.at("//h2[text()='Overview']").xpath('following-sibling::*').take_while {|n| n.name == 'p'})
                 xs.map {|a| a.inner_text}.join("\n\n")
               end
    r[:overview] = overview
    r[:companion_guides] = companion_guides
    r[:related_sample_code] = related_sample_code
    r
  end
end
