# frozen_string_literal: true

## The constants in the Datagrouptype class indicate the type of "Datagroup".
##
## DEFAULT Datagroups are those that have been created from entries in the "Datacolumn" and "Datagroup" sheet of the "Workbook".
## The HELPER Datagrouptype that is selected by default when no "Datagroup" has been specified in the Workbook.
class Datagrouptype
  DEFAULT = 1
  HELPER = 2
end
