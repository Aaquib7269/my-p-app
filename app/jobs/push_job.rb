class PushJob
    include SuckerPunch::Job

    def send_notification(user, notification_string, data)
        device_tokens = user.user_devices.where(:device_type.in => [1,2]).map(&:push_token)
        notification = {
                            send_date: 'now',
                            ignore_user_timezone: true,
                            content: notification_string,
                            data: data,
                            platforms: [1],
                            ios_root_params: {
                                                aps: { 'content-available': 1 }
                                            },
                            devices: device_tokens
                        }
        push = PushWoosher::Push.new(notification: notification)
        push.post
        puts push.inspect
    end

    def send_android_notification(user, notification_string, data)
        device_tokens = user.user_devices.where(:device_type.in => [3, 4]).map(&:push_token)
        notification = {
                            send_date: 'now',
                            ignore_user_timezone: true,
                            content: notification_string,
                            data: data,
                            platforms: [3],
                            android_root_params: {
                                                aps: { 'content-available': 1 }
                                            },
                            devices: device_tokens
                        }
        push = PushWoosher::Push.new(notification: notification)
        push.post
        puts push.inspect
    end

    def send_ios_notification(user,notification_string)
        device_tokens = user.user_devices.where(:device_type.in => [1,2]).map(&:push_token)
        notification = {
                            send_date: 'now',
                            ignore_user_timezone: true,
                            content: notification_string,
                            data: {},
                            platforms: [1],
                            ios_root_params: {
                                                aps: { 'content-available': 1 }
                                            },
                            devices: device_tokens
                        }
        push = PushWoosher::Push.new(notification: notification)
        push.post
        puts push.inspect
    end

    def send_test_notification(user)
        device_tokens = user.user_devices.where(:device_type.in => [1,2]).map(&:push_token)
        device_tokens.each do |token|
            n = Rpush::Apns::Notification.new
            n.app = Rpush::Apns::App.find_by(:name => "prod_ios_app")
            notification_string = "Hello #{user.email_address}"
            n.alert = notification_string
            n.device_token = token
            n.save!
        end
    end

    def send_push(user, notification_string, data)
        device_tokens = user.user_devices.where(:device_type.in => [1,2]).map(&:push_token)
        notification = {
                            send_date: 'now',
                            ignore_user_timezone: true,
                            content: notification_string,
                            data: data,
                            platforms: [1],
                            ios_root_params: {
                                                aps: { 'content-available': 0 }
                                            },
                            devices: device_tokens
                        }
        push = PushWoosher::Push.new(notification: notification)
        push.post
        puts push.inspect
    end

    def send_fcm(user, notification_string, data)
        fcm = FCM.new("AAAAJzMbq9A:APA91bEbhD8qAJ_gxMSqefURhFx3lHOMTeQwG3WWtTFJReAABR7jDZXvOr1hm8nmNKNjtbvoUep0fi63mN8SeVXKKoc7d1qbFEFZnbcdXUV4KtnG-jUi3B27Gbvtwh4waQz6bEb0WmD7vqviGcMjkk828cJWigKyhQ")
        device_tokens = user.user_devices.where(:device_type.in => [3,4]).map(&:push_token)
        options = {data: data, notification_string: notification_string}
        response = fcm.send(device_tokens, options)
        puts response
    end
end