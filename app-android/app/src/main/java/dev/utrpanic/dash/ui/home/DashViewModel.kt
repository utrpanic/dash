package dev.utrpanic.dash.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import dev.utrpanic.dash.DashContainer
import dev.utrpanic.dash.domain.model.BoardingPoint
import dev.utrpanic.dash.domain.model.UpcomingBus
import dev.utrpanic.dash.domain.usecase.FetchUpcomingBuses
import dev.utrpanic.dash.domain.usecase.ResolveCurrentBoardingPoint
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.time.Instant
import java.util.UUID

enum class DashDestination { HOME, BOARDING_POINTS, EDIT_BOARDING_POINT, ADD_BUS_STOP, SELECT_BUS_ROUTES }

data class BoardingPointDraft(
    val originalId: String?,
    val name: String,
    val routes: Map<dev.utrpanic.dash.domain.model.BusStop, Set<dev.utrpanic.dash.domain.model.BusRoute>>,
)

data class DashUiState(
    val isLoadingConfiguration: Boolean = true,
    val currentBoardingPoint: BoardingPoint? = null,
    val upcomingBuses: List<UpcomingBus> = emptyList(),
    val isRefreshing: Boolean = false,
    val errorMessage: String? = null,
    val lastUpdatedAt: Instant? = null,
    val now: Instant = Instant.now(),
    val destination: DashDestination = DashDestination.HOME,
    val boardingPoints: List<BoardingPoint> = emptyList(),
    val draft: BoardingPointDraft? = null,
    val isSaving: Boolean = false,
    val stopQuery: String = "",
    val stopResults: List<dev.utrpanic.dash.domain.model.BusStop> = emptyList(),
    val selectedStop: dev.utrpanic.dash.domain.model.BusStop? = null,
    val selectedStopRoutes: List<dev.utrpanic.dash.domain.model.BusRoute> = emptyList(),
    val isLoadingStops: Boolean = false,
    val isLoadingStopRoutes: Boolean = false,
    val stopSearchError: String? = null,
    val routeSelectionStop: dev.utrpanic.dash.domain.model.BusStop? = null,
    val routeCandidates: List<dev.utrpanic.dash.domain.model.BusRoute> = emptyList(),
    val selectedRoutes: Set<dev.utrpanic.dash.domain.model.BusRoute> = emptySet(),
    val isLoadingRouteCandidates: Boolean = false,
    val routeSelectionError: String? = null,
)

class DashViewModel(private val container: DashContainer) : ViewModel() {
    private val resolveCurrent = ResolveCurrentBoardingPoint(
        container.boardingPointRepository,
        container.locationProvider,
    )
    private val fetchUpcoming = FetchUpcomingBuses(container.busArrivalRepository)
    private val _state = MutableStateFlow(DashUiState())
    val state: StateFlow<DashUiState> = _state.asStateFlow()
    private var refreshJob: Job? = null
    private var stopSearchJob: Job? = null

    init {
        viewModelScope.launch {
            while (isActive) {
                delay(10_000)
                _state.update { it.copy(now = Instant.now()) }
            }
        }
    }

    fun resolveFromCurrentLocation() {
        viewModelScope.launch {
            _state.update { it.copy(isLoadingConfiguration = true, errorMessage = null) }
            runCatching { resolveCurrent() }
                .onSuccess { resolution ->
                    _state.update {
                        it.copy(
                            isLoadingConfiguration = false,
                            currentBoardingPoint = resolution.boardingPoint,
                            boardingPoints = container.boardingPointRepository.loadConfiguration().boardingPoints,
                        )
                    }
                    refresh()
                }
                .onFailure {
                    _state.update {
                        it.copy(isLoadingConfiguration = false, errorMessage = "탑승 지점을 불러오지 못했습니다.")
                    }
                }
        }
    }

    fun refresh() {
        val point = _state.value.currentBoardingPoint ?: return
        if (_state.value.isRefreshing) return
        refreshJob?.cancel()
        refreshJob = viewModelScope.launch {
            _state.update { it.copy(isRefreshing = true, errorMessage = null) }
            runCatching { fetchUpcoming(point) }
                .onSuccess { buses ->
                    _state.update {
                        it.copy(
                            upcomingBuses = buses,
                            isRefreshing = false,
                            lastUpdatedAt = Instant.now(),
                            now = Instant.now(),
                        )
                    }
                }
                .onFailure {
                    _state.update {
                        it.copy(isRefreshing = false, errorMessage = "도착 정보를 불러오지 못했습니다.")
                    }
                }
        }
    }

    fun selectNextBoardingPoint() {
        viewModelScope.launch {
            val configuration = container.boardingPointRepository.loadConfiguration()
            val validPoints = configuration.boardingPoints.filter(BoardingPoint::hasSelectedRoutes)
            if (validPoints.isEmpty()) return@launch
            val currentIndex = validPoints.indexOfFirst { it.id == _state.value.currentBoardingPoint?.id }
            val next = validPoints[(currentIndex + 1).mod(validPoints.size)]
            container.boardingPointRepository.saveConfiguration(
                configuration.copy(currentBoardingPointId = next.id),
            )
            _state.update { it.copy(currentBoardingPoint = next, upcomingBuses = emptyList()) }
            refresh()
        }
    }

    fun openBoardingPoints() {
        viewModelScope.launch {
            runCatching { container.boardingPointRepository.loadConfiguration() }
                .onSuccess { configuration ->
                    _state.update {
                        it.copy(
                            boardingPoints = configuration.boardingPoints,
                            destination = DashDestination.BOARDING_POINTS,
                            errorMessage = null,
                        )
                    }
                }
                .onFailure { _state.update { it.copy(errorMessage = "탑승 지점을 불러오지 못했습니다.") } }
        }
    }

    fun showHome() {
        _state.update { it.copy(destination = DashDestination.HOME, draft = null) }
    }

    fun selectBoardingPoint(point: BoardingPoint) {
        viewModelScope.launch {
            val configuration = container.boardingPointRepository.loadConfiguration()
            container.boardingPointRepository.saveConfiguration(configuration.copy(currentBoardingPointId = point.id))
            _state.update {
                it.copy(destination = DashDestination.HOME, currentBoardingPoint = point, upcomingBuses = emptyList())
            }
            refresh()
        }
    }

    fun editBoardingPoint(point: BoardingPoint) {
        _state.update {
            it.copy(
                draft = BoardingPointDraft(point.id, point.name, point.routes),
                destination = DashDestination.EDIT_BOARDING_POINT,
            )
        }
    }

    fun addBoardingPoint() {
        _state.update {
            it.copy(
                draft = BoardingPointDraft(null, "", emptyMap()),
                destination = DashDestination.EDIT_BOARDING_POINT,
            )
        }
    }

    fun updateDraftName(name: String) {
        _state.update { it.copy(draft = it.draft?.copy(name = name)) }
    }

    fun removeDraftStop(stop: dev.utrpanic.dash.domain.model.BusStop) {
        _state.update { state ->
            state.copy(draft = state.draft?.copy(routes = state.draft.routes - stop))
        }
    }

    fun openAddBusStop() {
        _state.update {
            it.copy(
                destination = DashDestination.ADD_BUS_STOP,
                stopQuery = "",
                stopResults = emptyList(),
                selectedStop = null,
                selectedStopRoutes = emptyList(),
                stopSearchError = null,
            )
        }
        stopSearchJob?.cancel()
        stopSearchJob = viewModelScope.launch {
            _state.update { it.copy(isLoadingStops = true) }
            runCatching {
                val location = container.locationProvider.currentLocation()
                container.busStopRepository.fetchNearbyStops(location.latitude, location.longitude).take(26)
            }.onSuccess { stops ->
                _state.update { it.copy(stopResults = stops, isLoadingStops = false) }
            }.onFailure {
                _state.update {
                    it.copy(isLoadingStops = false, stopSearchError = "현재 위치의 정류장을 불러오지 못했습니다. 검색은 사용할 수 있습니다.")
                }
            }
        }
    }

    fun returnToDraft() {
        _state.update { it.copy(destination = DashDestination.EDIT_BOARDING_POINT) }
    }

    fun updateStopQuery(query: String) {
        _state.update { it.copy(stopQuery = query, selectedStop = null, selectedStopRoutes = emptyList()) }
        stopSearchJob?.cancel()
        stopSearchJob = viewModelScope.launch {
            kotlinx.coroutines.delay(350)
            if (query.trim().isEmpty()) return@launch
            _state.update { it.copy(isLoadingStops = true, stopSearchError = null) }
            runCatching { container.busStopRepository.searchStops(query).take(26) }
                .onSuccess { stops -> _state.update { it.copy(stopResults = stops, isLoadingStops = false) } }
                .onFailure {
                    _state.update {
                        it.copy(isLoadingStops = false, stopSearchError = "정류장 정보를 불러오지 못했습니다.")
                    }
                }
        }
    }

    fun selectStop(stop: dev.utrpanic.dash.domain.model.BusStop) {
        _state.update {
            it.copy(selectedStop = stop, selectedStopRoutes = emptyList(), isLoadingStopRoutes = true)
        }
        viewModelScope.launch {
            runCatching { container.busRouteRepository.fetchRoutes(stop) }
                .onSuccess { routes ->
                    if (_state.value.selectedStop == stop) {
                        _state.update { it.copy(selectedStopRoutes = routes, isLoadingStopRoutes = false) }
                    }
                }
                .onFailure {
                    if (_state.value.selectedStop == stop) {
                        _state.update { it.copy(isLoadingStopRoutes = false) }
                    }
                }
        }
    }

    fun retrySelectedStopRoutes() {
        _state.value.selectedStop?.let(::selectStop)
    }

    fun addSelectedStop() {
        val stop = _state.value.selectedStop ?: return
        _state.update { state ->
            val draft = state.draft ?: return@update state
            state.copy(
                draft = draft.copy(routes = if (stop in draft.routes) draft.routes else draft.routes + (stop to emptySet())),
                destination = DashDestination.EDIT_BOARDING_POINT,
            )
        }
    }

    fun openRouteSelection(stop: dev.utrpanic.dash.domain.model.BusStop) {
        val storedRoutes = _state.value.draft?.routes?.get(stop).orEmpty()
        _state.update {
            it.copy(
                destination = DashDestination.SELECT_BUS_ROUTES,
                routeSelectionStop = stop,
                routeCandidates = storedRoutes.sortedWith(dev.utrpanic.dash.domain.model.BusRouteNaturalComparator),
                selectedRoutes = storedRoutes,
                isLoadingRouteCandidates = true,
                routeSelectionError = null,
            )
        }
        viewModelScope.launch {
            runCatching { container.busRouteRepository.fetchRoutes(stop) }
                .onSuccess { fetched ->
                    if (_state.value.routeSelectionStop == stop) {
                        _state.update { state ->
                            state.copy(
                                routeCandidates = (fetched + storedRoutes).distinct().sortedWith(
                                    dev.utrpanic.dash.domain.model.BusRouteNaturalComparator,
                                ),
                                isLoadingRouteCandidates = false,
                            )
                        }
                    }
                }
                .onFailure {
                    if (_state.value.routeSelectionStop == stop) {
                        _state.update {
                            it.copy(
                                isLoadingRouteCandidates = false,
                                routeSelectionError = "버스 노선을 불러오지 못했습니다.",
                            )
                        }
                    }
                }
        }
    }

    fun toggleRoute(route: dev.utrpanic.dash.domain.model.BusRoute) {
        _state.update {
            it.copy(selectedRoutes = if (route in it.selectedRoutes) it.selectedRoutes - route else it.selectedRoutes + route)
        }
    }

    fun completeRouteSelection() {
        val stop = _state.value.routeSelectionStop ?: return
        val routes = _state.value.selectedRoutes
        if (routes.isEmpty()) return
        _state.update { state ->
            val draft = state.draft ?: return@update state
            state.copy(
                draft = draft.copy(routes = draft.routes + (stop to routes)),
                destination = DashDestination.EDIT_BOARDING_POINT,
                routeSelectionStop = null,
            )
        }
    }

    fun retryRouteCandidates() {
        _state.value.routeSelectionStop?.let(::openRouteSelection)
    }

    fun saveDraft() {
        val draft = _state.value.draft ?: return
        val name = draft.name.trim()
        if (name.isEmpty() || _state.value.isSaving) return
        viewModelScope.launch {
            _state.update { it.copy(isSaving = true, errorMessage = null) }
            runCatching {
                val configuration = container.boardingPointRepository.loadConfiguration()
                val point = BoardingPoint(draft.originalId ?: UUID.randomUUID().toString().lowercase(), name, draft.routes)
                val points = if (draft.originalId == null) {
                    configuration.boardingPoints + point
                } else {
                    configuration.boardingPoints.map { if (it.id == draft.originalId) point else it }
                }
                container.boardingPointRepository.saveConfiguration(configuration.copy(boardingPoints = points))
                configuration.copy(boardingPoints = points) to point
            }.onSuccess { (configuration, point) ->
                _state.update { state ->
                    state.copy(
                        isSaving = false,
                        boardingPoints = configuration.boardingPoints,
                        currentBoardingPoint = if (state.currentBoardingPoint?.id == point.id) point else state.currentBoardingPoint,
                        destination = DashDestination.BOARDING_POINTS,
                        draft = null,
                    )
                }
            }.onFailure {
                _state.update { it.copy(isSaving = false, errorMessage = "탑승 지점을 저장하지 못했습니다.") }
            }
        }
    }

    fun deleteDraft() {
        val id = _state.value.draft?.originalId ?: return
        if (_state.value.boardingPoints.size <= 1 || _state.value.isSaving) return
        viewModelScope.launch {
            _state.update { it.copy(isSaving = true, errorMessage = null) }
            runCatching {
                val configuration = container.boardingPointRepository.loadConfiguration()
                val points = configuration.boardingPoints.filterNot { it.id == id }
                val currentId = configuration.currentBoardingPointId.takeUnless { it == id } ?: points.firstOrNull()?.id
                val updated = configuration.copy(boardingPoints = points, currentBoardingPointId = currentId)
                container.boardingPointRepository.saveConfiguration(updated)
                updated
            }.onSuccess { configuration ->
                _state.update {
                    it.copy(
                        isSaving = false,
                        boardingPoints = configuration.boardingPoints,
                        currentBoardingPoint = configuration.boardingPoints.firstOrNull { point ->
                            point.id == configuration.currentBoardingPointId
                        },
                        destination = DashDestination.BOARDING_POINTS,
                        draft = null,
                    )
                }
            }.onFailure {
                _state.update { it.copy(isSaving = false, errorMessage = "탑승 지점을 삭제하지 못했습니다.") }
            }
        }
    }

    class Factory(private val container: DashContainer) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T = DashViewModel(container) as T
    }
}
