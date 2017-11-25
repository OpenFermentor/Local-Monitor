defmodule BioMonitor.Router do
  use BioMonitor.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BioMonitor do
    pipe_through :api

    # Routine management
    post "/routines/stop", RoutineController, :stop
    post "/routines/start", RoutineController, :start
    get "/routines/current", RoutineController, :current

    #Restart connection with the board
    post "/system/restart", RoutineController, :restart

    # Ph sensor setup
    get "/ph/current", PhController, :current
    get "/ph/status", PhController, :calibration_status
    post "/ph/base", PhController, :set_base
    post "/ph/acid", PhController, :set_acid
    post "/ph/neutral", PhController, :set_neutral

    # Pump setup
    post "/ph/push_base", PhController, :push_base
    post "/ph/push_acid", PhController, :push_acid
    post "/ph/test_acid_drop", PhController, :test_acid_drop
    post "/ph/test_base_drop", PhController, :test_base_drop

    # API services for business entities.
    resources "/routines", RoutineController, except: [:new, :edit] do
      resources "/readings", ReadingController, except: [:new, :edit, :update, :show]
      get "/readings/q_values", ReadingController, :calculate_q
      resources "/log_entries", LogEntryController, only: [:index]
      get "/to_csv", RoutineController, :to_csv
    end
  end
end
