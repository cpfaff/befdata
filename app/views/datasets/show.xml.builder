# frozen_string_literal: true

xml.instruct!
xml.dataset(id: @dataset.id, version: 1) do
  if @dataset.visible_for_public || current_user
    xml.title @dataset.title
    xml.abstract @dataset.abstract
    xml.taxonomicextent @dataset.taxonomicextent
    xml.spatialextent @dataset.spatialextent
    xml.temporalextent do
      xml.begin @dataset.datemin
      xml.end @dataset.datemax
    end
    xml.design @dataset.design
    xml.uploaded_at @dataset.created_at
    xml.authors do
      @contacts.each do |u|
        xml.person(id: u.id) do
          xml.name u.full_name
          xml.email u.email
        end
      end
    end
    xml.projects do
      @projects.each do |p|
        xml.name p.shortname, id: p.id
      end
    end
    xml.accessRight @dataset.access_rights, code: @dataset.access_code
    xml.columns do
      @datacolumns.each do |dc|
        xml.column do
          xml.header dc.columnheader
          xml.definition dc.definition
          xml.unit dc.unit
          xml.type dc.import_data_type
          xml.instrumentation dc.instrumentation
          xml.reference dc.informationsource
          xml.datagroup(id: dc.datagroup_id) do
            xml.title dc.datagroup.title
            xml.description dc.datagroup.description
          end
          xml.keywordSet do
            dc.tags.each do |t|
              xml.keyword t.name, id: t.id
            end
          end
          xml.semanticTagging dc.semantic_term.try(:term)
        end
        unless params[:separate_category_columns].to_s.casecmp('true').zero? && dc.split_me?
          next
        end

        xml.column do
          xml.header dc.columnheader + '_Categories'
          xml.definition dc.definition
          xml.unit dc.unit
          xml.type 'category'
          xml.instrumentation dc.instrumentation
          xml.reference dc.informationsource
          xml.datagroup(id: dc.datagroup_id) do
            xml.title dc.datagroup.title
            xml.description dc.datagroup.description
          end
          xml.keywordSet do
            dc.tags.each do |t|
              xml.keyword t.name, id: t.id
            end
          end
          xml.semanticTagging dc.semantic_term.try(:term)
        end
      end
    end
    xml.files do
      xml.exported_file do
        if @dataset.has_research_data?
          xml.file do
            xml.type 'xls'
            xml.status @dataset.exported_excel.status
            xml.url download_dataset_url(@dataset, user_credentials: current_user.try(:single_access_token))
          end
          xml.file do
            xml.type 'csv'
            xml.status @dataset.exported_scc_csv.status
            xml.url download_dataset_url(@dataset, format: :csv, separate_category_columns: true, user_credentials: current_user.try(:single_access_token))
          end
        end
      end
      xml.attachments do
        @freeformats.each do |f|
          xml.file do
            xml.id f.id
            xml.type f.file_content_type
            xml.fileName f.file_file_name
            xml.description f.description
            xml.url download_freeformat_url(f, user_credentials: current_user.try(:single_access_token))
          end
        end
      end
    end
    xml.importstatus @dataset.import_status if @dataset.has_research_data?
    xml.keywordSet do
      @dataset.tags.each do |t|
        xml.keyword t.name, id: t.id
      end
    end
  else
    xml.error 'The meta data is not visibile for unlogged-in users'
  end
end
