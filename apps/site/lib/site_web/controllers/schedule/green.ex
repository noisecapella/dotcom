defmodule SiteWeb.ScheduleController.Green do
  @moduledoc """
    Alternate controller for Green Line schedules
  """
  use SiteWeb, :controller

  import UrlHelpers, only: [update_url: 2]
  import SiteWeb.ControllerHelpers, only: [call_plug: 2, call_plug_with_opts: 3, assign_alerts: 2]

  alias Schedules.Schedule
  alias SiteWeb.ScheduleController.LineController
  alias SiteWeb.ScheduleView

  plug(:route)
  plug(SiteWeb.Plugs.DateInRating)
  plug(SiteWeb.ScheduleController.DatePicker)
  plug(:assign_alerts)
  plug(SiteWeb.Plugs.AlertsByTimeframe)
  plug(SiteWeb.ScheduleController.Defaults)
  plug(:stops_on_routes)
  plug(:all_stops)
  plug(SiteWeb.ScheduleController.OriginDestination)
  plug(:validate_direction)
  plug(:schedules)
  plug(:vehicle_locations)
  plug(:predictions)
  plug(SiteWeb.ScheduleController.VehicleTooltips)
  plug(SiteWeb.ScheduleController.ExcludedStops)
  plug(SiteWeb.ScheduleController.Journeys)
  plug(:validate_journeys)
  plug(:hide_destination_selector)
  plug(SiteWeb.ScheduleController.TripInfo)
  plug(SiteWeb.ScheduleController.RouteBreadcrumbs)
  plug(SiteWeb.ScheduleController.ScheduleError)
  plug(:require_map)
  plug(:route_pdfs)
  plug(:channels)

  @task_timeout 10_000

  def show(%Plug.Conn{query_params: %{"tab" => "trip-view"}} = conn, _params),
    do: trip_view(conn, [])

  def show(%Plug.Conn{query_params: %{"tab" => "alerts"}} = conn, _params),
    do: alerts(conn, [])

  def show(conn, _params), do: line(conn, [])

  def trip_view(conn, _params) do
    redirect(conn, to: line_path(conn, :show, "Green", Map.delete(conn.query_params, "tab")))
  end

  def alerts(conn, _params) do
    conn
    |> assign(:tab, "alerts")
    |> put_view(ScheduleView)
    |> render("show.html", [])
  end

  def line(conn, _params) do
    conn
    |> assign(:tab, "line")
    |> assign(
      :meta_description,
      "MBTA Green Line trolley stations and schedules, including maps, real-time updates, " <>
        "parking and accessibility information, and connections."
    )
    |> call_plug(SiteWeb.ScheduleController.HoursOfOperation)
    |> call_plug(SiteWeb.ScheduleController.Holidays)
    |> call_plug(SiteWeb.ScheduleController.Line)
    |> call_plug(SiteWeb.ScheduleController.CMS)
    |> await_assign_all_default(__MODULE__)
    |> put_view(ScheduleView)
    |> LineController.assign_schedule_page_data()
    |> render("show.html", [])
  end

  def route(conn, _params) do
    assign(conn, :route, Routes.Repo.green_line())
  end

  def stops_on_routes(
        %Plug.Conn{assigns: %{direction_id: direction_id, date: date}} = conn,
        _opts
      ) do
    assign(conn, :stops_on_routes, GreenLine.stops_on_routes(direction_id, date))
  end

  def all_stops(%Plug.Conn{assigns: %{stops_on_routes: stops_on_routes}} = conn, _params) do
    case GreenLine.all_stops(stops_on_routes) do
      {:error, _} ->
        assign(conn, :all_stops, [])

      stops ->
        assign(conn, :all_stops, stops)
    end
  end

  def schedules(%Plug.Conn{assigns: %{origin: nil}} = conn, _) do
    conn
  end

  def schedules(conn, opts) do
    schedules =
      conn
      |> conn_with_branches
      |> Task.async_stream(
        fn conn ->
          call_plug_with_opts(conn, SiteWeb.ScheduleController.Schedules, opts).assigns.schedules
        end,
        timeout: @task_timeout
      )
      |> flat_map_results
      |> Enum.sort_by(&arrival_time/1, &Timex.before?/2)

    conn
    |> assign(:schedules, schedules)
    |> SiteWeb.ScheduleController.Schedules.assign_frequency_table(schedules)
  end

  def predictions(conn, opts) do
    {predictions} =
      if SiteWeb.ScheduleController.Predictions.should_fetch_predictions?(conn) do
        predictions_fn = opts[:predictions_fn] || (&Predictions.Repo.all/1)

        predictions_stream =
          conn
          |> conn_with_branches
          |> Task.async_stream(
            fn conn ->
              SiteWeb.ScheduleController.Predictions.predictions(conn, predictions_fn)
            end,
            timeout: @task_timeout,
            on_timeout: :kill_task
          )

        {flat_map_results(predictions_stream)}
      else
        {[]}
      end

    conn
    |> assign(:predictions, predictions)
  end

  def vehicle_locations(conn, opts) do
    vehicle_locations =
      conn
      |> conn_with_branches
      |> Task.async_stream(
        fn conn ->
          call_plug_with_opts(conn, SiteWeb.ScheduleController.VehicleLocations, opts).assigns.vehicle_locations
        end,
        timeout: @task_timeout
      )
      |> Enum.reduce(%{}, fn {:ok, result}, acc -> Map.merge(result, acc) end)

    assign(conn, :vehicle_locations, vehicle_locations)
  end

  @doc """

  For a few westbound stops, we don't have trip predictions, only how far
  away the train is. In those cases, we disabled the destination selector
  since we can't match pairs of trips.

  """
  def hide_destination_selector(%{assigns: %{direction_id: 0, origin: %{id: stop_id}}} = conn, [])
      when stop_id in [
             "place-spmnl",
             "place-north",
             "place-haecl",
             "place-gover",
             "place-pktrm",
             "place-boyls"
           ] do
    assign(conn, :hide_destination_selector?, true)
  end

  def hide_destination_selector(conn, []) do
    conn
  end

  @doc """

  If we built an empty journey list, but we had predictions for the
  origin, then redirect the user away from their selected destination so they
  at least get partial results.

  """
  def validate_journeys(%{assigns: %{destination: nil}} = conn, []) do
    conn
  end

  def validate_journeys(%{assigns: %{journeys: %JourneyList{journeys: [_ | _]}}} = conn, []) do
    conn
  end

  def validate_journeys(conn, []) do
    origin_predictions =
      conn.assigns.predictions |> Enum.find(&(&1.stop.id == conn.assigns.origin.id))

    if is_nil(origin_predictions) do
      conn
    else
      url = UrlHelpers.update_url(conn, destination: nil)

      conn
      |> redirect(to: url)
      |> halt
    end
  end

  defp conn_with_branches(conn) do
    GreenLine.branch_ids()
    |> Enum.map(fn route_id ->
      %{
        conn
        | assigns: %{conn.assigns | route: Routes.Repo.get(route_id)},
          params: Map.put(conn.params, "route", route_id)
      }
    end)
  end

  defp flat_map_results(results) do
    Enum.flat_map(results, &flat_map_ok/1)
  end

  @spec flat_map_ok({:ok, [value] | error} | error) :: [value]
        when error: {:error, any}, value: any
  defp flat_map_ok({:ok, values}) when is_list(values), do: values

  defp flat_map_ok(_) do
    []
  end

  @spec arrival_time({Schedule.t(), Schedule.t()} | Schedule.t()) :: DateTime.t()
  defp arrival_time({arrival, _departure}), do: arrival.time
  defp arrival_time(schedule), do: schedule.time

  defp validate_direction(
         %{
           assigns: %{
             origin: origin,
             destination: destination,
             direction_id: direction_id
           }
         } = conn,
         _
       )
       when not is_nil(origin) and not is_nil(destination) do
    {stops, _map} = conn.assigns.stops_on_routes

    stops = Enum.reverse(stops)

    if Util.ListHelpers.find_first(stops, origin, destination) == destination do
      conn
      |> redirect(to: update_url(conn, direction_id: 1 - direction_id))
      |> halt()
    else
      conn
    end
  end

  defp validate_direction(conn, _), do: conn

  defp require_map(conn, _), do: assign(conn, :requires_google_maps?, true)

  defp route_pdfs(%{assigns: %{date: date}} = conn, _) do
    pdfs = Site.RoutePdfs.fetch_and_choose_pdfs("Green", date)
    assign(conn, :route_pdfs, pdfs)
  end

  defp channels(conn, _) do
    assign(conn, :channel, "vehicles:Green:#{conn.assigns.direction_id}")
  end
end
