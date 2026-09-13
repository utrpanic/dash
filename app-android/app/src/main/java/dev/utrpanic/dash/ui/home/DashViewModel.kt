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

data class DashUiState(
    val isLoadingConfiguration: Boolean = true,
    val currentBoardingPoint: BoardingPoint? = null,
    val upcomingBuses: List<UpcomingBus> = emptyList(),
    val isRefreshing: Boolean = false,
    val errorMessage: String? = null,
    val lastUpdatedAt: Instant? = null,
    val now: Instant = Instant.now(),
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

    class Factory(private val container: DashContainer) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T = DashViewModel(container) as T
    }
}
