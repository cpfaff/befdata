# frozen_string_literal: true

require 'test_helper'

class PaperproposalTest < ActiveSupport::TestCase
  test 'any paperproposal can have one project linked' do
    paperproposal = paperproposals('paperproposals_001')
    assert paperproposal.authored_by_project
  end

  # test 'calculating authorship works' do
  # TODO: That is unreliable as the order in the strings can change
  # a regex match on the string might be better
    # paperproposal = Paperproposal.find(2)
    # author = User.find(6)
    # senior = User.find(4)
    # data_provider = User.find(5)
    # acknowledged = User.find(1)
    # foreign = User.find(2)

    # assert paperproposal.calc_authorship(author) == 'Author, Main aspect data provider, and Proponent'
    # assert paperproposal.calc_authorship(senior) == 'Proponent'
    # assert paperproposal.calc_authorship(data_provider) == 'Main aspect data provider'
    # assert paperproposal.calc_authorship(acknowledged) == 'Acknowledged'
    # assert paperproposal.calc_authorship(foreign) == ''
  # end

  test 'expired download rights are removed' do
    old_roles_count = Role.count
    Paperproposal.find(7).update_attribute(:expiry_date, Date.yesterday)
    Paperproposal.revoke_old_download_rights
    assert old_roles_count > Role.count
  end
end
