module Api::V1

    class ApiController < ApplicationController

        protect_from_forgery with: :null_session

        skip_before_filter  :verify_authenticity_token

        before_filter :setup_device

        def setup_device
            if apiuser
                language = request.headers['HTTP_X_API_LANGUAGE']
                if language == "en"
                    apiuser.update_attributes(:language_selected => 0)
                else
                    apiuser.update_attributes(:language_selected => 1)
                end
                push_enabled = request.headers['HTTP_X_API_PUSHENABLED']
                push_token = request.headers['HTTP_X_API_PUSHTOKEN']
                device_type_string = request.headers['HTTP_X_API_DEVICETYPE']
                device_type = 1
                if device_type_string == 'iPhone'
                    device_type = 1
                elsif device_type_string == 'iPad'
                    device_type = 2
                elsif device_type_string == 'Android'
                    device_type = 3
                else
                    device_type = 4
                end
                if push_enabled == "yes" && !push_token.blank?
                    device = UserDevice.find_or_create_by(:user => apiuser, :push_token => push_token)
                    if device
                        device.update_attributes(:device_type => device_type, :user => apiuser, :push_token => push_token, :push_enabled => push_enabled == 'yes' ? true : false)
                    end
                end
            end
        end

        def device_width
            width = request.headers['HTTP_X_API_DEVICEWIDTH'].blank? ? 748: request.headers['HTTP_X_API_DEVICEWIDTH']
            Rails.logger.info("Width: #{width}")
            return width
        end

        def apimodel
        	return Api::Modelv1.new
        end

        def apiuser
            api_key = request.headers['HTTP_X_API_KEY']
            api_email = request.headers['HTTP_X_API_USEREMAIL']
            return User.find_by(:email_address => api_email, :api_key => api_key)
        end

        def get_countries
        	render :json => ActiveSupport::JSON.encode(apimodel.get_countries(params))
        end

        def get_states
        	render :json => ActiveSupport::JSON.encode(apimodel.get_states(params))
        end

        def get_cities
        	render :json => ActiveSupport::JSON.encode(apimodel.get_cities(params))
        end

        def check_login_by_facebook
            render :json => ActiveSupport::JSON.encode(apimodel.check_login_by_facebook(params))
        end

        def check_login
        	render :json => ActiveSupport::JSON.encode(apimodel.check_login(params))
        end

        def create_account
        	render :json => ActiveSupport::JSON.encode(apimodel.create_account(params))
        end

        def get_messages
            render :json => ActiveSupport::JSON.encode(apimodel.get_messages(apiuser, params))
        end

        def ip_messaging_token
            render :json => ActiveSupport::JSON.encode(apimodel.ip_messaging_token(params))
        end

        def upload_avatar
            render :json => ActiveSupport::JSON.encode(apimodel.upload_avatar(apiuser, params))
        end

        def delete_account
            render :json => ActiveSupport::JSON.encode(apimodel.delete_account(apiuser))
        end

        def get_user_data
            render :json => ActiveSupport::JSON.encode(apimodel.get_user_data(apiuser))
        end

        def get_group_requests
            render :json => ActiveSupport::JSON.encode(apimodel.get_group_requests(apiuser, params))
        end

        def accept_reject_group_request
            render :json => ActiveSupport::JSON.encode(apimodel.accept_reject_group_request(apiuser, params))
        end

        def get_qualities
            render :json => ActiveSupport::JSON.encode(apimodel.get_qualities)
        end

        def delete_products
            render :json => ActiveSupport::JSON.encode(apimodel.delete_products(apiuser, params))
        end

        def accept_reject_bid
            render :json => ActiveSupport::JSON.encode(apimodel.accept_reject_bid(apiuser, params))
        end

        def get_chat_list
            render :json => ActiveSupport::JSON.encode(apimodel.get_chat_list(apiuser, params, device_width))
        end

        def get_categories
            render :json => ActiveSupport::JSON.encode(apimodel.get_categories)
        end

        def search_groups
            render :json => ActiveSupport::JSON.encode(apimodel.search_groups(apiuser))
        end

        def get_brands
            render :json => ActiveSupport::JSON.encode(apimodel.get_brands(params))
        end

        def get_models
            render :json => ActiveSupport::JSON.encode(apimodel.get_models(params))
        end

        def create_product
            render :json => ActiveSupport::JSON.encode(apimodel.create_product(apiuser, params))
        end

        def buy_product
            render :json => ActiveSupport::JSON.encode(apimodel.buy_product(apiuser, params))
        end

        def report_product
            render :json => ActiveSupport::JSON.encode(apimodel.report_product(apiuser, params))
        end

        def search_items
            render :json => ActiveSupport::JSON.encode(apimodel.search_items(apiuser, params, device_width))
        end

        def search_peoples_for_group
            render :json => ActiveSupport::JSON.encode(apimodel.search_peoples_for_group(apiuser, params, device_width))
        end

        def add_rating
            render :json => ActiveSupport::JSON.encode(apimodel.add_rating(apiuser, params))
        end

        def invite_to_group
            render :json => ActiveSupport::JSON.encode(apimodel.invite_to_group(apiuser, params))
        end

        def discover_products
            render :json => ActiveSupport::JSON.encode(apimodel.discover_products(apiuser, params, device_width))
        end

        def reject_product
            render :json => ActiveSupport::JSON.encode(apimodel.reject_product(apiuser, params))
        end

        def add_bid_to_product
            render :json => ActiveSupport::JSON.encode(apimodel.add_bid_to_product(apiuser, params))
        end

        def update_profile
            render :json => ActiveSupport::JSON.encode(apimodel.update_profile(apiuser, params))
        end

        def add_remove_saved_shapp
            render :json => ActiveSupport::JSON.encode(apimodel.add_remove_saved_shapp(apiuser, params))
        end

        def update_search_profile
            render :json => ActiveSupport::JSON.encode(apimodel.update_search_profile(apiuser, params))
        end

        def get_my_products
            render :json => ActiveSupport::JSON.encode(apimodel.get_my_products(apiuser, params, device_width))
        end

        def get_product
            render :json => ActiveSupport::JSON.encode(apimodel.get_product(apiuser, params, device_width))
        end

        def get_product_bids
            render :json => ActiveSupport::JSON.encode(apimodel.get_product_bids(apiuser, params))
        end

        def add_product_view
            render :json => ActiveSupport::JSON.encode(apimodel.add_product_view(apiuser, request.remote_ip, params))
        end

        def get_notifications
            render :json => ActiveSupport::JSON.encode(apimodel.get_notifications(apiuser, params))
        end

        def product_comments
            render :json => ActiveSupport::JSON.encode(apimodel.product_comments(apiuser, params))
        end

        def add_comment
            render :json => ActiveSupport::JSON.encode(apimodel.add_comment(apiuser, params))
        end

        def get_groups
            render :json => ActiveSupport::JSON.encode(apimodel.get_groups(apiuser, params))
        end

        def get_group
            render :json => ActiveSupport::JSON.encode(apimodel.get_group(apiuser, params))
        end

        def get_group_items
            render :json => ActiveSupport::JSON.encode(apimodel.get_group_items(apiuser, params, device_width))
        end

        def create_group
            render :json => ActiveSupport::JSON.encode(apimodel.create_group(apiuser, params))
        end

        def update_group
            render :json => ActiveSupport::JSON.encode(apimodel.update_group(apiuser, params))
        end

        def join_leave_group
            render :json => ActiveSupport::JSON.encode(apimodel.join_leave_group(apiuser, params))
        end

        def get_user_profile
            render :json => ActiveSupport::JSON.encode(apimodel.get_user_profile(apiuser, params))
        end

        def get_user_followers
            render :json => ActiveSupport::JSON.encode(apimodel.get_user_followers(apiuser))
        end

        def follow_unfollow
            render :json => ActiveSupport::JSON.encode(apimodel.follow_unfollow(apiuser, params))
        end

        def follow_unfollow_group
            render :json => ActiveSupport::JSON.encode(apimodel.follow_unfollow_group(apiuser, params))
        end

        def purchase_completed
            render :json => ActiveSupport::JSON.encode(apimodel.purchase_completed(apiuser, params))
        end

        def delete_group
            render :json => ActiveSupport::JSON.encode(apimodel.delete_group(apiuser, params))
        end

        
        def subscribe_to_chat
            user_one_id = params[:id]
            user_two_id = params[:from_user_id]
            response.headers['Content-Type'] = 'text/event-stream'
            sse = Reloader::SSE.new(response.stream)
            $redis.subscribe("#{user_one_id}-#{user_two_id}") do |on|
                on.message do |event, data|
                    parsed_data = JSON.parse(data)
                    sse.write(parsed_data, event: parsed_data["event"] || "push-message")
                end
            end
            render nothing: true
            rescue IOError
                puts "IOError"
            ensure
            $redis.quit
            sse.close
        end
    end
end
