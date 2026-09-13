package dev.utrpanic.dash.data.local

import dev.utrpanic.dash.domain.model.BoardingPoint
import dev.utrpanic.dash.domain.model.BoardingPointConfiguration
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.domain.model.BusStopId
import dev.utrpanic.dash.domain.model.ServiceRegion
import dev.utrpanic.dash.domain.repository.BoardingPointRepository

class RoomBoardingPointRepository(
    private val dao: BoardingPointDao,
    private val initialConfiguration: BoardingPointConfiguration = InitialBoardingPoints.configuration,
) : BoardingPointRepository {
    override suspend fun loadConfiguration(): BoardingPointConfiguration {
        val configuration = dao.configuration()
        if (configuration == null) {
            saveConfiguration(initialConfiguration)
            return initialConfiguration
        }
        val routeEntities = dao.routes().groupBy(SelectedRouteEntity::stopMembershipId)
        val stopEntities = dao.stops().groupBy(BoardingPointStopEntity::boardingPointId)
        return BoardingPointConfiguration(
            boardingPoints = dao.boardingPoints().map { point ->
                BoardingPoint(
                    id = point.id,
                    name = point.name,
                    routes = stopEntities[point.id].orEmpty().associate { stop ->
                        stop.toDomain() to routeEntities[stop.membershipId].orEmpty().mapTo(linkedSetOf()) {
                            it.toDomain()
                        }
                    },
                )
            },
            currentBoardingPointId = configuration.currentBoardingPointId,
        )
    }

    override suspend fun saveConfiguration(configuration: BoardingPointConfiguration) {
        val points = mutableListOf<BoardingPointEntity>()
        val stops = mutableListOf<BoardingPointStopEntity>()
        val routes = mutableListOf<SelectedRouteEntity>()
        configuration.boardingPoints.forEachIndexed { pointIndex, point ->
            points += BoardingPointEntity(point.id, point.name, pointIndex)
            point.routes.forEach { (stop, selectedRoutes) ->
                val stopMembershipId = "${point.id}|${stop.id.storageKey}"
                stops += stop.toEntity(point.id, stopMembershipId)
                selectedRoutes.forEach { route ->
                    routes += SelectedRouteEntity(
                        membershipId = "$stopMembershipId|${route.region.name}|${route.id}",
                        stopMembershipId = stopMembershipId,
                        routeId = route.id,
                        number = route.number,
                        region = route.region.name,
                    )
                }
            }
        }
        dao.replaceAll(
            ConfigurationEntity(currentBoardingPointId = configuration.currentBoardingPointId),
            points,
            stops,
            routes,
        )
    }
}

private fun BusStop.toEntity(boardingPointId: String, membershipId: String) = BoardingPointStopEntity(
    membershipId = membershipId,
    boardingPointId = boardingPointId,
    stopId = id.stopId,
    region = id.region.name,
    arsId = (id as? BusStopId.Seoul)?.arsId,
    name = name,
    alias = alias,
    latitude = latitude,
    longitude = longitude,
)

private fun BoardingPointStopEntity.toDomain() = BusStop(
    id = when (ServiceRegion.valueOf(region)) {
        ServiceRegion.GYEONGGI -> BusStopId.Gyeonggi(stopId)
        ServiceRegion.SEOUL -> BusStopId.Seoul(stopId, requireNotNull(arsId))
    },
    name = name,
    alias = alias,
    latitude = latitude,
    longitude = longitude,
)

private fun SelectedRouteEntity.toDomain() = BusRoute(
    id = routeId,
    number = number,
    region = ServiceRegion.valueOf(region),
)
