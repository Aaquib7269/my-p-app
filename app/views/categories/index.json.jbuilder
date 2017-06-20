json.array!(@categories) do |category|
  json.extract! category, :id, :parent_category_id, :name, :order
  json.url category_url(category, format: :json)
end
