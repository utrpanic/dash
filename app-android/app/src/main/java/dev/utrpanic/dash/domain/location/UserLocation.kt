package dev.utrpanic.dash.domain.location

data class UserLocation(
    val latitude: Double,
    val longitude: Double,
)

fun interface UserLocationProvider {
    suspend fun currentLocation(): UserLocation
}

class UserLocationUnavailableException : IllegalStateException("Current location is unavailable")
