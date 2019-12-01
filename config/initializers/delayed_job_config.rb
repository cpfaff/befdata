# frozen_string_literal: true

Delayed::Worker.max_attempts = 1
Delayed::Worker.delay_jobs = !Rails.env.test?
