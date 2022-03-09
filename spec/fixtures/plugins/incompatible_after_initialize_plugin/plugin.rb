# frozen_string_literal: true

# name: incompatible_after_initialize_plugin
# about: Incompatbile after initialize plugin fixture
# version: 0.1.1
# authors: Angus McLeod
# contact_emails: angus@test.com
# url: https://github.com/paviliondev/discourse-incompatible-after-initialize-plugin.git

after_initialize do
  ClassDoesNotExist
end
