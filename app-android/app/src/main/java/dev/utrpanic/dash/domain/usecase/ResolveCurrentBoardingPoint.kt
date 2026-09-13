package dev.utrpanic.dash.domain.usecase

import dev.utrpanic.dash.domain.location.UserLocation
import dev.utrpanic.dash.domain.location.UserLocationProvider
import dev.utrpanic.dash.domain.model.BoardingPoint
import dev.utrpanic.dash.domain.model.BoardingPointConfiguration
import dev.utrpanic.dash.domain.repository.BoardingPointRepository
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt
import kotlinx.coroutines.withTimeout

class ResolveCurrentBoardingPoint(
    private val repository: BoardingPointRepository,
    private val locationProvider: UserLocationProvider,
) {
    suspend operator fun invoke(): CurrentBoardingPointResolution {
        val configuration = repository.loadConfiguration()
        val location = runCatching { withTimeout(5_000) { locationProvider.currentLocation() } }.getOrNull()
        val nearest = location?.let { nearestValidPoint(configuration.boardingPoints, it) }
        if (nearest != null) {
            if (configuration.currentBoardingPointId != nearest.id) {
                repository.saveConfiguration(configuration.copy(currentBoardingPointId = nearest.id))
            }
            return CurrentBoardingPointResolution(nearest, SelectionSource.CURRENT_LOCATION)
        }

        val stored = configuration.boardingPoints.firstOrNull {
            it.id == configuration.currentBoardingPointId
        }
        return CurrentBoardingPointResolution(stored, SelectionSource.STORED_FALLBACK)
    }

    private fun nearestValidPoint(
        points: List<BoardingPoint>,
        location: UserLocation,
    ): BoardingPoint? = points.asSequence()
        .filter(BoardingPoint::hasSelectedRoutes)
        .filter { it.centerLatitude != null && it.centerLongitude != null }
        .minByOrNull { point ->
            distanceSquared(
                location.latitude,
                location.longitude,
                requireNotNull(point.centerLatitude),
                requireNotNull(point.centerLongitude),
            )
        }

    private fun distanceSquared(
        firstLatitude: Double,
        firstLongitude: Double,
        secondLatitude: Double,
        secondLongitude: Double,
    ): Double {
        val latitudeDelta = Math.toRadians(secondLatitude - firstLatitude)
        val longitudeDelta = Math.toRadians(secondLongitude - firstLongitude)
        val firstLatitudeRadians = Math.toRadians(firstLatitude)
        val secondLatitudeRadians = Math.toRadians(secondLatitude)
        val haversine = sin(latitudeDelta / 2).pow(2) +
            cos(firstLatitudeRadians) * cos(secondLatitudeRadians) * sin(longitudeDelta / 2).pow(2)
        return asin(sqrt(haversine)).pow(2)
    }
}

data class CurrentBoardingPointResolution(
    val boardingPoint: BoardingPoint?,
    val source: SelectionSource,
)

enum class SelectionSource {
    CURRENT_LOCATION,
    STORED_FALLBACK,
}
