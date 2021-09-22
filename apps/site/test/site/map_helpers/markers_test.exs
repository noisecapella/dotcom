defmodule Site.MapHelpers.MarkersTest do
  use ExUnit.Case, async: true
  alias GoogleMaps.MapData.{Marker, Symbol}
  alias Site.MapHelpers.Markers

  @route %Routes.Route{
    description: :rapid_transit,
    direction_names: %{0 => "South", 1 => "North"},
    id: "Red",
    long_name: "Red Line",
    name: "Red Line",
    type: 1,
    color: "DA291C",
    sort_order: 1
  }

  @stop %Stops.Stop{
    accessibility: ["accessible"],
    address: nil,
    closed_stop_info: nil,
    has_charlie_card_vendor?: false,
    has_fare_machine?: false,
    id: "place-sstat",
    is_child?: true,
    latitude: 42.352271,
    longitude: -71.055242,
    name: "South Station",
    note: nil,
    parking_lots: [],
    station?: false
  }

  @trip %Schedules.Trip{
    direction_id: 1,
    headsign: "Alewife",
    id: "ADDED-1538504683",
    name: "",
    shape_id: nil
  }

  @prediction %Predictions.Prediction{
    departing?: true,
    direction_id: 1,
    id: "prediction-ADDED-1538504683-70080-130",
    route: @route,
    schedule_relationship: :added,
    status: nil,
    stop: @stop,
    stop_sequence: 130,
    track: nil,
    trip: @trip
  }

  @vehicle %Vehicles.Vehicle{
    direction_id: 1,
    id: "R-54588CCE",
    latitude: 42.343658447265625,
    longitude: -71.05690002441406,
    route_id: "Red",
    shape_id: nil,
    status: :in_transit,
    stop_id: "place-sstat",
    trip_id: "ADDED-1538504683",
    bearing: 130
  }

  @bad_stop_vehicle %Vehicles.Vehicle{
    direction_id: 1,
    id: "R-54588CCE",
    latitude: 42.343658447265625,
    longitude: -71.05690002441406,
    route_id: "Red",
    shape_id: nil,
    status: :in_transit,
    stop_id: "not-real",
    trip_id: "ADDED-1538504683",
    bearing: 130
  }

  describe "stop/2" do
    test "builds data for a stop icon" do
      assert %Marker{
               latitude: latitude,
               longitude: longitude,
               id: id,
               size: :tiny,
               icon: "000000-dot",
               tooltip: tooltip
             } = Markers.stop(@stop, false)

      assert latitude == @stop.latitude
      assert longitude == @stop.longitude
      assert id == "stop-" <> @stop.id
      assert tooltip == @stop.name

      assert %Marker{
               icon: "000000-dot-filled"
             } = Markers.stop(@stop, true)
    end
  end
end
