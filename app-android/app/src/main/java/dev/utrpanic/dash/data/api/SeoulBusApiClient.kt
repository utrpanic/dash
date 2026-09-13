package dev.utrpanic.dash.data.api

import com.google.gson.JsonElement
import com.google.gson.JsonObject
import dev.utrpanic.dash.domain.model.BusArrival
import dev.utrpanic.dash.domain.model.BusArrivalPrediction
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.domain.model.BusStopId
import dev.utrpanic.dash.domain.model.ServiceRegion
import okhttp3.HttpUrl

class SeoulBusApiClient(
    private val serviceKey: String,
    private val transport: HttpTransport = OkHttpTransport(),
) : SeoulBusApi {
    override suspend fun searchStops(query: String): List<BusStop> = fetch(
        path = "/api/rest/stationinfo/getStationByName",
        parameters = mapOf("stSrch" to query),
    ).map(::busStop)

    override suspend fun fetchNearbyStops(latitude: Double, longitude: Double): List<BusStop> = fetch(
        path = "/api/rest/stationinfo/getStationByPos",
        parameters = mapOf(
            "tmX" to longitude.toString(),
            "tmY" to latitude.toString(),
            "radius" to "1000",
        ),
    ).map(::busStop)

    override suspend fun fetchRoutes(arsId: String): List<BusRoute> = fetch(
        path = "/api/rest/stationinfo/getRouteByStation",
        parameters = mapOf("arsId" to arsId),
    ).map { item ->
        BusRoute(
            id = item.long("busRouteId") ?: throw BusApiException.MalformedResponse("Missing busRouteId"),
            number = item.string("busRouteNm"),
            region = ServiceRegion.SEOUL,
        )
    }

    override suspend fun fetchArrivalsByRoute(routeId: Long): List<BusArrival> = fetch(
        path = "/api/rest/arrive/getArrInfoByRouteAll",
        parameters = mapOf("busRouteId" to routeId.toString()),
    ).map(::arrival)

    private suspend fun fetch(path: String, parameters: Map<String, String>): List<JsonObject> {
        val builder = HttpUrl.Builder()
            .scheme("http")
            .host("ws.bus.go.kr")
            .addPathSegments(path.removePrefix("/"))
            .addServiceKey(serviceKey)
        parameters.forEach { (name, value) -> builder.addQueryParameter(name, value) }
        builder.addQueryParameter("resultType", "json")

        val root = parseObject(transport.get(builder.build()))
        val header = mutableMapOf<String, String>()
        root.objectOrEmpty("comMsgHeader").entrySet()
            .forEach { (name, value) -> header[name] = value.scalarString() }
        root.objectOrEmpty("msgHeader").entrySet()
            .forEach { (name, value) -> header[name] = value.scalarString() }
        val resultCode = header["headerCd"] ?: header["resultCode"] ?: header["returnReasonCode"]
            ?: throw BusApiException.MalformedResponse("Missing result code")
        val resultMessage = header["headerMsg"] ?: header["resultMessage"] ?: header["returnAuthMsg"].orEmpty()
        if (resultCode != "0" && resultCode != "00") {
            throw BusApiException.ApiFailure(resultCode, resultMessage)
        }
        return root.objectOrEmpty("msgBody").items("itemList")
    }

    private fun busStop(item: JsonObject): BusStop {
        val stopId = item.long("stId") ?: item.long("stationId")
            ?: throw BusApiException.MalformedResponse("Missing stId")
        val longitude = item.double("tmX") ?: item.double("gpsX")
            ?: throw BusApiException.MalformedResponse("Missing longitude")
        val latitude = item.double("tmY") ?: item.double("gpsY")
            ?: throw BusApiException.MalformedResponse("Missing latitude")
        return BusStop(
            id = BusStopId.Seoul(stopId, item.string("arsId")),
            name = item.string("stNm").ifEmpty { item.string("stationNm") },
            latitude = latitude,
            longitude = longitude,
        )
    }

    private fun arrival(item: JsonObject): BusArrival = BusArrival(
        stopId = item.long("stId") ?: throw BusApiException.MalformedResponse("Missing stId"),
        route = BusRoute(
            id = item.long("busRouteId") ?: throw BusApiException.MalformedResponse("Missing busRouteId"),
            number = item.string("busRouteAbrv").ifEmpty { item.string("rtNm") },
            region = ServiceRegion.SEOUL,
        ),
        stopOrder = item.int("staOrd") ?: throw BusApiException.MalformedResponse("Missing staOrd"),
        operationState = if (item.string("deTourAt") == "11") "우회" else "",
        firstPrediction = prediction(item, 1),
        secondPrediction = prediction(item, 2),
    )

    private fun prediction(item: JsonObject, index: Int): BusArrivalPrediction? {
        val seconds = item.int("exps$index")
        val plateNumber = item.string("plainNo$index")
        val vehicleId = item.long("vehId$index")?.takeIf { it > 0 }
        val message = item.string("arrmsg$index")
        if (vehicleId == null && plateNumber.isEmpty() && (seconds ?: 0) <= 0 &&
            (message.isEmpty() || message == "운행종료")
        ) return null
        return BusArrivalPrediction(
            minutes = seconds?.div(60),
            seconds = seconds,
            locationNumber = null,
            plateNumber = plateNumber,
            remainingSeatCount = item.int("rerdie_Div$index")
                ?.takeIf { it == 2 }
                ?.let { item.int("reride_Num$index") },
            stateCode = item.int("isArrive$index"),
            stopName = item.string("stationNm$index"),
            vehicleId = vehicleId,
        )
    }
}

private fun JsonObject.objectOrEmpty(name: String): JsonObject =
    get(name)?.takeIf(JsonElement::isJsonObject)?.asJsonObject ?: JsonObject()

private fun JsonElement.scalarString(): String =
    takeUnless(JsonElement::isJsonNull)?.takeIf(JsonElement::isJsonPrimitive)?.asJsonPrimitive?.asString.orEmpty()
