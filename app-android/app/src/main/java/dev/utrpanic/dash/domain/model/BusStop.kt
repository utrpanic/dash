package dev.utrpanic.dash.domain.model

sealed interface BusStopId {
    val stopId: Long
    val region: ServiceRegion
    val storageKey: String

    data class Gyeonggi(
        override val stopId: Long,
    ) : BusStopId {
        override val region = ServiceRegion.GYEONGGI
        override val storageKey = "gyeonggi-$stopId"
    }

    data class Seoul(
        override val stopId: Long,
        val arsId: String,
    ) : BusStopId {
        override val region = ServiceRegion.SEOUL
        override val storageKey = "seoul-$stopId-$arsId"
    }
}

data class BusStop(
    val id: BusStopId,
    val name: String,
    val alias: String? = null,
    val latitude: Double,
    val longitude: Double,
) {
    val displayAlias = alias?.trim()?.takeIf(String::isNotEmpty)
}
