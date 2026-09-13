package dev.utrpanic.dash.domain.model

data class BoardingPoint(
    val id: String,
    val name: String,
    val routes: Map<BusStop, Set<BusRoute>>,
) {
    val hasSelectedRoutes: Boolean
        get() = routes.values.any(Set<BusRoute>::isNotEmpty)

    val centerLatitude: Double?
        get() = routes.keys.takeIf(Set<BusStop>::isNotEmpty)?.map(BusStop::latitude)?.average()

    val centerLongitude: Double?
        get() = routes.keys.takeIf(Set<BusStop>::isNotEmpty)?.map(BusStop::longitude)?.average()
}

data class BoardingPointConfiguration(
    val boardingPoints: List<BoardingPoint>,
    val currentBoardingPointId: String?,
)
