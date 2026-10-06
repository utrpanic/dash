package dev.utrpanic.dash.ui.home

import androidx.lifecycle.viewModelScope
import dev.utrpanic.dash.domain.location.UserLocation
import dev.utrpanic.dash.domain.location.UserLocationProvider
import dev.utrpanic.dash.domain.model.*
import dev.utrpanic.dash.domain.repository.*
import kotlinx.coroutines.*
import kotlinx.coroutines.test.*
import org.junit.Assert.*
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class DashViewModelTest {
    private val route = BusRoute(1, "1", ServiceRegion.GYEONGGI)
    private fun point(id: Long) = BoardingPoint(
        "$id", "지점 $id",
        mapOf(BusStop(BusStopId.Gyeonggi(id), "정류장 $id", latitude = 36.0 + id, longitude = 127.0) to setOf(route)),
    )
    private val first = point(1)
    private val second = point(2)

    @Test
    fun switchingStartsNewRequestAndIgnoresLateSuccess() = scenario {
        select(first)
        select(second)
        assertEquals(listOf(1L, 2L), requests.map { it.stop.id.stopId })
        requests[1].succeed(120)
        runCurrent()
        val expected = model.state.value
        requests[0].succeed(60)
        runCurrent()
        assertEquals(expected, model.state.value)
        assertEquals(second, model.state.value.upcomingBuses.single().boardingPoint)
    }

    @Test
    fun staleFailureDoesNotStopCurrentLoadingOrShowError() = scenario {
        select(first)
        model.selectNextBoardingPoint()
        runCurrent()
        assertEquals(second, model.state.value.currentBoardingPoint)
        requests[0].result.completeExceptionally(IllegalStateException("old request"))
        runCurrent()
        assertTrue(model.state.value.isRefreshing)
        assertNull(model.state.value.errorMessage)
        requests[1].succeed(120)
        runCurrent()
        assertFalse(model.state.value.isRefreshing)
        assertNull(model.state.value.errorMessage)
    }

    @Test
    fun returningToSamePointRejectsOriginalRequest() = scenario {
        select(first)
        select(second)
        select(first)
        requests[2].succeed(180)
        runCurrent()
        val expected = model.state.value
        requests[0].succeed(60)
        requests[1].succeed(120)
        runCurrent()
        assertEquals(expected, model.state.value)
        assertEquals(180L, model.state.value.upcomingBuses.single().timeUntilArrival.inWholeSeconds)
    }

    @Test
    fun editingCurrentPointReplacesPendingRequest() = scenario {
        select(first)
        model.editBoardingPoint(first)
        model.removeDraftStop(first.routes.keys.single())
        model.saveDraft()
        runCurrent()
        assertFalse(model.state.value.isRefreshing)
        assertTrue(model.state.value.upcomingBuses.isEmpty())
        val expected = model.state.value
        requests[0].succeed(60)
        runCurrent()
        assertEquals(expected, model.state.value)
    }

    @Test
    fun relocatingAfterBackgroundRefreshShowsOnlyNewPointArrivals() = scenario {
        select(first)
        requests[0].succeed(60)
        runCurrent()
        assertEquals(first, model.state.value.upcomingBuses.single().boardingPoint)

        // Returning to the foreground starts a refresh for the old point.
        model.refresh()
        runCurrent()
        assertEquals(2, requests.size)
        assertEquals(first, model.state.value.currentBoardingPoint)

        // The location button resolves a different point while that refresh is in flight.
        location = UserLocation(second.centerLatitude!!, second.centerLongitude!!)
        model.resolveFromCurrentLocation()
        runCurrent()
        assertEquals(second, model.state.value.currentBoardingPoint)
        assertTrue(model.state.value.upcomingBuses.isEmpty())
        assertTrue(model.state.value.isRefreshing)
        assertEquals(listOf(1L, 1L, 2L), requests.map { it.stop.id.stopId })

        requests[1].succeed(90)
        runCurrent()
        assertTrue(model.state.value.upcomingBuses.isEmpty())
        assertTrue(model.state.value.isRefreshing)
        requests[2].succeed(120)
        runCurrent()
        assertEquals(second, model.state.value.upcomingBuses.single().boardingPoint)
        assertFalse(model.state.value.isRefreshing)
    }

    @Test
    fun duplicateRefreshIsSkippedAndCurrentFailureIsShown() = scenario {
        select(first)
        model.refresh()
        runCurrent()
        assertEquals(1, requests.size)
        requests[0].result.completeExceptionally(IllegalStateException("current request"))
        runCurrent()
        assertFalse(model.state.value.isRefreshing)
        assertEquals("도착 정보를 불러오지 못했습니다.", model.state.value.errorMessage)
    }

    private fun scenario(block: suspend Fixture.() -> Unit) = runTest {
        Dispatchers.setMain(StandardTestDispatcher(testScheduler))
        val fixture = Fixture(this)
        try {
            fixture.block()
        } finally {
            fixture.requests.forEach { it.result.complete(emptyList()) }
            fixture.model.viewModelScope.cancel()
            runCurrent()
            Dispatchers.resetMain()
        }
    }

    private inner class Fixture(private val scope: TestScope) {
        val requests = mutableListOf<Request>()
        var location = UserLocation(first.centerLatitude!!, first.centerLongitude!!)
        private var configuration = BoardingPointConfiguration(listOf(first, second), first.id)
        val model = DashViewModel(
            boardingPointRepository = object : BoardingPointRepository {
                override suspend fun loadConfiguration() = configuration
                override suspend fun saveConfiguration(configuration: BoardingPointConfiguration) {
                    this@Fixture.configuration = configuration
                }
            },
            locationProvider = UserLocationProvider { location },
            busArrivalRepository = BusArrivalRepository { stop, _ ->
                val request = Request(stop)
                requests += request
                // Simulate an API operation that finishes even after cancellation.
                withContext(NonCancellable) { request.result.await() }
            },
            busStopRepository = object : BusStopRepository {
                override suspend fun searchStops(query: String) = emptyList<BusStop>()
                override suspend fun fetchNearbyStops(latitude: Double, longitude: Double) = emptyList<BusStop>()
            },
            busRouteRepository = BusRouteRepository { emptyList() },
        )

        fun runCurrent() = scope.runCurrent()
        fun select(point: BoardingPoint) {
            model.selectBoardingPoint(point)
            runCurrent()
        }
    }

    private inner class Request(val stop: BusStop) {
        val result = CompletableDeferred<List<BusArrival>>()
        fun succeed(seconds: Int) {
            result.complete(listOf(BusArrival(
                stop.id.stopId, route, 1, "",
                BusArrivalPrediction(null, seconds, null, "", null, null, "", null), null,
            )))
        }
    }
}
