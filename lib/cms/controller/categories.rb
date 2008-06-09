module CMS
  module Controller
    # Categories methods and filters for CMS::Category
    module Categories
      def self.included(base) #:nodoc:
        base.send :include, CMS::Controller::Base unless base.ancestors.include?(CMS::Controller::Base)
      end

      # List categories belonging to a Container
      #
      # GET /:container_type/:container_id/categories
      # GET /container_type/:container_id/categories.xml
      def index
        @categories = @container.container_categories
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
        @category = @container.container_categories.new(params[:cms_category])

        respond_to do |format|
          if @category.save
            flash[:notice] = 'Category created'.t
            format.html { redirect_to(category_path(@category)) }
            format.xml  { render :xml => @category, :status => :created, :location => category_url(@category) }
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
          if @category.update_attributes(params[:cms_category])
            flash[:notice] = 'Category updated'.t
            format.html { redirect_to(category_path(@category)) }
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
          format.html { redirect_to(container_categories_url(:container_type => @container.class.to_s.tableize, :container_id => @container.id)) }
          format.xml  { head :ok }
        end
      end

      protected

      # Find CMS::Category using params[:id]
      #
      # Sets @category and @container variables
      def get_category
        @category = CMS::Category.find(params[:id])
        @container = @category.container
      end
    end
  end
end

