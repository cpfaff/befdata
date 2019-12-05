# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Befchina::Application.config.secret_token = CONFIG[:application_secret_token]

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
Befchina::Application.config.secret_key_base = CONFIG[:application_secret_key_base]

