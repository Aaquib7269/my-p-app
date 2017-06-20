Rails.configuration.stripe = {
  :publishable_key => "pk_test_Hm0lcIUTg6NgePWYVxwwtL4i",
  :secret_key      => "sk_test_sHYpClyrGsY1FrQW30YIxu8H"
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
