class DashboardController < ApplicationController
  	include App
  	def index
  		counter_users = User.where(:created_at.gte => DateTime.now.beginning_of_year, :created_at.lte => DateTime.now.end_of_year).group_by {|d| d.created_at.to_date.month }
        counter_products = Product.where(:created_at.gte => DateTime.now.beginning_of_year, :created_at.lte => DateTime.now.end_of_year).group_by {|d| d.created_at.to_date.month }
        @users_data = Array.new
        @products_data = Array.new
        counter_users.keys.each do |data|
            @users_data << [data,counter_users[data].count]
        end
        counter_products.keys.each do |data|
            @products_data << [data,counter_products[data].count]
        end
  	end
end
