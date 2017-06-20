Rpush.configure do |config|
    config.client = :mongoid
    config.push_poll = 2
    config.batch_size = 100
    config.pid_file = 'tmp/rpush.pid'
    config.log_file = 'log/rpush.log'
end