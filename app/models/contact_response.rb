class ContactResponse
  include Common
  field :message, type: String
  belongs_to :contact, :class_name => "Contact", :index => true, :inverse_of => :contact
  belongs_to :admin, :class_name => "Admin", :index => true, :inverse_of => :admin
end
