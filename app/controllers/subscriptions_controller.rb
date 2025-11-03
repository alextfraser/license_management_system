class SubscriptionsController < ApplicationController
  before_action :set_account

  def index
    @subscriptions = @account.subscriptions.includes(:product)
  end

  def new
    @subscription = @account.subscriptions.build(
      issued_at: Date.today,
      expires_at: 1.year.from_now
    )
    @products = Product.all
  end

  def create
    @subscription = @account.subscriptions.build(subscription_params)

    if @subscription.save
      redirect_to account_subscriptions_path(@account), notice: "Subscription was successfully created."
    else
      @products = Product.all
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def subscription_params
    params.require(:subscription).permit(:product_id, :number_of_licenses, :issued_at, :expires_at)
  end
end
