package dev.utrpanic.dash.data.repository

import dev.utrpanic.dash.data.api.GyeonggiBusApi
import dev.utrpanic.dash.data.api.SeoulBusApi
import dev.utrpanic.dash.domain.model.BusArrival
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.domain.model.BusStopId
import dev.utrpanic.dash.domain.repository.BusArrivalRepository
import dev.utrpanic.dash.domain.repository.BusRouteRepository
import dev.utrpanic.dash.domain.repository.BusStopRepository
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope

class LiveBusStopRepository(
    private val gyeonggiApi: GyeonggiBusApi,
    private val seoulApi: SeoulBusApi,
) : BusStopRepository {
    override suspend fun searchStops(query: String): List<BusStop> {
        val normalizedQuery = query.trim()
        if (normalizedQuery.isEmpty()) return emptyList()
        return combine(
            first = { gyeonggiApi.searchStops(normalizedQuery) },
            second = { seoulApi.searchStops(normalizedQuery) },
        )
    }

    override suspend fun fetchNearbyStops(latitude: Double, longitude: Double): List<BusStop> {
        if (latitude !in 36.8..38.4 || longitude !in 126.0..128.3) return emptyList()
        return combine(
            first = { gyeonggiApi.fetchNearbyStops(latitude, longitude) },
            second = { seoulApi.fetchNearbyStops(latitude, longitude) },
        )
    }

    private suspend fun combine(
        first: suspend () -> List<BusStop>,
        second: suspend () -> List<BusStop>,
    ): List<BusStop> = coroutineScope {
        val results = listOf(async { capture(first) }, async { capture(second) }).awaitAll()
        if (results.none(Result<List<BusStop>>::isSuccess)) {
            throw BusRepositoryUnavailableException()
        }
        results.flatMap { it.getOrDefault(emptyList()) }.distinctBy(BusStop::id)
    }
}

class LiveBusRouteRepository(
    private val gyeonggiApi: GyeonggiBusApi,
    private val seoulApi: SeoulBusApi,
) : BusRouteRepository {
    override suspend fun fetchRoutes(busStop: BusStop): List<BusRoute> = when (val id = busStop.id) {
        is BusStopId.Gyeonggi -> gyeonggiApi.fetchRoutes(id.stopId)
        is BusStopId.Seoul -> seoulApi.fetchRoutes(id.arsId)
    }
}

class LiveBusArrivalRepository(
    private val gyeonggiApi: GyeonggiBusApi,
    private val seoulApi: SeoulBusApi,
) : BusArrivalRepository {
    override suspend fun fetchArrivals(busStop: BusStop, routes: Set<BusRoute>): List<BusArrival> {
        if (routes.isEmpty()) return emptyList()
        return when (val id = busStop.id) {
            is BusStopId.Gyeonggi -> {
                val routeIds = routes.mapTo(mutableSetOf(), BusRoute::id)
                gyeonggiApi.fetchArrivals(id.stopId).filter { it.route.id in routeIds }
            }

            is BusStopId.Seoul -> fetchSeoulArrivals(id.stopId, routes)
        }
    }

    private suspend fun fetchSeoulArrivals(
        stopId: Long,
        routes: Set<BusRoute>,
    ): List<BusArrival> = coroutineScope {
        val results = routes.map { route ->
            async { capture { seoulApi.fetchArrivalsByRoute(route.id).filter { it.stopId == stopId } } }
        }.awaitAll()
        if (results.none(Result<List<BusArrival>>::isSuccess)) {
            throw BusRepositoryUnavailableException()
        }
        results.flatMap { it.getOrDefault(emptyList()) }
    }
}

class BusRepositoryUnavailableException : IllegalStateException("All bus API requests failed")

private suspend fun <T> capture(operation: suspend () -> T): Result<T> = try {
    Result.success(operation())
} catch (exception: CancellationException) {
    throw exception
} catch (exception: Exception) {
    Result.failure(exception)
}
