import React from "react";
import { renderToString } from "react-dom/server";
import { useSelector } from "react-redux";
import { RouteStop, LineDiagramVehicle } from "../__schedule";
import CrowdingPill from "./CrowdingPill";
import { TooltipWrapper, vehicleArrowIcon } from "../../../helpers/icon";
import { StopCoord, CoordState, CIRC_RADIUS } from "./graphics/graphic-helpers";
import { RouteType, HeadsignWithTimeData } from "../../../__v3api";
import {
  vehicleRealtimeStatusText,
  vehicleName
} from "../../../models/vehicle";

interface VehicleIconsProps {
  stop: RouteStop;
  vehicles: LineDiagramVehicle[] | null;
  headsigns: HeadsignWithTimeData[];
}

const tooltipText = (
  routeType: RouteType | null,
  stopName: string | null,
  vehicle: LineDiagramVehicle,
  track: string | null
): string => {
  const status =
    stopName && stopName.length
      ? `${vehicleRealtimeStatusText(vehicle)} ${stopName}`
      : "";

  if (routeType !== null) {
    let baseText = vehicleName(routeType);
    if (routeType === 2) baseText += ` ${vehicle.trip_name}`;

    if (vehicle.headsign) {
      return `${vehicle.headsign} ${baseText.toLowerCase()} ${status}${
        track ? ` on Track ${track}` : ""
      }`;
    }

    return `${baseText} ${status}`;
  }

  return `Vehicle ${status}`;
};

const CrowdingIconString = (vehicle: LineDiagramVehicle): string =>
  renderToString(<CrowdingPill crowding={vehicle.crowding} />);

const VehicleIcons = ({
  stop,
  vehicles,
  headsigns
}: VehicleIconsProps): JSX.Element | null => {
  const coords: StopCoord | null = useSelector(
    (state: CoordState) => state[stop.id]
  );
  if (!vehicles || !coords) return null;
  const [x, y] = coords;
  const left = `${x - CIRC_RADIUS}px`;
  const routeType = stop.route ? stop.route.type : null;
  const tooltips = vehicles.map(vehicle => {
    const top = `${{
      // eslint-disable-next-line camelcase
      in_transit: y - 50,
      incoming: y - 25,
      stopped: y - 10
    }[vehicle.status] || y}px`;

    // const liveHeadsigns = headsigns.filter(hasPredictionTime);
    const headsignForVehicle = headsigns.find(
      (hs: HeadsignWithTimeData): boolean => hs.trip_name === vehicle.trip_name
    );
    const track =
      headsignForVehicle && headsignForVehicle.track!
        ? headsignForVehicle!.track
        : null;

    return (
      <div
        key={vehicle.id}
        className="m-schedule-diagram__vehicle"
        style={{ top, left }}
      >
        <TooltipWrapper
          tooltipText={`<div class="m-schedule-diagram__vehicle-tooltip">${
            vehicle.crowding ? `${CrowdingIconString(vehicle)}<br/>` : ""
          }${tooltipText(routeType, stop.name, vehicle, track)}</div>`}
          tooltipOptions={{ placement: "right", animation: false, html: true }}
        >
          {vehicleArrowIcon("m-schedule-diagram__vehicle--icon")}
        </TooltipWrapper>
      </div>
    );
  });

  return <>{tooltips}</>;
};

export default VehicleIcons;
