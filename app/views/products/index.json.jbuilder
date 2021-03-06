json.array!(@products) do |product|
  json.extract! product, :id, :user_id, :category_id, :product_name, :product_description, :bid_start, :bid_end, :bill_included, :min_bid_price, :buy_now_price, :sold_to_id
  json.url product_url(product, format: :json)
end
