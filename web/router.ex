defmodule BioMonitor.Router do
  use BioMonitor.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BioMonitor do
    pipe_through :api

    resources "/routines", RoutineController, except: [:new, :edit]
  end
end
