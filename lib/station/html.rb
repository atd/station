{ 'nokogiri' => 'HTML introspection',
  'prism'    => 'Microformats',
  'rdf/rdfa' => 'RDFa' }.each_pair do |gem, support|
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
      @doc ||= Nokogiri::HTML(@text)
    end

    def head_links
      doc.xpath('//head/link')
    end

    def feeds
      head_links.select{ |l|
        l['rel'].try(:match, /alternate/i)
      }
    end

    def atom_links
      head_links.select{ |l|
        l['type'].try(:match, /application\/atom\+xml/i)
      }
    end

    def rss_links
      head_links.select{ |l|
        l['type'].try(:match, /application\/rss\+xml/i)
      }
    end

    def rdf_links
      head_links.select{ |l|
        l['rel'].try(:match, /meta/i) && l['type'].try(:match, /application\/rdf\+xml/i)
      }
    end

    def foaf_links
      rdf_links.select{ |l|
        l['title'].try(:match, /^foaf$/i)
      }
    end

    def atom_service_links
      head_links.select{ |l|
        l['rel'].try(:match, /^service$/i)
      }
    end

    def rsd_links
      head_links.select{ |l|
        l['rel'].try(:match, /^EditURI$/i)
      }
    end

    def foaf?
      foaf_links.any?
    end

    # Find available Microformats for this HTML
    #
    # Needs the {prism}[http://github.com/mwunsch/prism] gem
    def microformats(format = nil)
      Prism.find text, format
    rescue
      Array.new
    end

    # Find hCard in this HTML 
    #
    # Needs the {prism}[http://github.com/mwunsch/prism] gem
    def hcard
      microformats(:hcard)
    rescue
      nil
    end

    # Does this URI has a hCard attached?
    def hcard?
      hcard.present?
    end

    def rdfa
      @rdfa ||=
        RDF::RDFa::Reader.new(@text, :version => :rdfa_1_0).dump(:ntriples)
    rescue NoMethodError
      ""
    end

    def rdfa?
      rdfa.present?
    end

    def rdfa_without_xhtml
      @rdfa_without_xhtml ||=
        rdfa.
          split("\n").
          delete_if{ |t| t =~ /#{ 'www.w3.org/1999/xhtml/vocab' }/ }
    end

    def rdfa_without_xhtml?
      rdfa_without_xhtml.present?
    end

    def to_s
      @text
    end
  end
end
