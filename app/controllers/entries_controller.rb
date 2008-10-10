# Controller methods and default filters for Entries Controllers
class EntriesController < ApplicationController
  include CMS::Controller::Base unless self.ancestors.include? CMS::Controller::Base
  include CMS::Controller::Authorization unless self.ancestors.include? CMS::Controller::Authorization

  before_filter :get_entry, :only => [ :show, :edit, :update, :destroy, :details, :media ]

  # List Entries belonging to Container
  #
  # List all entries when no Container is specified
  #
  #   GET /:container_type/:container_id/entries
  #   GET /entries
  def index
    if current_container
      @title ||= "#{ current_container.name } - #{ 'Entry'.t('Entries', 99) }"
      
      @entries = current_container.container_entries.content_type(params[:content_type]).column_sort(params[:order], params[:direction]).paginate(:page => params[:page], :per_page => Entry.per_page)

      @updated = @entries.blank? ? current_container.updated_at : @entries.first.updated_at
    else
      @title ||= 'Entry'.t('Entries', 99)
      @entries = Entry.content_type(params[:content_type]).column_sort(params[:order], params[:direction]).paginate(:page =>  params[:page])
      @updated = @entries.blank? ? Site.current.created_at : @entries.first.updated_at
    end

    @agents = CMS::Agent.classes.map(&:all).flatten.sort{ |a, b| a.login <=> b.login }
    container_classes = CMS.container_classes - ( CMS.agent_classes + [ Site, Entry ] )
    @containers = container_classes.map(&:all).flatten.uniq.sort{ |a, b| a.name <=> b.name }

    respond_to do |format|
      format.html
      format.atom
      format.xml { render :xml => @entries.to_xml }
    end
  end

  # Show this Entry
  #   GET /entries/:id
  def show
    @title ||= @entry.title

    @containers = Array(@entry.container)
    @agents = @entry.container.actors

    respond_to do |format|
      format.html
      format.xml { render :xml => @entry.to_xml(:include => [ :content ]) }
      format.atom { 
        headers["Content-type"] = 'application/atom+xml'
        render :partial => "entries/entry",
                           :locals => { :entry => @entry },
                           :layout => false
      }
      format.json { render :json => @entry.to_json(:include => :content) }
    end
  end

  # Renders form for editing this Entry metadata
  #   GET /entries/:id/edit
  def edit
    get_params_title_and_description(@entry)
    params[:category_ids] = @entry.category_ids

    render :template => "entries/edit"
  end

  # Update this Entry metadata
  #   PUT /entries/:id
  def update
    set_params_title_and_description(@entry.content)

    # If the Content of this Entry hasn't attachment, update it here
    # If it has, update via media
    # 
    # TODO: find old content when only entry params are updated
    # TODO: Update in AtomPub?
#        unless request.format == :atom
#        @content = @entry.content.class.create params[:content]
#        end

    # Avoid the user changes container through params
    params[:entry][:container] = @entry.container
    params[:entry][:agent]     = current_agent

    respond_to do |format|
      format.html {
        if @entry.content.update_attributes(params[:content]) && 
          @entry.update_attributes(params[:entry])
          @entry.category_ids = params[:category_ids]
          flash[:valid] = "#{ @content.class.to_s.humanize } updated".t
          redirect_to @entry
        else
          render :template => "entries/edit" 
        end
      }

      format.atom {
        if @entry.content.update_attributes(params[:content]) && @entry.update_attributes(params[:entry])
          head :ok
        else
          render :xml => [ @content.errors + @entry.errors ].to_xml,
                 :status => :not_acceptable
        end
      }
    end
  end

  # Manage Entry media (if Entry has media)
  # Retreive media
  #   GET /entries/:id/media 
  # Update media
  #   PUT /entries/:id/media 
  def media
    if request.get?
      # Render media file
      @content = @entry.content
      
      # Get thumbnail if content supports it and asking for it
      @content = @content.thumbnails.find_by_thumbnail(params[:thumbnail]) if 
        params[:thumbnail] && @content.respond_to?(:thumbnails)

      send_data @content.current_data, :filename => @content.filename,
                                       :type => @content.content_type,
                                       :disposition => @content.class.content_options[:disposition].to_s
    elsif request.put?
      # Have to set write entry filter here
      # because doesn't apply to GET
      unless @entry.update_by? current_agent
        access_denied
        return
      end

      # Set params when putting raw data
      set_params_from_raw_post

      respond_to do |format|
        format.html {
          if @entry.content.update_attributes(params[:content])
            flash[:valid] = "#{ @content.class.to_s.humanize } updated".t
            redirect_to @entry
          else
            render :template => "entries/edit_media"
          end
        }

        format.atom {
          if @entry.content.update_attributes(params[:content])
            head :ok
          else
            render :xml => @entry.content.errors.to_xml,
                   :status => :not_acceptable
          end
        } 
      end
    else
      bad_request
    end
  end

  # Renders form for editing this Entry's media
  #   GET /entries/:id/edit_media
  def edit_media
    render :template => "entries/edit_media"
  end

  # Delete this Entry
  #   DELETE /entries/:id
  def destroy
    @entry.destroy

    respond_to do |format|
      format.html { redirect_to polymorphic_path(@container) }
      format.atom { head :ok }
      # FIXME: Check AtomPub, RFC 5023
#      format.send(mime_type) { head :ok }
      format.xml { head :ok }
    end
  end

  protected

    # Find Entry using params[:id]
    # 
    # Sets @entry, @content and @container variables
    def get_entry
      @entry ||= Entry.find(params[:id])
      @content ||= @entry.content
      @container ||= @entry.container
    end

    # Filter for actions that require the Entry has a Content with attached media options
    def entry_has_media
      get_entry
      bad_request("Content doesn't have media") unless @entry.content.content_options[:has_media]
    end

    # Set Bad Request response    
    def bad_request(message = "Bad Request")
      respond_to do |format|
        format.html { 
          render :text => message, :status => 400 
        }
        format.atom {
          head :bad_request
        }
      end
    end
end
