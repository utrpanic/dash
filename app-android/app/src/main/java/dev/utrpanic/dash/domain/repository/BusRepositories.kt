package dev.utrpanic.dash.domain.repository

import dev.utrpanic.dash.domain.model.BusArrival
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop

interface BusStopRepository {
    suspend fun searchStops(query: String): List<BusStop>

    suspend fun fetchNearbyStops(
        latitude: Double,
        longitude: Double,
    ): List<BusStop>
}

interface BusRouteRepository {
    suspend fun fetchRoutes(busStop: BusStop): List<BusRoute>
}

interface BusArrivalRepository {
    suspend fun fetchArrivals(
        busStop: BusStop,
        routes: Set<BusRoute>,
    ): List<BusArrival>
}
