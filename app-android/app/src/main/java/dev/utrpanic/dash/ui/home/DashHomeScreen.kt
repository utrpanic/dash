package dev.utrpanic.dash.ui.home

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.Menu
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import dev.utrpanic.dash.domain.model.UpcomingBus
import java.time.Duration
import java.time.Instant
import java.time.format.DateTimeFormatter
import kotlin.math.ceil

@Composable
fun DashHomeScreen(
    state: DashUiState,
    onSelectNext: () -> Unit,
    onRefresh: () -> Unit,
    onLocate: () -> Unit,
    onManage: () -> Unit,
) {
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_START) onRefresh() }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    Scaffold { insets ->
        Box(Modifier.fillMaxSize().padding(insets)) {
            when {
                state.isLoadingConfiguration -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                state.currentBoardingPoint == null -> EmptyHome(onLocate)
                else -> ArrivalList(state, onSelectNext, onRefresh, onManage)
            }
            if (state.currentBoardingPoint != null) {
                Row(
                    modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    UtilityButton("현재 위치", Icons.Rounded.LocationOn, onLocate)
                    UtilityButton("새로고침", Icons.Rounded.Refresh, onRefresh)
                }
            }
        }
    }
}

@Composable
private fun ArrivalList(
    state: DashUiState,
    onSelectNext: () -> Unit,
    onRefresh: () -> Unit,
    onManage: () -> Unit,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp, 24.dp, 16.dp, 104.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f).clickable(onClick = onSelectNext).padding(vertical = 8.dp)) {
                    Text(state.currentBoardingPoint?.name.orEmpty(), style = MaterialTheme.typography.headlineMedium)
                    state.lastUpdatedAt?.let {
                        Text(elapsedText(it, state.now), color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                FilledIconButton(onClick = onManage) { Icon(Icons.Rounded.Menu, contentDescription = "탑승 지점 목록") }
            }
        }
        state.errorMessage?.let { message ->
            item {
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
                    Row(
                        Modifier.fillMaxWidth().padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Text(message)
                        Button(onClick = onRefresh) { Text("재시도") }
                    }
                }
            }
        }
        if (state.isRefreshing && state.upcomingBuses.isEmpty()) {
            item { CircularProgressIndicator(Modifier.padding(24.dp)) }
        } else if (!state.isRefreshing && state.errorMessage == null && state.upcomingBuses.isEmpty()) {
            item { Text("도착 예정 버스가 없습니다.", color = MaterialTheme.colorScheme.onSurfaceVariant) }
        }
        items(state.upcomingBuses, key = UpcomingBus::id) { ArrivalCard(it) }
    }
}

@Composable
private fun ArrivalCard(bus: UpcomingBus) {
    val seconds = bus.timeUntilArrival.inWholeSeconds.coerceAtLeast(0)
    val minutes = ceil(seconds / 60.0).toInt()
    val weight = when (minutes) {
        in 0..3 -> FontWeight.Bold
        in 4..10 -> FontWeight.Normal
        else -> FontWeight.Light
    }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
        shape = RoundedCornerShape(16.dp),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(20.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column {
                Text(bus.busRoute.number, style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.SemiBold)
                Text(bus.busStop.name, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Column(horizontalAlignment = Alignment.End) {
                Text("${minutes}분", style = MaterialTheme.typography.displayMedium, fontWeight = weight)
                Text(
                    DateTimeFormatter.ofPattern("a h:mm").format(java.time.ZonedDateTime.now().plusSeconds(seconds)),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun UtilityButton(label: String, icon: ImageVector, action: () -> Unit) {
    FilledIconButton(onClick = action, modifier = Modifier.shadow(8.dp, CircleShape), shape = CircleShape) {
        Icon(icon, contentDescription = label)
    }
}

@Composable
private fun EmptyHome(onLocate: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("표시할 탑승 지점이 없습니다.")
        Spacer(Modifier.height(16.dp))
        Button(onClick = onLocate) { Text("다시 시도") }
    }
}

private fun elapsedText(updatedAt: Instant, now: Instant): String {
    val seconds = Duration.between(updatedAt, now).seconds.coerceAtLeast(0)
    return when {
        seconds < 60 -> "${seconds}초 전"
        seconds < 3600 -> "${seconds / 60}분 전"
        else -> "${seconds / 3600}시간 전"
    }
}
