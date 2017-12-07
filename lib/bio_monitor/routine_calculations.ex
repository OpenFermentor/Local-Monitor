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
    readings
    |> Enum.filter(fn reading ->
      reading.biomass != nil && reading.biomass != 0 && reading.substratum != nil && reading.substratum != 0
    end)
    |> Enum.reduce(
      [],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            acc |> List.insert_at(-1, %PartialResult{x: time, y: (reading.biomass / reading.substratum), reading: reading})
          last ->
            acc
            |> List.insert_at(
              -1,
              %PartialResult{
                x: time,
                y: (reading.biomass - last.reading.biomass) / (reading.substratum - last.reading.substratum),
                reading: reading
              }
            )
        end
      end
    )  |> Enum.map(fn partial_result -> %Result{x: partial_result.x, y: partial_result.y} end)
  end

  @doc """
    Calculates all product performance for each reading.
    returns: [{ x: seconds elapsed, y: dBiomass/dProduct}]
  """
  def product_performance(readings, started_timestamp) do
    readings
    |> Enum.filter(fn reading ->
      reading.biomass != nil && reading.biomass != 0 && reading.product != nil && reading.product != 0
    end)
    |> Enum.reduce(
      [],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            acc |> List.insert_at(-1, %PartialResult{x: time, y: (reading.biomass / reading.product), reading: reading})
          last ->
            acc
            |> List.insert_at(
              -1,
              %PartialResult{
                x: time,
                y: (reading.biomass - last.reading.biomass) / (reading.product - last.reading.product),
                reading: reading
              }
            )
        end
      end
    )  |> Enum.map(fn partial_result -> %Result{x: partial_result.x, y: partial_result.y} end)
  end

  @doc """
    Calculates all performance for each reading.
    returns: [{ x: seconds elapsed, y: dProduct/dBiomass}]
  """
  def inverse_product_performance(readings, started_timestamp) do
    readings
    |> Enum.filter(fn reading ->
      reading.biomass != nil && reading.biomass != 0 && reading.product != nil && reading.product != 0
    end)
    |> Enum.reduce(
      [],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            acc |> List.insert_at(-1, %PartialResult{x: time, y: (reading.product / reading.biomass), reading: reading})
          last ->
            acc
            |> List.insert_at(
              -1,
              %PartialResult{
                x: time,
                y: (reading.product - last.reading.product) / (reading.biomass - last.reading.biomass),
                reading: reading
              }
            )
        end
      end
    ) |> Enum.map(fn partial_result -> %Result{x: partial_result.x, y: partial_result.y} end)
  end

  @doc """
    Calculates de Product Q for every point.
  """
  def product_q_values(readings, started_timestamp) do
    readings
    |> Enum.filter(fn reading ->
      reading.product != nil && reading.product != 0
    end)
    |> Enum.reduce(
      [],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            acc |> List.insert_at(-1, %PartialResult{x: time, y: (reading.product / time), reading: reading})
          last ->
            acc
            |> List.insert_at(
              -1,
              %PartialResult{
                x: time,
                y: (reading.product - last.reading.product) / (time - last.x),
                reading: reading
              }
            )
        end
      end
    ) |> Enum.map(fn partial_result -> %Result{x: partial_result.x, y: partial_result.y} end)
  end

  @doc """
    Calculates de Biomass Q for every point.
  """
  def biomass_q_values(readings, started_timestamp) do
    readings
    |> Enum.filter(fn reading ->
      reading.biomass != nil && reading.biomass != 0
    end)
    |> Enum.reduce(
      [],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            acc |> List.insert_at(-1, %PartialResult{x: time, y: (reading.biomass / time), reading: reading})
          last ->
            acc
            |> List.insert_at(
              -1,
              %PartialResult{
                x: time,
                y: (reading.biomass - last.reading.biomass) / (time - last.x),
                reading: reading
              }
            )
        end
      end
    ) |> Enum.map(fn partial_result -> %Result{x: partial_result.x, y: partial_result.y} end)
  end

  @doc """
    Calculates de specific ph velocity for each reading.
  """
  def specific_ph_velocity(readings, started_timestamp) do
    results = readings |> Enum.reduce([],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            result = %PartialResult{
              y: (1/reading.ph),
              x: time,
              reading: reading
            }
            acc |> List.insert_at(-1, result)
          last_val ->
            result = %PartialResult{
              y: (1/(reading.ph - last_val.reading.ph)),
              x: time,
              reading: reading
            }
            acc |> List.insert_at(-1, result)
        end
      end
    )
    results.results
    |> Enum.map(fn partial_result ->
      %Result{x: partial_result.x, y: partial_result.y}
    end)
  end

  @doc """
    Calculates de specific biomass velocity for each reading.
  """
  def specific_biomass_velocity(readings, started_timestamp) do
    results = readings |> Enum.reduce([],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            result = %PartialResult{
              y: (1/reading.biomass),
              x: time,
              reading: reading
            }
            acc |> List.insert_at(-1, result)
          last_val ->
            result = %PartialResult{
              y: (1/(reading.biomass - last_val.reading.biomass)),
              x: time,
              reading: reading
            }
            acc |> List.insert_at(-1, result)
        end
      end
    )
    results.results
    |> Enum.map(fn partial_result ->
      %Result{x: partial_result.x, y: partial_result.y}
    end)
  end

  @doc """
    Calculates de specific product velocity for each reading.
  """
  def specific_product_velocity(readings, started_timestamp) do
    results = readings |> Enum.reduce([],
      fn reading, acc ->
        last_value = acc |> List.last
        time = NaiveDateTime.diff(reading.inserted_at, started_timestamp)
        case last_value do
          nil ->
            result = %PartialResult{
              y: (1/reading.product),
              x: time,
              reading: reading
            }
            acc |> List.insert_at(-1, result)
          last_val ->
            result = %PartialResult{
              y: (1/(reading.product - last_val.reading.product)),
              x: time,
              reading: reading
            }
            acc |> List.insert_at(-1, result)
        end
      end
    )
    results.results
    |> Enum.map(fn partial_result ->
      %Result{x: partial_result.x, y: partial_result.y}
    end)
  end

  @doc """
    Calculates de maximium point for a list of Results by comparing it's y values.
    Returns a %Result with the value and the time it happened.
  """
  def calculate_max_point(results) do
    first_val = results |> List.first
    results
    |> Enum.reduce(
      first_val,
      fn result, acc ->
        case result.y > acc.y do
          true -> result
          false -> acc
        end
      end
    )
  end
end
