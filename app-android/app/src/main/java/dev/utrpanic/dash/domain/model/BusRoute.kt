package dev.utrpanic.dash.domain.model

data class BusRoute(
    val id: Long,
    val number: String,
    val region: ServiceRegion,
)

data class BusRouteInfo(
    val route: BusRoute,
    val routeTypeName: String,
    val regionName: String,
    val companyName: String,
    val startStopName: String,
    val endStopName: String,
)

data class BusRouteLinePoint(
    val sequence: Int,
    val x: Double,
    val y: Double,
)
