# Docs: https://terraspace.cloud/docs/config/reference/
Terraspace.configure do |config|
  # config.logger.level = :info

  # copy_modules setting introduced 2.2.5 to speed up terraspace build
  # See: https://terraspace.cloud/docs/config/reference
  config.build.copy_modules = true
  config.auto_create_backend = false # Set to false to disable auto creation of backend.tf files
end
