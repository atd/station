class SitesController < ApplicationController

  # GET /site
  # GET /site.xml
  def show
    @site = current_site
    @agents = CMS::ActiveRecord::Agent.authentication_classes.map(&:all).flatten.uniq.sort{ |x, y| x.name <=> y.name }
    @containers = ( CMS::ActiveRecord::Container.classes - CMS::ActiveRecord::Agent.classes).map(&:all).flatten.uniq.sort{ |x, y| x.name <=> y.name }
  end

  # GET /site/new
  # GET /site/new.xml
  def new
    redirect_to edit_site_path
  end

  # GET /site/edit
  def edit
    @site = current_site
  end

  # POST /site
  # POST /site.xml
  def create
    update
  end

  # PUT /site
  # PUT /site.xml
  def update
    respond_to do |format|
      #TODO acts_as_logotypable: Rails support for nested objects
      if current_site.logotype
        current_site.logotype.attributes = params[:logotype]
      else
        current_site.logotype = Logotype.new(params[:logotype])
      end unless params[:logotype][:media].blank?

      if current_site.update_attributes(params[:site])
        flash[:valid] = 'Site configuration was successfully updated.'.t
        format.html { redirect_to site_path }
        format.xml  { head :ok }
      else
        @site = current_site
        format.html { render :action => "edit" }
        format.xml  { render :xml => @site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /site
  # DELETE /site.xml
  def destroy
    current_site.destroy if Site.count > 0

    respond_to do |format|
      format.html { redirect_to root_path  }
      format.xml  { head :ok }
    end
  end
end
