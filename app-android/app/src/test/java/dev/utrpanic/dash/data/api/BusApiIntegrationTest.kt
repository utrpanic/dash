package dev.utrpanic.dash.data.api

import dev.utrpanic.dash.BuildConfig
import dev.utrpanic.dash.domain.model.BusStopId
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Before
import org.junit.Test

class BusApiIntegrationTest {
    private val serviceKey = BuildConfig.DATA_GO_KR_SERVICE_KEY
    private val gyeonggi = GyeonggiBusApiClient(serviceKey)
    private val seoul = SeoulBusApiClient(serviceKey)

    @Before
    fun requireRealServiceKey() {
        assumeTrue(serviceKey.isNotBlank() && !serviceKey.startsWith("DEFAULT_"))
    }

    @Test
    fun searchesStopsInBothRegions() = kotlinx.coroutines.runBlocking {
        val gyeonggiStops = gyeonggi.searchStops("수원역")
        val seoulStops = seoul.searchStops("영등포역")

        assertTrue(gyeonggiStops.any { it.name.contains("수원역") })
        assertTrue(gyeonggiStops.all { it.id is BusStopId.Gyeonggi })
        assertTrue(seoulStops.any { it.name.contains("영등포역") })
        assertTrue(seoulStops.all { it.id is BusStopId.Seoul && it.id.arsId.isNotEmpty() })
    }

    @Test
    fun fetchesRoutesForInitialStops() = kotlinx.coroutines.runBlocking {
        assertTrue(gyeonggi.fetchRoutes(202000219).isNotEmpty())
        assertTrue(seoul.fetchRoutes("19005").any { it.number == "662" })
        assertTrue(seoul.fetchRoutes("19282").any { it.number == "662" })
    }

    @Test
    fun fetchesArrivalResponsesInBothRegions() = kotlinx.coroutines.runBlocking {
        val gyeonggiArrivals = gyeonggi.fetchArrivals(200000275)
        val seoulArrivals = seoul.fetchArrivalsByRoute(100100550)

        assertTrue(gyeonggiArrivals.all { it.stopId == 200000275L })
        assertTrue(seoulArrivals.isNotEmpty())
        assertTrue(seoulArrivals.all { it.route.id == 100100550L })
        assertEquals("662", seoulArrivals.first().route.number)
    }
}
