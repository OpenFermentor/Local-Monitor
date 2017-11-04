defmodule BioMonitor.LogEntryView do
  use BioMonitor.Web, :view

  def render("index.json", %{log_entries: log_entries}) do
    %{data: render_many(log_entries, BioMonitor.LogEntryView, "log_entry.json")}
  end


  def render("log_entry.json", %{log_entry: log_entry}) do
    %{
      id: log_entry.id,
      type: log_entry.type,
      description: log_entry.description,
      inserted_at: log_entry.inserted_at,
    }
  end
end
