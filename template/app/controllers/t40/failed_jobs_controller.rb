class T40::FailedJobsController < ApplicationController
  layout "public"
  before_action :require_account!
  require_role :admin

  def index
    authorize! :can_view_job_operations?
    @failures = T40::JobOperations.for_account(Current.account)
    @backlog_age = T40::JobOperations.backlog_age
    render T40::Ui::FailedJobs.new(failures: @failures, backlog_age: @backlog_age)
  end

  def replay
    authorize! :can_replay_jobs?
    require_step_up!
    T40::JobOperations.replay!(id: params[:id], account: Current.account)
    redirect_to failed_jobs_path, notice: "The job was queued for one bounded replay."
  end
end
