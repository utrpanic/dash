package dev.utrpanic.dash.domain.usecase

import dev.utrpanic.dash.domain.model.BoardingPoint
import dev.utrpanic.dash.domain.model.UpcomingBus
import dev.utrpanic.dash.domain.model.sortedByArrival
import dev.utrpanic.dash.domain.repository.BusArrivalRepository
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope

class FetchUpcomingBuses(private val repository: BusArrivalRepository) {
    suspend operator fun invoke(boardingPoint: BoardingPoint): List<UpcomingBus> = coroutineScope {
        val requests = boardingPoint.routes.filterValues { it.isNotEmpty() }
        if (requests.isEmpty()) return@coroutineScope emptyList()
        val results = requests.map { (stop, routes) ->
            async {
                try {
                    Result.success(
                        repository.fetchArrivals(stop, routes).flatMap {
                            it.upcomingBuses(boardingPoint, stop)
                        },
                    )
                } catch (exception: CancellationException) {
                    throw exception
                } catch (exception: Exception) {
                    Result.failure(exception)
                }
            }
        }.awaitAll()
        if (results.none(Result<List<UpcomingBus>>::isSuccess)) {
            throw UpcomingBusesUnavailableException()
        }
        results.flatMap { it.getOrDefault(emptyList()) }.sortedByArrival().take(10)
    }
}

class UpcomingBusesUnavailableException : IllegalStateException("All arrival requests failed")
