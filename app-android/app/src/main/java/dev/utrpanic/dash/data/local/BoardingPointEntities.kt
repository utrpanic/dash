package dev.utrpanic.dash.data.local

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index

@Entity(tableName = "configuration", primaryKeys = ["singletonId"])
data class ConfigurationEntity(
    val singletonId: Int = 1,
    val currentBoardingPointId: String?,
)

@Entity(tableName = "boarding_points", primaryKeys = ["id"])
data class BoardingPointEntity(
    val id: String,
    val name: String,
    val sortIndex: Int,
)

@Entity(
    tableName = "boarding_point_stops",
    primaryKeys = ["membershipId"],
    foreignKeys = [
        ForeignKey(
            entity = BoardingPointEntity::class,
            parentColumns = ["id"],
            childColumns = ["boardingPointId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("boardingPointId")],
)
data class BoardingPointStopEntity(
    val membershipId: String,
    val boardingPointId: String,
    val stopId: Long,
    val region: String,
    val arsId: String?,
    val name: String,
    val alias: String?,
    val latitude: Double,
    val longitude: Double,
)

@Entity(
    tableName = "selected_routes",
    primaryKeys = ["membershipId"],
    foreignKeys = [
        ForeignKey(
            entity = BoardingPointStopEntity::class,
            parentColumns = ["membershipId"],
            childColumns = ["stopMembershipId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("stopMembershipId")],
)
data class SelectedRouteEntity(
    val membershipId: String,
    val stopMembershipId: String,
    val routeId: Long,
    val number: String,
    val region: String,
)
