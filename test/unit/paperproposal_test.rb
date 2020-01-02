# frozen_string_literal: true

require 'test_helper'

class PaperproposalTest < ActiveSupport::TestCase
  test 'any paperproposal can have one project linked' do
    paperproposal = paperproposals('paperproposals_001')
    assert paperproposal.authored_by_project
  end

  test 'calculating the authorship for paperproposals' do
    paperproposal = Paperproposal.find(2)
    author = User.find(6)
    senior = User.find(4)
    data_provider = User.find(5)
    acknowledged = User.find(1)
    foreign = User.find(2)

    assert_match('Author', paperproposal.calc_authorship(author))
    assert_match('Main aspect data provider', paperproposal.calc_authorship(author))
    assert_match('Main aspect data provider', paperproposal.calc_authorship(author))
    assert_match('Proponent', paperproposal.calc_authorship(author))
    assert_match('Proponent', paperproposal.calc_authorship(senior))
    assert_match('Main aspect data provider', paperproposal.calc_authorship(data_provider))
    assert_match('Acknowledged', paperproposal.calc_authorship(acknowledged))
    assert_match('', paperproposal.calc_authorship(foreign))
  end

  test 'expired download rights are removed' do
    old_roles_count = Role.count
    Paperproposal.find(7).update_attribute(:expiry_date, Date.yesterday)
    Paperproposal.revoke_old_download_rights
    assert old_roles_count > Role.count
  end
end
