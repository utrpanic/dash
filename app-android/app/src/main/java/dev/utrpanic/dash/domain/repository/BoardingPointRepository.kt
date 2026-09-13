package dev.utrpanic.dash.domain.repository

import dev.utrpanic.dash.domain.model.BoardingPointConfiguration

interface BoardingPointRepository {
    suspend fun loadConfiguration(): BoardingPointConfiguration

    suspend fun saveConfiguration(configuration: BoardingPointConfiguration)
}

class BoardingPointNotConfiguredException : IllegalStateException("Boarding points are not configured")
