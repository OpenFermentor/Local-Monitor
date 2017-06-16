defmodule BioMonitor.Router do
  use BioMonitor.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BioMonitor do
    pipe_through :api
  end
end
