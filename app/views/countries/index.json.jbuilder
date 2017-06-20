json.array!(@countries) do |country|
  json.extract! country, :id, :name, :shortcode
  json.url country_url(country, format: :json)
end
