CarrierWave.configure do |config|
    config.fog_credentials = {
      provider:              'AWS',                        # required
      aws_access_key_id:     Rails.application.credentials[:aws_access_key_id],                        # required unless using use_iam_profile
      aws_secret_access_key: Rails.application.credentials[:aws_secret_access_key],                        # required unless using use_iam_profile
      # use_iam_profile:       true,                         # optional, defaults to false
      region:                'us-west-2',                  # optional, defaults to 'us-east-1'
    }
    config.fog_directory  = 'musapp'                                      # required
    config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" } # optional, defaults to {}
end