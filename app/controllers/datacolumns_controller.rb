class DatacolumnsController < ApplicationController
  before_filter :load_datacolumn_and_dataset
  before_filter :redirect_if_datagroup_unapproved, only: %i[update_invalid_values update_invalid_values_with_csv autofill_and_update_invalid_values]
  after_filter  :dataset_edit_message,
                only: %i[create_and_update_datagroup update_datagroup update_datatype update_metadata
                         update_invalid_values update_invalid_values_with_csv autofill_and_update_invalid_values]

  skip_before_filter :deny_access_to_all
  access_control do
    actions :approval_overview, :next_approval_step, :approve_datagroup, :approve_datatype, :approve_metadata,
            :approve_invalid_values, :update_datagroup, :create_and_update_datagroup, :update_datatype,
            :update_metadata, :update_invalid_values, :update_invalid_values_with_csv, :autofill_and_update_invalid_values, :update,
            :annotate, :update_annotation do
      allow :admin, :data_admin
      allow :owner, of: :dataset
    end
  end

  layout :choose_layout

  def update
    respond_to do |format|
      if @datacolumn.update_attributes(params.require(:datacolumn).permit(:columnheader, :definition))
        expire_type = @datacolumn.previous_changes.keys.include?('columnheader') ? :all : :xls
        ExportedFile.invalidate(@dataset.id, expire_type)

        format.html { redirect_to :back }
        format.json { render json: @datacolumn }
      else
        format.html { redirect_to :back, error: @datacolumn.errors.full_messages.to_sentence }
        format.json { render json: { error: @datacolumn.errors.full_messages.to_sentence } }
      end
    end
  end

  def approval_overview; end

  def next_approval_step
    unless @datacolumn.datagroup_approved?
      redirect_to(action: 'approve_datagroup') && return
    end
    unless @datacolumn.datatype_approved?
      redirect_to(action: 'approve_datatype') && return
    end
    if @datacolumn.has_invalid_values?
      redirect_to(action: 'approve_invalid_values') && return
    end
    unless @datacolumn.finished
      redirect_to(action: 'approve_metadata') && return
    end
    redirect_to action: 'approval_overview'
  end

  def approve_datagroup
    if @datacolumn.datagroup_id
      @data_groups_available = Datagroup.order(:title).where(['id <> ?', @datacolumn.datagroup_id])
    else # no datagroup assigned
      @data_groups_available = Datagroup.order(:title)
    end
  end

  def approve_datatype
    @datatype = Datatypehelper.find_by_name(@datacolumn.import_data_type)
  end

  def approve_invalid_values
    respond_to do |format|
      format.html do
        @invalid_values = @datacolumn.invalid_values.paginate(page: params[:page], per_page: 50)
        @count_of_all_invalid_values = @datacolumn.invalid_values.count
      end
      format.csv do
        csvdata = CSV.generate do |csv|
          csv << ['import value', 'category short', 'category long', 'category description']
          @datacolumn.invalid_values.each do |value|
            csv << [value.import_value, value.import_value]
          end
        end
        send_data csvdata, type: 'text/csv', filename: "invalid_values_of_#{@datacolumn.columnheader}.csv", disposition: 'attachment'
      end
    end
  end

  def approve_metadata
    @methods_short_list = Datagroup.order('title').collect { |m| [m.title, m.id] }
    @ppl = @datacolumn.users
  end

  def create_and_update_datagroup
    @datagroup = Datagroup.new(params.require(:new_datagroup).permit(:title, :description))

    if @datagroup.save
      @datacolumn.approve_datagroup(@datagroup)
      ExportedFile.invalidate(@dataset.id, :xls)
      flash[:notice] = 'Data group successfully saved.'
      next_approval_step
    else
      flash[:error] = @datagroup.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

  # This method is called whenever someone clicks on the 'Save Data Group' Button
  # in the Data Column approval process.
  def update_datagroup
    if params[:datagroup].nil?
      flash[:error] = 'You need to choose a datagroup.'
      redirect_to(:back) && return
    else
      @datagroup = Datagroup.find(params[:datagroup])
      @datacolumn.approve_datagroup(@datagroup)
      ExportedFile.invalidate(@dataset.id, :xls)
      flash[:notice] = 'Data group successfully saved.'
      next_approval_step
    end
  end

  # This method is called whenever someone clicks on the 'Save Data Type' Button
  # in the Data Column approval process.
  #
  # The datatype of this Data Column is saved and the respective Sheetcells are updated.
  def update_datatype
    unless params[:import_data_type]
      flash[:error] = 'Please select a datatype'
      redirect_to :back
    end

    begin
      @datacolumn.approve_datatype(params[:import_data_type], current_user)
      ExportedFile.invalidate(@dataset.id, :all)
      flash[:notice] = 'Successfully updated Datatype'
      next_approval_step
    rescue
      flash[:error] = "An error occured while updating the datatype: #{$ERROR_INFO}"
      redirect_to :back
    end
  end

  # The meta data of this Data Column is saved. The people submitted via form are assigned
  # to the Data Column or their assignation is revoked.
  def update_metadata
    unless @datacolumn.update_attributes(params.require(:datacolumn).permit(:definition))
      flash[:error] = @datacolumn.errors.to_a.first.capitalize
      redirect_to(:back) && return
    end
    expire_type = @datacolumn.previous_changes.keys.include?('columnheader') ? :all : :xls
    ExportedFile.invalidate(@dataset.id, expire_type)

    # Retrieve the new list of people from the form params.
    new_people = params[:people].blank? ? [] : User.find(params[:people])
    @datacolumn.users = new_people

    @datacolumn.dataset.refresh_paperproposal_authors
    if @datacolumn.final_check_for_valid_sheetcells
      flash[:notice] = 'Metadata and acknowledgements successfully saved.'
      next_approval_step
    else
      flash[:error] = 'There are still invalid values left'
      redirect_to approve_invalid_values_datacolumn_path @datacolumn
    end
  end

  # creates categories for all invalid values completed in the form and assigns the category to the sheetcell
  def update_invalid_values
    invalid_values = params.permit(invalid_values: [ :import_value, :short, :long, :description ]).require(:invalid_values)
    unless invalid_values.blank?
      invalid_values.each do |h|
        next if h['short'].blank?
        @datacolumn.update_invalid_value(h['import_value'], h['short'], h['long'], h['description'], @dataset)
      end
      @datacolumn.touch
    end
    ExportedFile.invalidate(@dataset.id, :all)
    flash[:notice] = 'The invalid values have been successfully approved'
    next_approval_step
  end

  def update_invalid_values_with_csv
    redirect_to(:back, error: 'No File given') && return unless params[:csvfile]
    f = params.require(:csvfile).path
    begin
      CSV.foreach(f, headers: true, skip_blanks: true) do |row|
        next if row['import value'].blank? || row['category short'].blank?
        @datacolumn.update_invalid_value(row['import value'], row['category short'], row['category long'], row['category description'], @dataset)
      end
      @datacolumn.touch
      ExportedFile.invalidate(@dataset.id, :all)
      flash[:notice] = 'The invalid values have been successfully approved'
      next_approval_step
    rescue => e
      flash[:error] = e.message
      redirect_to(:back) && return
    end
  end

  def autofill_and_update_invalid_values
    @datacolumn.batch_approve_invalid_values(current_user)
    ExportedFile.invalidate(@dataset.id, :all)
    @datacolumn.touch
    flash[:notice] = 'The invalid values have been successfully approved'
    next_approval_step
  end

  def annotate; end

  def update_annotation
    if params[:new_term].present?
      term = Vocab.where(['term iLike ?', params.require(:new_term).permit(:new_term)]).first || Vocab.create(term: params.require(:new_term))
    elsif params[:term_id].present?
      term = Vocab.find(params.require(:term_id).permit(:term_id))
    else
      term = nil
    end

    @datacolumn.update_attribute(:semantic_term, term)
    redirect_to :back, notice: 'Semantic tag was updated'
  end

  private

  def choose_layout
    if request.xhr?
      nil
    elsif [].include? action_name
      'application'
    else
      'approval'
    end
  end

  def load_datacolumn_and_dataset
    @datacolumn = Datacolumn.find(params[:id])
    @dataset = @datacolumn.dataset
  end

  def dataset_edit_message
    @dataset.log_edit('Datacolumns approved')
  end

  def redirect_if_datagroup_unapproved
    unless @datacolumn.datagroup_id
      flash[:error] = 'Please approve the datagroup before approving invalid values'
      redirect_to approve_datagroup_datacolumn_path(@datacolumn)
    end
  end
end
