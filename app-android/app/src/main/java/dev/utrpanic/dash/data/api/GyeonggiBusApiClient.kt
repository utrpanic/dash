package dev.utrpanic.dash.data.api

import com.google.gson.JsonObject
import com.google.gson.JsonParser
import dev.utrpanic.dash.domain.model.BusArrival
import dev.utrpanic.dash.domain.model.BusArrivalPrediction
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.domain.model.BusStopId
import dev.utrpanic.dash.domain.model.ServiceRegion
import okhttp3.HttpUrl

class GyeonggiBusApiClient(
    private val serviceKey: String,
    private val transport: HttpTransport = OkHttpTransport(),
) : GyeonggiBusApi {
    override suspend fun searchStops(query: String): List<BusStop> = fetch(
        path = "/6410000/busstationservice/v2/getBusStationListv2",
        parameters = mapOf("keyword" to query),
    ).bodyItems("busStationList").mapNotNull(::busStop)

    override suspend fun fetchNearbyStops(latitude: Double, longitude: Double): List<BusStop> = fetch(
        path = "/6410000/busstationservice/v2/getBusStationAroundListv2",
        parameters = mapOf("x" to longitude.toString(), "y" to latitude.toString()),
    ).bodyItems("busStationAroundList").mapNotNull(::busStop)

    override suspend fun fetchRoutes(stopId: Long): List<BusRoute> = fetch(
        path = "/6410000/busstationservice/v2/getBusStationViaRouteListv2",
        parameters = mapOf("stationId" to stopId.toString()),
    ).bodyItems("busRouteList").map { item ->
        BusRoute(
            id = item.long("routeId") ?: throw BusApiException.MalformedResponse("Missing routeId"),
            number = item.string("routeName"),
            region = ServiceRegion.GYEONGGI,
        )
    }

    override suspend fun fetchArrivals(stopId: Long): List<BusArrival> = fetch(
        path = "/6410000/busarrivalservice/v2/getBusArrivalListv2",
        parameters = mapOf("stationId" to stopId.toString()),
        allowedResultCodes = setOf(0, 4),
    ).bodyItems("busArrivalList").map(::arrival)

    private suspend fun fetch(
        path: String,
        parameters: Map<String, String>,
        allowedResultCodes: Set<Int> = setOf(0),
    ): JsonObject {
        val builder = HttpUrl.Builder()
            .scheme("https")
            .host("apis.data.go.kr")
            .addPathSegments(path.removePrefix("/"))
            .addServiceKey(serviceKey)
        parameters.forEach { (name, value) -> builder.addQueryParameter(name, value) }
        builder.addQueryParameter("format", "json")

        val root = parseObject(transport.get(builder.build()))
        val response = root.requiredObject("response")
        val header = response.requiredObject("msgHeader")
        val resultCode = header.int("resultCode")
            ?: throw BusApiException.MalformedResponse("Missing resultCode")
        if (resultCode !in allowedResultCodes) {
            throw BusApiException.ApiFailure(resultCode.toString(), header.string("resultMessage"))
        }
        return response
    }

    private fun JsonObject.bodyItems(name: String): List<JsonObject> =
        get("msgBody")?.takeIf { it.isJsonObject }?.asJsonObject?.items(name).orEmpty()

    private fun busStop(item: JsonObject): BusStop? {
        val stopId = item.long("stationId") ?: return null
        val longitude = item.double("x") ?: return null
        val latitude = item.double("y") ?: return null
        if (longitude == 0.0 || latitude == 0.0) return null
        return BusStop(
            id = BusStopId.Gyeonggi(stopId),
            name = item.string("stationName"),
            latitude = latitude,
            longitude = longitude,
        )
    }

    private fun arrival(item: JsonObject): BusArrival = BusArrival(
        stopId = item.long("stationId") ?: throw BusApiException.MalformedResponse("Missing stationId"),
        route = BusRoute(
            id = item.long("routeId") ?: throw BusApiException.MalformedResponse("Missing routeId"),
            number = item.string("routeName"),
            region = ServiceRegion.GYEONGGI,
        ),
        stopOrder = item.int("staOrder") ?: throw BusApiException.MalformedResponse("Missing staOrder"),
        operationState = item.string("flag"),
        firstPrediction = prediction(item, 1),
        secondPrediction = prediction(item, 2),
    )

    private fun prediction(item: JsonObject, index: Int): BusArrivalPrediction? {
        val minutes = item.int("predictTime$index")
        val seconds = item.int("predictTimeSec$index")
        val location = item.int("locationNo$index")
        val vehicleId = item.long("vehId$index")
        if (minutes == null && seconds == null && location == null && vehicleId == null) return null
        return BusArrivalPrediction(
            minutes = minutes,
            seconds = seconds,
            locationNumber = location,
            plateNumber = item.string("plateNo$index"),
            remainingSeatCount = item.int("remainSeatCnt$index"),
            stateCode = item.int("stateCd$index"),
            stopName = item.string("stationNm$index"),
            vehicleId = vehicleId,
        )
    }
}

internal fun parseObject(json: String): JsonObject = try {
    val element = JsonParser.parseString(json)
    if (!element.isJsonObject) throw BusApiException.MalformedResponse("Invalid JSON response root")
    element.asJsonObject
} catch (exception: BusApiException) {
    throw exception
} catch (_: Exception) {
    throw BusApiException.MalformedResponse("Unable to parse JSON response")
}
