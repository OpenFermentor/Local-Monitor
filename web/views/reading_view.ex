defmodule BioMonitor.ReadingView do
  use BioMonitor.Web, :view

  def render("index.json", %{readings: readings}) do
    %{data: render_many(readings, BioMonitor.ReadingView, "reading.json")}
  end

  def render("calculations.json", %{values: values}) do
    %{
      data: %{
        biomass_performance: render_many(values.biomass_performance, BioMonitor.ReadingView, "result.json", as: :result),
        product_performance: render_many(values.product_performance, BioMonitor.ReadingView, "result.json", as: :result),
        product_biomass_performance: render_many(values.product_biomass_performance, BioMonitor.ReadingView, "result.json", as: :result),
        product_volumetric_performance: render_many(values.product_volumetric_performance, BioMonitor.ReadingView, "result.json", as: :result),
        biomass_volumetric_performance: render_many(values.biomass_volumetric_performance, BioMonitor.ReadingView, "result.json", as: :result),
        max_product_volumetric_performance: render("result.json", %{result: values.max_product_volumetric_performance}),
        max_biomass_volumetric_performance: render("result.json", %{result: values.max_biomass_volumetric_performance}),
        specific_ph_velocity: render_many(values.specific_ph_velocity, BioMonitor.ReadingView, "result.json", as: :result),
        specific_biomass_velocity: render_many(values.specific_biomass_velocity, BioMonitor.ReadingView, "result.json", as: :result),
        specific_product_velocity: render_many(values.specific_product_velocity, BioMonitor.ReadingView, "result.json", as: :result),
        max_ph_velocity: render("result.json", %{result: values.max_ph_velocity}),
        max_biomass_velocity: render("result.json", %{result: values.max_biomass_velocity}),
        max_product_velocity: render("result.json", %{result: values.max_product_velocity}),
      }
    }
  end

  def render("reading.json", %{reading: reading}) do
    %{
      id: reading.id,
      temp: reading.temp,
      ph: reading.ph,
      substratum: reading.substratum,
      product: reading.product,
      biomass: reading.biomass,
      inserted_at: reading.inserted_at,
      routine_id: reading.routine_id
    }
  end

  def render("result.json", %{result: result}) do
    case result do
      nil -> nil
      result ->
        %{
          x: result.x,
          y: result.y
        }
    end
  end
end
