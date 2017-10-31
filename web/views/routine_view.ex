defmodule BioMonitor.RoutineView do
  use BioMonitor.Web, :view

  def render("index.json", %{routine: routine, page_info: page_info}) do
    Map.merge(
      %{
        data: render_many(routine, BioMonitor.RoutineView, "routine.json")
      },
      page_info
    )
  end

  def render("show.json", %{routine: routine}) do
    %{data: render_one(routine, BioMonitor.RoutineView, "routine.json")}
  end

  def render("routine.json", %{routine: routine}) do
    %{
      id: routine.id,
      uuid: routine.uuid,
      title: routine.title,
      strain: routine.strain,
      medium: routine.medium,
      target_temp: routine.target_temp,
      target_ph: routine.target_ph,
      target_co2: routine.target_co2,
      target_density: routine.target_density,
      estimated_time_seconds: routine.estimated_time_seconds,
      extra_notes: routine.extra_notes,
      started: routine.started,
      started_date: routine.started_date,
      inserted_at: routine.inserted_at,
      updated_at: routine.updated_at,
      ph_tolerance: routine.ph_tolerance,
      balance_ph: routine.balance_ph,
      loop_delay: routine.loop_delay,
      temp_tolerance: routine.temp_tolerance,
      temp_ranges: render_temp_ranges(routine),
      trigger_for: routine.trigger_for,
      trigger_after: routine.trigger_after,
    }
  end

  def render("unavailable.json", _assigns) do
    %{error: "El fermentador está trabajando en otro experimento en este momento."}
  end

  def render("already_run.json", _assigns) do
    %{error: "El experimento ya fue corrido."}
  end

  defp render_temp_ranges(routine) do
    routine.temp_ranges
    |> Enum.map(fn range ->
      %{temp: range.temp, from_second: range.from_second}
    end)
  end
end
