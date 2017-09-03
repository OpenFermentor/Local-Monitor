defmodule BioMonitor.PhControllerTest do
  use BioMonitor.ConnCase

  @moduledoc """
    Test cases for PhController
    The commented tests won't pass unless the board is connected.
  """

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  # test "returns current ph value", %{conn: conn} do
  #   conn = get conn, ph_path(conn, :current)
  #   assert json_response(conn, 200)["current_value"] != nil
  # end

  # test "sets offset ph value", %{conn: conn} do
  #   conn = get conn, ph_path(conn, :current, %{"offset" => "#{0.3}"})
  #   assert json_response(conn, 200)["current_value"] != nil
  # end

  test "fails to return current ph value", %{conn: conn} do
    conn = get conn, ph_path(conn, :current)
    assert response(conn, 422)
  end

  test "sets base offset ph value", %{conn: conn} do
    conn = post conn, ph_path(conn, :set_base, %{})
    assert response(conn, 422)
  end

  test "sets acid offset ph value", %{conn: conn} do
    conn = post conn, ph_path(conn, :set_acid, %{})
    assert response(conn, 422)
  end

  test "sets neutral offset ph value", %{conn: conn} do
    conn = post conn, ph_path(conn, :set_neutral, %{})
    assert response(conn, 422)
  end

end
