package dev.utrpanic.dash.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Transaction

@Dao
interface BoardingPointDao {
    @Query("SELECT * FROM configuration WHERE singletonId = 1")
    suspend fun configuration(): ConfigurationEntity?

    @Query("SELECT * FROM boarding_points ORDER BY sortIndex")
    suspend fun boardingPoints(): List<BoardingPointEntity>

    @Query("SELECT * FROM boarding_point_stops")
    suspend fun stops(): List<BoardingPointStopEntity>

    @Query("SELECT * FROM selected_routes")
    suspend fun routes(): List<SelectedRouteEntity>

    @Insert
    suspend fun insertConfiguration(configuration: ConfigurationEntity)

    @Insert
    suspend fun insertBoardingPoints(boardingPoints: List<BoardingPointEntity>)

    @Insert
    suspend fun insertStops(stops: List<BoardingPointStopEntity>)

    @Insert
    suspend fun insertRoutes(routes: List<SelectedRouteEntity>)

    @Query("DELETE FROM selected_routes")
    suspend fun deleteRoutes()

    @Query("DELETE FROM boarding_point_stops")
    suspend fun deleteStops()

    @Query("DELETE FROM boarding_points")
    suspend fun deleteBoardingPoints()

    @Query("DELETE FROM configuration")
    suspend fun deleteConfiguration()

    @Transaction
    suspend fun replaceAll(
        configuration: ConfigurationEntity,
        boardingPoints: List<BoardingPointEntity>,
        stops: List<BoardingPointStopEntity>,
        routes: List<SelectedRouteEntity>,
    ) {
        deleteRoutes()
        deleteStops()
        deleteBoardingPoints()
        deleteConfiguration()
        insertConfiguration(configuration)
        if (boardingPoints.isNotEmpty()) insertBoardingPoints(boardingPoints)
        if (stops.isNotEmpty()) insertStops(stops)
        if (routes.isNotEmpty()) insertRoutes(routes)
    }
}
