defmodule SiteWeb.VehicleChannelTest do
  use SiteWeb.ChannelCase

  alias Leaflet.MapData.Marker
  alias SiteWeb.{VehicleChannel, UserSocket}
  alias Vehicles.Vehicle
  import Mock

  @vehicles [
    %Vehicle{
      id: "1",
      route_id: "CR-Lowell",
      direction_id: 0,
      stop_id: "BNT-0000-01",
      status: :in_transit,
      trip_id: "trip"
    }
  ]

  test "sends vehicles and marker data" do
    # subscribes to a random channel name to
    # avoid receiving real data in assert_push
    assert {:ok, _, socket} =
             UserSocket
             |> socket("", %{some: :assign})
             |> subscribe_and_join(VehicleChannel, "vehicles:VehicleChannelTest")

    [vehicle | _] = @vehicles

    assert {:noreply, %Phoenix.Socket{}} =
             VehicleChannel.handle_out("reset", %{data: @vehicles}, socket)

    assert_push("data", vehicles)

    assert %{data: [vehicle_with_marker | _]} = vehicles

    assert %{
             data: %{stop_name: _, vehicle: ^vehicle},
             marker: %Marker{}
           } = vehicle_with_marker
  end

  test "sends vehicle ids for remove event" do
    assert {:ok, _, socket} =
             UserSocket
             |> socket("", %{some: :assign})
             |> subscribe_and_join(VehicleChannel, "vehicles:VehicleChannelTest2")

    assert {:noreply, %Phoenix.Socket{}} =
             VehicleChannel.handle_out("remove", %{data: ["vehicle_id"]}, socket)

    assert_push("data", vehicles)

    assert vehicles == %{data: ["vehicle_id"], event: "remove"}
  end

  test "responds to init push by sending data" do
    assert {:ok, _, socket} =
             UserSocket
             |> socket("", %{some: :assign})
             |> subscribe_and_join(VehicleChannel, "vehicles:VehicleChannelTest3")

    assert {:noreply, %Phoenix.Socket{}} =
             VehicleChannel.handle_in(
               "init",
               %{"route_id" => "route_id", "direction_id" => "0"},
               socket
             )

    assert_push("data", _)
  end

  test "fetches and processes vehicle prediction when buliding tooltip_text" do
    route = %Routes.Route{id: "CR-Lowell"}

    trip = %Schedules.Trip{
      id: "trip",
      headsign: "Train Trip"
    }

    stop = %Stops.Stop{name: "North Station", id: "place-north"}

    prediction = %Predictions.Prediction{
      route: route,
      trip: trip,
      stop: stop,
      direction_id: 0,
      status: "All aboard",
      track: "20",
      departing?: true
    }

    with_mocks [
      {Routes.Repo, [:passthrough], [get: fn _ -> route end]},
      {Schedules.Repo, [:passthrough], [trip: fn _ -> trip end]},
      {Predictions.Repo, [:passthrough], [all: fn _ -> [prediction] end]},
      {Stops.Repo, [:passthrough], [get: fn _ -> stop end]}
    ] do
      assert {:ok, _, socket} =
               UserSocket
               |> socket("", %{some: :assign})
               |> subscribe_and_join(VehicleChannel, "vehicles:VehicleChannelTest4")

      [vehicle | _] = @vehicles

      VehicleChannel.handle_out("reset", %{data: @vehicles}, socket)

      assert_push("data", vehicles)

      assert %{data: [vehicle_with_marker | _]} = vehicles

      assert %{
               data: %{stop_name: _, vehicle: ^vehicle},
               marker: %Marker{
                 tooltip_text: tooltip_text
               }
             } = vehicle_with_marker

      assert tooltip_text =~ "Train Trip train is on the way to North Station"
      assert tooltip_text =~ "all aboard on track 20"
    end
  end
end
