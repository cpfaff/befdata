# frozen_string_literal: true

class CsvData
  include ActiveModel::Validations
  validate :check_csvfile

  # define 'strip' and 'upcase' converters
  CSV::Converters[:strip] = ->(f) { f.to_s.try(:squish) }
  CSV::HeaderConverters[:strip] = ->(f) { f.to_s.try(:squish) }
  CSV::HeaderConverters[:upcase] = ->(f) { f.to_s.try(:upcase) }

  OPTS = {
    headers: true,
    return_headers: false,
    skip_blanks: true,
    converters: :strip,
    header_converters: %i[strip upcase]
  }.freeze

  def initialize(datafile)
    @dataset = datafile.dataset
    @path = datafile.path
    @delimitor = detect_separator
  end

  def general_metadata_hash
    {}
  end

  def authors_list
    {
      found_users: [],
      unfound_users: []
    }
  end

  def projects_list
    {}
  end

  def headers
    return @headers if defined? @headers

    CSV.open @path, OPTS.merge(col_sep: @delimitor) do |csv|
      @headers = csv.first.headers
    end
    @headers
  end

  def import_data
    save_datacolumns
    import_sheetcells
  end

  private

  def detect_separator # TODO: this rule is not strict
    first_row = File.open(@path, &:readline)
    # because TAB is rarely part of data, if tabs are detected in the header,
    # it's very possible that it's the delimitor.
    begin
      first_row.count("\t") > 0 ? "\t" : ','
    rescue StandardError
      nil
    end
  end

  def check_csvfile
    begin
      headers
    rescue CSV::MalformedCSVError => e
      errors.add(:file, 'is not valid CSV file.') && (return)
    rescue ArgumentError => e
      errors.add(:base, 'File with non-english characters should be in UTF-8 encoding') && return if e.message =~ /invalid byte sequence in UTF-8/
    end
    errors.add(:base, 'Failed to find data in your file') && return unless headers.present?
    errors.add(:base, 'It seems one or more columns do not have a header') && return if headers.any?(&:blank?)
    errors.add :file, 'column headers must be uniq' unless headers_unique?
  end

  def headers_unique?
    headers.uniq.map(&:upcase).length == headers.length
  end

  def save_datacolumns
    @datacolumns = headers.map.with_index do |h, i|
      Datacolumn.create! do |dc|
        dc.columnheader = h
        dc.definition = h
        dc.columnnr = i + 1
        dc.dataset_id = @dataset.id
      end
    end
  end

  def import_sheetcells
    id_for_header = header_id_lookup_table
    counter = 0
    sheetcells_in_queue = []

    CSV.foreach @path, OPTS.merge(col_sep: @delimitor) do |row|
      row.to_hash.each do |k, v|
        next if v.blank?

        sheetcells_in_queue << [id_for_header[k], v, $INPUT_LINE_NUMBER, Datatypehelper::UNKNOWN.id]
        counter += 1
      end
      if counter >= 1000
        save_data_into_database(sheetcells_in_queue)
        counter = 0
        sheetcells_in_queue.clear
      end
    end
    save_data_into_database(sheetcells_in_queue)
  end

  def header_id_lookup_table
    hash = {}
    columns = defined?(@datacolumns) ? @datacolumns : @dataset.datacolumns
    columns.each do |dc|
      hash[dc.columnheader] = dc.id
    end
    hash
  end

  def save_data_into_database(sheetcells)
    columns = %i[datacolumn_id import_value row_number datatype_id]
    Sheetcell.import columns, sheetcells, validate: false
    @dataset.update_attribute(:import_status, "Imported #{$INPUT_LINE_NUMBER - 1} rows")
  end
end
