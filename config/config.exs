# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :sunstone,
  ecto_repos: [Sunstone.Repo]

# Configures the endpoint
config :sunstone, SunstoneWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4p++zdWKt7TWSjz9x4aCoLdLvZdSgeLAFGIT5lZsydiS/vzxLPTPab5epcE388A/",
  render_errors: [view: SunstoneWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Sunstone.PubSub,
  live_view: [signing_salt: "CSuh5duX"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :sunstone, Sunstone.Accounts.Guardian,
  issuer: "sunstone", # Name of your app/company/product
  secret_key: "sf/dnMKYVw9YfRs5mFDyPkT7Rm/bnatbEsf8QmJWLtf24PGhTCTF7dqU/9HogDTx",
  redirect_uri: "/live"

config :web_push_encryption, :vapid_details,
  subject: "mailto:administrator@inoffice.chat",
  public_key: "BCUN8eQ6_Q71ijNY4jJ0O4taC3gfQhmpruj4YVCbkI4N9bqmskRy_6atNt2dtg66WLETOm6-j3p-n9ABX106slA",
  private_key: "oeAP5ohr1QQ7he2G4hXJNlG8c_KtljzSn2J38x9CZLc"

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
