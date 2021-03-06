# frozen_string_literal: true

class Datafile < ApplicationRecord
  belongs_to :dataset, counter_cache: true

  has_attached_file :file, basename: 'basename', path: ':rails_root/files/uploaded/:id_:filename', validate_media_type: false
  # validates_attachment_content_type :file, :content_type => ["text/csv", "application/vnd.ms-excel"]
  do_not_validate_attachment_file_type :file

  validates_attachment_presence :file

  def basename
    File.basename(file.original_filename, File.extname(file.original_filename))
  end

  def path
    file.queued_for_write[:original] ? file.queued_for_write[:original].path : file.path
  end

  def spreadsheet
    return nil unless file.present?
    return @spreadsheet if defined? @spreadsheet

    @spreadsheet = case File.extname(path)
                   when '.xls' then Workbook.new(self)
                   when '.csv' then CsvData.new(self)
      end
  end
  delegate :import_data, :general_metadata_hash, :authors_list, :projects_list, to: :spreadsheet, allow_nil: true

  # TODO: that might be deprecated with the paperclip validation
  validate :check_spreadsheet, if: proc { file.present? }
  def check_spreadsheet
    errors[:base] = 'We currently only support Excel-2003 and CSV files.' && return unless spreadsheet
    unless spreadsheet.valid?
      spreadsheet.errors.to_hash.each do |k, v|
        errors.add k, v
      end
    end
  end
end
