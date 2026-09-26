package dev.utrpanic.dash.domain.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.time.Duration.Companion.seconds

class DomainModelTest {
    @Test
    fun busStopIdentityIncludesRegionAndSeoulArsId() {
        assertEquals("gyeonggi-1", BusStopId.Gyeonggi(1).storageKey)
        assertEquals("seoul-1-19005", BusStopId.Seoul(1, "19005").storageKey)
        assertFalse(BusStopId.Gyeonggi(1) == BusStopId.Seoul(1, "19005"))
    }

    @Test
    fun boardingPointCenterIncludesStopsWithoutSelectedRoutes() {
        val firstStop = stop(id = 1, latitude = 37.0, longitude = 126.0)
        val secondStop = stop(id = 2, latitude = 38.0, longitude = 128.0)
        val boardingPoint = BoardingPoint(
            id = "commute",
            name = "출근",
            routes = mapOf(
                firstStop to setOf(route()),
                secondStop to emptySet(),
            ),
        )

        assertTrue(boardingPoint.hasSelectedRoutes)
        assertEquals(37.5, boardingPoint.centerLatitude!!, 0.0)
        assertEquals(127.0, boardingPoint.centerLongitude!!, 0.0)
    }

    @Test
    fun emptyBoardingPointHasNoCenterOrSelectedRoutes() {
        val boardingPoint = BoardingPoint(id = "empty", name = "빈 지점", routes = emptyMap())

        assertFalse(boardingPoint.hasSelectedRoutes)
        assertNull(boardingPoint.centerLatitude)
        assertNull(boardingPoint.centerLongitude)
    }

    @Test
    fun arrivalUsesSecondsBeforeMinutesAndDropsPredictionsWithoutTime() {
        val stop = stop(id = 1)
        val route = route()
        val boardingPoint = BoardingPoint("commute", "출근", mapOf(stop to setOf(route)))
        val arrival = BusArrival(
            stopId = 1,
            route = route,
            stopOrder = 3,
            operationState = "",
            firstPrediction = prediction(minutes = 3, seconds = 95),
            secondPrediction = prediction(minutes = null, seconds = null),
        )

        assertEquals(listOf(95.seconds), arrival.upcomingBuses(boardingPoint, stop).map { it.timeUntilArrival })
    }

    @Test
    fun predictionsWithTheSameArrivalTimeHaveDistinctIds() {
        val stop = stop(id = 1)
        val route = route()
        val boardingPoint = BoardingPoint("commute", "출근", mapOf(stop to setOf(route)))
        val prediction = prediction(minutes = 0, seconds = 0)
        val arrival = BusArrival(1, route, 3, "", prediction, prediction)

        val ids = arrival.upcomingBuses(boardingPoint, stop).map(UpcomingBus::id)

        assertEquals(2, ids.distinct().size)
    }

    private fun stop(
        id: Long,
        latitude: Double = 37.0,
        longitude: Double = 127.0,
    ) = BusStop(
        id = BusStopId.Gyeonggi(id),
        name = "정류장",
        latitude = latitude,
        longitude = longitude,
    )

    private fun route() = BusRoute(id = 10, number = "10", region = ServiceRegion.GYEONGGI)

    private fun prediction(
        minutes: Int?,
        seconds: Int?,
    ) = BusArrivalPrediction(
        minutes = minutes,
        seconds = seconds,
        locationNumber = null,
        plateNumber = "",
        remainingSeatCount = null,
        stateCode = null,
        stopName = "",
        vehicleId = null,
    )
}
