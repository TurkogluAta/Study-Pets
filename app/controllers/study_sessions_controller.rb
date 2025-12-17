class StudySessionsController < ApplicationController
  before_action :set_study_session, only: %i[ show update destroy ]

  # GET /study_sessions
  def index
    # Only return current user's study sessions
    @study_sessions = @current_user.study_sessions

    render json: @study_sessions
  end

  # GET /study_sessions/1
  def show
    render json: @study_session
  end

  # POST /study_sessions
  def create
    @study_session = @current_user.study_sessions.new(study_session_params)

    if @study_session.save
      render json: @study_session, status: :created, location: @study_session
    else
      render json: @study_session.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /study_sessions/1
  def update
    if @study_session.update(study_session_params)
      # If session is completed, award XP and calculate streak
      if @study_session.completed?
        rewards = GamificationSystem.award_session_rewards(@study_session.user, @study_session)
        streak_info = GamificationSystem.calculate_streak(@study_session.user)

        # Save XP earned to the session for future display
        @study_session.update_column(:xp_earned, rewards[:xp])

        render json: {
          study_session: @study_session.as_json,
          rewards: rewards,
          streak: streak_info
        }
      else
        render json: @study_session
      end
    else
      render json: @study_session.errors, status: :unprocessable_content
    end
  end

  # DELETE /study_sessions/1
  def destroy
    @study_session.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_study_session
      @study_session = @current_user.study_sessions.find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Study session not found" }, status: :not_found
    end

    # Only allow a list of trusted parameters through.
    def study_session_params
      params.expect(study_session: [ :title, :start_time, :end_time, :duration, :focus_rating, :notes ])
    end
end
