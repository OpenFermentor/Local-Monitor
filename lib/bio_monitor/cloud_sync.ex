defmodule BioMonitor.CloudSync do
  @moduledoc """
    Module in charge of sending all the sync information to the cloud backend.
  """

   @base_url "https://bio-monitor-staging.herokuapp.com/api"
  # @base_url "http://localhost:2000/api"
  @headers [Accept: "application/json", "Content-Type": "application/json"]

  def new_routine(routine) do
    case HTTPotion.post("#{@base_url}/routines", [body: Poison.encode!(routine), headers: @headers]) do
      %HTTPotion.Response{body: _body, status_code: _status} -> :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
      _ -> :error
    end
  end

  def update_routine(routine, uid) do
    case HTTPotion.put("#{@base_url}/routines/#{uid}/sync_update", [body: Poison.encode!(routine), headers: @headers]) do
      %HTTPotion.Response{body: _body, status_code: _status} -> :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
      _ -> :error
    end
  end

  def delete_routine(uid) do
    case HTTPotion.delete("#{@base_url}/routines/#{uid}/sync_delete", [headers: @headers]) do
      %HTTPotion.Response{body: _body, status_code: _status} -> :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
      _ -> :error
    end
  end

  def started_routine(params) do
    case HTTPotion.post("#{@base_url}/sync/started_routine", [body: Poison.encode!(params), headers: @headers]) do
      %HTTPotion.Response{body: _body, status_code: _status} -> :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
      _ -> :error
    end
  end

  def stopped_routine(params) do
    case HTTPotion.post("#{@base_url}/sync/stopped_routine", [body: Poison.encode!(params), headers: @headers]) do
      %HTTPotion.Response{body: _body, status_code: _status} -> :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
      _ -> :error
    end
  end

  def new_reading(params) do
    case HTTPotion.post("#{@base_url}/sync/new_reading", [body: Poison.encode!(params), headers: @headers]) do
      %HTTPotion.Response{body: _body, status_code: _status} -> :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
      _ -> :error
    end
  end


  def batch_reading_sync(uid, readings) do
    case HTTPotion.post("#{@base_url}/sync/all_readings", [body: Poison.encode!(%{routine_uuid: uid, readings: encode_readings(uid, readings)}), headers: @headers]) do
      %HTTPotion.Response{body: body, status_code: status} ->
        IO.puts "Batch sync"
        IO.inspect status
        IO.inspect body
        :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
        IO.inspect :failed_to_connect
      _ ->
        IO.inspect "Uknown error"
        :error
    end
  end

  def alert(params) do
    case HTTPotion.post("#{@base_url}/sync/alert", [body: Poison.encode!(params), headers: @headers]) do
      %HTTPotion.Response{body: _body, status_code: _status} -> :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
      _ -> :error
    end
  end

  def sensor_status(params) do
    case HTTPotion.post("#{@base_url}/sync/sensor_status", [body: Poison.encode!(params), headers: @headers]) do
      %HTTPotion.Response{body: _body, status_code: _status} -> :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
      _ -> :error
    end
  end

  def sensor_error(params) do
    case HTTPotion.post("#{@base_url}/sync/sensor_error", [body: Poison.encode!(params), headers: @headers]) do
      %HTTPotion.Response{body: _body, status_code: _status} -> :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
      _ -> :error
    end
  end

  def instruction(params) do
    case HTTPotion.post("#{@base_url}/sync/instruction", [body: Poison.encode!(params), headers: @headers]) do
      %HTTPotion.Response{body: _body, status_code: _status} -> :ok
      %HTTPotion.ErrorResponse{message: _message} -> :failed_to_connect
      _ -> :error
    end
  end

  defp encode_readings(uuid, readings) do
    readings |> Enum.map(fn reading ->
      %{
        routine_uuid: uuid,
        id: reading.id,
        temp: reading.temp,
        ph: reading.ph,
        product: reading.product,
        biomass: reading.biomass,
        substratum: reading.substratum,
        inserted_at: reading.inserted_at
      }
    end)
  end

  def routine_to_map(routine) do
    %{
      "routine" => %{
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
        tags: render_tags(routine),
        trigger_for: routine.trigger_for,
        trigger_after: routine.trigger_after,
    }
  }
  end

  defp render_tags(routine) do
    routine.tags
    |> Enum.map(fn tag ->
      %{value: tag.value}
    end)
  end

  defp render_temp_ranges(routine) do
    routine.temp_ranges
    |> Enum.map(fn range ->
      %{temp: range.temp, from_second: range.from_second}
    end)
  end
end
