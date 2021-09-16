defmodule Site.Stream.VehiclesTest do
  use SiteWeb.ChannelCase, async: true
  alias Vehicles.Vehicle

  @vehicles [
    %Vehicle{route_id: "Red", direction_id: 0},
    %Vehicle{route_id: "CR-Lowell", direction_id: 1},
    %Vehicle{route_id: "Blue", direction_id: nil},
    %Vehicle{route_id: "Green-B", direction_id: 1},
    %Vehicle{route_id: "Green-C", direction_id: 1}
  ]

  test "start_link/1" do
    assert {:ok, _} = Site.Stream.Vehicles.start_link(name: __MODULE__)
  end

  test "broadcasts vehicles by route and direction id" do
    Phoenix.PubSub.subscribe(Site.PubSub, "vehicles:Red:0")
    Phoenix.PubSub.subscribe(Site.PubSub, "vehicles:CR-Lowell:1")
    Phoenix.PubSub.subscribe(Site.PubSub, "vehicles:Blue:0")
    Phoenix.PubSub.subscribe(Site.PubSub, "vehicles:Blue:1")

    assert {:ok, pid} = GenServer.start_link(Site.Stream.Vehicles, [])

    send(pid, {:reset, @vehicles})

    assert_broadcast("reset", %{
      data: [
        %Vehicle{route_id: "Red", direction_id: 0}
      ]
    })

    assert_broadcast("reset", %{
      data: [
        %Vehicle{route_id: "CR-Lowell", direction_id: 1}
      ]
    })

    refute_broadcast("reset", %{
      data: [
        %Vehicle{route_id: "Blue", direction_id: nil}
      ]
    })
  end

  test "sends a generic Green broadcast" do
    Phoenix.PubSub.subscribe(Site.PubSub, "vehicles:Green:1")
    assert {:ok, pid} = GenServer.start_link(Site.Stream.Vehicles, [])

    send(pid, {:reset, @vehicles})

    assert_broadcast("reset", %{
      data: [
        %Vehicle{route_id: "Green-B", direction_id: 1},
        %Vehicle{route_id: "Green-C", direction_id: 1}
      ]
    })
  end
end
