package dev.utrpanic.dash

import android.app.Application
import dev.utrpanic.dash.data.api.GyeonggiBusApiClient
import dev.utrpanic.dash.data.api.SeoulBusApiClient
import dev.utrpanic.dash.data.local.DashDatabase
import dev.utrpanic.dash.data.local.RoomBoardingPointRepository
import dev.utrpanic.dash.data.location.AndroidUserLocationProvider
import dev.utrpanic.dash.data.repository.LiveBusArrivalRepository
import dev.utrpanic.dash.data.repository.LiveBusRouteRepository
import dev.utrpanic.dash.data.repository.LiveBusStopRepository

class DashApplication : Application() {
    val container by lazy { DashContainer(this) }
}

class DashContainer(application: Application) {
    private val database = DashDatabase.open(application)
    private val gyeonggiApi = GyeonggiBusApiClient(BuildConfig.DATA_GO_KR_SERVICE_KEY)
    private val seoulApi = SeoulBusApiClient(BuildConfig.DATA_GO_KR_SERVICE_KEY)

    val boardingPointRepository = RoomBoardingPointRepository(database.boardingPointDao())
    val busStopRepository = LiveBusStopRepository(gyeonggiApi, seoulApi)
    val busRouteRepository = LiveBusRouteRepository(gyeonggiApi, seoulApi)
    val busArrivalRepository = LiveBusArrivalRepository(gyeonggiApi, seoulApi)
    val locationProvider = AndroidUserLocationProvider(application)
}
