defmodule Schedules.Schedule do
  @moduledoc """
  Representation of GTFS schedules.
  """

  @derive Jason.Encoder

  defstruct route: nil,
            trip: nil,
            stop: nil,
            time: nil,
            flag?: false,
            early_departure?: false,
            last_stop?: false,
            stop_sequence: 0,
            pickup_type: 0

  @type t :: %Schedules.Schedule{
          route: Routes.Route.t(),
          trip: Schedules.Trip.t(),
          stop: Stops.Stop.t(),
          time: DateTime.t(),
          flag?: boolean,
          early_departure?: boolean,
          last_stop?: boolean,
          stop_sequence: non_neg_integer,
          pickup_type: integer
        }

  def flag?(%Schedules.Schedule{flag?: value}), do: value
end

defmodule Schedules.ScheduleCondensed do
  @moduledoc """
  Light weight alternate to Schedule.t()
  """
  defstruct stop_id: nil,
            time: nil,
            trip_id: nil,
            route_pattern_id: nil,
            train_number: nil,
            stop_sequence: 0,
            headsign: nil

  @type t :: %Schedules.ScheduleCondensed{
          stop_id: String.t(),
          time: DateTime.t(),
          trip_id: String.t(),
          route_pattern_id: String.t() | nil,
          train_number: String.t() | nil,
          stop_sequence: non_neg_integer,
          headsign: String.t()
        }
end

defmodule Schedules.Trip do
  @moduledoc """
  Representation of GTFS trips.
  """

  alias RoutePatterns.RoutePattern
  alias Routes.Shape

  @derive Jason.Encoder

  defstruct [
    :id,
    :name,
    :headsign,
    :direction_id,
    :shape_id,
    :route_pattern_id,
    :occupancy,
    bikes_allowed?: false
  ]

  @type id_t :: String.t()
  @type headsign :: String.t()
  @type crowding :: Vehicles.Vehicle.crowding()
  @type t :: %Schedules.Trip{
          id: id_t,
          name: String.t(),
          headsign: headsign,
          direction_id: 0 | 1,
          shape_id: Shape.id_t() | nil,
          route_pattern_id: RoutePattern.id_t() | nil,
          bikes_allowed?: boolean,
          occupancy: crowding() | nil
        }
end
