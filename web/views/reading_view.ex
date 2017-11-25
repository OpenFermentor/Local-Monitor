defmodule BioMonitor.ReadingView do
  use BioMonitor.Web, :view

  def render("index.json", %{readings: readings}) do
    %{data: render_many(readings, BioMonitor.ReadingView, "reading.json")}
  end

  def render("q_values.json", %{values: values}) do
    %{data: render_many(values, BioMonitor.ReadingView, "result.json")}
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

  def render("result.json", %{reading: result}) do
    %{
      x: result.x,
      y: result.y
    }
  end
end
