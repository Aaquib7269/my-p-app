class UserPurchase
    include Common

    field :item_id, type: String
    field :item_count, type: Integer
    field :purchased_from, type: String
    field :purchase_id, type: String

    belongs_to :user, :class_name => "User", :index => true, :inverse_of => :user
end
