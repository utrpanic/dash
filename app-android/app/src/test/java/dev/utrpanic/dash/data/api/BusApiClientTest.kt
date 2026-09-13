package dev.utrpanic.dash.data.api

import dev.utrpanic.dash.domain.model.BusStopId
import dev.utrpanic.dash.domain.model.ServiceRegion
import kotlinx.coroutines.runBlocking
import okhttp3.HttpUrl
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BusApiClientTest {
    @Test
    fun gyeonggiRouteParserAcceptsSingleObjectAndNumericRouteName() = runBlocking {
        val transport = StubTransport(
            """
            {"response":{"msgHeader":{"resultCode":0,"resultMessage":"OK"},"msgBody":{"busRouteList":{"routeId":"200000037","routeName":13}}}}
            """.trimIndent(),
        )

        val routes = GyeonggiBusApiClient("key", transport).fetchRoutes(202000219)

        assertEquals(1, routes.size)
        assertEquals(200000037L, routes.single().id)
        assertEquals("13", routes.single().number)
        assertEquals(ServiceRegion.GYEONGGI, routes.single().region)
        assertEquals("202000219", transport.lastUrl!!.queryParameter("stationId"))
    }

    @Test
    fun gyeonggiArrivalResultCodeFourIsAnEmptySuccess() = runBlocking {
        val transport = StubTransport(
            """
            {"response":{"msgHeader":{"resultCode":4,"resultMessage":"결과 없음"}}}
            """.trimIndent(),
        )

        assertTrue(GyeonggiBusApiClient("key", transport).fetchArrivals(1).isEmpty())
    }

    @Test
    fun seoulParserAcceptsNumericFieldsAndFallbackNames() = runBlocking {
        val transport = StubTransport(
            """
            {
              "msgHeader":{"headerCd":"0","headerMsg":"OK"},
              "msgBody":{"itemList":{"stationId":118000005,"stationNm":"영등포역","arsId":19005,"gpsX":126.905,"gpsY":37.515}}
            }
            """.trimIndent(),
        )

        val stops = SeoulBusApiClient("key", transport).searchStops("영등포역")

        assertEquals(1, stops.size)
        assertEquals(BusStopId.Seoul(118000005, "19005"), stops.single().id)
        assertEquals("영등포역", stops.single().name)
        assertEquals("json", transport.lastUrl!!.queryParameter("resultType"))
    }

    private class StubTransport(private val response: String) : HttpTransport {
        var lastUrl: HttpUrl? = null

        override suspend fun get(url: HttpUrl): String {
            lastUrl = url
            return response
        }
    }
}
