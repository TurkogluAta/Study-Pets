class ApplicationController < ActionController::API
  before_action :authenticate_user!

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
end
