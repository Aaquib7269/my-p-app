class RedisServer
    include Singleton

    def initialize
        @redis = Redis.new
    end

    def push_message(group, user, options = {})
        @redis.publish(group.id.to_s, queue_data(user).merge(options).to_json)
    end

    def subscribed?(group, user)
        @redis.sismember(group.id.to_s, user.id.to_s)
    end

    def members(group)
        @redis.smembers(group.id.to_s)
    end

    def subscribe(group, user)
        @redis.sadd(group.id.to_s, user.id.to_s)
        push_message(group, user, sub_unsub_options(group).merge(:message => user.language_selected == 0 ? "#{user.full_name} is entering into this chat room" : "#{user.full_name} er logget ind på chat"))
    end

    def unsubscribe(group, user)
        @redis.srem(group.id.to_s, user.id.to_s)
        push_message(group, user, sub_unsub_options(group).merge(:message => user.language_selected == 0 ? "#{user.full_name} is exiting from this chat room" : "#{user.full_name} er logget ud af chat"))
    end

    private
    def queue_data(user)
        { 
            :username   => user.email_address, 
            :time       => Time.now.strftime("%T") ,
            :bg_color   => "bg-color-#{user.email_address.length % 5}",
            :event      => "push-message" ,
            :thumb_url  => user.avatar.blank? ? "" : "#{user.avatar.url}",
        }
    end

    def sub_unsub_options(group)
        { 
            :event    => "enter-exit-chatroom",
            :members  => members(group),
            :bg_color => "bg-color-normal" 
        }
    end
end