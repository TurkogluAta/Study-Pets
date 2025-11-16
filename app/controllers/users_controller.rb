class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :register, :login ]

  # POST /register
  def register
    @user = User.new(user_params)

    if @user.save
      token = generate_token(@user)
      render json: {
        user: @user,
        token: token
      }, status: :created
    else
      render json: { errors: @user.errors }, status: :unprocessable_content
    end
  end

  # POST /login
  def login
    @user = User.find_by(email: params[:email])

    if @user&.authenticate(params[:password])
      token = generate_token(@user)
      render json: {
        user: @user,
        token: token
      }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  # GET /profile
  def profile
    render json: @current_user
  end

  # PATCH/PUT /profile
  def update_profile
    if @current_user.update(user_params)
      render json: @current_user
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /profile
  def delete_account
    @current_user.destroy
    head :no_content
  end

  private
    # Only allow a list of trusted parameters through.
    def user_params
      params.expect(user: [ :username, :email, :password, :password_confirmation, :name, :pet_name, :pet_type ])
    end

    def generate_token(user)
      JWT.encode(
        {
          user_id: user.id,
          exp: 24.hours.from_now.to_i
        },
        Rails.application.secret_key_base
      )
    end
end
