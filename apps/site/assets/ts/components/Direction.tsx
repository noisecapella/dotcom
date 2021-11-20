import React, { ReactElement } from "react";
import Headsigns from "./Headsign";
import { Direction as DirectionType, EnhancedRoute } from "../__v3api";

interface Props {
  direction: DirectionType;
  route: EnhancedRoute;
}

export const directionIsEmpty = (dir: DirectionType): boolean =>
  dir.headsigns.length === 0;

export const Direction = ({
  direction,
  route
}: Props): ReactElement<HTMLElement> | null => {
  if (directionIsEmpty(direction)) {
    return null;
  }

  const condensed = direction.headsigns.length === 1;

  const hideDirectionDestination =
    condensed || route.type === 0 || route.type === 1 || route.type === 2;

  return (
    <div className="m-tnm-sidebar__direction">
      <div className="m-tnm-sidebar__direction-name u-small-caps">
        {route.direction_names[direction.direction_id]}
      </div>
      {!hideDirectionDestination && (
        <div className="m-tnm-sidebar__direction-destination">
          {route.direction_destinations[direction.direction_id]}
        </div>
      )}
      <div className="m-tnm-sidebar__direction-headsigns">
        <Headsigns
            key={`headsigns-${route.direction_destinations[direction.direction_id]}`}
            routeType={route.type}
            condensed={condensed}
            headsigns={direction.headsigns}
          />
        {/* {direction.headsigns.map(headsign => (
          <Headsign
            key={headsign.headsign_name!}
            routeType={route.type}
            condensed={condensed}
            {...headsign}
          />
        ))} */}
      </div>
    </div>
  );
};

export default Direction;
