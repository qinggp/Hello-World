# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_mars_session',
  :secret      => 'd2ec039659cd55e46abd86dc79d1d2e1fc71d7f3a43fcf9e5b3280fade2e81a04bcdf7a8099bbe4b3fc6f7c0e1f310ec5109d6b0e30de380e79a1a834a7171c8',
  :cookie_only => false
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
