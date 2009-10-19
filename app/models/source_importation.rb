class SourceImportation < ActiveRecord::Base
  belongs_to :source
  belongs_to :importation, :polymorphic => true, :dependent => :destroy
end
