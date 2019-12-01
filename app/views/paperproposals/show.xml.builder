# frozen_string_literal: true

xml.instruct!
xml.paperproposal(id: @paperproposal.id) do
  xml.title @paperproposal.title
  xml.rationale @paperproposal.rationale
  xml.createdAt @paperproposal.created_at
  xml.status @paperproposal.board_state
  xml.project @paperproposal.authored_by_project, id: @paperproposal.project_id
  xml.proposer do
    xml.person(id: @paperproposal.author_id) do
      xml.name @paperproposal.author
      xml.email @paperproposal.author.email
    end
  end
  xml.proponents do
    @paperproposal.proponents.each do |u|
      xml.person(id: u.id) do
        xml.name u
        xml.email u.email
      end
    end
  end
  xml.datasets do
    @paperproposal.dataset_paperproposals.each do |dspp|
      dataset = dspp.dataset
      xml.dataset(id: dataset.id) do
        xml.title dataset.title
        xml.aspect dspp.aspect
        xml.authorizable dataset.can_download_by? current_user
        xml.owners do
          dataset.owners.each do |u|
            xml.person(id: u.id) do
              xml.name u
              xml.email u.email
            end
          end
        end
        xml.urls do
          xml.xls download_dataset_url(dataset, user_credentials: current_user.try(:single_access_token))
          xml.csv download_dataset_url(dataset, format: :csv, separate_category_columns: true, user_credentials: current_user.try(:single_access_token))
        end
      end
    end
  end
  xml.envisaged do
    xml.journal @paperproposal.envisaged_journal
    xml.date @paperproposal.envisaged_date
    xml.state @paperproposal.state
  end
end
