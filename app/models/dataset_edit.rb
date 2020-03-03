# frozen_string_literal: true

class DatasetEdit < ApplicationRecord
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

    if new_record?
      save
    else
      touch
    end
  end

  def notify(params)
    return unless params

    # collect
    downloaders = params.permit(:downloaders) ? dataset.downloaders : []
    proposers = params.permit(:proposers) ? dataset.proposers : []

    # normalize
    [downloaders, proposers].each do |a|
      a.to_a.reject! { |x| dataset.owners.include?(x) }
    end
    downloaders -= proposers # proposers are more important

    # send notification
    # Previously, calling a mailer method on a mailer class will result in the
    # corresponding instance method being executed directly. With the
    # introduction of Active Job and #deliver_later, this is no longer true. In
    # Rails 4.2, the invocation of the instance methods are deferred until
    # either deliver_now or deliver_later is called. For example:
    # deliver_now or deliver_later
    # TODO: Keep an eye on if that stuff is working otherwise migrate to
    # active job.
    proposers.each { |u| NotificationMailer.delay.dataset_edit(u, self, :proposer) }
    downloaders.each { |u| NotificationMailer.delay.dataset_edit(u, self, :downloader) }
  end
end
