require 'rss/1.0'
require 'rss/2.0'
require 'atom/feed'

class Source < ActiveRecord::Base
  attr_accessor :title
  attr_protected :container_id, :container_type

  belongs_to :uri
  accepts_nested_attributes_for :uri
  belongs_to :container, :polymorphic => true

  has_many :source_importations, :dependent => :destroy

  validates_presence_of :uri, :target
  validates_presence_of :content_type, :on => :update

  before_validation :add_http_protocol_to_uri

  def title
    @title || feed.try(:title) || nil
  end

  def feed
    @feed ||= case self.content_type
              when 'application/atom+xml'
                Atom::Feed.new(self.uri).update!
              when 'application/rss+xml'
                RSS::Parser.parse(self.uri.dereference.body)
              else
                nil
              end
  end

  def import
    feed.entries.each do |entry|
      # Import feed entries until reach an already imported one
      break if imported_at && entry.updated < imported_at

      # Find previous Importation with this guid
      if entry.id.present? && old_source_importation = source_importations.find_by_guid(entry.id)
        # Importation may have been deleted previously
        if old_source_importation.importation.present?
          old_source_importation.importation.from_atom!(entry)
        end
        old_source_importation.touch
      else
        # Create new Importation
        source_importations.create :importation => importation_class.new.from_atom!(entry),
                                   :guid => entry.id
      end
    end

    update_attribute :imported_at, Time.now
  end

  protected

  def validate
    return if target.blank?

    raise "Target model #{ self.target } must implement 'params_from_atom' class method" unless
      self.target.constantize.respond_to?(:params_from_atom)
  end

  def validate_on_create
    return if content_type.present? || uri.blank?

    res = self.uri.dereference

    unless res
      errors.add_to_base I18n.t('source.errors.can_not_dereference')
      return
    end

    case res.content_type
    when 'text/html'
      html = Station::Html.new(res.body)
      case html.feeds.size
      when 0
        errors.add_to_base I18n.t('source.errors.no_feed')
      when 1
        f = html.feeds.first
        self.uri.uri = f['href']
        self.content_type = f['type']
      else
        errors.add_to_base I18n.t('source.errors.multiple_feeds')
      end
    when 'application/xml', 'text/xml'
      # Well try to guess what type of feed we have
      if RSS::Parser.parse(res.body)
        # RSS Feed
        self.content_type = 'application/rss+xml'
      else
        begin
          Atom::Feed.parse(res.body)
        rescue
          errors.add :content_type, I18n.t('source.errors.content_type.invalid', :content_type => res.content_type)
        else
          self.content_type = 'application/atom+xml'
        end
      end
    else
      errors.add :content_type, I18n.t('source.errors.content_type.invalid', :content_type => res.content_type)
    end
  end

  private

  def add_http_protocol_to_uri
    # Source URI are obtained using HTTP protocol
    if uri && uri.uri.present? && ! ( uri.uri =~ /^http:\/\/.+/ )
      uri.uri = "http://#{ uri.uri }"
    end
  end

  # The target class to be instanciated when importing from from this source
  def importation_class
    self.container && self.container.send(target.tableize) ||
      target.constantize
  end

end
