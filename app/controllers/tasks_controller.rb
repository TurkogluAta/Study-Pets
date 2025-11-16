class TasksController < ApplicationController
  before_action :set_task, only: %i[ show update destroy ]

  # GET /tasks
  def index
    # Only return current user's tasks
    @tasks = @current_user.tasks

    render json: @tasks
  end

  # GET /tasks/1
  def show
    render json: @task
  end

  # POST /tasks
  def create
    @task = @current_user.tasks.new(task_params)

    if @task.save
      render json: @task, status: :created, location: @task
    else
      render json: @task.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /tasks/1
  def update
    if @task.update(task_params)
      render json: @task
    else
      render json: @task.errors, status: :unprocessable_content
    end
  end

  # DELETE /tasks/1
  def destroy
    @task.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = @current_user.tasks.find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Task not found" }, status: :not_found
    end

    # Only allow a list of trusted parameters through.
    def task_params
      params.expect(task: [ :title, :due_date, :status, :priority, :description ])
    end
end
