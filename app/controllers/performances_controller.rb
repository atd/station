class PerformancesController < ApplicationController
  before_filter :get_stage, :only => [ :index, :new, :create ]
  before_filter :get_performance, :only => [ :edit, :update, :destroy ]
  before_filter :parse_polymorphic_agent, :only => [ :create, :update ]

  def index
    index_data
  end

  def create
    @performance = Performance.new(params[:performance])
    @performance.stage = get_stage

    if @performance.save
      respond_to do |format|
        format.js {
          index_data
        }
      end
    else
      respond_to do |format|
        format.js
      end
    end
  end

  def update
    # Prevent Performance forge
    params[:performance].delete(:stage_id)
    params[:performance].delete(:stage_type)

    if @performance.update_attributes(params[:performance])
      respond_to do |format|
        format.html {
          redirect_to polymorphic_path([ @stage, Performance.new ])
        }
        format.js {
          index_data
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.js 
      end
    end
  end

  def destroy
    @performance.destroy

    respond_to do |format|
      format.html { 
        redirect_to polymorphic_path([ @stage, Performance.new ])
      }

      format.js {
        index_data
      }
    end
  end

  private

  def get_stage
    @stage ||= get_resource_from_path(:acts_as => :stage)
  end

  def get_performance
    @performance = Performance.find(params[:id])
    @stage = @performance.stage
  end

  def index_data
    @performances = @stage.stage_performances.find(:all,
                                                   :include => :role).sort{ |x, y| y.role <=> x.role }
    @roles = @stage.class.roles.sort{ |x, y| y <=> x }
    @roles = @roles.select{ |r| r <= @stage.role_for(current_agent) } if @stage.role_for(current_agent)

    @agents = ActiveRecord::Agent.all - @performances.map(&:agent)
  end

  def parse_polymorphic_agent
    if a = params[:performance].delete(:agent)
      klass, id = a.split("-", 2)
      params[:performance][:agent_id] = id 
      params[:performance][:agent_type] = klass.classify
      unless ActiveRecord::Agent.symbols.include?(klass.pluralize.to_sym)
        raise "Wrong Agent Type in PerformancesController: #{ h params[:performance][:agent_type] }"
      end
    end
  end


end
