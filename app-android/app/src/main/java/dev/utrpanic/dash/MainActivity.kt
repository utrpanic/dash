package dev.utrpanic.dash

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import dev.utrpanic.dash.ui.home.DashHomeScreen
import dev.utrpanic.dash.ui.home.DashDestination
import dev.utrpanic.dash.ui.home.DashViewModel
import dev.utrpanic.dash.ui.boardingpoint.BoardingPointEditScreen
import dev.utrpanic.dash.ui.boardingpoint.BoardingPointListScreen
import dev.utrpanic.dash.ui.theme.DashTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            DashTheme {
                val application = application as DashApplication
                val viewModel: DashViewModel = viewModel(factory = DashViewModel.Factory(application.container))
                val state by viewModel.state.collectAsStateWithLifecycle()
                val context = LocalContext.current
                val permissionLauncher = rememberLauncherForActivityResult(
                    ActivityResultContracts.RequestMultiplePermissions(),
                ) { viewModel.resolveFromCurrentLocation() }

                LaunchedEffect(Unit) {
                    val granted = ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.ACCESS_COARSE_LOCATION,
                    ) == PackageManager.PERMISSION_GRANTED
                    if (granted) {
                        viewModel.resolveFromCurrentLocation()
                    } else {
                        permissionLauncher.launch(
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION,
                            ),
                        )
                    }
                }

                when (state.destination) {
                    DashDestination.HOME -> DashHomeScreen(
                        state = state,
                        onSelectNext = viewModel::selectNextBoardingPoint,
                        onRefresh = viewModel::refresh,
                        onLocate = viewModel::resolveFromCurrentLocation,
                        onManage = viewModel::openBoardingPoints,
                    )
                    DashDestination.BOARDING_POINTS -> BoardingPointListScreen(
                        points = state.boardingPoints,
                        currentId = state.currentBoardingPoint?.id,
                        onBack = viewModel::showHome,
                        onSelect = viewModel::selectBoardingPoint,
                        onEdit = viewModel::editBoardingPoint,
                        onAdd = viewModel::addBoardingPoint,
                    )
                    DashDestination.EDIT_BOARDING_POINT -> BoardingPointEditScreen(
                        draft = state.draft,
                        canDelete = state.draft?.originalId != null && state.boardingPoints.size > 1,
                        isSaving = state.isSaving,
                        errorMessage = state.errorMessage,
                        onBack = viewModel::openBoardingPoints,
                        onNameChange = viewModel::updateDraftName,
                        onRemoveStop = viewModel::removeDraftStop,
                        onSave = viewModel::saveDraft,
                        onDelete = viewModel::deleteDraft,
                    )
                }
            }
        }
    }
}
