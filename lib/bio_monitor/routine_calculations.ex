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

  @doc """
    Calculates all biomass performance for each reading.
    returns: [{ x: seconds elapsed, y: dBiomass/dSubstratum}]
  """
  def biomass_performance(readings, started_timestamp) do
    readings |> Enum.reduce(
      [],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            acc |> List.insert_at(-1, %Result{x: time, y: (reading.biomass / reading.substratum)})
          last ->
            acc
            |> List.insert_at(
              -1,
              %Result{
                x: time,
                y: (reading.biomass - last.reading.biomass) / (reading.substratum - last.reading.substratum)
              }
            )
        end
      end
    )
  end

  @doc """
    Calculates all product performance for each reading.
    returns: [{ x: seconds elapsed, y: dBiomass/dProduct}]
  """
  def product_performance(readings, started_timestamp) do
    readings |> Enum.reduce(
      [],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            acc |> List.insert_at(-1, %Result{x: time, y: (reading.biomass / reading.product)})
          last ->
            acc
            |> List.insert_at(
              -1,
              %Result{
                x: time,
                y: (reading.biomass - last.reading.biomass) / (reading.product - last.reading.product)
              }
            )
        end
      end
    )
  end

  @doc """
    Calculates all performance for each reading.
    returns: [{ x: seconds elapsed, y: dProduct/dBiomass}]
  """
  # TODO: Rename this when rodrigo explains it's meaning
  def inverse_product_performance(readings, started_timestamp) do
    readings |> Enum.reduce(
      [],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            acc |> List.insert_at(-1, %Result{x: time, y: (reading.product / reading.biomass)})
          last ->
            acc
            |> List.insert_at(
              -1,
              %Result{
                x: time,
                y: (reading.product - last.reading.product) / (reading.biomass - last.reading.biomass)
              }
            )
        end
      end
    )
  end

  @doc """
    Calculates de Product Q for every point.
  """
  def product_q_values(readings, started_timestamp) do
    readings |> Enum.reduce(
      [],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            acc |> List.insert_at(-1, %Result{x: time, y: (reading.product / time)})
          last ->
            acc
            |> List.insert_at(
              -1,
              %Result{
                x: time,
                y: (reading.product - last.reading.product) / (time - last.x)
              }
            )
        end
      end
    )
  end

  @doc """
    Calculates de Biomass Q for every point.
  """
  def biomass_q_values(readings, started_timestamp) do
    readings |> Enum.reduce(
      [],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            acc |> List.insert_at(-1, %Result{x: time, y: (reading.biomass / time)})
          last ->
            acc
            |> List.insert_at(
              -1,
              %Result{
                x: time,
                y: (reading.biomass - last.reading.biomass) / (time - last.x)
              }
            )
        end
      end
    )
  end

  @doc """
    Calculates the maximum point for biomass performance
    using the biomass Q values calculated on the function defined before
  """
  def max_biomass_performance(biomass_results) do
    first_val = biomass_results |> List.first
    biomass_results
    |> Enum.reduce(
      first_val.y,
      fn result, acc ->
        case result.y > acc do
          true -> result.y
          false -> acc
        end
      end
    )
  end

  @doc """
    Calculates q sub ph for al points.
  """
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
