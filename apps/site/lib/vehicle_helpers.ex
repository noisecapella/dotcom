defmodule VehicleHelpers do
  @moduledoc """
  Various functions for working on lists of vehicle to show on a map, or render tooltips.
  """
  alias Vehicles.Vehicle
  alias Predictions.Prediction
  alias Routes.{Route, Shape}
  alias Stops.Stop
  alias Schedules.Trip
  alias SiteWeb.ScheduleController.VehicleLocations

  import Routes.Route, only: [vehicle_name: 1]
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]
  import SiteWeb.TimeHelpers, only: [format_schedule_time: 1]

  @type tooltip_index_key :: {Trip.id_t() | nil, Stop.id_t()} | Stop.id_t()
  @type tooltip_index :: %{
          optional({Trip.id_t() | nil, Stop.id_t()}) => VehicleTooltip.t(),
          optional(Stop.id_t()) => VehicleTooltip.t()
        }

  @doc """
  There are multiple places where vehicle tooltips are used. This function is called from the controller to
  construct a convenient map that can be used in views / templates to determine if a tooltip is available
  and to fetch all of the required data
  """
  @spec build_tooltip_index(Route.t(), VehicleLocations.t(), [Prediction.t()]) :: tooltip_index
  def build_tooltip_index(route, vehicle_locations, vehicle_predictions) do
    indexed_predictions = index_vehicle_predictions(vehicle_predictions)

    vehicle_locations
    |> Stream.reject(fn {{_trip_id, stop_id}, _status} -> is_nil(stop_id) end)
    |> Enum.reduce(%{}, fn vehicle_location, output ->
      {{trip_id, child_stop_id}, vehicle_status} = vehicle_location

      {prediction, trip} =
        if trip_id do
          {
            prediction_for_stop(indexed_predictions, trip_id, child_stop_id),
            Schedules.Repo.trip(trip_id)
          }
        else
          {nil, nil}
        end

      parent_stop = Stops.Repo.get_parent(child_stop_id)
      stop_id = stop_id(parent_stop, child_stop_id)

      tooltip = %VehicleTooltip{
        vehicle: vehicle_status,
        prediction: prediction,
        stop_name: stop_name(parent_stop),
        trip: trip,
        route: route
      }

      output
      |> Map.put(stop_id, tooltip)
      |> Map.put({trip_id, stop_id}, tooltip)
    end)
  end

  @spec prediction_for_stop(VehicleLocations.t(), String.t(), String.t()) :: Prediction.t() | nil
  defp prediction_for_stop(vehicle_predictions, trip_id, stop_id) do
    Map.get(vehicle_predictions, {trip_id, stop_id})
  end

  @spec index_vehicle_predictions([Prediction.t()]) :: %{
          {String.t(), String.t()} => Prediction.t()
        }
  defp index_vehicle_predictions(predictions) do
    predictions
    |> Stream.filter(&(&1.trip && &1.stop))
    |> Stream.map(&{{&1.trip.id, &1.stop.id}, &1})
    |> Enum.into(Map.new())
  end

  @spec stop_name(Stops.Stop.t() | nil) :: String.t()
  defp stop_name(nil), do: ""
  defp stop_name(stop), do: stop.name

  @spec stop_id(Stops.Stop.t() | nil, String.t()) :: String.t()
  defp stop_id(nil, child_stop_id), do: child_stop_id
  defp stop_id(stop, _), do: stop.id

  @doc """
  Get polylines for vehicles that didn't already have their shape included when the route polylines were requested
  """
  @spec get_vehicle_polylines(VehicleLocations.t(), [Shape.t()]) :: [String.t()]
  def get_vehicle_polylines(locations, route_shapes) do
    vehicle_shape_ids = vehicle_shape_ids(locations)
    route_shape_ids = MapSet.new(route_shapes, & &1.id)

    vehicle_shape_ids
    |> MapSet.difference(route_shape_ids)
    |> Enum.map(&Routes.Repo.get_shape(&1))
    |> Enum.flat_map(fn
      [] ->
        []

      [%Shape{} = shape | _] ->
        [shape.polyline]
    end)
  end

  @spec vehicle_shape_ids(VehicleLocations.t()) :: MapSet.t()
  defp vehicle_shape_ids(locations) do
    for {_, value} <- locations,
        is_binary(value.shape_id),
        into: MapSet.new() do
      value.shape_id
    end
  end

  @doc """
  Function used to return tooltip text for a VehicleTooltip struct
  """
  @spec tooltip(VehicleTooltip.t() | nil) :: Phoenix.HTML.Safe.t()
  def tooltip(nil) do
    ""
  end

  def tooltip(%{
        prediction: prediction,
        vehicle: vehicle,
        trip: trip,
        stop_name: stop_name,
        route: route
      }) do
    # Get stop name from vehicle if present, otherwise use provided predicted stop_name
    stop_name =
      if vehicle.stop_id do
        case Stops.Repo.get_parent(vehicle.stop_id) do
          nil -> stop_name
          %Stops.Stop{name: name} -> name
        end
      else
        stop_name
      end

    time_text = prediction_time_text(prediction)
    status_text = prediction_status_text(prediction)
    stop_text = realtime_stop_text(trip, stop_name, vehicle, route)
    build_tooltip(time_text, status_text, stop_text)
  end

  @spec prediction_status_text(Prediction.t() | nil) :: iodata
  defp prediction_status_text(%Prediction{status: status, track: track})
       when not is_nil(track) and not is_nil(status) do
    [String.capitalize(status), " on track ", track]
  end

  defp prediction_status_text(_) do
    []
  end

  @spec prediction_time_text(Prediction.t() | nil) :: iodata
  defp prediction_time_text(nil) do
    []
  end

  defp prediction_time_text(%Prediction{time: nil}) do
    []
  end

  defp prediction_time_text(%Prediction{time: time, departing?: true}) do
    ["Expected departure at ", format_schedule_time(time)]
  end

  defp prediction_time_text(%Prediction{time: time}) do
    ["Expected arrival at ", format_schedule_time(time)]
  end

  @spec realtime_stop_text(Trip.t() | nil, String.t(), Vehicle.t() | nil, Route.t()) :: iodata
  defp realtime_stop_text(trip, stop_name, %Vehicle{status: status}, route) do
    [
      display_headsign_text(route, trip),
      String.downcase(vehicle_name(route)),
      display_trip_name(route, trip)
    ] ++
      realtime_status_with_stop(status, stop_name)
  end

  @spec display_headsign_text(Route.t(), Trip.t() | nil) :: iodata
  defp display_headsign_text(_, %{headsign: headsign}), do: [headsign, " "]
  defp display_headsign_text(%{name: name}, _), do: [name, " "]
  defp display_headsign_text(_, _), do: ""

  @spec realtime_status_with_stop(atom, String.t()) :: iodata()
  defp realtime_status_with_stop(_status, "") do
    []
  end

  defp realtime_status_with_stop(status, stop_name) do
    [
      realtime_status_text(status),
      stop_name
    ]
  end

  @spec realtime_status_text(atom) :: String.t()
  defp realtime_status_text(:incoming), do: " is arriving at "
  defp realtime_status_text(:stopped), do: " has arrived at "
  defp realtime_status_text(:in_transit), do: " is on the way to "

  @spec display_trip_name(Route.t(), Trip.t() | nil) :: iodata
  defp display_trip_name(%{type: 2}, %{name: name}), do: [" ", name]
  defp display_trip_name(_, _), do: ""

  @spec build_tooltip(iodata, iodata, iodata) :: String.t()
  defp build_tooltip(time_text, status_text, stop_text) do
    time_tag = do_build_tooltip(time_text)
    status_tag = do_build_tooltip(status_text)
    stop_tag = do_build_tooltip(stop_text)

    :div
    |> content_tag([stop_tag, time_tag, status_tag])
    |> safe_to_string
    |> String.replace(~s("), ~s('))
  end

  @spec do_build_tooltip(iodata) :: Phoenix.HTML.Safe.t()
  defp do_build_tooltip([]) do
    ""
  end

  defp do_build_tooltip(text) do
    content_tag(:p, text, class: 'prediction-tooltip')
  end
end
