package dev.utrpanic.dash.data.api

import dev.utrpanic.dash.domain.model.BusArrival
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop

interface GyeonggiBusApi {
    suspend fun searchStops(query: String): List<BusStop>

    suspend fun fetchNearbyStops(latitude: Double, longitude: Double): List<BusStop>

    suspend fun fetchRoutes(stopId: Long): List<BusRoute>

    suspend fun fetchArrivals(stopId: Long): List<BusArrival>
}

interface SeoulBusApi {
    suspend fun searchStops(query: String): List<BusStop>

    suspend fun fetchNearbyStops(latitude: Double, longitude: Double): List<BusStop>

    suspend fun fetchRoutes(arsId: String): List<BusRoute>

    suspend fun fetchArrivalsByRoute(routeId: Long): List<BusArrival>
}

sealed class BusApiException(message: String) : Exception(message) {
    class MissingServiceKey : BusApiException("The data.go.kr service key is missing")

    class HttpStatus(val statusCode: Int) : BusApiException("Unexpected HTTP status: $statusCode")

    class ApiFailure(val code: String, apiMessage: String) :
        BusApiException("Bus API failed ($code): $apiMessage")

    class MalformedResponse(reason: String) : BusApiException(reason)
}
