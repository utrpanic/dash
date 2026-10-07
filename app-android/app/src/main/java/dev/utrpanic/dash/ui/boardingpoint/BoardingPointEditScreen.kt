package dev.utrpanic.dash.ui.boardingpoint

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowRight
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.utrpanic.dash.domain.model.BusRouteNaturalComparator
import dev.utrpanic.dash.domain.model.BusStop
import dev.utrpanic.dash.ui.home.BoardingPointDraft

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BoardingPointEditScreen(
    draft: BoardingPointDraft?,
    canDelete: Boolean,
    isSaving: Boolean,
    errorMessage: String?,
    onBack: () -> Unit,
    onNameChange: (String) -> Unit,
    onRemoveStop: (BusStop) -> Unit,
    onSave: () -> Unit,
    onDelete: () -> Unit,
    onAddStop: () -> Unit,
    onSelectRoutes: (BusStop) -> Unit,
) {
    if (draft == null) return
    var confirmingDelete by remember { mutableStateOf(false) }
    val canSave = draft.name.trim().isNotEmpty() && !isSaving
    val stops = draft.routes.keys.sortedWith(
        compareBy<BusStop> { it.name }.thenBy { it.id.stopId },
    )
    val selectedRouteCount = draft.routes.values.sumOf { it.size }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            Column {
                CenterAlignedTopAppBar(
                    title = {
                        Text(
                            if (draft.originalId == null) "탑승 지점 추가" else "탑승 지점 편집",
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
                        TextButton(onClick = onSave, enabled = canSave) {
                            Text(
                                "저장",
                                color = MaterialTheme.colorScheme.primary.copy(
                                    alpha = if (canSave) 1f else 0.45f,
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
                HorizontalDivider(color = dividerColor())
            }
        },
    ) { insets ->
        Column(Modifier.fillMaxSize().padding(insets)) {
            LazyColumn(Modifier.weight(1f)) {
                item {
                    NameSection(
                        name = draft.name,
                        onNameChange = onNameChange,
                    )
                }
                item {
                    SectionHeader(
                        stopCount = stops.size,
                        selectedRouteCount = selectedRouteCount,
                    )
                }
                item { HorizontalDivider(color = dividerColor()) }
                items(stops, key = { it.id.storageKey }) { stop ->
                    BusStopRow(
                        stop = stop,
                        routeSummary = draft.routes[stop].orEmpty()
                            .sortedWith(BusRouteNaturalComparator)
                            .joinToString(", ") { it.number }
                            .ifEmpty { "없음" },
                        onClick = { onSelectRoutes(stop) },
                        onRemove = { onRemoveStop(stop) },
                    )
                    HorizontalDivider(color = dividerColor())
                }
                item {
                    TextButton(
                        onClick = onAddStop,
                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp),
                    ) {
                        Icon(Icons.Rounded.Add, contentDescription = null)
                        Text(
                            "정류장 추가",
                            fontSize = 17.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                }
                item { HorizontalDivider(color = dividerColor()) }
                errorMessage?.let { message ->
                    item {
                        Text(
                            message,
                            color = MaterialTheme.colorScheme.error,
                            fontSize = 16.sp,
                            modifier = Modifier.padding(16.dp),
                        )
                    }
                }
            }
            if (draft.originalId != null) {
                TextButton(
                    onClick = { confirmingDelete = true },
                    enabled = canDelete && !isSaving,
                    modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                        .padding(horizontal = 16.dp),
                ) {
                    Text(
                        "탑승 지점 삭제",
                        color = MaterialTheme.colorScheme.error.copy(
                            alpha = if (canDelete && !isSaving) 1f else 0.45f,
                        ),
                        fontSize = 16.sp,
                    )
                }
            }
        }
    }

    if (confirmingDelete) {
        AlertDialog(
            onDismissRequest = { confirmingDelete = false },
            title = { Text("탑승 지점을 삭제할까요?") },
            text = { Text("‘${draft.name.trim()}’ 탑승 지점을 삭제합니다.") },
            confirmButton = {
                TextButton(onClick = { confirmingDelete = false; onDelete() }) {
                    Text("탑승 지점 삭제", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmingDelete = false }) { Text("취소") }
            },
        )
    }
}

@Composable
private fun NameSection(
    name: String,
    onNameChange: (String) -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            "이름",
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
        )
        OutlinedTextField(
            value = name,
            onValueChange = onNameChange,
            placeholder = { Text("탑승 지점 이름") },
            singleLine = true,
            textStyle = MaterialTheme.typography.bodyLarge.copy(fontSize = 20.sp),
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = MaterialTheme.colorScheme.surface,
                unfocusedContainerColor = MaterialTheme.colorScheme.surface,
                focusedBorderColor = MaterialTheme.colorScheme.primary,
                unfocusedBorderColor = dividerColor(),
            ),
            modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp),
        )
    }
}

@Composable
private fun SectionHeader(
    stopCount: Int,
    selectedRouteCount: Int,
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            "정류장",
            color = MaterialTheme.colorScheme.onSurface,
            fontSize = 17.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.weight(1f),
        )
        Text(
            "${stopCount}개 · ${selectedRouteCount}개 노선",
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontSize = 14.sp,
        )
    }
}

@Composable
private fun BusStopRow(
    stop: BusStop,
    routeSummary: String,
    onClick: () -> Unit,
    onRemove: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth().heightIn(min = 88.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            modifier = Modifier.weight(1f).clickable(onClick = onClick)
                .testTag("edit-stop-${stop.id.storageKey}")
                .padding(start = 16.dp, top = 14.dp, bottom = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
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
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    "정류장 번호 ${stop.id.stopId}",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontSize = 14.sp,
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        "선택 노선",
                        color = MaterialTheme.colorScheme.primary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                    )
                    Text(
                        routeSummary,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontSize = 14.sp,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false),
                    )
                }
            }
            Icon(
                Icons.AutoMirrored.Rounded.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        IconButton(onClick = onRemove) {
            Icon(
                Icons.Rounded.Delete,
                contentDescription = "${stop.name} 정류장 삭제",
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun dividerColor(): Color =
    MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.25f)
