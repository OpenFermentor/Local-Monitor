defmodule BioMonitor.ReadingView do
  use BioMonitor.Web, :view

  def render("index.json", %{readings: readings}) do
    %{data: render_many(readings, BioMonitor.ReadingView, "reading.json")}
  end

  def render("show.json", %{reading: reading}) do
    %{data: render_one(reading, BioMonitor.ReadingView, "reading.json")}
  end

  def render("reading.json", %{reading: reading}) do
    %{id: reading.id,
      temp: reading.temp,
      ph: reading.ph,
      substratum: reading.substratum,
      observancy: reading.observancy,
      biomass: reading.biomass,
      inserted_at: reading.inserted_at,
      routine_id: reading.routine_id}
  end
end
