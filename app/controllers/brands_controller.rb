class BrandsController < ApplicationController
    include App

    before_action :set_brand, only: [:show, :edit, :update, :destroy]

    def index
        respond_to do |format|
            format.html
            format.json { render json: BrandsDatatable.new(view_context) }
        end
    end

    def show
    end

    def new
        @brand = Brand.new
    end

    def edit
    end

    def create
        @brand = Brand.new(brand_params)
        respond_to do |format|
            if @brand.save
                format.html { redirect_to @brand, notice: 'Brand was successfully created.' }
                format.json { render :show, status: :created, location: @brand }
            else
                format.html { render :new }
                format.json { render json: @brand.errors, status: :unprocessable_entity }
            end
        end
    end

    def update
        respond_to do |format|
            if @brand.update(brand_params)
                format.html { redirect_to @brand, notice: 'Brand was successfully updated.' }
                format.json { render :show, status: :ok, location: @brand }
            else
                format.html { render :edit }
                format.json { render json: @brand.errors, status: :unprocessable_entity }
            end
        end
    end

    def destroy
        @brand.destroy
        respond_to do |format|
            format.html { redirect_to brands_url, notice: 'Brand was successfully destroyed.' }
            format.json { head :no_content }
        end
    end

    private
    def set_brand
        @brand = Brand.find(params[:id])
    end

    def brand_params
        params.require(:brand).permit(:category_id, :name, item_models_attributes: [:id, :name, :is_enabled, :_destroy])
    end
end
