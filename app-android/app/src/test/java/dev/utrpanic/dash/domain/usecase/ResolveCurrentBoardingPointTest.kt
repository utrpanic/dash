package dev.utrpanic.dash.domain.usecase

import dev.utrpanic.dash.domain.location.UserLocation
import dev.utrpanic.dash.domain.location.UserLocationProvider
import dev.utrpanic.dash.domain.model.BoardingPoint
import dev.utrpanic.dash.domain.model.BoardingPointConfiguration
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.domain.model.BusStopId
import dev.utrpanic.dash.domain.model.ServiceRegion
import dev.utrpanic.dash.domain.repository.BoardingPointRepository
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ResolveCurrentBoardingPointTest {
    @Test
    fun currentLocationAlwaysOverridesStoredSelection() = runBlocking {
        val far = point("far", 37.0, 127.0)
        val near = point("near", 37.5, 126.9)
        val repository = FakeRepository(BoardingPointConfiguration(listOf(far, near), far.id))

        val result = ResolveCurrentBoardingPoint(repository) { UserLocation(37.5001, 126.9001) }()

        assertEquals(near, result.boardingPoint)
        assertEquals(SelectionSource.CURRENT_LOCATION, result.source)
        assertEquals(near.id, repository.saved?.currentBoardingPointId)
    }

    @Test
    fun pointsWithoutSelectedRoutesAreExcludedFromAutomaticSelection() = runBlocking {
        val invalid = point("invalid", 37.5, 126.9, hasRoutes = false)
        val valid = point("valid", 37.6, 127.0)
        val repository = FakeRepository(BoardingPointConfiguration(listOf(invalid, valid), invalid.id))

        val result = ResolveCurrentBoardingPoint(repository) { UserLocation(37.5, 126.9) }()

        assertEquals(valid, result.boardingPoint)
    }

    @Test
    fun locationFailureFallsBackToStoredSelectionWithoutSaving() = runBlocking {
        val stored = point("stored", 37.0, 127.0)
        val repository = FakeRepository(BoardingPointConfiguration(listOf(stored), stored.id))

        val result = ResolveCurrentBoardingPoint(repository, UserLocationProvider { throw SecurityException() })()

        assertEquals(stored, result.boardingPoint)
        assertEquals(SelectionSource.STORED_FALLBACK, result.source)
        assertNull(repository.saved)
    }

    private fun point(id: String, latitude: Double, longitude: Double, hasRoutes: Boolean = true): BoardingPoint {
        val stop = BusStop(BusStopId.Seoul(id.hashCode().toLong(), id), id, latitude = latitude, longitude = longitude)
        val routes = if (hasRoutes) setOf(BusRoute(1, "1", ServiceRegion.SEOUL)) else emptySet()
        return BoardingPoint(id, id, mapOf(stop to routes))
    }

    private class FakeRepository(private var configuration: BoardingPointConfiguration) : BoardingPointRepository {
        var saved: BoardingPointConfiguration? = null
        override suspend fun loadConfiguration() = configuration
        override suspend fun saveConfiguration(configuration: BoardingPointConfiguration) {
            saved = configuration
            this.configuration = configuration
        }
    }
}
