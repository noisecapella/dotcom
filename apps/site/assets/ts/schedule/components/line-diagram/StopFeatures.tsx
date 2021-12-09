import React from "react";
import { RouteStop } from "../__schedule";
import {
  TooltipWrapper,
  parkingIcon,
  accessibleIcon
} from "../../../helpers/icon";
import { isACommuterRailRoute } from "../../../models/route";

const StopFeatures = (routeStop: RouteStop): JSX.Element => (
  <div className="m-schedule-diagram__features">
    {routeStop.stop_features.includes("parking_lot") ? (
      <TooltipWrapper
        tooltipText="Parking"
        tooltipOptions={{ placement: "bottom" }}
      >
        {parkingIcon(
          "c-svg__icon-parking-default m-schedule-diagram__feature-icon"
        )}
      </TooltipWrapper>
    ) : null}
    {routeStop.stop_features.includes("access") ? (
      <TooltipWrapper
        tooltipText="Accessible"
        tooltipOptions={{ placement: "bottom" }}
      >
        {accessibleIcon(
          "c-svg__icon-acessible-default m-schedule-diagram__feature-icon"
        )}
      </TooltipWrapper>
    ) : null}
    {routeStop.zone &&
      routeStop.route &&
      isACommuterRailRoute(routeStop.route) && (
        <span className="c-icon__cr-zone m-schedule-diagram__feature-icon">{`Zone ${routeStop.zone}`}</span>
      )}
  </div>
);

export default StopFeatures;
