package dev.utrpanic.dash.data.repository

import dev.utrpanic.dash.data.api.GyeonggiBusApi
import dev.utrpanic.dash.data.api.SeoulBusApi
import dev.utrpanic.dash.domain.model.BusArrival
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.domain.model.BusStopId
import dev.utrpanic.dash.domain.model.ServiceRegion
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class LiveBusRepositoriesTest {
    @Test
    fun stopSearchKeepsOneRegionWhenTheOtherFailsAndRemovesDuplicateIds() = runBlocking {
        val stop = gyeonggiStop()
        val repository = LiveBusStopRepository(
            gyeonggiApi = FakeGyeonggiBusApi(searchResult = listOf(stop, stop)),
            seoulApi = FakeSeoulBusApi(failure = IllegalStateException()),
        )

        assertEquals(listOf(stop), repository.searchStops(" 수원역 "))
    }

    @Test
    fun nearbySearchOutsideSupportedAreaDoesNotCallApis() = runBlocking {
        val gyeonggi = FakeGyeonggiBusApi()
        val seoul = FakeSeoulBusApi()
        val repository = LiveBusStopRepository(gyeonggi, seoul)

        assertTrue(repository.fetchNearbyStops(37.7749, -122.4194).isEmpty())
        assertEquals(0, gyeonggi.nearbyCallCount)
        assertEquals(0, seoul.nearbyCallCount)
    }

    @Test
    fun routesRemoveDuplicateDomainIds() = runBlocking {
        val first = BusRoute(212000001, "0017", ServiceRegion.SEOUL)
        val duplicate = first.copy(number = "17")
        val repository = LiveBusRouteRepository(
            gyeonggiApi = FakeGyeonggiBusApi(),
            seoulApi = FakeSeoulBusApi(routeResult = listOf(first, duplicate)),
        )

        assertEquals(listOf(first), repository.fetchRoutes(seoulStop()))
    }

    @Test
    fun gyeonggiArrivalsAreFilteredToSelectedRoutes() = runBlocking {
        val selected = route(1, ServiceRegion.GYEONGGI)
        val other = route(2, ServiceRegion.GYEONGGI)
        val repository = LiveBusArrivalRepository(
            gyeonggiApi = FakeGyeonggiBusApi(
                arrivalResult = listOf(arrival(selected), arrival(selected), arrival(other)),
            ),
            seoulApi = FakeSeoulBusApi(),
        )

        assertEquals(listOf(arrival(selected)), repository.fetchArrivals(gyeonggiStop(), setOf(selected)))
    }

    @Test
    fun seoulArrivalsKeepSuccessfulRouteWhenAnotherFails() = runBlocking {
        val successful = route(662, ServiceRegion.SEOUL)
        val failed = route(6628, ServiceRegion.SEOUL)
        val repository = LiveBusArrivalRepository(
            gyeonggiApi = FakeGyeonggiBusApi(),
            seoulApi = FakeSeoulBusApi(
                arrivals = mapOf(successful.id to listOf(arrival(successful, stopId = 118000197))),
                failedRouteId = failed.id,
            ),
        )

        assertEquals(
            listOf(arrival(successful, stopId = 118000197)),
            repository.fetchArrivals(seoulStop(), setOf(successful, failed)),
        )
    }

    private fun gyeonggiStop() = BusStop(BusStopId.Gyeonggi(202000219), "수원역", latitude = 37.2, longitude = 127.0)

    private fun seoulStop() = BusStop(BusStopId.Seoul(118000197, "19282"), "더현대서울", latitude = 37.5, longitude = 126.9)

    private fun route(id: Long, region: ServiceRegion) = BusRoute(id, id.toString(), region)

    private fun arrival(route: BusRoute, stopId: Long = 202000219) = BusArrival(stopId, route, 1, "", null, null)

    private class FakeGyeonggiBusApi(
        private val searchResult: List<BusStop> = emptyList(),
        private val arrivalResult: List<BusArrival> = emptyList(),
    ) : GyeonggiBusApi {
        var nearbyCallCount = 0
        override suspend fun searchStops(query: String) = searchResult
        override suspend fun fetchNearbyStops(latitude: Double, longitude: Double): List<BusStop> {
            nearbyCallCount += 1
            return emptyList()
        }
        override suspend fun fetchRoutes(stopId: Long) = emptyList<BusRoute>()
        override suspend fun fetchArrivals(stopId: Long) = arrivalResult
    }

    private class FakeSeoulBusApi(
        private val failure: Exception? = null,
        private val routeResult: List<BusRoute> = emptyList(),
        private val arrivals: Map<Long, List<BusArrival>> = emptyMap(),
        private val failedRouteId: Long? = null,
    ) : SeoulBusApi {
        var nearbyCallCount = 0
        override suspend fun searchStops(query: String): List<BusStop> = failure?.let { throw it } ?: emptyList()
        override suspend fun fetchNearbyStops(latitude: Double, longitude: Double): List<BusStop> {
            nearbyCallCount += 1
            return failure?.let { throw it } ?: emptyList()
        }
        override suspend fun fetchRoutes(arsId: String) = routeResult
        override suspend fun fetchArrivalsByRoute(routeId: Long): List<BusArrival> {
            if (routeId == failedRouteId) throw IllegalStateException()
            return arrivals[routeId].orEmpty()
        }
    }
}
