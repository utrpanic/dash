package dev.utrpanic.dash.ui.navigation

import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.core.tween
import androidx.compose.animation.togetherWith
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.navigation3.runtime.NavEntry
import androidx.navigation3.ui.NavDisplay
import dev.utrpanic.dash.ui.boardingpoint.BoardingPointEditScreen
import dev.utrpanic.dash.ui.boardingpoint.BoardingPointListScreen
import dev.utrpanic.dash.ui.busroute.SelectBusRoutesScreen
import dev.utrpanic.dash.ui.busstop.AddBusStopScreen
import dev.utrpanic.dash.ui.home.DashDestination
import dev.utrpanic.dash.ui.home.DashHomeScreen
import dev.utrpanic.dash.ui.home.DashUiState
import dev.utrpanic.dash.ui.home.DashViewModel

private const val NavigationFadeDurationMillis = 300

private fun navigationFadeTransition() =
    fadeIn(tween(NavigationFadeDurationMillis)) togetherWith
        fadeOut(tween(NavigationFadeDurationMillis))

@Composable
fun DashNavigation(state: DashUiState, viewModel: DashViewModel) {
    val currentState by rememberUpdatedState(state)
    NavDisplay(
        backStack = state.backStack,
        onBack = viewModel::navigateBack,
        transitionSpec = { navigationFadeTransition() },
        popTransitionSpec = { navigationFadeTransition() },
        predictivePopTransitionSpec = { navigationFadeTransition() },
        entryProvider = { destination ->
            NavEntry(destination) {
                // Keep popped content visible until Navigation finishes its exit transition.
                var lastActiveState by remember { mutableStateOf(currentState) }
                val screenState = if (destination in currentState.backStack) currentState else lastActiveState
                SideEffect { lastActiveState = screenState }
                when (destination) {
                    DashDestination.HOME -> DashHomeScreen(
                        state = screenState,
                        onSelectNext = viewModel::selectNextBoardingPoint,
                        onRefresh = viewModel::refresh,
                        onLocate = viewModel::resolveFromCurrentLocation,
                        onEdit = { screenState.currentBoardingPoint?.let(viewModel::editBoardingPoint) },
                        onManage = viewModel::openBoardingPoints,
                    )
                    DashDestination.BOARDING_POINTS -> BoardingPointListScreen(
                        points = screenState.boardingPoints,
                        currentId = screenState.currentBoardingPoint?.id,
                        onBack = viewModel::navigateBack,
                        onSelect = viewModel::selectBoardingPoint,
                        onEdit = viewModel::editBoardingPoint,
                        onDelete = viewModel::deleteBoardingPoint,
                        onAdd = viewModel::addBoardingPoint,
                    )
                    DashDestination.EDIT_BOARDING_POINT -> BoardingPointEditScreen(
                        draft = screenState.draft,
                        canDelete = screenState.draft?.originalId != null && screenState.boardingPoints.size > 1,
                        isSaving = screenState.isSaving,
                        errorMessage = screenState.errorMessage,
                        onBack = viewModel::navigateBack,
                        onNameChange = viewModel::updateDraftName,
                        onRemoveStop = viewModel::removeDraftStop,
                        onSave = viewModel::saveDraft,
                        onDelete = viewModel::deleteDraft,
                        onAddStop = viewModel::openAddBusStop,
                        onSelectRoutes = viewModel::openRouteSelection,
                    )
                    DashDestination.ADD_BUS_STOP -> AddBusStopScreen(
                        state = screenState,
                        onBack = viewModel::navigateBack,
                        onQueryChange = viewModel::updateStopQuery,
                        onSelect = viewModel::selectStop,
                        onRetryRoutes = viewModel::retrySelectedStopRoutes,
                        onAdd = viewModel::addSelectedStop,
                    )
                    DashDestination.SELECT_BUS_ROUTES -> SelectBusRoutesScreen(
                        state = screenState,
                        onBack = viewModel::navigateBack,
                        onToggle = viewModel::toggleRoute,
                        onRetry = viewModel::retryRouteCandidates,
                        onComplete = viewModel::completeRouteSelection,
                    )
                }
            }
        },
    )
}
