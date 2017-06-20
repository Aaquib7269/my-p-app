json.array!(@users) do |user|
  json.extract! user, :id, :first_name, :last_name, :email, :encrypted_password, :avtar, :country, :push_notification, :auto_refresh, :email_notification, :longitude, :latitude
  json.url user_url(user, format: :json)
end
