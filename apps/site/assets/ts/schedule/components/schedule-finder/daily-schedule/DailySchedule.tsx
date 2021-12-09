import React, { ReactElement, useEffect, useState } from "react";
import { Dictionary } from "lodash";
import { DirectionId, Service } from "../../../../__v3api";
import Loading from "../../../../components/Loading";
import { stringToDateObject } from "../../../../helpers/date";
import {
  hasMultipleWeekdaySchedules,
  groupServicesByDateRating,
  isCurrentValidService,
  serviceStartDateComparator,
  optGroupComparator,
  serviceComparator
} from "../../../../helpers/service";
import useFetch, {
  isLoading,
  isNotStarted
} from "../../../../helpers/use-fetch";
import { EnhancedRoutePattern, ServiceInSelector } from "../../__schedule";
import { Journey } from "../../__trips";
import SelectContainer from "../SelectContainer";
import ScheduleTable from "./ScheduleTable";
import ServiceOptGroup from "./ServiceOptGroup";

// until we come up with a good integration test for async with loading
// some lines in this file have been ignored from codecov

interface Props {
  stopId: string;
  services: ServiceInSelector[];
  routeId: string;
  directionId: DirectionId;
  routePatterns: EnhancedRoutePattern[];
  today: string;
}

// Exported solely for testing
export const fetchJourneys = (
  routeId: string,
  stopId: string,
  selectedService: Service,
  selectedDirection: DirectionId,
  isCurrent: boolean
): (() => Promise<Response>) => () =>
  window.fetch &&
  window.fetch(
    `/schedules/finder_api/journeys?id=${routeId}&date=${selectedService.end_date}&direction=${selectedDirection}&stop=${stopId}&is_current=${isCurrent}`
  );

// Exported solely for testing
export const parseResults = (json: JSON): Journey[] =>
  (json as unknown) as Journey[];

const SchedulesSelect = ({
  sortedServices,
  todayServiceId,
  defaultSelectedServiceId,
  todayDate,
  onSelectService
}: {
  sortedServices: ServiceInSelector[];
  defaultSelectedServiceId: string;
  todayServiceId: string;
  todayDate: Date;
  onSelectService: (service: ServiceInSelector | undefined) => void;
}): ReactElement<HTMLElement> => {
  const servicesByOptGroup: Dictionary<Service[]> = groupServicesByDateRating(
    sortedServices,
    todayDate
  );

  return (
    <div className="schedule-finder__service-selector">
      <label>
        <span className="sr-only">
          Choose a schedule type from the available options
        </span>
        <SelectContainer>
          <select
            className="c-select-custom text-center u-bold"
            defaultValue={defaultSelectedServiceId}
            onChange={e =>
              onSelectService(sortedServices.find(s => s.id === e.target.value))
            }
            aria-controls="daily-schedule"
          >
            {Object.keys(servicesByOptGroup)
              .sort(optGroupComparator)
              .map((group: string) => {
                const groupedServices = servicesByOptGroup[group];
                /* istanbul ignore next */
                if (groupedServices.length <= 0) return null;

                return (
                  <ServiceOptGroup
                    key={group}
                    label={group}
                    services={groupedServices.sort(serviceComparator)}
                    multipleWeekdays={hasMultipleWeekdaySchedules(
                      groupedServices
                    )}
                    todayServiceId={todayServiceId}
                  />
                );
              })}
          </select>
        </SelectContainer>
      </label>
    </div>
  );
};

export const DailySchedule = ({
  stopId,
  services,
  routeId,
  directionId,
  routePatterns,
  today
}: Props): ReactElement<HTMLElement> | null => {
  const [fetchState, fetch] = useFetch<Journey[]>();

  const todayDate = stringToDateObject(today);

  // By default, show the current day's service
  const sortedServices = services.sort(serviceStartDateComparator);
  const currentServices = sortedServices.filter(service =>
    isCurrentValidService(service, todayDate)
  );
  const todayServiceId =
    currentServices.length > 0 ? currentServices[0].id : "";
  const [defaultSelectedService] = currentServices.length
    ? currentServices
    : sortedServices;

  const [selectedService, setSelectedService] = useState(
    defaultSelectedService
  );

  const getJourneysForSelectedService = (service: Service): void => {
    fetch({
      fetcher: fetchJourneys(routeId, stopId, service, directionId, false),
      parser: parseResults
    });
  };

  useEffect(
    () => {
      /* istanbul ignore next */
      if (selectedService && isNotStarted(fetchState)) {
        getJourneysForSelectedService(selectedService);
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  );

  if (services.length <= 0) return null;

  return (
    <>
      <h3>Daily Schedule</h3>

      <SchedulesSelect
        sortedServices={sortedServices}
        todayServiceId={todayServiceId}
        defaultSelectedServiceId={defaultSelectedService.id}
        todayDate={todayDate}
        onSelectService={chosenService => {
          if (chosenService) {
            setSelectedService(chosenService);
            getJourneysForSelectedService(chosenService);
          }
        }}
      />

      <div id="daily-schedule">
        {isLoading(fetchState) ? (
          <Loading />
        ) : (
          <span className="sr-only" aria-live="polite">
            Showing times for {selectedService.description}
          </span>
        )}

        {/* istanbul ignore next */ !isLoading(fetchState) &&
          /* istanbul ignore next */ fetchState.data && (
            /* istanbul ignore next */ <ScheduleTable
              journeys={fetchState.data}
              routePatterns={routePatterns}
              input={{
                route: routeId,
                origin: stopId,
                direction: directionId,
                date: selectedService!.end_date
              }}
            />
          )}
      </div>
    </>
  );
};

export default DailySchedule;
