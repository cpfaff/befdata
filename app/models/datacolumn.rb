class Datacolumn < ActiveRecord::Base

  is_taggable :tags, :languages
  after_destroy :destroy_taggings

  acts_as_authorization_object :subject_class_name => 'User'


  belongs_to :datagroup
  belongs_to :dataset

  has_many :sheetcells, :dependent => :destroy

  has_many :import_categories, :dependent => :destroy

  validates_presence_of :datagroup_id, :dataset_id, :columnheader, :columnnr, :definition
  validates_uniqueness_of :columnheader, :columnnr, :scope => :dataset_id

  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end

  # Returns a hash of the imported entries as value and the rownumber
  # from the Observation as key.
  def rownr_entry_hash
    ms = self.sheetcells
    rownr_entry_hash = Hash.new
    ms.each do |m|
      rownr = m.observation.rownr
      rownr_entry_hash[rownr] = m.import_value
    end
    return rownr_entry_hash
  end

  # Are there values associated to the measurements of this data column instance?
  def values_stored?
    ms = self.sheetcells.find(:all, :conditions => ["accepted_value IS NOT NULL OR accepted_value !='' OR category_id > 0"])
    return !ms.empty?
  end

  # returns the first 'count' number unique imported values
  def imported_values(count)
    values = self.sheetcells.find(:all, :order => "import_value",
                                        :limit => count,
                                        :group => "import_value",
                                        :select => "import_value")
    return values
  end

  # returns the first 'count' number unique accepted values
  def accepted_values(count)
    values = self.sheetcells.find(:all, :limit => count,
                                        :joins => "LEFT OUTER JOIN categories ON categories.id = sheetcells.category_id" ,
                                        :select => "distinct case when sheetcells.category_id > 0 then categories.short else sheetcells.accepted_value end as accepted_value",
                                        :order => "accepted_value")

    return values
  end

  # saves the accepted values for each sheetcell in the column
  # first looking for a match in existing categories
  # then looking for a match in categories from the datasheet
  # if there are no category matches then the import value is used as the accepted value
  # NB: all of the business logic is in functions within the database
  def add_data_values(user)

    # remove any previous accepted values so that we can keep a track of what has been updated
    sqlclean = "select clear_datacolumn_accepted_values(#{id})"
    # this bit will need to change once we change the column datatype to be an integer
    case self.import_data_type
        when "text"
          datatype = Datatypehelper.find_by_id(1)
        when "year"
          datatype = Datatypehelper.find_by_id(2)
        when "date(2009-07-14)"
          datatype = Datatypehelper.find_by_id(3)
        when "date(14.07.2009)"
          datatype = Datatypehelper.find_by_id(4)
        when "category"
          datatype = Datatypehelper.find_by_id(5)
        when "number"
          datatype = Datatypehelper.find_by_id(7)
      else
        #unknown
        datatype = Datatypehelper.find_by_id(8)
      end
    # I would like to change this so that the SQL is in one function but it wasn't working
    # TODO: I will look at this again - SR
    if(datatype.name == "text") then
      sql = "select accept_text_datacolumn_values(#{id})"
    else
      dataset = Dataset.find(self.dataset_id)
      comment = ""
      unless dataset.nil?
        comment = dataset.title
      end
      sql = "select accept_datacolumn_values(#{datatype.id}, #{id}, #{datagroup_id}, #{user.id}, '#{comment}')"
    end

    begin
      connection = ActiveRecord::Base.connection()
      connection.begin_db_transaction
      connection.execute(sqlclean)
      connection.execute(sql)

      connection.commit_db_transaction
    rescue
      connection.rollback_db_transaction
      raise
    end

  end

  # returns all the invalid uploaded sheetcells
  def invalid_values
    # Get all the invalid sheetcells of this data column from the database
    invalid_sheetcells = self.sheetcells.find(:all, :conditions => ["status_id = ?", Sheetcellstatus::INVALID])
      
    # No need to order the sheetcells if none were found
    return Hash.new if invalid_sheetcells.blank? 
    
    # Create a new hash and preset the keys with empty arrays
    invalid_values_hash = Hash.new {|h,k| h[k] = []}
    
    # Move all found sheetcell ids to the hash ordered by value
    invalid_sheetcells.each{|sc| invalid_values_hash[sc.import_value] << sc.id}
    return invalid_values_hash
  end


  def to_label
    columnheader
  end

  def approval_stage
    stage = '0'
    stage = '1' if self.datagroup_approved
    stage = '2' if self.datagroup_approved && self.datatype_approved
    stage = '3' if self.datagroup_approved && self.datatype_approved && self.invalid_values.blank?
    return stage
  end
end
