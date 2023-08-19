# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :require_login

  def index
    result = ProductCatalog.list

    if result.success?
      @products = result.products
    else
      @products = []
      flash.now[:alert] = result.error
    end
  end

  def show
    result = ProductCatalog.find(params[:id])

    unless result.success?
      redirect_to products_path, alert: result.error
      return
    end

    @product = result.product
    @comments = Comment.for_product(@product.id)
    @comment = current_user.comments.new(product_id: @product.id)
  end
end
