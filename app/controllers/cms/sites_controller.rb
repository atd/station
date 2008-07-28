module CMS
  class SitesController < ApplicationController
    include CMS::Controller::Base unless ancestors.include?(CMS::Controller::Base)

    # GET /site
    # GET /site.xml
    def show
      redirect_to edit_cms_site_path
    end

    # GET /site/new
    # GET /site/new.xml
    def new
      redirect_to edit_cms_site_path
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
        if current_site.update_attributes(params[:site])
          flash[:valid] = 'Site configuration was successfully updated.'.t
          format.html { redirect_to root_path }
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
      current_site.destroy if CMS::Site.count > 0

      respond_to do |format|
        format.html { redirect_to root_path  }
        format.xml  { head :ok }
      end
    end
  end
end
