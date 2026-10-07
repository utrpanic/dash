package dev.utrpanic.dash.ui.busstop

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MarkerComposable
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.domain.model.BusStopId
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
    val cameraState = rememberCameraPositionState()
    val focusStop = state.selectedStop ?: state.stopResults.firstOrNull()
    LaunchedEffect(focusStop?.id) {
        focusStop?.let {
            cameraState.move(
                CameraUpdateFactory.newLatLngZoom(LatLng(it.latitude, it.longitude), 17f),
            )
        }
    }
    val listState = rememberLazyListState()
    LaunchedEffect(state.selectedStop?.id) {
        val index = state.stopResults.indexOf(state.selectedStop)
        if (index >= 0) listState.scrollToItem(index)
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            Column {
                CenterAlignedTopAppBar(
                    title = {
                        Text(
                            "정류장 추가",
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
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.background,
                    ),
                )
                HorizontalDivider(color = dividerColor())
            }
        },
    ) { insets ->
        Column(
            Modifier.fillMaxSize().padding(insets).testTag("add-bus-stop-screen"),
        ) {
            Box(Modifier.fillMaxWidth().aspectRatio(1f)) {
                GoogleMap(
                    modifier = Modifier.fillMaxSize(),
                    cameraPositionState = cameraState,
                ) {
                    state.stopResults.forEachIndexed { index, stop ->
                        val label = markerLabel(index)
                        val selected = stop == state.selectedStop
                        MarkerComposable(
                            keys = arrayOf<Any>(label, selected),
                            state = MarkerState(LatLng(stop.latitude, stop.longitude)),
                            title = label,
                            snippet = stop.name,
                            onClick = {
                                onSelect(stop)
                                true
                            },
                        ) {
                            StopMarker(label = label, selected = selected, compact = false)
                        }
                    }
                }
                SearchField(
                    query = state.stopQuery,
                    onQueryChange = onQueryChange,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 24.dp),
                )
            }
            when {
                state.isLoadingStops -> LoadingStops()
                state.stopSearchError != null -> StatusMessage(state.stopSearchError)
                state.stopResults.isEmpty() -> StatusMessage(
                    if (state.stopQuery.isBlank()) "주변 정류장이 없습니다." else "검색 결과가 없습니다.",
                )
                else -> LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    state = listState,
                ) {
                    itemsIndexed(
                        items = state.stopResults,
                        key = { _, stop -> stop.id.storageKey },
                    ) { index, stop ->
                        StopRow(
                            label = markerLabel(index),
                            stop = stop,
                            selected = stop == state.selectedStop,
                            state = state,
                            onSelect = { onSelect(stop) },
                            onRetryRoutes = onRetryRoutes,
                            onAdd = onAdd,
                        )
                        if (index != state.stopResults.lastIndex) {
                            HorizontalDivider(color = dividerColor())
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SearchField(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.semantics { contentDescription = "정류장 검색" }
            .shadow(8.dp, CircleShape).background(
            MaterialTheme.colorScheme.surface,
            CircleShape,
        ).heightIn(min = 52.dp).padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(
            Icons.Rounded.Search,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        BasicTextField(
            value = query,
            onValueChange = onQueryChange,
            singleLine = true,
            textStyle = TextStyle(
                color = MaterialTheme.colorScheme.onSurface,
                fontSize = 20.sp,
            ),
            cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
            modifier = Modifier.weight(1f),
            decorationBox = { innerTextField ->
                Box(contentAlignment = Alignment.CenterStart) {
                    if (query.isEmpty()) {
                        Text(
                            "정류장 이름 또는 번호 검색",
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.55f),
                            fontSize = 20.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    innerTextField()
                }
            },
        )
    }
}

@Composable
private fun LoadingStops() {
    Box(
        modifier = Modifier.fillMaxWidth().padding(vertical = 24.dp),
        contentAlignment = Alignment.Center,
    ) {
        CircularProgressIndicator(
            modifier = Modifier.size(24.dp),
            strokeWidth = 2.dp,
        )
    }
}

@Composable
private fun StatusMessage(message: String) {
    Text(
        message,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        fontSize = 16.sp,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 24.dp),
    )
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
    val interactionSource = remember { MutableInteractionSource() }

    Row(
        modifier = Modifier.fillMaxWidth().height(IntrinsicSize.Min).background(
            if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)
            else MaterialTheme.colorScheme.background,
        ),
    ) {
        Box(
            Modifier.width(4.dp).fillMaxHeight().background(
                if (selected) MaterialTheme.colorScheme.primary else Color.Transparent,
            ),
        )
        Column(
            modifier = Modifier.weight(1f).padding(horizontal = 16.dp, vertical = 14.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth().heightIn(min = 60.dp).clickable(
                    interactionSource = interactionSource,
                    indication = null,
                    onClick = onSelect,
                ),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                StopMarker(label = label, selected = selected, compact = true)
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text(
                        stop.name,
                        color = MaterialTheme.colorScheme.onSurface,
                        fontSize = 20.sp,
                        lineHeight = 28.sp,
                        fontWeight = FontWeight.Medium,
                    )
                    Text(
                        "정류장 번호 ${displayNumber(stop)}",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontSize = 14.sp,
                    )
                }
            }
            if (selected) {
                SelectedStopDetails(
                    state = state,
                    onRetryRoutes = onRetryRoutes,
                    onAdd = onAdd,
                )
            }
        }
    }
}

@Composable
private fun SelectedStopDetails(
    state: DashUiState,
    onRetryRoutes: () -> Unit,
    onAdd: () -> Unit,
) {
    Column {
        HorizontalDivider(
            color = dividerColor(),
            modifier = Modifier.padding(top = 16.dp),
        )
        when {
            state.isLoadingStopRoutes -> RouteStatusText("경유 노선을 불러오는 중…")
            state.selectedStopRoutes.isEmpty() -> {
                RouteStatusText("경유 노선을 불러오지 못했습니다.")
                TextButton(
                    onClick = onRetryRoutes,
                    modifier = Modifier.fillMaxWidth().heightIn(min = 44.dp).border(
                        1.dp,
                        MaterialTheme.colorScheme.primary,
                        RoundedCornerShape(12.dp),
                    ),
                ) {
                    Icon(Icons.Rounded.Refresh, contentDescription = null)
                    Text(
                        "다시 시도",
                        fontSize = 17.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
            else -> RouteStatusText(
                state.selectedStopRoutes.take(6).joinToString(" · ") { it.number } +
                    (state.selectedStopRoutes.size.takeIf { it > 6 }?.let { " 외 ${it - 6}개" }
                        ?: ""),
                primary = true,
            )
        }
        if (!state.selectedStopRoutes.isEmpty() || state.isLoadingStopRoutes) {
            Button(
                onClick = onAdd,
                modifier = Modifier.fillMaxWidth().height(56.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = Color.White,
                ),
            ) {
                Text("이 정류장 추가", fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
private fun RouteStatusText(
    text: String,
    primary: Boolean = false,
) {
    Text(
        text,
        color = if (primary) MaterialTheme.colorScheme.onSurface
        else MaterialTheme.colorScheme.onSurfaceVariant,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        modifier = Modifier.fillMaxWidth().heightIn(min = 44.dp).padding(vertical = 10.dp),
    )
}

@Composable
private fun StopMarker(
    label: String,
    selected: Boolean,
    compact: Boolean,
) {
    val size = if (compact) 48.dp else 32.dp
    Box(
        Modifier.size(size).background(
            if (selected) MaterialTheme.colorScheme.primary
            else MaterialTheme.colorScheme.onSurfaceVariant,
            CircleShape,
        ).then(
            if (compact) Modifier else Modifier.border(2.dp, Color.White.copy(alpha = 0.8f), CircleShape),
        ),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            color = Color.White,
            fontSize = if (compact) 17.sp else 14.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

private fun markerLabel(index: Int): String = ('A' + index.coerceAtMost(25)).toString()

private fun displayNumber(stop: BusStop): String = when (val id = stop.id) {
    is BusStopId.Gyeonggi -> id.stopId.toString()
    is BusStopId.Seoul -> id.arsId.ifEmpty { id.stopId.toString() }
}

@Composable
private fun dividerColor(): Color =
    MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.25f)
