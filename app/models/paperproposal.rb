# frozen_string_literal: false

# This file contains the Paperproposal model definition. Paperproposals are used for organizing data exchange.

# Paperproposals assemble the Dataset instances (DatasetPaperproposal) )that are
# needed for a particular purpose, in most cases
# a scientific analysis. *Proponents* of the paperproposal are those users (User) that have submitted
# the paperproposal.
#
# Proponents submit proposals to the project board (see Role) for approval as well as hints and tips
# and then to the owners of datasets for the permission to use the data.
#
# Datasets can be of main or side aspect for the proposal. Dataset owners of main aspect datasets
# should be offered a co-authorship in the resulting paper.

class Paperproposal < ApplicationRecord
  belongs_to :author,
             class_name: 'User',
             foreign_key: 'author_id'

  belongs_to :authored_by_project,
             class_name: 'Project',
             foreign_key: :project_id

  # User roles in a paperproposal: proponents, main aspect dataset owner, side
  # aspect dataset owner, acknowledged. many-to-many association with User
  # model through author_paperproposal joint table.
  has_many :author_paperproposals,
           -> { includes [:user] },
           dependent: :destroy

  has_many :authors, class_name: 'User',
                     source: :user,
                     through: :author_paperproposals

  # with four conditional association.
  has_many :proponents,
           -> { where "kind = 'user'" },
           class_name: 'User',
           source: :user,
           through: :author_paperproposals

  has_many :main_aspect_dataset_owners,
           -> { where "kind = 'main'" },
           class_name: 'User',
           source: :user,
           through: :author_paperproposals

  has_many :side_aspect_dataset_owners,
           -> { where "kind = 'side'" },
           class_name: 'User',
           source: :user,
           through: :author_paperproposals

  has_many :acknowledgements_from_datasets,
           -> { where "kind = 'ack'" },
           class_name: 'User',
           source: :user,
           through: :author_paperproposals

  # User votes on a paperproposal. has_many association with
  # paperproposal_votes model. two conditional association to differentiate
  # project board vote and dataset request vote.(FIXME: dataset owner's vote?)
  has_many :paperproposal_votes,
           dependent: :destroy

  has_many :project_board_votes,
           -> { where project_board_vote: true },
           class_name: 'PaperproposalVote',
           source: :paperproposal_votes

  has_many :for_data_request_votes,
           -> { where project_board_vote: false },
           class_name: 'PaperproposalVote',
           source: :paperproposal_votes

  # habtm association with Dataset model.
  before_destroy :reset_download_rights # needs to be before association definition,see https://rails.lighthouseapp.com/projects/8994/tickets/4386
  has_many :dataset_paperproposals,
           dependent: :destroy
  has_many :datasets,
           through: :dataset_paperproposals

  # one-to-many association with freeformat model.
  has_many :freeformats,
           as: :freeformattable,
           dependent: :destroy

  validates_presence_of :title, :rationale, :author_id

  before_create :set_initial_title

  STATES = {
    # for sorting purposes
    'accepted' => 1,
    'in review' => 2,
    'manuscript avaible' => 3,
    'in prep' => 4,
    'deletion' => 5
  }.freeze

  KIND = { 'user' => 'Proponent',
           'main' => 'Main aspect data provider',
           'side' => 'Side aspect data provider',
           'ack' => 'Acknowledged' }.freeze

  # includes
  include PgSearch

  # search scope
  pg_search_scope :search, against: {
    title: 'A',
    initial_title: 'A',
    rationale: 'A',
    envisaged_journal: 'B'
  },
  using: {
    tsearch: {
      dictionary: 'english',
      prefix: true
    }
  }

  def set_initial_title
    self.initial_title = title
  end

  def beautiful_title
    str = "#{author.short_name}: #{created_at.year}, #{title}, "
    str = "#{authored_by_project.shortname}, " + str if authored_by_project.present?
    proponents_and_dataowners = authors_selection(:proponents_and_all_owners)
    unless proponents_and_dataowners.empty?
      str << '<i>Proponents and dataowners</i>: '
      str << proponents_and_dataowners.collect(&:full_name).sort.join(', ')
    end
    str << ", <i>Citation</i>: #{envisaged_journal}" if envisaged_journal.present?
    str
  end

  def <=>(other)
    # sort by state, then by year if published, then title
    x = STATES[state] <=> STATES[other.state]
    if state == 'accepted'
      x = (x != 0 ? x : envisaged_date.year <=> other.envisaged_date.year)
    end
    x = (x != 0 ? x : beautiful_title <=> other.beautiful_title)
    x = (x != 0 ? x : title.downcase <=> other.title.downcase)
    x
  end

  # TODO: Board states could be enumerables.
  def calc_board_state
    return 'can be send to project board' if board_state == 'prep' && includes_datasets?
    return 'in preparation, no data selected' if board_state == 'prep'
    return 'submitted to board, waiting for acceptance' if board_state == 'submit'
    return 'rejected by project board' if board_state == 're_prep'
    return 'project board approved, requesting data' if board_state == 'accept'
    return 'data request rejected' if board_state == 'data_rejected'
    return 'final' if board_state == 'final' && !expiry_date.blank?

    'download rights expired' if board_state == 'final' && expiry_date.blank?
  end

  def calc_authorship(user)
    authorship = []
    authorship << 'Author' if user.id == author_id
    authorship += author_paperproposals.where(user_id: user.id).collect { |r| KIND[r.kind] }
    authorship.uniq.to_sentence
  end

  def all_authors_ordered(focus = nil)
    categorized_authors = [[author], proponents]
    unless focus == :without_data
      categorized_authors << main_aspect_dataset_owners
      categorized_authors << side_aspect_dataset_owners
      categorized_authors << acknowledgements_from_datasets
    end
    ordered_authors = []
    categorized_authors.each do |cat|
      sorted_category = cat.sort_by(&:lastname)
      sorted_category.each do |user|
        ordered_authors << user unless ordered_authors.include?(user)
      end
    end
    ordered_authors
  end

  def authors_selection(specific_selection)
    result = case specific_selection
             when :author_and_proponents then [author] + proponents
             when :proponents_and_main then [author] + proponents + main_aspect_dataset_owners
             when :proponents_and_all_owners then [author] + proponents + main_aspect_dataset_owners + side_aspect_dataset_owners
             when :all_mentioned then [author] + proponents + main_aspect_dataset_owners + side_aspect_dataset_owners + acknowledgements_from_datasets
            end
    result.flatten.uniq
  end

  def proponents=(proponents_array)
    author_paperproposals.where(kind: 'user').destroy_all
    author_paperproposals << proponents_array.map { |person| AuthorPaperproposal.new(user: person, kind: 'user') }
  end

  def calculate_data_providers
    all_proponents = { main: [], side: [], ack: [] }
    # collect relevant users
    dataset_paperproposals.includes(:dataset).each do |ds_pp|
      dataset = ds_pp.dataset
      all_proponents[ds_pp.aspect.to_sym] << dataset.owners
      all_proponents[:ack] << dataset.datacolumns.map(&:users)
    end
    all_proponents
  end

  def update_datasets_providers
    all_proponents = calculate_data_providers
    # clear out the old ones
    author_paperproposals.where(kind: %w[main side ack]).delete_all

    # reassign
    new_author_paperproposals = []
    all_proponents.each do |aspect, user_array|
      user_array.flatten!
      user_array.uniq!
      new_author_paperproposals <<
        user_array.map { |u| AuthorPaperproposal.new(user: u, paperproposal: self, kind: aspect.to_s) }
    end
    new_author_paperproposals.flatten!
    author_paperproposals << new_author_paperproposals
    save
  end

  def data_providers
    main_aspect_dataset_owners | side_aspect_dataset_owners
  end

  def non_free_data_providers
    non_free_data_owner_voters = datasets.collect do |dt|
      dt.owners unless dt.free_for?(author) || author.has_role?(:owner, dt)
    end
    non_free_data_owner_voters.flatten.uniq
  end

  def auto_voters
    data_providers - non_free_data_providers
  end

  def project_board_voters
    User.all_project_boards
  end

  def includes_datasets?
    !datasets.empty?
  end

  def all_votes_accepted?
    paperproposal_votes.all?(&:accepted?)
  end

  def has_been_rejected?
    paperproposal_votes.any?(&:rejected?)
  end

  def current_votes
    case board_state
    when 're_prep', 'submit'
      { type: :project_board, votes: project_board_votes }
    when 'accept', 'data_rejected'
      { type: :data_requests, votes: for_data_request_votes }
    else
      { type: :none, votes: [] }
    end
  end

  # datasets_array in form of [{id: 6, aspect: 'main'}, {id: 7, aspect: 'side'}]
  def update_datasets(datasets_array = [])
    old_datasets = datasets.to_a

    if board_state == 'final'
      self.board_state = 'accept'
      download_rights_message = reset_download_rights
    end

    if datasets_array[:datasets].present?
      self.dataset_paperproposals = datasets_array[:datasets].collect do |da|
        DatasetPaperproposal.new(dataset_id: da[:id], aspect: da[:aspect], paperproposal_id: id)
      end
    else
      datasets.map(&:delete)
    end

    reload

    update_datasets_providers if datasets_array[:datasets].present?

    if %w[prep re_prep submit].include?(board_state)
      set_lock_status
      save
    else
      if datasets_array[:datasets].present?
        calculate_votes old_datasets
        finalize_votes_and_lock
      end
    end
    download_rights_message || ''
  end

  def calculate_votes(old_datasets_array = [])
    return if %w[prep re_prep submit].include? board_state # there are no data votes right now

    old_data_voters = for_data_request_votes.collect(&:user)
    new_data_voters = datasets.collect(&:owners).flatten.uniq
    removed_voters = old_data_voters - new_data_voters
    added_voters = new_data_voters - old_data_voters

    all_referred_datasets = (old_datasets_array + datasets).uniq
    unchanged_datasets = old_datasets_array & datasets
    changed_datasets = all_referred_datasets - unchanged_datasets
    changed_datasets_owners = changed_datasets.collect(&:owners).flatten.uniq

    # add, reset and delete votes
    changed_datasets_owners.each do |u|
      if removed_voters.include? u
        for_data_request_votes.where(user_id: u.id).first.destroy
      elsif added_voters.include? u
        paperproposal_votes << PaperproposalVote.new(user: u, project_board_vote: false)
      else
        vote = for_data_request_votes.where(user_id: u.id).first
        vote.update_attribute(:vote, 'none') if vote.vote == 'accept'
      end
    end
  end

  def user_changes_state
    if %w[prep re_prep].include?(board_state)
      submit_to_board
    elsif board_state == 'data_rejected'
      re_request_data
    elsif board_state == 'final'
      hard_reset
    else
      'Paperproposal state could not be changed'
    end
  end

  def check_votes
    reload
    if all_votes_accepted?
      all_votes_accepted
    elsif has_been_rejected?
      reject_data_request
    end
  end

  def hard_reset
    result = ''
    result = reset_download_rights if board_state == 'final'
    result << "#{paperproposal_votes.count} votes deleted."
    paperproposal_votes.delete_all

    self.board_state = 'prep'
    finalize_votes_and_lock
    result
  end

  def safe_delete(user)
    if board_state == 'prep' || user.has_role?(:admin) || user.has_role?(:data_admin)
      destroy
      'Paperproposal was destroyed'
    else
      update_attribute :state, 'deletion'
      'Paperproposal flagged for deletion by an admin'
    end
  end

  def reset_download_rights
    return 'paperproposal is not final' unless board_state == 'final'

    update_attribute(:expiry_date, '')
    other_final_paperproposals = Paperproposal.where("board_state = 'final' AND author_id = ? AND id != ?", author_id, id)
    other_downloadable_datasets = other_final_paperproposals.collect(&:datasets).flatten.uniq
    unique_downloadable_datasets = (datasets - other_downloadable_datasets)

    reverted_roles = []
    unique_downloadable_datasets.each do |ds|
      author.has_no_role! :proposer, ds
      reverted_roles << ds.id
    end
    "Reverted proposer roles for datasets #{reverted_roles}. "
  end

  def self.revoke_old_download_rights
    expired = Paperproposal.where('expiry_date < ?', Date.today.to_s)
    expired.each do |pp|
      puts Time.now.to_s + ' Paperproposal ' + pp.id.to_s + ': ' + pp.reset_download_rights
    end
  end

  private

  def submit_to_board
    pre_state = board_state
    self.board_state = 'submit'

    if pre_state == 're_prep'
      project_board_votes.each { |vote| vote.update_attribute(:vote, 'none') }
    else
      project_board_voters.each do |user|
        paperproposal_votes << PaperproposalVote.new(user: user, project_board_vote: true)
      end
    end

    finalize_votes_and_lock
    'Submitted to project board'
  end

  def re_request_data
    self.board_state = 'accept'

    for_data_request_votes.where(vote: 'reject').each do |v|
      v.update_attribute :vote, 'none'
    end

    finalize_votes_and_lock
    'Requesting data again'
  end

  def all_votes_accepted
    case board_state
    when 'submit'
      if includes_datasets?
        make_data_request_accepted
      else
        make_data_request_final
      end
    when 'accept'
      make_data_request_final
    end
  end

  def reject_data_request
    self.board_state = case board_state
                       when 'submit' then 're_prep'
                       when 'accept' then 'data_rejected'
                       else board_state
                       end
    # Previously, calling a mailer method on a mailer class will result in the
    # corresponding instance method being executed directly. With the
    # introduction of Active Job and #deliver_later, this is no longer true. In
    # Rails 4.2, the invocation of the instance methods are deferred until
    # either deliver_now or deliver_later is called. For example:
    # deliver_now or deliver_later
    # TODO: Keep an eye on if that stuff is working otherwise migrate to
    # active job.
    # NotificationMailer.data_request_rejected(self).deliver_now
    NotificationMailer.delay.data_request_rejected(self)
    set_lock_status
    save
  end

  def make_data_request_accepted
    self.board_state = 'accept'
    calculate_votes
    finalize_votes_and_lock
  end

  def make_data_request_final
    self.expiry_date = Date.today + 2.years
    self.board_state = 'final'
    datasets.each do |ds|
      ds.accepts_role! :proposer, author
    end
    # TODO: this one is not delivered compared to others. I have no idea why.
    NotificationMailer.delay.data_request_accepted(self)
    set_lock_status
    save
  end

  def auto_vote
    case board_state
    when 'accept'
      # accept data request votes
      for_data_request_votes.where('user_id IN (?)', auto_voters).each do |v|
        next if v.vote == 'accept'

        v.update_attribute(:vote, 'accept')
        # Previously, calling a mailer method on a mailer class will result in the
        # corresponding instance method being executed directly. With the
        # introduction of Active Job and #deliver_later, this is no longer true. In
        # Rails 4.2, the invocation of the instance methods are deferred until
        # either deliver_now or deliver_later is called. For example:
        # deliver_now or deliver_later
        # TODO: Keep an eye on if that stuff is working otherwise migrate to
        # active job.
        NotificationMailer.delay.auto_accept_for_free_datasets(v.user, self) unless v.user == author
      end
    when 'submit'
      project_board_votes.where(user_id: author).each do |v|
        v.update_attribute(:vote, 'accept') unless v.vote == 'accept'
      end
    end
  end

  def set_lock_status
    self.lock = %w[prep re_prep data_rejected final].include?(board_state) ? false : true
  end

  def finalize_votes_and_lock
    set_lock_status
    save
    auto_vote
    check_votes
  end
end
