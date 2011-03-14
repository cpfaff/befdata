class Filevalue < ActiveRecord::Base



  validates_uniqueness_of :file_file_name

  has_attached_file :file,
  :basename => "basename",
  :path => ":rails_root/files/:filename",
  :url => "files/:id/download"

  # tagging
  is_taggable :tags, :languages

#  before_destroy :check_for_measurements
#
# measurements will not be linked to filevalues, there will be a
# separate table for uploading free format files

  after_destroy :destroy_taggings

end
