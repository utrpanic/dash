package dev.utrpanic.dash.ui.home

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.FormatListBulleted
import androidx.compose.material.icons.rounded.AccessTime
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.DirectionsBus
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.MyLocation
import androidx.compose.material.icons.rounded.Navigation
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import dev.utrpanic.dash.domain.model.UpcomingBus
import dev.utrpanic.dash.ui.theme.LocalDashDarkTheme
import kotlinx.coroutines.delay
import java.time.Duration
import java.time.Instant
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.ceil

@Composable
fun DashHomeScreen(
    state: DashUiState,
    onSelectNext: () -> Unit,
    onRefresh: () -> Unit,
    onLocate: () -> Unit,
    onEdit: () -> Unit,
    onManage: () -> Unit,
) {
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_START) onRefresh() }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    Scaffold(containerColor = MaterialTheme.colorScheme.background) { insets ->
        Column(Modifier.fillMaxSize().padding(insets)) {
            HomeNavigationBar(
                state = state,
                onSelectNext = onSelectNext,
                onEdit = onEdit,
                onManage = onManage,
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.25f))
            Box(Modifier.fillMaxSize()) {
                HomeContent(state, onRefresh, onLocate)
                if (state.currentBoardingPoint != null) {
                    FloatingUtilities(
                        lastUpdatedAt = state.lastUpdatedAt,
                        isRefreshing = state.isRefreshing,
                        hasSelectedRoutes = state.currentBoardingPoint.hasSelectedRoutes,
                        onLocate = onLocate,
                        onRefresh = onRefresh,
                    )
                }
            }
        }
    }
}

@Composable
private fun HomeNavigationBar(
    state: DashUiState,
    onSelectNext: () -> Unit,
    onEdit: () -> Unit,
    onManage: () -> Unit,
) {
    val title = when {
        state.isLoadingConfiguration -> "위치 확인 중…"
        state.currentBoardingPoint != null -> state.currentBoardingPoint.name
        else -> "탑승 지점 없음"
    }
    Row(
        modifier = Modifier.fillMaxWidth().heightIn(min = 64.dp).padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(
            onClick = onSelectNext,
            enabled = state.currentBoardingPoint != null,
            modifier = Modifier.widthIn(max = 220.dp),
            shape = CircleShape,
            color = MaterialTheme.colorScheme.surface,
        ) {
            Row(
                modifier = Modifier.heightIn(min = 48.dp).padding(start = 8.dp, end = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Surface(
                    modifier = Modifier.size(36.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.primary,
                ) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Icon(
                            Icons.Rounded.Navigation,
                            contentDescription = null,
                            modifier = Modifier.size(22.dp),
                            tint = Color.White,
                        )
                    }
                }
                Text(
                    title,
                    modifier = Modifier.widthIn(max = 140.dp),
                    color = if (state.currentBoardingPoint == null) {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    } else {
                        MaterialTheme.colorScheme.onSurface
                    },
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Normal,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (state.currentBoardingPoint != null) {
                    Icon(
                        Icons.Rounded.ChevronRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
        Spacer(Modifier.weight(1f))
        IconButton(onClick = onEdit, enabled = state.currentBoardingPoint != null) {
            Icon(
                Icons.Rounded.Edit,
                contentDescription = "현재 탑승 지점 편집",
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        IconButton(onClick = onManage) {
            Icon(
                Icons.AutoMirrored.Rounded.FormatListBulleted,
                contentDescription = "탑승 지점 목록",
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun HomeContent(
    state: DashUiState,
    onRefresh: () -> Unit,
    onLocate: () -> Unit,
) {
    when {
        state.isLoadingConfiguration -> LoadingState()
        state.currentBoardingPoint == null -> EmptyHome(onLocate)
        state.isRefreshing -> LoadingState()
        state.errorMessage != null -> MessageState(state.errorMessage, "다시 시도", onRefresh)
        !state.currentBoardingPoint.hasSelectedRoutes -> {
            MessageState("선택한 버스 노선이 없습니다.\n탑승 지점을 편집해 노선을 선택하세요.")
        }
        state.upcomingBuses.isEmpty() -> MessageState("도착 예정인 버스가 없습니다.")
        else -> ArrivalList(state.upcomingBuses)
    }
}

@Composable
private fun LoadingState() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator()
    }
}

@Composable
private fun ArrivalList(buses: List<UpcomingBus>) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, top = 12.dp, end = 16.dp, bottom = 176.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(buses, key = UpcomingBus::id) { ArrivalCard(it) }
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
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.25f)),
        shape = RoundedCornerShape(16.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 24.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(
                    bus.busRoute.number,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontSize = 40.sp,
                    lineHeight = 48.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(
                        Icons.Rounded.AccessTime,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Text(
                        DateTimeFormatter.ofPattern("a h:mm", Locale.KOREAN)
                            .format(java.time.ZonedDateTime.now().plusSeconds(seconds)),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontSize = 16.sp,
                        lineHeight = 24.sp,
                        fontWeight = FontWeight.Medium,
                    )
                }
            }
            Row(
                verticalAlignment = Alignment.Bottom,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(
                    minutes.toString(),
                    color = MaterialTheme.colorScheme.primary,
                    fontSize = 48.sp,
                    lineHeight = 56.sp,
                    fontWeight = weight,
                )
                Text(
                    "분",
                    modifier = Modifier.padding(bottom = 5.dp),
                    color = MaterialTheme.colorScheme.primary,
                    fontSize = 24.sp,
                    lineHeight = 32.sp,
                    fontWeight = weight,
                )
            }
        }
    }
}

@Composable
private fun FloatingUtilities(
    lastUpdatedAt: Instant?,
    isRefreshing: Boolean,
    hasSelectedRoutes: Boolean,
    onLocate: () -> Unit,
    onRefresh: () -> Unit,
) {
    val darkTheme = LocalDashDarkTheme.current
    val buttonsEnabled = !isRefreshing && hasSelectedRoutes
    Box(Modifier.fillMaxSize().padding(end = 24.dp, bottom = 24.dp)) {
        Column(
            modifier = Modifier.align(Alignment.BottomEnd).width(64.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            UtilityButton(
                label = "현재 위치",
                icon = Icons.Rounded.MyLocation,
                containerColor = if (darkTheme) MaterialTheme.colorScheme.surfaceContainerHigh
                else MaterialTheme.colorScheme.surface,
                contentColor = MaterialTheme.colorScheme.primary,
                action = onLocate,
                enabled = buttonsEnabled,
                modifier = if (darkTheme) {
                    Modifier.border(1.dp, MaterialTheme.colorScheme.outline, CircleShape)
                } else Modifier,
            )
            Spacer(Modifier.height(16.dp))
            UtilityButton(
                label = "새로고침",
                icon = Icons.Rounded.Refresh,
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = Color.White,
                action = onRefresh,
                enabled = buttonsEnabled,
            )
            Spacer(Modifier.height(8.dp))
            Box(Modifier.fillMaxWidth().height(16.dp), contentAlignment = Alignment.Center) {
                ElapsedTimeLabel(lastUpdatedAt, isRefreshing)
            }
        }
    }
}

@Composable
private fun ElapsedTimeLabel(lastUpdatedAt: Instant?, isRefreshing: Boolean) {
    if (lastUpdatedAt == null || isRefreshing) return
    val lifecycleOwner = LocalLifecycleOwner.current
    val now = produceState(initialValue = Instant.now(), lastUpdatedAt, lifecycleOwner) {
        lifecycleOwner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            while (true) {
                value = Instant.now()
                delay(1_000)
            }
        }
    }.value
    if (Duration.between(lastUpdatedAt, now).seconds < 10) return
    val label = elapsedText(lastUpdatedAt, now)
    Text(
        label,
        modifier = Modifier.fillMaxWidth().semantics {
            contentDescription = "마지막 업데이트, $label"
        },
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        textAlign = TextAlign.Center,
    )
}

@Composable
private fun UtilityButton(
    label: String,
    icon: ImageVector,
    containerColor: Color,
    contentColor: Color,
    action: () -> Unit,
    enabled: Boolean,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = Modifier.size(64.dp)
            .shadow(8.dp, CircleShape)
            .background(containerColor, CircleShape)
            .clip(CircleShape)
            .then(modifier)
            .clickable(enabled = enabled, role = Role.Button, onClick = action)
            .alpha(if (enabled) 1f else 0.45f),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = label, tint = contentColor, modifier = Modifier.size(28.dp))
    }
}

@Composable
private fun MessageState(
    message: String,
    actionTitle: String? = null,
    action: (() -> Unit)? = null,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            Icons.Rounded.DirectionsBus,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            message,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontSize = 16.sp,
            lineHeight = 24.sp,
            textAlign = TextAlign.Center,
        )
        if (actionTitle != null && action != null) {
            Spacer(Modifier.height(8.dp))
            TextButton(onClick = action) { Text(actionTitle) }
        }
    }
}

@Composable
private fun EmptyHome(onLocate: () -> Unit) {
    MessageState("표시할 탑승 지점이 없습니다.", "다시 시도", onLocate)
}

private fun elapsedText(updatedAt: Instant, now: Instant): String {
    val seconds = Duration.between(updatedAt, now).seconds.coerceAtLeast(0)
    return when {
        seconds < 60 -> "${seconds}초 전"
        seconds < 3600 -> "${seconds / 60}분 전"
        else -> "${seconds / 3600}시간 전"
    }
}
