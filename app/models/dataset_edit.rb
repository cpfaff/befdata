class DatasetEdit < ActiveRecord::Base
  belongs_to :dataset
  # attr_accessible :description, :submitted

  validates_presence_of :dataset, :description
  # validate :only_one_unsubmitted_per_dataset

  # def only_one_unsubmitted_per_dataset
  #  unsubmitted_edits = self.dataset.dataset_edits.where(:submitted => 'false')
  #  unless unsubmitted_edits.count == 0 || unsubmitted_edits.first == self
  #    errors.add(:submitted, 'only one unsubmitted edit per dataset allowed')
  #  end
  # end

  def add_line!(line)
    unless description =~ /- #{line}/
      self.description ||= ''
      self.description = self.description + "\r\n- #{line}"
    end

    unless new_record?
      touch
    else
      save
    end
  end

  def notify(params)
    return unless params

    # collect
    downloaders = params.permit(:downloaders) ? dataset.downloaders : []
    proposers = params.permit(:proposers) ? dataset.proposers : []

    # normalize
    [downloaders, proposers].each do |a|
      a.reject! { |x| dataset.owners.include?(x) }
    end
    downloaders -= proposers # proposers are more important

    # send notification
    proposers.each { |u| NotificationMailer.delay.dataset_edit(u, self, :proposer) }
    downloaders.each { |u| NotificationMailer.delay.dataset_edit(u, self, :downloader) }
  end
end
