package dev.utrpanic.dash.ui.busroute

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.utrpanic.dash.domain.model.BusRoute
import dev.utrpanic.dash.ui.home.DashUiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SelectBusRoutesScreen(
    state: DashUiState,
    onBack: () -> Unit,
    onToggle: (BusRoute) -> Unit,
    onRetry: () -> Unit,
    onComplete: () -> Unit,
) {
    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            Column {
                CenterAlignedTopAppBar(
                    title = {
                        Text(
                            "버스 노선 선택",
                            color = MaterialTheme.colorScheme.onSurface,
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Normal,
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Rounded.ArrowBack, "뒤로")
                        }
                    },
                    actions = {
                        val canComplete = state.selectedRoutes.isNotEmpty()
                        TextButton(onClick = onComplete, enabled = canComplete) {
                            Text(
                                "완료",
                                color = MaterialTheme.colorScheme.primary.copy(
                                    alpha = if (canComplete) 1f else 0.45f,
                                ),
                                fontSize = 17.sp,
                                fontWeight = FontWeight.SemiBold,
                            )
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.background,
                    ),
                )
                HorizontalDivider(color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.25f))
            }
        },
    ) { insets ->
        Column(Modifier.fillMaxSize().padding(insets).testTag("select-bus-routes-screen")) {
            Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    state.routeSelectionStop?.name.orEmpty(),
                    color = MaterialTheme.colorScheme.onSurface,
                    fontSize = 20.sp,
                    lineHeight = 28.sp,
                    fontWeight = FontWeight.Medium,
                )
                Text(
                    "정류장 번호 ${state.routeSelectionStop?.id?.stopId.orEmptyText()}",
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("경유 노선", fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                    Text("${state.selectedRoutes.size}개 선택", fontSize = 14.sp, color = MaterialTheme.colorScheme.primary)
                }
            }
            when {
                state.isLoadingRouteCandidates && state.routeCandidates.isEmpty() -> {
                    CircularProgressIndicator(Modifier.padding(24.dp))
                }
                state.routeSelectionError != null && state.routeCandidates.isEmpty() -> {
                    Column(Modifier.padding(16.dp)) {
                        Text(state.routeSelectionError)
                        TextButton(onClick = onRetry) { Text("재시도") }
                    }
                }
                state.routeCandidates.isEmpty() -> Text(
                    "선택할 수 있는 노선이 없습니다.",
                    modifier = Modifier.padding(16.dp),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                else -> LazyVerticalGrid(
                    columns = GridCells.Adaptive(96.dp),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    items(state.routeCandidates, key = { "${it.region}-${it.id}" }) { route ->
                        val selected = route in state.selectedRoutes
                        Card(
                            modifier = Modifier.heightIn(min = 68.dp).clickable { onToggle(route) },
                            shape = RoundedCornerShape(16.dp),
                            border = BorderStroke(1.dp, MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.25f)),
                            colors = CardDefaults.cardColors(
                                containerColor = if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)
                                else MaterialTheme.colorScheme.surface,
                            ),
                        ) {
                            Row(
                                Modifier.fillMaxSize().padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween,
                            ) {
                                Text(route.number, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                                Box(
                                    Modifier.size(24.dp).background(
                                        if (selected) MaterialTheme.colorScheme.primary else Color.Transparent,
                                        CircleShape,
                                    ),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    if (selected) Icon(Icons.Rounded.Check, "선택됨", tint = Color.White)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun Long?.orEmptyText() = this?.toString().orEmpty()
