class Contact
  include Common
  field :full_name, type: String
  field :email_address, type: String
  field :message, type: String
  has_many :contact_responses
  	accepts_nested_attributes_for :contact_responses, :reject_if => :all_blank, :allow_destroy => true
end
