defmodule Vehicles.Parser do
  @moduledoc false
  alias Vehicles.Vehicle

  @spec parse(JsonApi.Item.t()) :: Vehicle.t()
  def parse(%JsonApi.Item{id: id, attributes: attributes, relationships: relationships}) do
    %Vehicle{
      id: id,
      route_id: optional_id(relationships["route"]),
      trip_id: optional_id(relationships["trip"]),
      shape_id: shape(relationships["trip"]),
      stop_id: stop_id(relationships["stop"]),
      direction_id: attributes["direction_id"],
      status: status(attributes["current_status"]),
      longitude: attributes["longitude"],
      latitude: attributes["latitude"],
      bearing: attributes["bearing"] || 0,
      crowding: crowding(attributes["occupancy_status"])
    }
  end

  @spec status(String.t()) :: Vehicle.status()
  defp status("STOPPED_AT"), do: :stopped
  defp status("INCOMING_AT"), do: :incoming
  defp status("IN_TRANSIT_TO"), do: :in_transit

  @spec optional_id([JsonApi.Item.t()]) :: String.t() | nil
  defp optional_id([]), do: nil
  defp optional_id([%JsonApi.Item{id: id}]), do: id

  @spec stop_id([JsonApi.Item.t()]) :: Stops.Stop.id_t() | nil
  defp stop_id([%JsonApi.Item{id: stop_id}]) do
    case Stops.Repo.get_parent(stop_id) do
      %Stops.Stop{id: id} -> id
      _ -> nil
    end
  end

  defp stop_id(_) do
    nil
  end

  @spec shape([JsonApi.Item.t()]) :: Routes.Shape.id_t() | nil
  defp shape([%JsonApi.Item{id: trip_id}]) do
    case Schedules.Repo.trip(trip_id) do
      %Schedules.Trip{shape_id: id} -> id
      _ -> nil
    end
  end

  defp shape(_) do
    nil
  end

  @spec crowding(String.t()) :: Vehicle.crowding() | nil
  defp crowding("MANY_SEATS_AVAILABLE"), do: :not_crowded
  defp crowding("FEW_SEATS_AVAILABLE"), do: :some_crowding
  defp crowding("FULL"), do: :crowded
  defp crowding(_), do: nil
end
