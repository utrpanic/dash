package dev.utrpanic.dash.domain.model

import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

data class BusArrivalPrediction(
    val minutes: Int?,
    val seconds: Int?,
    val locationNumber: Int?,
    val plateNumber: String,
    val remainingSeatCount: Int?,
    val stateCode: Int?,
    val stopName: String,
    val vehicleId: Long?,
) {
    val timeUntilArrival: Duration?
        get() = seconds?.seconds ?: minutes?.minutes
}

data class BusArrival(
    val stopId: Long,
    val route: BusRoute,
    val stopOrder: Int,
    val operationState: String,
    val firstPrediction: BusArrivalPrediction?,
    val secondPrediction: BusArrivalPrediction?,
) {
    val id = "$stopId-${route.region.name}-${route.id}-$stopOrder"

    fun upcomingBuses(
        boardingPoint: BoardingPoint,
        busStop: BusStop,
    ): List<UpcomingBus> = listOfNotNull(firstPrediction, secondPrediction).mapNotNull { prediction ->
        prediction.timeUntilArrival?.let { duration ->
            UpcomingBus(
                boardingPoint = boardingPoint,
                busStop = busStop,
                busRoute = route,
                timeUntilArrival = duration,
            )
        }
    }
}

data class UpcomingBus(
    val boardingPoint: BoardingPoint,
    val busStop: BusStop,
    val busRoute: BusRoute,
    val timeUntilArrival: Duration,
) {
    val id = "${boardingPoint.id}-${busStop.id.storageKey}-${busRoute.region.name}-${busRoute.id}-$timeUntilArrival"
}

fun Iterable<UpcomingBus>.sortedByArrival(): List<UpcomingBus> = sortedBy(UpcomingBus::timeUntilArrival)
