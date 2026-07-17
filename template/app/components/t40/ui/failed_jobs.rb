class T40::Ui::FailedJobs < T40::Ui::Base
  def initialize(failures:, backlog_age:)
    @failures = failures
    @backlog_age = backlog_age
  end

  def view_template
    flow(title: "Failed jobs", id: "failed-jobs-title") do
      p { "Oldest ready work: #{distance_of_time_in_words(@backlog_age)}." }
      if @failures.empty?
        p { "No failed jobs for this account." }
      else
        ul do
          @failures.each do |failure|
            li do
              strong { failure.job_class }
              plain " — #{failure.error} "
              button_to("Replay once", replay_failed_job_path(failure.id), method: :post)
            end
          end
        end
      end
    end
  end
end
