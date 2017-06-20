class Api::Modelv1

	def decrypt_password(password)
		key = "49f9ceb472a7c3d24bb3fd38f6e1647d13c01d2e8ed03a72230c4641dabff0789f89a4cae83823378277138579d945a4733c24903e90201f8c1059947338e2b5"
        crypt = ActiveSupport::MessageEncryptor.new(key)
        return crypt.decrypt_and_verify(password)
	end

	def get_countries(search_params)
		searched_countries = Country.all
		return {:status => searched_countries.count > 0 ? 1 : 0, :items => searched_countries.map { |object| object.to_api}}
	end

	def get_states(search_params)
		searched_states = State.any_of({:name => /^#{search_params[:query]}/i}).and(:country_id => search_params[:country_id])
		return {:status => searched_states.count > 0 ? 1 : 0, :items => searched_states.map { |object| object.to_api}}
	end

	def get_groups(apiuser, params)
		return {:status => 1, :items => Group.order_by(:created_at => 'desc').where(:admin_id => params[:admin_id]).map {|object| object.to_api(apiuser)}}
	end

	def get_chat_list(apiuser, params, device_width)
		products = params["item_type"] == "sold" ? apiuser.products.reject{|product| product.sold_to.blank?} : Product.where(:sold_to => apiuser)
		return {:status => 1, :chat_users => products.map{|u| u.to_chat(device_width, params["item_type"])}}
	end

	def get_cities(search_params)
		searched_cities = City.any_of({:name => /^#{search_params[:query]}/i}).and(:state_id => search_params[:state_id])
		return {:status => searched_cities.count > 0 ? 1 : 0, :items => searched_cities.map { |object| object.to_api}}
	end

	def check_login_by_facebook(login_params)
		if User.where(:fb_id => login_params[:fb_id], :email_address => login_params[:email_address]).any?
			user = User.find_by(:fb_id => login_params[:fb_id], :email_address => login_params[:email_address])
			return {:status => 1, :message => "Email and id combination is correct", :user_data => user.to_api}
		else
			if User.where(:email_address => login_params[:email_address]).any?
				return {:status => 0, :message => 'Email address already exists'}
			else
				user = User.create(:email_address => login_params[:email_address], :first_name => login_params[:first_name], :last_name => login_params[:last_name], :password => login_params[:fb_id].blank? ? "" : login_params[:fb_id], :longitude => login_params[:longitude].blank? ? 0.0 : login_params[:longitude], :latitude => login_params[:latitude].blank? ? 0.0 : login_params[:latitude], :fb_id => login_params[:fb_id].blank? ? "" : login_params[:fb_id])
				if user.errors.any?
					return {:status => 0, :message => user.errors.messages.values.first.first}
				else
					return {:status => 1, :message => "Email and id combination is correct", :user_data => user.to_api}
				end
			end
		end
	end

	def check_login(login_params)
		if User.where(:email_address => login_params[:email_address]).any?	
			user = User.find_by(:email_address => login_params[:email_address])
			if decrypt_password(user.encrypted_password) == login_params[:password]
				if user.is_active == false
					return {:status => 0, :message => "Please confirm your account from the email sent to you before login", :user_data => user.to_api}
				else
					return {:status => 1, :message => "Email and password combination is correct", :user_data => user.to_api}
				end
			else
				return {:status => 0, :message => "Email and password combination is incorrect"}
			end
		else
			return {:status => 0, :message => "User with email do not exists"}
		end
	end

	def report_product(apiuser, params)
		product = Product.find(params[:product_id])
		if product.blank?
			return {:status => 0, :message => "Product do not exists"}
		else
			product.product_reports.create(:user => apiuser, :report_text => params[:report_text])
			return {:status => 1, :message => "Product reported to admin"}
		end
	end

	def buy_product(apiuser, params)
		product = Product.find(params[:product_id])
		if product.blank?
			return {:status => 0, :message => "Product does not exists"}
		else
			if product.sold_to.blank?
				product.update_attributes(:sold_to => apiuser)
				return {:status => 1, :message => "Product sold"}
			else
				return {:status => 0, :message => "Product is already sold"}
			end
		end
	end

	def create_account(account_params)
		user = User.create(:email_address => account_params[:email_address], :first_name => account_params[:first_name], :last_name => account_params[:last_name], :password => account_params[:password].blank? ? "" : account_params[:password], :longitude => account_params[:longitude].blank? ? 0.0 : account_params[:longitude], :latitude => account_params[:latitude].blank? ? 0.0 : account_params[:latitude], :fb_id => account_params[:fb_id].blank? ? "" : account_params[:fb_id])
		if user.errors.any?
			return {:status => 0, :message => user.errors.messages.values.first.first}
		else
			return {:status => 1, :api_key => user.api_key}
		end
	end

	def upload_avatar(user, user_params)
		user = User.find(user.id)
		if user
			if user_params.has_key?(:is_android)
				user.avatar = parse_image_data(user_params[:avatar_upload]) if user_params[:avatar_upload]
			else
				user.avatar = user_params[:avatar_upload]
			end
			user.save
			return {:status => 1, :avatar => "#{user.avatar.url}"}
		else
			return {:status => 0}
		end
	end

	def get_group_requests(apiuser,params)
		group = Group.find(params[:group_id])
		if group.blank?
			return {:status => 0, :message => "Group not found"}
		else
			requests = group.group_requests
			data = Array.new
			requests.each do |request_data|
				user = User.find(request_data.user_id.to_s)
				if !user.blank?
					data << {:user_id => user.id.to_s, :request_id => request_data.id.to_s, :full_name => user.full_name, :avatar => user.avatar.blank? ? "" : "#{user.avatar.url}"}
				end
			end
			return {:status => 1, :request_data => data}
		end
	end

	def accept_reject_group_request(apiuser,params)
		request = GroupRequest.find(params[:request_id])
		if request.blank?
			return {:status => 0, :message => "Request not found"}
		else
			if params[:accept].to_i == 1
				user = User.find(request.user_id.to_s)
				if user.blank?
					request.destroy
					notification_string = user.language_selected == 0 ? "#{group.admin.full_name} has rejected your request to join #{group.group_name}" : "#{group.admin.full_name} har afvist din anmodning om medlemskab #{group.group_name}"
	            	data_one = {:action => "group_rejected", :item_id => ""}
	            	PushJob.new.send_notification(user, notification_string, data_one)
	            	PushJob.new.send_android_notification(user, notification_string, data_one)
					return {:status => 0, :message => "User not found"}
				else
					group = Group.find(request.group_id.to_s)
					user.follow(group)
					request.destroy
					notification_string = user.language_selected == 0 ? "#{group.admin.full_name} has accepted your request to join #{group.group_name}" : "#{group.admin.full_name} har accepteret din anmodning om medlemskab #{group.group_name}"
	            	data_one = {:action => "group_accepted", :item_id => ""}
	            	PushJob.new.send_notification(user, notification_string, data_one)
	            	PushJob.new.send_android_notification(user, notification_string, data_one)
					return {:status => 1, :message => "Request accepted"}
				end
			else
				request.destroy
				return {:status => 1, :message => "Request rejected"}
			end
		end
    end

	def add_remove_saved_shapp(user, params)
		product = Product.find(params[:product_id])
		if product.blank?
			return {:status => 0, :message => "Product does not exists"}
		else
			if params[:add_remove].to_i == 1
				if user.saved_shapps.include?(product)
					return {:status => 0, :message => "Already added to saved shapps"}
				else
					user.saved_shapps.create(:product => product)
					return {:status => 1, :message => "Added to saved shapps"}
				end
			else
				if user.saved_shapps.include?(product)
					user.saved_shapps.delete(product)
					return {:status => 1, :message => "Removed from saved shapps"}
				else
					return {:status => 0, :message => "Nothing to remove from saved shapps"}
				end
			end
		end
	end

	def add_bid_to_product(user, params)
		product = Product.find(params[:product_id])
		if product.blank?
			return {:status => 0, :message => "Product does not exists"}
		else
			if user.bids.where(:product_id => product.id, :bid_amount => params[:bid_amount]).count > 0
				return {:status => 0, :message => "Already added to my bids"}
			else
				user.bids.create(:product => product, :bid_amount => params[:bid_amount])
				return {:status => 1, :message => "Added to to my bids"}
			end
		end
	end

	def reject_product(user, params)
		product = Product.find(params[:product_id])
		if product.blank?
			return {:status => 0, :message => "Product does not exists"}
		else
			if user.rejected_products.include?(product)
				return {:status => 1, :message => "Product is already rejected"}
			else
				user.rejected_products.create(:product => product)
				return {:status => 0, :message => "Product Rejected"}
			end
		end
	end

	def get_my_products(apiuser, params, device_width)
		user = User.find(apiuser.id)
		if !params[:user_id].blank?
			user = User.find(params[:user_id])
		end

		if params[:product_type] == "saved_shapps"
			return {:status => 1, :products => user.saved_shapps.where(:product_id.nin => [nil, '']).order_by(:created_at => 'desc').reject{|s| s.product.blank?}.reject{|s| (!s.product.sold_to_id.blank? || s.product.bid_closed?)}.map{|saved_shapp| saved_shapp.product.to_discover(user, device_width)}}
		elsif params[:product_type] == "my_bids"
			return {:status => 1, :products => user.bids.order_by(:created_at => 'desc').map(&:product_id).uniq.map{|product_id| Product.find(product_id).to_discover(user, device_width)}}
		elsif params[:product_type] == "my_sales"
			return {:status => 1, :products => user.products.order_by(:created_at => 'desc').map{|product| product.to_discover(user, device_width)}}
		elsif params[:product_type] == "my_products"
			return {:status => 1, :products => user.products.order_by(:created_at => 'desc').where(:sold_to.exists => false).map{|product| product.to_discover(user, device_width)}}
		elsif params[:product_type] == "sold_products"
			return {:status => 1, :products => user.products.order_by(:created_at => 'desc').where(:sold_to.ne => "", :sold_to.exists => true).map{|product| product.to_discover(user, device_width)}}
		end
	end

	def get_product_bids(user, params)
		product = Product.find(params[:product_id])
		if product && product.user == user
			return {:status => 1, :bids => product.bids_to_api }
		else
			return {:status => 0}
		end
	end

	def get_messages(user, params)
		messages = Message.order_by(:created_at => 'asc').where(:product_id => params[:product_id]).reject{|m| m.message_text.blank?}
		return {:status => 1, :messages => messages.map{|m| m.to_api}}
	end

	def get_product(apiuser, params, device_width)
		product = Product.find(params[:product_id])
		if product
			return {:status => 1, :product => product.to_discover(apiuser, device_width)}
		else
			return {:status => 0}
		end
	end

	def get_user_data(user)
		if user
			return {:status => 1, :user_data => user.to_api, :message => "User found"}
		else
			return {:status => 0, :message => "System cannot find your account. Please contact administrator for support"}
		end
	end

	def get_qualities
		qualities = Quality.all
		if qualities.count > 0
			return {:status => 1, :items => qualities.map{|quality| quality.to_api} }
		else
			return {:status => 0}
		end
	end

	def get_categories
		categories = Category.all
		if categories.count > 0
			return {:status => 1, :items => categories.map{|category| category.to_api} }
		else
			return {:status => 0}
		end
	end

	def get_brands(search_params)
		brands = Brand.any_of({:name => /^#{search_params[:query]}/i}).and(:category_id => search_params[:category_id])
		if brands.count > 0
			return {:status => 1, :items => brands.map{|brand| brand.to_api} }
		else
			return {:status => 0}
		end
	end

	def search_groups(apiuser)
		groups = Group.all.reject{|g| g.followers.map(&:f_id).include?(apiuser.id.to_s) == false}
		if groups.count > 0
			return {:status => 1, :items => groups.map{|group| group.to_search} }
		else
			return {:status => 0}
		end
	end

	def get_models(search_params)
		models = ItemModel.any_of({:name => /^#{search_params[:query]}/i}).and(:brand_id => search_params[:brand_id])
		if models.count > 0
			return {:status => 1, :items => models.map{|model| model.to_api} }
		else
			return {:status => 0}
		end
	end

	def update_profile(user, user_params)
		user = User.find(user.id)
		if user
			if user_params.has_key?(:first_name)
				if user_params[:first_name].blank?
					return {:status => 0, :message => "First name is required"}
				else
					user.update_attributes(:first_name => user_params[:first_name])
					return {:status => 1}
				end
			end
			if user_params.has_key?(:push_switch)
				user.update_attributes(:push_notification => user_params[:push_switch].to_i == 1 ? true : false)
				return {:status => 1}
			end
			if user_params.has_key?(:email_switch)
				user.update_attributes(:email_notification => user_params[:email_switch].to_i == 1 ? true : false)
				return {:status => 1}
			end
			if user_params.has_key?(:refresh_switch)
				user.update_attributes(:auto_refresh => user_params[:refresh_switch].to_i == 1 ? true : false)
				return {:status => 1}
			end
			if user_params.has_key?(:last_name)
				if user_params[:last_name].blank?
					return {:status => 0, :message => "Last name is required"}
				else
					user.update_attributes(:last_name => user_params[:last_name])
					return {:status => 1}
				end
			end
			if user_params.has_key?(:phone_number)
				if user_params[:phone_number].blank?
					return {:status => 0}
				else
					user.update_attributes(:phone_number => user_params[:phone_number])
					return {:status => 1}
				end
			end
			if user_params.has_key?(:email_address)
				if user_params[:email_address].blank?
					return {:status => 0, :message => "Email address is required"}
				else
					user.update_attributes(:email_address => user_params[:email_address])
					if user.errors.any?
						return {:status => 0, :message => user.errors.messages.values.first.first}
					else
						return {:status => 1}
					end
				end
			end
			if user_params.has_key?(:current_password) && user_params.has_key?(:new_password) && user_params.has_key?(:confirm_password)
				if decrypt_password(user.encrypted_password) == user_params[:current_password]
					if user_params[:new_password] == user_params[:confirm_password]
						user.update_attributes(:password => user_params[:new_password])
						return {:status => 1}
					else
						return {:status => 0, :message => "New password and confirm password do not match"}
					end
				else
					return {:status => 0, :message => "Current password do not match"}
				end
			end
			if user_params.has_key?(:country_name)
				country = Country.find_by(:name => user_params[:country_name])
				if country
					user.update_attributes(:country => country)
					return {:status => 1}
				else
					return {:status => 0, :message => "Country not found"}
				end
			end
			if user_params.has_key?(:state_name)
				state = State.find_by(:name => user_params[:state_name])
				if state
					user.update_attributes(:state => state)
					return {:status => 1}
				else
					return {:status => 0, :message => "State not found"}
				end
			end
			if user_params.has_key?(:city_name)
				city = City.find_by(:name => user_params[:city_name])
				if city
					user.update_attributes(:city => city)
					return {:status => 1}
				else
					return {:status => 0, :message => "City not found"}
				end
			end
		else
			return {:status => 0}
		end
	end

	def create_group(apiuser, params)
		if params[:group_name].blank?
			return {:status => 0, :message => 'Group name is required'}
		else
			group = Group.create(:group_name => params[:group_name], :admin => apiuser, :group_type => params[:group_type])
			if params.has_key?("group_image")
				group.group_image = params[:group_image]
				group.save
				Rails.logger.info("Saved group image")
			end
			if group.errors.any?
				return {:status => 0, :message => group.errors.messages.values.first.first}
			else
				return {:status => 1, :message => 'Group created successfully'}
			end
		end
	end

	def update_group(apiuser, params)
		if params[:group_id].blank?
			return {:status => 0, :message => 'Group id is required'}
		else
			group = Group.find(params[:group_id])
			if group.blank?
				return {:status => 0, :message => "Group not found"}
			else
				group.update_attributes(:group_name => params[:group_name], :admin => apiuser, :group_type => params[:group_type])
			end
			if params.has_key?("group_image")
				group.group_image = params[:group_image]
				group.save
				Rails.logger.info("Saved group image")
			end
			if group.errors.any?
				return {:status => 0, :message => group.errors.messages.values.first.first}
			else
				return {:status => 1, :message => 'Group created successfully'}
			end
		end
	end

	def get_group(apiuser, params)
		group = Group.find(params[:group_id])
		if group.blank?
			return {:status => 0, :message => 'Group does not exists'}
		else
			return {:status => 1, :group_data => group.to_api(apiuser)}
		end
	end

	def get_user_followers(apiuser)
		user_ids = apiuser.followers.map(&:f_id)
		required_users = Array.new
		user_ids.each do |id|
			user = User.find(id)
			if !user.blank?
				required_users << user.details_to_api(apiuser)
			end
		end
		return {:status => 1, :followers => required_users}
	end

	def get_group_items(apiuser, params, device_width)
		group = Group.find(params[:group_id])
		if group.blank?
			return {:status => 0, :message => 'Group not available'}
		else
			if params[:item_type] == "members"
				return {:status => 1, :items => group.followers.map{|group_user| User.find(group_user.f_id).details_to_api(apiuser)}}
			elsif params[:item_type] == "followers"
				return {:status => 1, :items => group.followers.map{|group_user| User.find(group_user.f_id).details_to_api(apiuser)}}
			else
				return {:status => 1, :items => Product.where(:group_id => group.id).map{|product| product.to_discover(apiuser, device_width)}}
			end
		end
	end

	def delete_group(apiuser, params)
		group = Group.find(params[:group_id])
		if group.blank?
			return {:status => 0, :message => 'Group not available'}
		else
			group.destroy
			return {:status => 1, :message => 'Group removed'}
		end
	end
	
	def create_product(user, product_params)
            if user.email_address == "demo@shapp.dk" || user.blank?
		return {:status => 0}
        else
    		product = Product.create(:user => user, :show_in_both => product_params[:show_in_both].to_i,:product_name => product_params[:product_name], :product_description => product_params[:product_description], :min_bid_price => product_params[:min_bid_price].to_f, :buy_now_price => product_params[:buy_now_price].to_f, :bill_included => product_params[:bill_included].to_i == 1 ? true : false, :quality_id => product_params[:quality_id], :category_id => product_params[:category_id], :brand_id => product_params[:brand_id], :item_model_id => product_params[:model_id], :group_id => product_params[:group_id], :longitude => product_params[:longitude].to_f, :latitude => product_params[:latitude].to_f)
    		if product.errors.any?
    			return {:status => 0, :message => product.errors.messages.values.first.first}
    		else
    			if product_params.has_key?('bid_end')
                    product.update_attributes(:bid_start => DateTime.now, :bid_end => DateTime.parse(product_params[:bid_end]))
                end

    			images_array = Array.new

    			product_params.each do |key,value|
    				if key.start_with?('file_field_')
    					images_array << key
    				end
    			end

    			if product_params.has_key?("video_field")
    				product.product_video = product_params[:video_field]
    				product.save
    				user.update_attributes(:videos_left => user.videos_left > 0 ? user.videos_left - 1 : 0)
    			end

    			images_array.each do |image|
    				if product_params[:is_android].to_i == 1
    					if !product_params[image].blank?
    						product_image = ProductImage.create(:product => product)
    						product_image.image_upload = parse_image_data(product_params[image])
    						product_image.save
    					end
    				else
    					product_image = ProductImage.create(:product => product)
    					product_image.image_upload = product_params[image]
    					product_image.save
    				end
    			end

    			user.update_attributes(:images_left => user.images_left - images_array.count)

    			return {:status => 1, :images_left => user.images_left.to_i, :videos_left => user.videos_left.to_i}
    		end
        end
	end

	def deep_hash_keys(h)
 		h.keys + h.map { |_, v| v.is_a?(Hash) ? deep_hash_keys(v) : nil }.flatten.compact
	end

	def discover_products(user, params, device_width)
		
		saved_shapps = user.saved_shapps.map(&:product_id)
		
		rejected_shapps = user.rejected_products.map(&:product_id)
		
		bids_products = user.bids.map(&:product_id)
		
		my_products = user.products.map(&:id)
		
		skiped_products = saved_shapps + rejected_shapps + bids_products + my_products
		
		required_products = Kaminari.paginate_array(Product.order_by(:created_at => 'desc').where(:id.nin => skiped_products).reject{|p| p.bid_closed? == true || !p.sold_to_id.blank? || p.user_id.blank? == true}).page(params[:page_number].to_i).per(5)
		
		if required_products.count == 0
			skiped_products = saved_shapps + bids_products + my_products
			required_products = Kaminari.paginate_array(Product.order_by(:created_at => 'desc').where(:id.nin => skiped_products).reject{|p| p.bid_closed? == true || !p.sold_to_id.blank? || p.user_id.blank? == true}).page(params[:page_number].to_i).per(5)
		end

		search_profile = user.search_profile
		if search_profile.show_all == true
			return {:status => 1, :products => required_products.map{|product| product.to_discover(user, device_width)}, :total_pages => required_products.total_pages}
		else
			required_products = required_products.reject{|p| p.latitude.blank? || p.longitude.blank? || p.category_id.blank?}.reject{|p| distance([user.latitude, user.longitude],[p.latitude, p.longitude]) < search_profile.radius}.reject{|p| p.buy_now_price > search_profile.price_range}.reject{|p| p.category_id.to_s != search_profile.category_id.to_s}
		end
		if required_products.count > 0
			return {:status => 1, :products => required_products.map{|product| product.to_discover(user, device_width)}, :total_pages => required_products.count / 5}
		else
			return {:status => 0, :products => [], :total_pages => 0}
		end
	end

	def delete_products(apiuser, params)
		if params[:item_type] == "my_bids"
			Bid.where(:user_id => apiuser.id, :product_id => params[:product_id]).destroy_all
			return {:status => 1, :message => "Bid deleted"}
		else
			SavedShapp.where(:user_id => apiuser.id, :product_id => params[:product_id]).destroy_all
			return {:status => 1, :message => "Saved Shapp deleted"}
		end
	end

	def search_items(apiuser, params, device_width)
		if params[:search_type] == 'peoples'
			searched_peoples = User.any_of({:first_name => /^#{params[:query]}/i}).uniq
			return {:status => 1, :items => searched_peoples.map{|user| user.details_to_api(apiuser)}}
		elsif params[:search_type] == 'products'
			searched_products = Product.any_of({:product_name => /^#{params[:query]}/i}).uniq
			return {:status => 1, :items => searched_products.map{|product| product.to_discover(apiuser, device_width)}}
		elsif params[:search_type] == 'groups'
			searched_groups = Group.any_of({:group_name => /^#{params[:query]}/i}).uniq
			return {:status => 1, :items => searched_groups.map{|product| product.to_api(apiuser)}}
		end
	end

	def ip_messaging_token(params)
		# NbmLNn75PXOy7p58ol9SiqaebcIRA3iz
		device_id = params['device']
      	identity = Faker::Internet.user_name
      	endpoint_id = "TwilioDemoApp:#{identity}:#{device_id}"
      	token = Twilio::Util::AccessToken.new "ACadd11157f5e3af7405036fab39f03fe1", "SKb0b89d68f0e9b800b967b5415c0f1979", "IS76fb638ab2a641eab81a195c77aa38a1", 3600, identity
      	grant = Twilio::Util::AccessToken::IpMessagingGrant.new
      	grant.service_sid = "IS76fb638ab2a641eab81a195c77aa38a1"
      	grant.endpoint_id = endpoint_id
      	token.add_grant grant
      	return {:identity => identity, :token => token.to_jwt}
	end

	def search_peoples_for_group(apiuser, params, device_width)
		group = Group.find(params[:group_id])
		if group.blank?
			return {:status => 0, :message => "No group available"}
		else
			existing_users = group.followers.map(&:f_id)
			users = User.any_of({:first_name => /^#{params[:query]}/i}, {:id.nin => existing_users}).uniq
			return {:status => 1, :items => users.map{|user| user.details_to_api(apiuser)}}
		end
	end

	def add_rating(apiuser, params)
		if params[:rating_for] == 'user'
			user = User.find(params[:item_id])
			if user.blank?
				return {:status => 0, :message => 'User does not exists'}
			else
				if user.user_ratings.where(:rated_by_id => apiuser.id).count > 0
					return {:status => 0, :message => 'You have already rated this user'}
				else
					user.user_ratings.create(:rated_by_id => apiuser.id, :rating => params[:item_rating].to_f)
					return {:status => 1, :message => "User rated successfully"}
				end
			end
		elsif params[:rating_for] == 'product'
			product = Product.find(params[:item_id])
			if product.blank?
				return {:status => 0, :message => 'Product does not exists'}
			else
				if product.product_ratings.where(:rated_by_id => apiuser.id).count > 0
					return {:status => 0, :message => 'You have already rated this product'}
				else
					product.product_ratings.create(:rated_by_id => apiuser.id, :rating => params[:item_rating].to_f)
					return {:status => 1, :message => "User rated successfully"}
				end
			end
		else
			return {:status => 0}
		end
	end

	def join_leave_group(apiuser, params)
		group = Group.find(params[:group_id])
		if group.blank?
			return {:status => 0, :message => 'Group not available'}
		else
			existing_user = GroupUser.where(:group_id => params[:group_id], :user_id => apiuser.id).first
			if existing_user.blank?
				group.users << GroupUser.create(:group_id => params[:group_id], :user_id => apiuser.id)
				return {:status => 1, :message => "Added to group"}
			else
				existing_user.destroy
				return {:status => 1, :message => "Removed from group"}
			end
		end
	end

	def accept_reject_bid(apiuser, params)
		bid = Bid.find(params[:bid_id])
		if bid.blank?
			return {:status => 0, :message => "Bid not found"}
		else
			bid.update_attributes(:accepted => params[:accepted].to_i == 1 ? true : false, :accepted_rejected_on => DateTime.now)
			if bid.errors.any?
				return {:status => 0, :message => bid.errors.messages.values.first.first}
			else
				return {:status => 1, :message => "Bid has been #{params[:accepted] == 1 ? 'accepted' : 'rejected'}"}
			end
		end
	end

	def get_notifications(user, params)
		notifications = Notification.where(:user_id => user.id).order_by(:created_at => 'desc').page(params[:page_number]).per(50)
		return {:status => 1, :notifications => notifications.map{|notification| notification.to_api}, :total_pages => notifications.total_pages}
	end

	def product_comments(apiuser, params)
		product = Product.find(params[:product_id])
		if product.blank?
			return {:status => 0}
		else
			comments = product.comments.page(params[:page_number]).per(5).map{|comment| comment.to_api}
			return {:status => 1, :comments => comments, :total_pages => product.comments.count/5}
		end
	end

	def add_comment(apiuser, params)
		product = Product.find(params[:product_id])
		if product.blank?
			return {:status => 0}
		else
			comment = product.comments.create(:comment_text => params[:comment_text], :user => User.find(apiuser.id), :show_on_app => true)
			return {:status => 1, :comment => comment.to_api}
		end
	end

	def update_search_profile(user, search_params)
		search_profile = user.search_profile
		if search_profile.blank?
			search_profile = user.search_profile.create(:user_id => user.id)
		end
		search_profile.update_attributes(:show_all => search_params[:show_all].to_i == 1 ? true : false, :radius => search_params[:radius].to_i, :price_range => search_params[:price_range].to_f, :category => search_params[:category_id].blank? ? nil : Category.find(search_params[:category_id]), :quality => search_params[:quality_id].blank? ? nil : Quality.find(search_params[:quality_id]))
		return {:status => search_profile.errors.any? ? 0 : 1}
	end

	def add_product_view(apiuser, ip_address, params)
		product = Product.find(params[:product_id])
		if product.blank?
			return {:status => 0}
		else
			product.product_views.find_or_create_by(:ip_address => ip_address)
			return {:status => 1}
		end
	end

	def get_user_profile(apiuser, params)
		user = User.find(params[:user_id])
		if user.blank?
			return {:status => 0, :message => "User does not exists"}
		else
			return {:status => 1, :user_data => user.details_to_api(apiuser)}
		end
	end

	def delete_account(apiuser)
		user = User.find(apiuser.id)
		if user.blank?
			return {:status => 0, :message => "User does not exists"}
		else
			user.destroy
			return {:status => 1, :message => "Account deleted"}
		end
	end

	def purchase_completed(apiuser, params)
		user = User.find(params[:user_id])
		paying_for = params[:paying_for]
		purchased_item = user.user_purchases.create(:item_id => paying_for, :item_count => 1, :purchased_from => params[:purchased_from], :purchase_id => params[:purchase_id])
		if !purchased_item.blank?
			if paying_for == "video"
				remaining_videos = user.videos_left + 1
				user.update_attributes(:videos_left => remaining_videos, :is_premium => true)
				return {:status => 1, :images_left => user.images_left, :videos_left => user.videos_left}
			else
				remaining_images = user.images_left + 1
				user.update_attributes(:images_left => remaining_images, :is_premium => true)
				return {:status => 1, :images_left => user.images_left, :videos_left => user.videos_left}
			end
		else
			return {:status => 0}
		end
	end

	def follow_unfollow(apiuser, params)
		Rails.logger.info "Api: #{apiuser.id}"
		user = User.find(params[:user_id])
		if user.blank?
			return {:status => 0}
		else
			if apiuser.follower_of?(user)
				if user.follower_of?(apiuser)
					user.unfollow(apiuser)
				end
				apiuser.unfollow(user)
				return {:status => 1}
			else
				apiuser.follow(user)
				notification_string = apiuser.language_selected == 0 ? "You got a new follower" : "Du har en ny følgere"
            	data_one = {:action => "follower_list", :item_id => user.id.to_s}
            	PushJob.new.send_notification(user, notification_string, data_one)
            	PushJob.new.send_android_notification(user, notification_string, data_one)
            	user.notifications.create(:notification_string => notification_string, :notification_type => 1, :action => "")
				return {:status => 1}
			end
		end
	end

	def follow_unfollow_group(apiuser, params)
		group = Group.find(params[:group_id])
		if group.blank?
			return {:status => 0}
		else
			if apiuser.follower_of?(group)
				apiuser.unfollow(group)
				return {:status => 1, :message => "unfollowing"}
			else
				if group.group_type == "open"
					apiuser.follow(group)
					return {:status => 1, :message => "accepted"}
				else
					group.group_requests.create(:user => apiuser)
					notification_string = group.admin.language_selected == 0 ? "#{apiuser.full_name} has requested to join #{group.group_name}" : "#{apiuser.full_name} har opfordret dig til at blive medlem #{group.group_name}"
                	data_one = {:action => "open_group", :item_id => group.id.to_s, :item_name => group.group_name}
                	PushJob.new.send_notification(group.admin, notification_string, data_one)
                	PushJob.new.send_android_notification(group.admin, notification_string, data_one)
                	group.admin.notifications.create(:notification_string => notification_string, :notification_type => 1, :action => "")
					return {:status => 1, :message => "requested"}
				end
				
			end
		end
	end

	def invite_to_group(apiuser, params)
		group = Group.find(params[:group_id])
		if group.blank?
			return {:status => 0}
		else
			user = User.find(params[:user_id])
			if user
				if group.group_type == "open"
					user.follow(group)
	            	return {:status => 1, :message => "Invited"}
				else
					group.group_requests.create(:user => user)
					group_admin = group.admin
					if group.admin.id.to_s == apiuser.id.to_s
						user.follow(group)
					else
						if !group.admin.blank?
							notification_string = user.language_selected == 0 ? "#{group_admin.full_name} has invited you to #{group.group_name}" : "#{group_admin.full_name} har inviteret dig til at blive medlem #{group.group_name}"
			            	data_one = {:action => "", :item_id => ""}
			            	PushJob.new.send_notification(user, notification_string, data_one)	
			            	PushJob.new.send_android_notification(user, notification_string, data_one)
						end
					end 
	            	return {:status => 1, :message => "Invited"}
				end
				
				
			else
				return {:status => 0, :message => "User not found"}
			end
		end
	end

	def parse_image_data(base64_image)
			current_date = DateTime.now
            filename = "upload-image-#{current_date.year}-#{current_date.month}-#{current_date.day}-#{current_date.hour}-#{current_date.min}"
            in_content_type, encoding, string = base64_image.split(/[:;,]/)[1..3]
            @tempfile = Tempfile.new(filename)
            @tempfile.binmode
            @tempfile.write Base64.decode64(base64_image)
            @tempfile.rewind
            content_type = `file --mime -b #{@tempfile.path}`.split(";")[0]
            extension = content_type.match(/gif|jpeg|png/).to_s
            filename += ".#{extension}" if extension
            ActionDispatch::Http::UploadedFile.new({
                tempfile: @tempfile,
                content_type: content_type,
                filename: filename
            })
    end


  	def clean_tempfile
    	if @tempfile
      		@tempfile.close
      		@tempfile.unlink
    	end
  	end

  	def distance loc1, loc2
  		rad_per_deg = Math::PI/180  # PI / 180
  		rkm = 6371                  # Earth radius in kilometers
  		rm = rkm * 1000             # Radius in meters

  		dlat_rad = (loc2[0]-loc1[0]) * rad_per_deg  # Delta, converted to rad
  		dlon_rad = (loc2[1]-loc1[1]) * rad_per_deg

  		lat1_rad, lon1_rad = loc1.map {|i| i * rad_per_deg }
  		lat2_rad, lon2_rad = loc2.map {|i| i * rad_per_deg }

  		a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
  		c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

  		rm * c # Delta in meters
	end
end


# [07/10/16, 6:44:36 PM] Alex B: Tillykke! Du har vundet auktionen ! 
# Der er kommet bud på den varer du følger
# Der er kommet bud på den varer du har budt på
# Jacob, du følger har sat en IPhone til salg! BYD nu
# Auktionen er afsluttet
# Auktionen afslutter om 10 min
# Du har fået en ny følger
# Der er blevet lagt varer til salg i din gruppe:
# [18:43:32] Eyup Tekbas: look them
# [18:43:33] Alex B: ?
# [18:43:47] Eyup Tekbas: its notifications message to shapp
# [18:43:48] Eyup Tekbas: ok
# [18:43:56] Eyup Tekbas: lets take step by step
# [18:43:58] Eyup Tekbas: ok

# [07/10/16, 6:44:50 PM] Alex B: Congratulations! You've won the auction!
# There have been bid on the items you follow
# There have been bid on the items you have bid on
# Jacob, you follow set a Iphone for sale! BYD now
# The auction is closed
# The auction ends on 10 min
# You've got a new follow
# There have been placed items for sale in your group:


# def search(url,pages)
# 	for i in 0..pages
# 		url = i == 0 ? url : "#{url}&p=#{i}"
# 		doc = Nokogiri::HTML(open(url))
# 		doc.css(".thumb-block p > a").each do |item|
# 			puts "#{i} - #{item}"
# 		end
# 	end
# end


# c5dc_iW6z1M:APA91bEHO-dSbjauoVEJN9tQU071tH7nMT3nRirKzASuLN08c3BY5z18yw_kG3io0oVutRczQOCkLFYXk8mnEYLE5NgeQQc1TgLzkicduXoOnooTSB6VX5qqpCFNWO5F4uM_D2L-JB35