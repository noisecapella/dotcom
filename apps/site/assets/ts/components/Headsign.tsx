import React, { ReactElement } from "react";
import { RouteType, PredictedOrScheduledTime, Headsign } from "../__v3api";
import {
  statusForCommuterRail,
  trackForCommuterRail,
  predictedOrScheduledTime,
  PredictionForCommuterRail
} from "../helpers/prediction-helpers";

interface Props {
  headsign_name: string;
  routeType: RouteType;
  condensed: boolean;
}

const headsignClass = (condensed: boolean): string => {
  if (condensed === true) {
    return "m-tnm-sidebar__headsign-schedule m-tnm-sidebar__headsign-schedule--condensed";
  }
  return "m-tnm-sidebar__headsign-schedule";
};

const renderHeadsignName = ({
  headsign_name: headsignName,
  routeType,
  condensed
}: Props): ReactElement<HTMLElement> => {
  const modifier = !condensed && routeType === 3 ? "small" : "large";

  const headsignNameClass = `m-tnm-sidebar__headsign-name m-tnm-sidebar__headsign-name--${modifier}`;

  if (headsignName && headsignName.includes(" via ")) {
    const split = headsignName.split(" via ");
    return (
      <>
        <div className={headsignNameClass}>{split[0]}</div>
        <div className="m-tnm-sidebar__via">{`via ${split[1]}`}</div>
      </>
    );
  }
  return <div className={headsignNameClass}>{headsignName}</div>;
};

const renderTrainName = (trainName: string): ReactElement<HTMLElement> => (
  <div className="m-tnm-sidebar__headsign-train">{trainName}</div>
);

const renderTimeCommuterRail = (
  data: PredictedOrScheduledTime,
  modifier: string
): ReactElement<HTMLElement> => {
  const status = statusForCommuterRail(data);
  const className = `${
    status === "Canceled" ? "strikethrough" : ""
  } m-tnm-sidebar__time-number`;

  return (
    <div
      className={`m-tnm-sidebar__time m-tnm-sidebar__time--commuter-rail ${modifier} ${
        status === "Scheduled" ? "text-muted" : ""
      }`}
    >
      <PredictionForCommuterRail data={data} modifier={className} />
      <div className="m-tnm-sidebar__status">
        {`${status || ""}${trackForCommuterRail(data)}`}
      </div>
    </div>
  );
};

const renderTimeDefault = (
  time: string,
  modifier: string
): ReactElement<HTMLElement> | null => {
  if (!time) return null;
  const [t1, t2] = time.split(" "); // splits "2 min" or "10:10 AM"
  return (
    <div className={`m-tnm-sidebar__time ${modifier}`}>
      <div className="m-tnm-sidebar__time-number">{t1}</div>
      <div className="m-tnm-sidebar__time-mins">{t2}</div>
    </div>
  );
};

const renderTime = (
  tnmTime: PredictedOrScheduledTime,
  headsignName: string,
  routeType: RouteType,
  idx: number
): ReactElement<HTMLElement> => {
  // eslint-disable-next-line camelcase
  const { prediction } = tnmTime;
  // eslint-disable-next-line camelcase
  const time = predictedOrScheduledTime(tnmTime);

  const classModifier =
    !prediction && [0, 1, 3].includes(routeType)
      ? "m-tnm-sidebar__time--schedule"
      : "";

  return (
    <div
      // eslint-disable-next-line camelcase
      key={`${headsignName}-${idx}`}
      className="m-tnm-sidebar__schedule"
    >
      {routeType === 2
        ? renderTimeCommuterRail(tnmTime, classModifier)
        : renderTimeDefault(time!, classModifier)}
    </div>
  );
};

// iterate through a list of predicted schedules? idk?
const HeadsignComponent = (props: Props): ReactElement<HTMLElement> => {
  const { headsign_name, trip_name: trainNumber, routeType, condensed, headsignsList } = props;
  return (
    <div className={headsignClass(condensed)}>
      <div className="m-tnm-sidebar__headsign">
        {renderHeadsignName(props)}

        {routeType === 2 && trainNumber
          ? renderTrainName(`Train ${trainNumber}`)
          : null}
      </div>
      <div className="m-tnm-sidebar__schedules">
        {headsignsList
          .filter(time => predictedOrScheduledTime(time)) // non-null time
          .map((time: Date, idx: number) => {
            if (routeType === 2 && idx > 0) return null; // limit to 1 headsign
            return renderTime(time, headsign_name, routeType, idx);
          })}
      </div>
    </div>
  );
};

export default HeadsignComponent;
