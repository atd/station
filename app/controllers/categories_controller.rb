# Categories methods and filters for Category
class CategoriesController < ApplicationController
  include CMS::Controller::Base unless self.ancestors.include?(CMS::Controller::Base)

  before_filter :needs_container, :only => [ :index, :new, :create ]

  before_filter :get_category, :only => [ :show, :edit, :update, :destroy ]

  before_filter :containers_and_agents

  # List categories belonging to a Container
  #
  # GET /:container_type/:container_id/categories
  # GET /container_type/:container_id/categories.xml
  def index
    @categories = @container.container_categories.column_sort(params[:order], params[:direction])
    @title = "#{ 'Listing categories'.t } - #{ @container.name }"
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @categories }
    end
  end

  # Show category
  #
  # GET /categories/1
  # GET /categories/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # New Category form
  #
  # GET /:container_type/:container_id/categories/new
  # GET /:container_type/:container_id/categories/new.xml
  def new
    @category = @container.container_categories.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # Edit category form
  #
  # GET /categories/1/edit
  def edit
  end

  # Create new category
  #
  # POST /:container_type/:container_id/categories
  # POST /:container_type/:container_id/categories.xml
  def create
    @category = @container.container_categories.new(params[:category])

    respond_to do |format|
      if @category.save
        flash[:valid] = 'Category created'.t
        format.html { redirect_to(@category) }
        format.xml  { render :xml => @category, :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Update category
  #
  # PUT /categories/1
  # PUT /categories/1.xml
  def update
    respond_to do |format|
      if @category.update_attributes(params[:category])
        flash[:valid] = 'Category updated'.t
        format.html { redirect_to(@category) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Destroy category
  #
  # DELETE /categories/1
  # DELETE /categories/1.xml
  def destroy
    @category.destroy

    respond_to do |format|
      format.html { redirect_to(polymorphic_path([ @container.to_ppath, Category.new ])) }
      format.xml  { head :ok }
    end
  end

  protected

  # Find Category using params[:id]
  #
  # Sets @category and @container variables
  def get_category
    @category = Category.find(params[:id])
    @container = @category.container
  end

  # Set @containers and @agents variables from @container
  #
  # @container variable is set either in :needs_container or :get_category
  def containers_and_agents #:nodoc:
    @containers = Array(@container)
    @agents = @container.actors
  end
end

