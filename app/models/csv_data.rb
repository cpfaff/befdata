class CsvData
  include ActiveModel::Validations
  validate :check_csvfile

  # define 'strip' converter
  CSV::Converters[:strip] = lambda {|f| f.try(:strip) }
  CSV::HeaderConverters[:strip] = lambda {|f| f.try(:strip) }

  OPTS = {
    headers: true,
    return_headers: false,
    skip_blanks: true,
    converters: :strip,
    header_converters: :strip
  }

  def initialize(datafile)
    @dataset = datafile.dataset
    @path = datafile.path
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
    CSV.open @path, OPTS do |csv|
      @headers = csv.first.headers
    end
    return @headers
  end

  def import_data
    save_datacolumns
    import_sheetcells
  end
  
private

  def check_csvfile
    errors.add :base, 'Failed to find data in your file' and return unless headers.present?
    errors.add :base, 'It seems one or more columns have not a header' and return if headers.any? {|h| h.blank? }
    errors.add :file, 'column headers must be uniq' unless headers.uniq_by(&:downcase).length == headers.length
  end

  def save_datacolumns
    @datacolumns = headers.map.with_index do |h, i|
      datagroup = assign_datagroup_to_column(h)
      Datacolumn.create! do |dc|
        dc.columnheader = h
        dc.definition = h
        dc.columnnr = i + 1
        dc.dataset_id = @dataset.id
        dc.datatype_approved = false
        dc.datagroup_approved = false
        dc.finished = false
        dc.datagroup_id = datagroup.id
      end
    end
  end

  def import_sheetcells
    id_for_header = header_id_lookup_table
    counter = 0
    sheetcells_in_queue = []

    CSV.foreach @path, OPTS do |row|
      row.to_hash.each do |k, v|
        next if v.blank?
        sheetcells_in_queue << [ id_for_header[k], v, $INPUT_LINE_NUMBER,
            Datatypehelper::UNKNOWN.id, Sheetcellstatus::UNPROCESSED ]

        counter += 1
        if counter == 1000
          save_data_into_database(sheetcells_in_queue)
          counter = 0
          sheetcells_in_queue.clear
        end
      end
    end
    save_data_into_database(sheetcells_in_queue)
  end

  def assign_datagroup_to_column(columnheader)
    datagroup = Datagroup.where(["title iLike ?", columnheader]).first
    return datagroup if datagroup
    return Datagroup.create!(title: columnheader)
  end

  def header_id_lookup_table
    hash = {}
    columns = defined?(@datacolumns) ? @datacolumns : @dataset.datacolumns
    columns.each do |dc|
      hash[dc.columnheader] = dc.id
    end
    return hash
  end

  def save_data_into_database(sheetcells)
    columns = [:datacolumn_id, :import_value, :row_number, :datatype_id, :status_id] 
    Sheetcell.import columns, sheetcells, :validate => false
  end

end