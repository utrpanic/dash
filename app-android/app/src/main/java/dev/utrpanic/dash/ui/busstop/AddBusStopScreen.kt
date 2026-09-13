package dev.utrpanic.dash.ui.busstop

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MarkerComposable
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.ui.home.DashUiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddBusStopScreen(
    state: DashUiState,
    onBack: () -> Unit,
    onQueryChange: (String) -> Unit,
    onSelect: (BusStop) -> Unit,
    onRetryRoutes: () -> Unit,
    onAdd: () -> Unit,
) {
    BackHandler(onBack = onBack)
    val cameraState = rememberCameraPositionState()
    val focusStop = state.selectedStop ?: state.stopResults.firstOrNull()
    LaunchedEffect(focusStop?.id) {
        focusStop?.let {
            cameraState.move(CameraUpdateFactory.newLatLngZoom(LatLng(it.latitude, it.longitude), 17f))
        }
    }
    val listState = rememberLazyListState()
    LaunchedEffect(state.selectedStop?.id) {
        val index = state.stopResults.indexOf(state.selectedStop)
        if (index >= 0) listState.scrollToItem(index)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("정류장 추가") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, "뒤로") } },
            )
        },
    ) { insets ->
        Column(Modifier.fillMaxSize().padding(insets).testTag("add-bus-stop-screen")) {
            Box(Modifier.fillMaxWidth().aspectRatio(1f)) {
                GoogleMap(modifier = Modifier.fillMaxSize(), cameraPositionState = cameraState) {
                    state.stopResults.forEachIndexed { index, stop ->
                        val label = ('A' + index).toString()
                        val selected = stop == state.selectedStop
                        MarkerComposable(
                            keys = arrayOf<Any>(label, selected),
                            state = MarkerState(LatLng(stop.latitude, stop.longitude)),
                            title = label,
                            snippet = stop.name,
                            onClick = { onSelect(stop); true },
                        ) {
                            Box(
                                Modifier.size(34.dp)
                                    .background(
                                        if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                                        CircleShape,
                                    )
                                    .border(2.dp, Color.White, CircleShape),
                                contentAlignment = Alignment.Center,
                            ) { Text(label, color = Color.White, fontWeight = FontWeight.SemiBold) }
                        }
                    }
                }
                OutlinedTextField(
                    value = state.stopQuery,
                    onValueChange = onQueryChange,
                    placeholder = { Text("정류장 이름 또는 번호 검색") },
                    leadingIcon = { Icon(Icons.Rounded.Search, null) },
                    singleLine = true,
                    shape = RoundedCornerShape(28.dp),
                    modifier = Modifier.fillMaxWidth().padding(16.dp).background(Color.White, RoundedCornerShape(28.dp)),
                )
            }
            state.stopSearchError?.let { Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(16.dp)) }
            if (state.isLoadingStops) CircularProgressIndicator(Modifier.padding(horizontal = 16.dp, vertical = 8.dp))
            LazyColumn(Modifier.fillMaxSize(), state = listState) {
                itemsIndexed(state.stopResults, key = { _, stop -> stop.id.storageKey }) { index, stop ->
                    StopRow(
                        label = ('A' + index).toString(),
                        stop = stop,
                        selected = stop == state.selectedStop,
                        state = state,
                        onSelect = { onSelect(stop) },
                        onRetryRoutes = onRetryRoutes,
                        onAdd = onAdd,
                    )
                    HorizontalDivider()
                }
            }
        }
    }
}

@Composable
private fun StopRow(
    label: String,
    stop: BusStop,
    selected: Boolean,
    state: DashUiState,
    onSelect: () -> Unit,
    onRetryRoutes: () -> Unit,
    onAdd: () -> Unit,
) {
    Row(
        Modifier.fillMaxWidth()
            .height(IntrinsicSize.Min)
            .background(if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f) else MaterialTheme.colorScheme.background)
            .clickable(onClick = onSelect),
    ) {
        Box(
            Modifier.width(4.dp).fillMaxHeight().background(
                if (selected) MaterialTheme.colorScheme.primary else Color.Transparent,
            ),
        )
        Column(Modifier.weight(1f).padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    Modifier.width(48.dp).height(48.dp)
                        .background(if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant, CircleShape),
                    contentAlignment = Alignment.Center,
                ) { Text(label, color = Color.White) }
                Column(Modifier.padding(start = 16.dp)) {
                    Text(stop.name, style = MaterialTheme.typography.titleLarge, fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium)
                    Text("정류장 번호 ${stop.id.stopId}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            if (selected) {
                HorizontalDivider()
                when {
                    state.isLoadingStopRoutes -> Text("경유 노선을 불러오는 중…", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    state.selectedStopRoutes.isEmpty() -> Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("경유 노선을 불러오지 못했습니다.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                        TextButton(onClick = onRetryRoutes) { Text("재시도") }
                    }
                    else -> Text(
                        state.selectedStopRoutes.take(6).joinToString(" · ") { it.number } +
                            (state.selectedStopRoutes.size.takeIf { it > 6 }?.let { " 외 ${it - 6}개" } ?: ""),
                    )
                }
                Button(onClick = onAdd, modifier = Modifier.fillMaxWidth().height(56.dp)) { Text("이 정류장 추가") }
            }
        }
    }
}
