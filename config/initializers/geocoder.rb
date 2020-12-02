Geocoder.configure(
   lookup:    :google,
   api_key:   Rails.application.credentials[:google_api_server_key],
   use_https: true,
   # [...]
) 