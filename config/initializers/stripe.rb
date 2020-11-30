if !Rails.env.development?
    Stripe.api_key = Rails.application.credentials.stripe[:production][:secret_key]
else
    Stripe.api_key = Rails.application.credentials.stripe[:development][:secret_key]
end

Stripe.api_version = "2019-08-14"