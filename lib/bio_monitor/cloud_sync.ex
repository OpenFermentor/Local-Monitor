defmodule BioMonitor.CloudSync do
  @moduledoc """
    Module in charge of sending all the sync information to the cloud backend.
  """

  # @base_url "https://bio-monitor-staging.herokuapp.com/api"
  @base_url "http://localhost:4000/api"

  def new_routine(routine) do
    HTTPoison.start
    case HTTPoison.post("#{@base_url}/routines", Poison.encode!(routine)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} -> :ok
      {:ok, _} -> :error
      {:error, _} -> :failed_to_connect
    end
  end

  def update_routine(routine, uid) do
    HTTPoison.start
    case HTTPoison.put("#{@base_url}/routines/#{uid}/sync_update", Poison.encode!(routine)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} -> :ok
      {:ok, _} -> :error
      {:error, _} -> :failed_to_connect
    end
  end

  def delete_routine(uid) do
    HTTPoison.start
    case HTTPoison.delete("#{@base_url}/routines/#{uid}/sync_delete") do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} -> :ok
      {:ok, _} -> :error
      {:error, _} -> :failed_to_connect
    end
  end

  def started_routine(params) do
    HTTPoison.start
    case HTTPoison.post("#{@base_url}/sync/started_routine", Poison.encode!(params)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} -> :ok
      {:ok, _} -> :error
      {:error, _} -> :failed_to_connect
    end
  end

  def stopped_routine(params) do
    HTTPoison.start
    case HTTPoison.post("#{@base_url}/sync/stopped_routine", Poison.encode!(params)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} -> :ok
      {:ok, _} -> :error
      {:error, _} -> :failed_to_connect
    end
  end

  def new_reading(params) do
    HTTPoison.start
    case HTTPoison.post("#{@base_url}/sync/new_reading", Poison.encode!(params)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} -> :ok
      {:ok, _} -> :error
      {:error, _} -> :failed_to_connect
    end
  end

  def alert(params) do
    HTTPoison.start
    case HTTPoison.post("#{@base_url}/sync/alert", Poison.encode!(params)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} -> :ok
      {:ok, _} -> :error
      {:error, _} -> :failed_to_connect
    end
  end

  def sensor_status(params) do
    HTTPoison.start
    case HTTPoison.post("#{@base_url}/sync/sensor_status", Poison.encode!(params)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} -> :ok
      {:ok, _} -> :error
      {:error, _} -> :failed_to_connect
    end
  end

  def sensor_error(params) do
    HTTPoison.start
    case HTTPoison.post("#{@base_url}/sync/sensor_error", Poison.encode!(params)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} -> :ok
      {:ok, _} -> :error
      {:error, _} -> :failed_to_connect
    end
  end

  def instruction(params) do
    HTTPoison.start
    case HTTPoison.post("#{@base_url}/sync/instruction", Poison.encode!(params)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} -> :ok
      {:ok, _} -> :error
      {:error, _} -> :failed_to_connect
    end
  end
end
