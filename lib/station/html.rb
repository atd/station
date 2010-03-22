{ 'hpricot' => 'HTML introspection',
  'mofo'    => 'Microformats' }.each_pair do |gem, support|
  begin
    require gem
  rescue MissingSourceFile
    Rails.logger.info "Station Info: You need '#{ gem }' gem for #{ support } support"
  end
end

module Station #:nodoc:
  # Manage HTML documents
  class Html
    attr_reader :text

    def initialize(text)
      @text = text || ""
    end

    def doc
      @doc ||= Hpricot(@text)
    end

    def head_links
      doc.search('//link')
    end

    def feeds
      head_links.select{ |l|
        l['rel'].match(/alternate/i)
      }
    end

    def rdf_links
      head_links.select{ |l|
        l['rel'].match(/meta/i) && l['type'].match(/application\/rdf\+xml/)
      }
    end

    def foaf_links
      rdf_links.select{ |l|
        l['title'].match(/^foaf$/i)
      }
    end

    def atom_service_links
      head_links.select{ |l|
        l['rel'].match(/^service$/i)
      }
    end

    def rsd_links
      head_links.select{ |l|
        l['rel'].match(/^EditURI$/i)
      }
    end

    def foaf?
      foaf_links.any?
    end

    def microformats
      Microformat.find :text => text
    rescue
      Array.new
    end

    # Find hCard in this HTML 
    #
    # Needs the {mofo}[http://mofo.rubyforge.org/] gem
    def hcard
      hCard.find :text => text
    rescue
      nil
    end

    # Does this URI has a hCard attached?
    def hcard?
      hcard.present?
    end

    def to_s
      @text
    end
  end
end
