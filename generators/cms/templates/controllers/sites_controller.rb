class SitesController < ApplicationController
    include CMS::Controller::Sites

    before_filter :site_admin
end
