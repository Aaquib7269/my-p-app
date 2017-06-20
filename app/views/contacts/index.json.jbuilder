json.array!(@contacts) do |contact|
  json.extract! contact, :id, :full_name, :email_address, :message
  json.url contact_url(contact, format: :json)
end
