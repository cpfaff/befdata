# frozen_string_literal: true

class ExportedSheetcell < ApplicationRecord
  self.primary_key = :id
  belongs_to :datacolumn
end
