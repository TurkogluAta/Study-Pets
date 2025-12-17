class ApplicationController < ActionController::API
  before_action :authenticate_user!
  before_action :apply_pending_decay, if: :current_user

  private

  def authenticate_user!
    header = request.headers["Authorization"]
    token = header.split(" ").last if header.present?

    begin
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")
      @current_user = User.find(decoded[0]["user_id"])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  # Apply energy decay lazily (once per day per user)
  def apply_pending_decay
    # Only apply once per day to avoid performance overhead
    return if current_user.last_checked_at&.to_date == Date.current

    GamificationSystem.apply_pending_decay(current_user)
  end
end
