# frozen_string_literal: true

class UserSession < Authlogic::Session::Base
  single_access_allowed_request_types :any

  def to_key
    new_record? ? nil : [send(self.class.primary_key)]
  end
end
