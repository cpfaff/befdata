# frozen_string_literal: true

xml.instruct!
xml.datagroups do
  @datagroups.each do |dg|
    xml.datagroup(id: dg.id) do
      xml.id dg.id
      xml.title dg.title
      xml.description dg.description
      xml.columns_count dg.datacolumns_count
      xml.categories_count dg.categories_count
    end
  end
end
