# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :site, SiteWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "yK6hUINZWlq04EPu3SJjAHNDYgka8MZqgXZykF+AQ2PvWs4Ua4IELdFl198aMvw0",
  render_errors: [accepts: ~w(html), layout: {SiteWeb.LayoutView, "app.html"}],
  pubsub_server: Site.PubSub

config :phoenix, :gzippable_exts, ~w(.txt .html .js .css .svg)

# Configures Elixir's Logger
config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  metadata: [:request_id]

# Include referrer in Logster request log
config :logster, :allowed_headers, ["referer"]

config :site, SiteWeb.ViewHelpers, google_tag_manager_id: System.get_env("GOOGLE_TAG_MANAGER_ID")

config :laboratory,
  features: [
    {:events_hub_redesign, "Events Hub Redesign (Feb. 2021)",
     "Changes to the event listings and the event pages as part of the 🤝 Public Engagement epic"}
  ],
  cookie: [
    # one month,
    max_age: 3600 * 24 * 30,
    http_only: true
  ]

config :site, Site.BodyTag, mticket_header: "x-mticket"

# Centralize Error reporting
config :sentry,
  dsn: System.get_env("SENTRY_DSN") || "",
  environment_name:
    (case System.get_env("SENTRY_REPORTING_ENV") do
       nil -> Mix.env()
       env -> String.to_existing_atom(env)
     end),
  enable_source_code_context: false,
  root_source_code_path: File.cwd!(),
  included_environments: [:prod],
  json_library: Poison,
  filter: Site.SentryFilter

config :site, :former_mbta_site, host: "https://old.mbta.com"
config :site, tile_server_url: "https://mbta-map-tiles-dev.s3.amazonaws.com"

config :site, OldSiteFileController,
  response_fn: {SiteWeb.OldSiteFileController, :send_file},
  gtfs_s3_bucket: {:system, "GTFS_S3_BUCKET", "mbta-gtfs-s3"}

config :site, StaticFileController, response_fn: {SiteWeb.StaticFileController, :send_file}

config :util,
  router_helper_module: {:ok, SiteWeb.Router.Helpers},
  endpoint: {:ok, SiteWeb.Endpoint}

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

config :recaptcha,
  public_key: {:system, "RECAPTCHA_PUBLIC_KEY"},
  secret: {:system, "RECAPTCHA_PRIVATE_KEY"}

config :site, :react,
  source_path: Path.join(File.cwd!(), "/apps/site/assets/"),
  build_path: Path.join(File.cwd!(), "/apps/site/react_renderer/dist/app.js")

config :site,
  allow_indexing: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
