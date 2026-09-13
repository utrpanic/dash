package dev.utrpanic.dash.data.local

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import dev.utrpanic.dash.domain.model.BoardingPoint
import dev.utrpanic.dash.domain.model.BoardingPointConfiguration
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.domain.model.BusStopId
import dev.utrpanic.dash.domain.model.ServiceRegion
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class RoomBoardingPointRepositoryTest {
    private val context = ApplicationProvider.getApplicationContext<android.content.Context>()
    private lateinit var database: DashDatabase

    @Before
    fun setUp() {
        context.deleteDatabase(DATABASE_NAME)
        database = openDatabase()
    }

    @After
    fun tearDown() {
        database.close()
        context.deleteDatabase(DATABASE_NAME)
    }

    @Test
    fun firstLoadPersistsInitialConfiguration() = runBlocking {
        val expected = InitialBoardingPoints.configuration
        val firstLoad = RoomBoardingPointRepository(database.boardingPointDao()).loadConfiguration()
        database.close()
        database = openDatabase()

        val reopenedLoad = RoomBoardingPointRepository(database.boardingPointDao()).loadConfiguration()

        assertEquals(expected, firstLoad)
        assertEquals(expected, reopenedLoad)
    }

    @Test
    fun configurationRoundTripsAfterDatabaseReopen() = runBlocking {
        val stop = BusStop(BusStopId.Gyeonggi(202000219), "수원역", " 외부 ", 37.2, 127.0)
        val route = BusRoute(200000037, "13", ServiceRegion.GYEONGGI)
        val expected = BoardingPointConfiguration(
            boardingPoints = listOf(BoardingPoint("custom", "출근", mapOf(stop to setOf(route)))),
            currentBoardingPointId = "custom",
        )
        RoomBoardingPointRepository(database.boardingPointDao()).saveConfiguration(expected)
        database.close()
        database = openDatabase()

        assertEquals(expected, RoomBoardingPointRepository(database.boardingPointDao()).loadConfiguration())
    }

    private fun openDatabase() = Room.databaseBuilder(context, DashDatabase::class.java, DATABASE_NAME).build()

    private companion object {
        const val DATABASE_NAME = "boarding-point-test.db"
    }
}
