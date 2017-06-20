require 'reloader/sse'
class ChatsController < ApplicationController

    include ActionController::Live

    protect_from_forgery with: :null_session

    skip_before_filter  :verify_authenticity_token

    def subscribe_to_chat
        product_id = params[:product_id]
        user_id = params[:user_id]
        product = Product.find(product_id)
        RedisServer.instance.subscribe(product, User.find(user_id))
        response.headers['Content-Type'] = 'text/event-stream'
        sse = Reloader::SSE.new(response.stream)
        begin
            $redis.subscribe(product.id.to_s) do |on|
                on.message do |event, data|
                    parsed_data = JSON.parse(data)
                    sse.write(data: parsed_data, event: parsed_data["event"] || "push-message")
                end
            end
        rescue IOError
                puts "IOError"
                Rails.logger.info("IOError")
        ensure
            sse.close
        end
        render nothing: true
    end

    def add_chat_message
        product_id = params[:product_id]
        from_id = params[:from_id]
        response.headers['Content-Type'] = 'text/javascript'
        @message = Message.create(:message_text => params[:message], :product => Product.find(product_id), :user_one => User.find(from_id))
        render nothing: true
    end

    def unsubscribe_to_chat
        product_id = params[:product_id]
        user_id = params[:from_id]

        RedisServer.instance.unsubscribe(Product.find(product_id), User.find(user_id))
        render :json => ActiveSupport::JSON.encode( {:status => 1} )
    end
end
