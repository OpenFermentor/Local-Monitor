defmodule BioMonitor.RoutineMessageBroker do
  @moduledoc """
    Wrapper module around all channel
    communication for all routine related operations.
  """
  @channel "routine"
  @started_msg "started"
  @stopped_msg "stopped"
  @update_msg "update"
  @alert_msg "alert"
  @sensors_channel "sensors"
  @status_msg "status"
  @error_msg "error"

  alias BioMonitor.Endpoint
  alias BioMonitor.SyncServer

  def send_sensor_error(message) do
    Endpoint.broadcast(
        @sensors_channel,
        @error_msg,
        %{message: message}
      )
    SyncServer.send(@error_msg, message)
  end

  def send_routine_error(message) do
    Endpoint.broadcast(
      @channel,
      @alert_msg,
      %{message: message}
    )
    SyncServer.send(@alert_msg, message)
  end

  def send_start(routine) do
    Endpoint.broadcast(
      @channel,
      @started_msg,
      %{message: "Started routine", routine: routine_to_map(routine)}
    )
    SyncServer.send(@started_msg, routine_to_map(routine))
  end

  def send_stop(routine) do
    Endpoint.broadcast(
      @channel,
      @stopped_msg,
      %{message: "Stopped routine", routine: routine_to_map(routine)}
    )
    SyncServer.send(@stopped_msg, routine_to_map(routine))
  end

  def send_status(status) do
    Endpoint.broadcast(
      @sensors_channel,
      @status_msg,
      status
    )
    SyncServer.send(@status_msg, status)
  end

  def send_reading(reading, routine) do
    Endpoint.broadcast(@channel, @update_msg, reading_to_map(reading, routine))
    SyncServer.send(@update_msg, reading_to_map(reading, routine))
  end

  def send_reading_changeset_error(changeset) do
    Endpoint.broadcast(
      @channel,
      @alert_msg,
      %{
        message: "Error while saving the reading",
        errors: changeset.errors
      }
    )
    SyncServer.send(
      @alert_msg,
      %{
        message: "Error while saving the reading",
        errors: changeset.errors
      }
    )
  end

  def send_reading_error(message) do
    Endpoint.broadcast(
      @channel,
      @alert_msg,
      %{
        message: "Error while saving the reading",
        errors: [message]
      }
    )
    SyncServer.send(
      @alert_msg,
      %{
        message: "Error while saving the reading",
        errors: [message]
      }
    )
  end

  defp reading_to_map(reading, routine) do
    %{
      routine_id: routine.id,
      id: reading.id,
      temp: reading.temp,
      inserted_at: reading.inserted_at
    }
  end

  defp routine_to_map(routine) do
    %{
      id: routine.id,
      target_temp: routine.target_temp,
      inserted_at: routine.inserted_at
    }
  end
end
