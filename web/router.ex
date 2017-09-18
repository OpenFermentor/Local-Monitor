defmodule BioMonitor.Router do
  use BioMonitor.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BioMonitor do
    pipe_through :api

    post "/routines/stop", RoutineController, :stop
    post "/routines/start", RoutineController, :start
    post "/system/restart", RoutineController, :restart
    get "/ph/current", PhController, :current
    get "/ph/status", PhController, :calibration_status
    post "/ph/base", PhController, :set_base
    post "/ph/acid", PhController, :set_acid
    post "/ph/neutral", PhController, :set_neutral
    resources "/routines", RoutineController, except: [:new, :edit] do
      resources "/readings", ReadingController, except: [:new, :edit, :update]
      get "/to_csv", RoutineController, :to_csv
    end
  end
end
