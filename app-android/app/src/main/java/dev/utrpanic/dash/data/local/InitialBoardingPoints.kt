package dev.utrpanic.dash.data.local

import dev.utrpanic.dash.domain.model.BoardingPoint
import dev.utrpanic.dash.domain.model.BoardingPointConfiguration
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.domain.model.BusStopId
import dev.utrpanic.dash.domain.model.ServiceRegion

object InitialBoardingPoints {
    val configuration = BoardingPointConfiguration(
        boardingPoints = listOf(
            BoardingPoint(
                id = "yeongdeungpo-station",
                name = "영등포역",
                routes = mapOf(
                    BusStop(
                        id = BusStopId.Seoul(118000005, "19005"),
                        name = "영등포역",
                        latitude = 37.5158657465,
                        longitude = 126.90509208,
                    ) to setOf(
                        seoulRoute(100100550, "662"),
                        seoulRoute(100100033, "160"),
                        seoulRoute(100100085, "600"),
                        seoulRoute(212000001, "88"),
                        seoulRoute(114000003, "8671"),
                    ),
                ),
            ),
            BoardingPoint(
                id = "the-hyundai-seoul",
                name = "더현대서울",
                routes = mapOf(
                    BusStop(
                        id = BusStopId.Seoul(118000197, "19282"),
                        name = "더현대서울",
                        latitude = 37.5250045778,
                        longitude = 126.9281836353,
                    ) to setOf(
                        seoulRoute(212000001, "88"),
                        seoulRoute(100100550, "662"),
                        seoulRoute(100100305, "6628"),
                    ),
                ),
            ),
        ),
        currentBoardingPointId = "yeongdeungpo-station",
    )

    private fun seoulRoute(id: Long, number: String) = BusRoute(id, number, ServiceRegion.SEOUL)
}
