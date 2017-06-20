json.array!(@brands) do |brand|
  json.extract! brand, :id, :category_id, :name
  json.url brand_url(brand, format: :json)
end
