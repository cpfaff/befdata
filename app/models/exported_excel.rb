# frozen_string_literal: true

require 'dataworkbook_format'

class ExportedExcel < ExportedFile
  include DataworkbookFormat

  has_attached_file :file, path: ':rails_root/files/generated/:dataset_id_generated-download.xls', validate_media_type: false
  # validates_attachment_content_type :file, :content_type => ["application/vnd.ms-excel"]
  do_not_validate_attachment_file_type :file

  def format
    'xls'
  end

  def export
    update_attribute(:status, STARTED)

    Spreadsheet.client_encoding = 'UTF-8'
    excel_workbook = Spreadsheet.open Rails.root.join('public', 'templates', 'befdata_workbook_empty.xls')

    create_metasheet(excel_workbook, dataset)
    create_columnsheet(excel_workbook, dataset)
    create_peoplesheet(excel_workbook, dataset)
    create_categorysheet(excel_workbook, dataset)
    create_datasheet(excel_workbook, dataset)

    workaround_for_readable_xls(excel_workbook)

    tf = Tempfile.new('ds-temp')
    excel_workbook.write(tf)

    self.file = tf
    self.file_file_name = dataset.title.gsub(/[^\w]/, '-')
    self.generated_at = Time.now
    self.status = FINISHED
    puts "=== Download generated for Dataset id: #{dataset_id}.#{format} at #{Time.now}"
    save
  end

  private

  def workaround_for_readable_xls(excel_workbook)
    # there needs to be some modification on every worksheet
    # otherwise multi-sheet spreadsheets won't be readable
    excel_workbook.worksheets.each do |ws|
      x = ws[0, 0]
      ws[0, 0] = x
    end
  end

  def create_metasheet(book, dataset)
    sheet = book.worksheet WBF[:metadata_sheet]

    sheet[*WBF[:meta_version_pos]] = WBF[:wb_format_version]

    sheet[*WBF[:meta_title_pos]] = dataset.title ||= ''
    sheet[*WBF[:meta_abstract_pos]] = dataset.abstract_with_freeformats ||= ''
    sheet[*WBF[:meta_comment_pos]] = dataset.comment ||= ''
    sheet[*WBF[:meta_usagerights_pos]] = dataset.usagerights ||= ''
    sheet[*WBF[:meta_published_pos]] = dataset.published ||= ''
    sheet[*WBF[:meta_spatial_extent_pos]] = dataset.spatialextent ||= ''
    sheet[*WBF[:meta_temporalextent_pos]] = dataset.temporalextent ||= ''
    sheet[*WBF[:meta_taxonomicextent_pos]] = dataset.taxonomicextent ||= ''
    sheet[*WBF[:meta_design_pos]] = dataset.design ||= ''
    sheet[*WBF[:meta_dataanalysis_pos]] = dataset.dataanalysis ||= ''
    sheet[*WBF[:meta_circumstances_pos]] = dataset.circumstances ||= ''

    sheet[*WBF[:meta_datemin_pos]] = dataset.datemin ? dataset.datemin.to_date.to_s : ''
    sheet[*WBF[:meta_datemax_pos]] = dataset.datemax ? dataset.datemax.to_date.to_s : ''
    sheet[*WBF[:meta_projects_pos]] = dataset.projects.uniq.collect(&:shortname).sort.join(', ')

    c_owners = dataset.owners
    unless c_owners.blank?
      i = WBF[:meta_owners_start_col]
      c_owners.each do |cpr|
        sheet[WBF[:meta_owners_start_row], i] = cpr.firstname ||= ''
        sheet[WBF[:meta_owners_start_row] + 1, i] = cpr.lastname ||= ''
        sheet[WBF[:meta_owners_start_row] + 2, i] = cpr.email
        i += 1
      end
    end
  end

  def create_columnsheet(book, dataset, column_selection = nil)
    sheet = book.worksheet WBF[:columns_sheet]
    datacolumns = query_datacolumns(dataset, column_selection)

    row = 0
    datacolumns.each do |datacolumn|
      if column_selection
        row += 1
      else
        row = datacolumn.columnnr
      end
      sheet[row, WBF[:column_header_col]]            = datacolumn.columnheader
      sheet[row, WBF[:column_definition_col]]        = datacolumn.definition
      sheet[row, WBF[:column_methodvaluetype_col]]   = datacolumn.import_data_type
      sheet[row, WBF[:column_unit_col]]              = datacolumn.unit
      sheet[row, WBF[:column_instrumentation_col]]   = datacolumn.instrumentation
      sheet[row, WBF[:column_informationsource_col]] = datacolumn.informationsource

      keywords = datacolumn.tag_list.join(', ')
      sheet[row, WBF[:column_keywords_col]] = keywords unless keywords.blank?

      sheet[row, WBF[:group_title_col]] = datacolumn.datagroup.title if datacolumn.datagroup.present?
      sheet[row, WBF[:group_description_col]] = datacolumn.datagroup.description if datacolumn.datagroup.present?
    end
  end

  def create_peoplesheet(book, dataset, column_selection = nil)
    sheet = book.worksheet WBF[:people_sheet]
    datacolumns = query_datacolumns(dataset, column_selection)

    row = 1
    datacolumns.each do |datacolumn|
      datacolumn.users.each do |pr|
        sheet[row, WBF[:people_columnheader_col]] = datacolumn.columnheader if datacolumn.columnheader
        sheet[row, WBF[:people_firstname_col]] = pr.firstname if pr.firstname
        sheet[row, WBF[:people_lastname_col]] = pr.lastname if pr.lastname
        row += 1
      end
    end
  end

  def create_categorysheet(book, dataset, column_selection = nil)
    sheet = book.worksheet WBF[:category_sheet]
    datacolumns = query_datacolumns(dataset, column_selection)

    approved_cols_ids = datacolumns.select(&:datatype_approved?).collect(&:id)

    row = 1
    approved_cols_ids.each do |col_id|
      col_loop = Datacolumn.find(col_id)
      clean_cats = col_loop.sheetcells.where('sheetcells.datatype_id = ?', Datatypehelper.find_by_name('category').id).joins('JOIN categories ON categories.id = sheetcells.category_id').select('distinct categories.short, categories.long, categories.description').order('categories.short')

      clean_cats.each do |cat|
        sheet[row, WBF[:category_columnheader_col]] = col_loop.columnheader
        sheet[row, WBF[:category_short_col]] = cat.short
        sheet[row, WBF[:category_long_col]] = cat.long
        sheet[row, WBF[:category_description_col]] = cat.description
        row += 1
      end

      download_time = Time.now.to_s
      clean_un_val = col_loop.sheetcells.where('status_id = ?', Sheetcellstatus::INVALID).select('distinct import_value').order('import_value')

      clean_un_val.each do |uv|
        sheet.row(row).default_format = WBF[:unapproved_format]
        sheet[row, WBF[:category_columnheader_col]] = col_loop.columnheader
        sheet[row, WBF[:category_short_col]] = uv.import_value
        sheet[row, WBF[:category_long_col]] = uv.import_value
        sheet[row, WBF[:category_description_col]] = "#{uv.import_value}: automatically added during validation, as of #{download_time}"
        row += 1
      end
      col_loop = nil
    end
  end

  def create_datasheet(book, dataset, column_selection = nil)
    sheet = book.worksheet WBF[:data_sheet]

    datacolumns = query_datacolumns(dataset, column_selection)

    col = 0
    datacolumns.each do |datacolumn|
      if column_selection
        col += 1 # render from beginning
      else
        col = datacolumn.columnnr # use original col number
      end

      sheet[0, col - 1] = datacolumn.columnheader if datacolumn.columnheader
      ExportedSheetcell.uncached do
        datacolumn.exported_sheetcells.find_each do |sheetcell|
          sheet[sheetcell.row_number - 1, col - 1] = sheetcell.export_value
        end
      end
    end
  end

  def query_datacolumns(dataset = nil, column_selection = nil)
    column_selection || Datacolumn.where(dataset_id: dataset.id).order('columnnr ASC').uniq
  end
end
