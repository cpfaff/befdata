# frozen_string_literal: true

class CartsController < ApplicationController
  skip_before_action :deny_access_to_all
  access_control do
    actions :show, :create_cart_context do
      allow logged_in
    end
    action :delete_cart_context do
      # TODO: this should be only allowed for the
      # owner of a cart or similar see #4670
      allow logged_in
    end
  end

  def show
    @cart = current_cart
  end

  def create_cart_context
    @dataset = Dataset.find(params.require(:dataset_id))
    @cart_dataset = CartDataset.new(cart: current_cart, dataset: @dataset)
    if @cart_dataset.save
      flash[:notice] = "Added #{@dataset.title} to cart."
    else
      flash[:error] = "#{@dataset.title} is already in cart."
    end
    redirect_back(fallback_location: current_cart_path)
  end

  def delete_cart_context
    @cart_dataset = CartDataset.find(params.require(:dataset_id))
    @cart_dataset.destroy
    redirect_back(fallback_location: root_url)
  end
end
