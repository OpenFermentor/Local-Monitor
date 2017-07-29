defmodule BioMonitor.SyncChannel do
  @moduledoc """
    Channel that handles the sync between the local monitor
    and the cloud backend.
  """
  use PhoenixChannelClient

  alias BioMonitor.RoutineMonitor
  alias BioMonitor.Repo
  alias BioMonitor.RoutineMonitor
  alias BioMonitor.Routine

  @started_msg "start"
  @stopped_msg "stopped"
  @new_routine_msg "new_routine"
  @update_routine_msg "update_routine"
  @delete_routine_msg "delete_routine"

  @doc """
    Handler for remote routine start.
    Receives the routine id.
    Fails if the routine is already started, or it does not exist.
  """
  def handle_in(@started_msg, %{"id" => id}, state) do
    with routine = Repo.get(Routine, id),
      running = RoutineMonitor.is_running?(),
      true <- routine != nil,
      {:ok, false} <- running,
      :ok <- RoutineMonitor.start_routine(routine)
    do
      IO.puts("routine started remotely")
      {:noreply, state}
    else
      false ->
        IO.puts("Routine not found")
        {:noreply, state}
      {:error, _, message} ->
        IO.puts(message)
        {:noreply, state}
      {:ok, true} ->
        IO.puts("Already running another routine")
        {:noreply, state}
      _ ->
        IO.puts("Uknown error")
        {:noreply, state}
    end
  end

  def handle_in(@stopped_msg, _payload, state) do
    RoutineMonitor.stop_routine()
    IO.puts("Stopped routine")
    {:noreply, state}
  end

  def handle_in(@update_routine_msg, routine_params, state) do
    IO.puts("New update for routine id #{routine_params.id}")
    with routine = Repo.get(Routine, routine_params.id),
      true <- routine != nil,
      changeset = Routine.changeset(routine, routine_params),
      {:ok, routine} <- Repo.update(changeset)
    do
      IO.puts("Successfuly updated routine with id #{routine.id}")
      {:noreply, state}
    else
      {:error, _changeset} ->
        IO.puts("Error while updating routine")
        {:noreply, state}
    end
    {:noreply, state}
  end

  def handle_in(@delete_routine_msg, %{"id" => id}, state) do
    IO.puts("Delete routine with id #{id}")
    with routine = Repo.get!(Routine, id),
      true <- routine != nil,
      {:ok, struct} <- Repo.delete(routine)
    do
      IO.puts("Successfuly deleted routine with id #{struct.id}")
      {:noreply, state}
    else
      _ ->
        IO.puts("Failed to delete routine")
        {:noreply, state}
    end
  end

  def handle_in(@new_routine_msg, routine_params, state) do
    IO.puts("New routine #{routine_params.title}")
    changeset = Routine.changeset(%Routine{}, routine_params)
    case Repo.insert(changeset) do
      {:ok, routine} ->
        IO.puts("Successfuly saved routine #{routine.id}")
        {:noreply, state}
      {:error, _changeset} ->
        IO.puts("Failed to create routine.")
        {:noreply, state}
    end
  end

  def handle_reply({:ok, :join, _payload, _ref}, state) do
    IO.puts("Successfuly joined channel")
    {:noreply, state}
  end

  def handle_reply({:error, message, _payload, _ref}, state) do
    IO.puts("Unexpected error on reply #{message}")
    {:noreply, state}
  end

  def handle_reply({:timeout, :join, _ref}, state) do
    IO.puts("Join Timed out.")
    {:noreply, state}
  end

  def handle_reply({:timeout, message, _ref}, state) do
    IO.puts("Message #{message} Timed out.")
    {:noreply, state}
  end

  def handle_close(_reason, state) do
    IO.puts("Channel closed")
    {:noreply, state}
  end
end
