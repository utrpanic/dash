package dev.utrpanic.dash.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [
        ConfigurationEntity::class,
        BoardingPointEntity::class,
        BoardingPointStopEntity::class,
        SelectedRouteEntity::class,
    ],
    version = 1,
    exportSchema = true,
)
abstract class DashDatabase : RoomDatabase() {
    abstract fun boardingPointDao(): BoardingPointDao

    companion object {
        fun open(context: Context, name: String = "dash.db"): DashDatabase = Room.databaseBuilder(
            context.applicationContext,
            DashDatabase::class.java,
            name,
        ).build()
    }
}
