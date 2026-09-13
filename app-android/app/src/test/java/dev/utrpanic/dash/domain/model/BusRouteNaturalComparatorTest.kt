package dev.utrpanic.dash.domain.model

import org.junit.Assert.assertEquals
import org.junit.Test

class BusRouteNaturalComparatorTest {
    @Test
    fun sortsRouteNumbersNaturally() {
        val routes = listOf("10-2", "9-1", "10", "2-1", "9").mapIndexed { index, number ->
            BusRoute(index.toLong(), number, ServiceRegion.GYEONGGI)
        }

        assertEquals(
            listOf("2-1", "9", "9-1", "10", "10-2"),
            routes.sortedWith(BusRouteNaturalComparator).map(BusRoute::number),
        )
    }
}
