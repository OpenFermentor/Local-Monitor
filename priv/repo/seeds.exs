# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     BioMonitor.Repo.insert!(%BioMonitor.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.


routine = BioMonitor.Routine.changeset(%BioMonitor.Routine{}, %{
  title: "Fermentación E.Coli en medio de hongos",
  estimated_time_seconds: 28_800_000,
  extra_notes: "Fermentación de prueba para el fermentador automatizado.",
  medium: "Medio de nutrientes consistente de hongos",
  strain: "E.Coli 123",
  target_ph: 6,
  target_temp: 35,
  target_density: 0,
  balance_ph: true,
  loop_delay: 900_000,
  triger_after: 7_200_000,
  trigger_for: 60_000,
  temp_ranges: [
    %{
      temp: 38,
      from_second: 3600
    },
    %{
      temp: 32,
      from_second: 7200
    }
  ],
  tags: [ %{value: "E.Coli"}, %{value: "Juan"}]
}) |> BioMonitor.Repo.insert!()

routine = routine |> BioMonitor.Repo.preload([:temp_ranges, :tags, :log_entries, :readings])
BioMonitor.Routine.started_changeset(routine, %{started: true, started_date: DateTime.utc_now}) |> BioMonitor.Repo.update!()

# ==================== 1st hour ===================================

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 31,
  ph: 6,
  biomass: 20,
  substratum: 23,
  product: 34
}) |> BioMonitor.Repo.insert!()
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "La temperatura esta por debajo del rango establecido.")

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 21,
  substratum: 22,
  product: 37
}) |> BioMonitor.Repo.insert!()
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "La temperatura esta por debajo del rango establecido.")

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 34,
  ph: 6,
}) |> BioMonitor.Repo.insert!()
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "La temperatura esta por debajo del rango establecido.")

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 35,
  ph: 6,
  biomass: 25,
  substratum: 29,
  product: 20
}) |> BioMonitor.Repo.insert!()
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.temp_change, "Cambio de temperatura objetivo a 37 grados.")

:timer.sleep(2000)

# ============================ 2nd hour ================================================================================================

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 36,
  ph: 6,
  biomass: 30,
  substratum: 33,
  product: 36
}) |> BioMonitor.Repo.insert!()
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "La temperatura esta por debajo del rango establecido.")

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 36.5,
  ph: 6,
  biomass: 35,
  substratum: 36,
  product: 38
}) |> BioMonitor.Repo.insert!()
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "La temperatura esta por debajo del rango establecido.")

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 37,
  ph: 6,
  biomass: 40,
  substratum: 39,
  product: 40
}) |> BioMonitor.Repo.insert!()

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 37,
  ph: 5,
  biomass: 45,
  substratum: 39,
  product: 40
}) |> BioMonitor.Repo.insert!()
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "El ph esta por debajo del rango establecido.")
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.base_cal, "Balanceando el ph a base.")
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.temp_change, "Cambio de temperatura objetivo a 32 grados.")

:timer.sleep(2000)

# ======================== 3rd hour ===============================================

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 35,
  ph: 5.5,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "La temperatura esta por encima del rango establecido.")
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "El ph esta por debajo del rango establecido.")
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.base_cal, "Balanceando el ph a base.")

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 34.5,
  ph: 5.8,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "La temperatura esta por encima del rango establecido.")
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "El ph esta por debajo del rango establecido.")
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.base_cal, "Balanceando el ph a base.")

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 33,
  ph: 6.1,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()
BioMonitor.Routine.log_entry(routine, BioMonitor.Routine.log_types.reading_error, "La temperatura esta por encima del rango establecido.")

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32.5,
  ph: 6.1,
  biomass: 51,
  substratum: 41,
  product: 42
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

# =============== 4th hour =====================================
BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

# =============== 5th hour =====================================
BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

# =============== 6th hour =====================================
BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 50,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

# =============== 7th hour =====================================
BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 45,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 40,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 38,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
  biomass: 36,
  substratum: 40,
  product: 41
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

# =============== 8th hour =====================================
BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
}) |> BioMonitor.Repo.insert!()

:timer.sleep(2000)

BioMonitor.Reading.changeset(%BioMonitor.Reading{}, %{
  routine_id: routine.id,
  temp: 32,
  ph: 6,
}) |> BioMonitor.Repo.insert!()
