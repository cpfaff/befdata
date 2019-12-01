# frozen_string_literal: true

desc 'Start delayed jobs'
task :start_delayed_jobs do
  system("#{Rails.root}/bin/delayed_job_production start")
end

desc 'Restart delayed jobs'
task :restart_delayed_jobs do
  system("#{Rails.root}/bin/delayed_job_production restart")
end
