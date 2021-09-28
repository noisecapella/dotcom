defmodule SiteWeb.ScheduleController.VehicleTooltips do
  @moduledoc """
  Assigns :vehicle_tooltips based on previously requested :route, and :vehicle_locations
  """
  @behaviour Plug
  import Plug.Conn, only: [assign: 3]

  @impl true
  def init([]), do: []

  @impl true
  def call(conn, []) do
    Util.log_duration(__MODULE__, :do_call, [conn])
  end

  def do_call(conn) do
    assign(
      conn,
      :vehicle_tooltips,
      VehicleHelpers.build_tooltip_index(
        conn.assigns.route,
        conn.assigns.vehicle_locations
      )
    )
  end
end
