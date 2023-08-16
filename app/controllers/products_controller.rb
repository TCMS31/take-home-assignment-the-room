# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :ensure_logged_in, only: :show

  def index
    product_response = products_api.fetch_all

    if product_response.success?
      @products = products_api.all_products
    else
      flash[:notice] = product_response.errors
    end
  end

  def show
    product_response = show_products_api.fetch

    if product_response.success?
      @product = show_products_api.show_product
      @comments = Comment.where(product_id: params[:id])
    else
      flash[:alert] = product_response.errors
      redirect_to products_path
    end
  end

  private

  def products_api
    @products_api ||= DummyJson::Products.new
  end

  def show_products_api
    @show_products_api ||= DummyJson::Products.new(args: { id: params[:id] })
  end
end
