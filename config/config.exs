# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

import_config "config_smoke_server.exs"
import_config "config_prime_time_server.exs"
import_config "config_means_to_end_server.exs"
import_config "config_budget_chat_server.exs"
import_config "config_unusual_database_server.exs"
import_config "config_mob_in_the_middle_server.exs"
