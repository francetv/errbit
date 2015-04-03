require File.expand_path('lib/omniauth/strategies/doorkeeper', Rails.root)

OmniAuth.config.logger = Rails.logger

#Rails.application.config.middleware.use OmniAuth::Builder do
#  provider :doorkeeper, "dfd831972b41caa50febeaf88aa9423a7320aca61c53c67f4cfafc6012c4c003", "b2f3635e6a16fd22d181324d8b436dc19c79ca975703da18e0f2a59763a36164"
#end
