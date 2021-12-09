defmodule SiteWeb.VehicleChannel do
  @moduledoc """
  VehicleChannel module
  """
  use SiteWeb, :channel
  alias Leaflet.MapData.Marker
  alias Vehicles.Vehicle

  intercept(["reset", "add", "update", "remove"])

  @impl Phoenix.Channel
  def join("vehicles:" <> _params, %{}, socket) do
    {:ok, socket}
  end

  @impl Phoenix.Channel
  def handle_in("init", %{"route_id" => route_id, "direction_id" => direction_id}, socket) do
    vehicles = Vehicles.Repo.route(route_id, direction_id: String.to_integer(direction_id))
    push(socket, "data", %{event: "reset", data: Enum.map(vehicles, &build_marker/1)})
    {:noreply, socket}
  end

  @impl Phoenix.Channel
  def handle_out(event, %{data: vehicles}, socket) when event in ["reset", "add", "update"] do
    push(socket, "data", %{event: event, data: Enum.map(vehicles, &build_marker/1)})
    {:noreply, socket}
  end

  def handle_out("remove", %{data: ids}, socket) do
    push(socket, "data", %{
      event: "remove",
      data: ids
    })

    {:noreply, socket}
  end

  @type data_map :: %{
          required(:data) => %{vehicle: Vehicle.t(), stop_name: String.t()},
          required(:marker) => Marker.t()
        }
  @spec build_marker(Vehicles.Vehicle.t()) :: data_map
  def build_marker(%Vehicles.Vehicle{} = vehicle) do
    route = Routes.Repo.get(vehicle.route_id)
    stop_name = get_stop_name(vehicle.stop_id)
    trip = Schedules.Repo.trip(vehicle.trip_id)

    prediction =
      Predictions.Repo.all(
        route: vehicle.route_id,
        stop: vehicle.stop_id,
        trip: vehicle.trip_id,
        direction_id: vehicle.direction_id
      )
      |> List.first()

    %{
      data: %{vehicle: vehicle, stop_name: stop_name},
      marker:
        Marker.new(
          vehicle.latitude,
          vehicle.longitude,
          id: vehicle.id,
          icon: "vehicle-bordered-expanded",
          rotation_angle: vehicle.bearing,
          shape_id: trip && trip.shape_id,
          vehicle_crowding: vehicle.crowding,
          tooltip_text:
            %VehicleTooltip{
              prediction: prediction,
              vehicle: vehicle,
              route: route,
              stop_name: stop_name,
              trip: trip
            }
            |> VehicleHelpers.tooltip()
        )
    }
  end

  @spec get_stop_name(String.t() | nil) :: String.t()
  defp get_stop_name(nil) do
    ""
  end

  defp get_stop_name(stop_id) do
    case Stops.Repo.get(stop_id) do
      nil -> ""
      %Stops.Stop{name: name} -> name
    end
  end
end
