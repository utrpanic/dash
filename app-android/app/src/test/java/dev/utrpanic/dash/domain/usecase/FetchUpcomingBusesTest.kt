package dev.utrpanic.dash.domain.usecase

import dev.utrpanic.dash.domain.model.BoardingPoint
import dev.utrpanic.dash.domain.model.BusArrival
import dev.utrpanic.dash.domain.model.BusArrivalPrediction
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.domain.model.BusStopId
import dev.utrpanic.dash.domain.model.ServiceRegion
import dev.utrpanic.dash.domain.repository.BusArrivalRepository
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Test

class FetchUpcomingBusesTest {
    @Test
    fun keepsSuccessfulStopsSortsArrivalsAndLimitsToTen() = runBlocking {
        val successfulStop = stop(1)
        val failedStop = stop(2)
        val route = BusRoute(1, "1", ServiceRegion.GYEONGGI)
        val point = BoardingPoint("point", "지점", mapOf(successfulStop to setOf(route), failedStop to setOf(route)))
        val repository = BusArrivalRepository { stop, _ ->
            if (stop == failedStop) throw IllegalStateException()
            (1..12).map { arrival(route, stop.id.stopId, seconds = it * 60) }.reversed()
        }

        val buses = FetchUpcomingBuses(repository)(point)

        assertEquals(10, buses.size)
        assertEquals((1L..10L).map { it * 60 }, buses.map { it.timeUntilArrival.inWholeSeconds })
    }

    private fun stop(id: Long) = BusStop(BusStopId.Gyeonggi(id), "정류장 $id", latitude = 37.0, longitude = 127.0)

    private fun arrival(route: BusRoute, stopId: Long, seconds: Int) = BusArrival(
        stopId,
        route,
        1,
        "",
        BusArrivalPrediction(null, seconds, null, "", null, null, "", null),
        null,
    )
}
