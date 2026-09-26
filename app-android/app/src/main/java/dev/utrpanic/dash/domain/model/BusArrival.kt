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
    ): List<UpcomingBus> = listOf(firstPrediction, secondPrediction).mapIndexedNotNull { index, prediction ->
        prediction ?: return@mapIndexedNotNull null
        prediction.timeUntilArrival?.let { duration ->
            UpcomingBus(
                boardingPoint = boardingPoint,
                busStop = busStop,
                busRoute = route,
                timeUntilArrival = duration,
                sourceArrivalId = id,
                predictionIndex = index,
            )
        }
    }
}

data class UpcomingBus(
    val boardingPoint: BoardingPoint,
    val busStop: BusStop,
    val busRoute: BusRoute,
    val timeUntilArrival: Duration,
    val sourceArrivalId: String,
    val predictionIndex: Int,
) {
    val id = "${boardingPoint.id}-${busStop.id.storageKey}-$sourceArrivalId-$predictionIndex"
}

fun Iterable<UpcomingBus>.sortedByArrival(): List<UpcomingBus> = sortedBy(UpcomingBus::timeUntilArrival)
