# frozen_string_literal: true

## A Freeformat file is an asset file that has been uploaded to the application within a "Dataset". A "Dataset" can have
## none, one or more than one Freeformat files. No validation is performed on a Freeformat file.
class Freeformat < ApplicationRecord
  belongs_to :freeformattable, polymorphic: true, touch: true, counter_cache: true

  validates_presence_of :file_file_name, message: 'You have to select a file to be uploaded.'
  validates_presence_of :freeformattable, message: 'Freeformat must belong to something'

  # this is not good. As everybody can pass anything. We need to create a list and maintain the list of
  has_attached_file :file, basename: 'basename', path: ':rails_root/files/freeformats/:id_:filename', validate_media_type: false
  do_not_validate_attachment_file_type :file

  def basename
    File.basename(file.original_filename, File.extname(file.original_filename))
  end

  def to_label
    file_file_name.to_s
  end
end
