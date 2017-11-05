defmodule BioMonitor.LogEntryController do
  use BioMonitor.Web, :controller

  alias BioMonitor.LogEntry

  def index(conn, _params) do
    log_entries = Repo.all(LogEntry)
    render(conn, "index.json", log_entries: log_entries)
  end
end
