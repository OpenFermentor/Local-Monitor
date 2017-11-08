defmodule BioMonitor.CloudSync do
  @moduledoc """
    Module in charge of sending all the sync information to the cloud backend.
  """

  # @base_url "https://bio-monitor-staging.herokuapp.com/api"
  @base_url "http://localhost:3000/api"
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
