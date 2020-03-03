# frozen_string_literal: true

module ProjectsHelper
  def formated_role_text(user, proj)
    roles = user.roles_for(proj).collect do |role|
      str = user.alumni ? 'Former ' : ''
      str += t('role.' + role.name)
    end
    roles.join(', ')
  end
end
