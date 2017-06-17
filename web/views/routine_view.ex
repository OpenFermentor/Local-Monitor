defmodule BioMonitor.RoutineView do
  use BioMonitor.Web, :view

  def render("index.json", %{title: title}) do
    %{data: render_many(title, BioMonitor.RoutineView, "routine.json")}
  end

  def render("show.json", %{routine: routine}) do
    %{data: render_one(routine, BioMonitor.RoutineView, "routine.json")}
  end

  def render("routine.json", %{routine: routine}) do
    %{id: routine.id,
      title: routine.title,
      strain: routine.strain,
      medium: routine.medium,
      target_temp: routine.target_temp,
      target_ph: routine.target_ph,
      target_co2: routine.target_co2,
      target_density: routine.target_density,
      estimated_time_seconds: routine.estimated_time_seconds,
      extra_notes: routine.extra_notes,
      inserted_at: routine.inserted_at,
      updated_at: routine.updated_at,
    }
  end
end
