defmodule BioMonitor.RoutineCalculations do
  @moduledoc """
    Module in charge of processing the readings to infer new data
  """
  require Math

  defmodule Result do
    @moduledoc """
      Struct that reperesent a result as a 2 axis point.
    """
    defstruct x: 0, y: 0
  end

  defmodule PartialResult do
    @moduledoc """
     Struct used to store partial results during calculations
    """
    defstruct x: 0, y: 0, reading: nil
  end

  def calculate_q(readings, started_timestamp) do
    readings |> Enum.reduce([],
      fn reading, acc ->
        acc |> List.insert_at(-1, derivate_point(reading, List.last(acc), started_timestamp))
      end
    ) |> Enum.map(fn r -> %Result{x: r.x, y: r.y} end)
  end

  defp derivate_point(reading, nil, started_timestamp) do
    y = reading.ph
    x = reading.inserted_at
    d_time = NaiveDateTime.diff(started_timestamp, x)
    %PartialResult{x: x, y: y/d_time, reading: reading}
  end

  defp derivate_point(reading, last_value, _started_timestamp) do
    y = reading.ph - last_value.reading.y
    x = reading.inserted_at
    d_time = NaiveDateTime.diff(x, last_value.x)
    %PartialResult{x: x, y: y/d_time, reading: reading}
  end
end
