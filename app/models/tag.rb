class Tag < ActiveRecord::Base

  DELIMITER = "," # Controls how to split and join tagnames from strings. You may need to change the <tt>validates_format_of parameters</tt> if you change this.

  # If database speed becomes an issue, you could remove these validations and rescue the ActiveRecord database constraint errors instead.
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  
  # Change this validation if you need more complex tag names.
  validates_format_of :name, :with => /^[\w\_\ \-\.]+$/, :message => "can not contain special characters"
  
  has_many :taggings

  for taggable in CMS.taggables
    has_many taggable, :through => :taggings,
                       :source => :taggable,
                       :source_type => taggable.to_s.classify
  end

  # All the instances tagged with some Tag
  def taggables
    CMS.taggables.map{ |t| send(t) }.flatten
  end


  # Callback to strip extra spaces from the tagname before saving it. If you allow tags to be renamed later, you might want to use the <tt>before_save</tt> callback instead.
  def before_create 
    self.name = name.downcase.strip.squeeze(" ")
  end
end
