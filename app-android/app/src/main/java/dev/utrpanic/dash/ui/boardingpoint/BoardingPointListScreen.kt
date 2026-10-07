package dev.utrpanic.dash.ui.boardingpoint

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.DirectionsBus
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CenterAlignedTopAppBar
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.utrpanic.dash.domain.model.BoardingPoint
import dev.utrpanic.dash.domain.model.BusRouteNaturalComparator

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BoardingPointListScreen(
    points: List<BoardingPoint>,
    currentId: String?,
    onBack: () -> Unit,
    onSelect: (BoardingPoint) -> Unit,
    onEdit: (BoardingPoint) -> Unit,
    onDelete: (BoardingPoint) -> Unit,
    onAdd: () -> Unit,
) {
    var deleteConfirmation by remember { mutableStateOf<BoardingPoint?>(null) }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            Column {
                CenterAlignedTopAppBar(
                    title = {
                        Text(
                            "탑승 지점",
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
                        IconButton(onClick = onAdd) {
                            Icon(
                                Icons.Rounded.Add,
                                contentDescription = "탑승 지점 추가",
                                tint = MaterialTheme.colorScheme.primary,
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
        if (points.isEmpty()) {
            EmptyBoardingPoints(
                modifier = Modifier.fillMaxSize().padding(insets),
                onAdd = onAdd,
            )
        } else {
            LazyColumn(Modifier.fillMaxSize().padding(insets)) {
                items(points, key = BoardingPoint::id) { point ->
                    BoardingPointRow(
                        point = point,
                        selected = point.id == currentId,
                        canDelete = points.size > 1,
                        onSelect = { onSelect(point) },
                        onEdit = { onEdit(point) },
                        onDelete = { deleteConfirmation = point },
                    )
                    HorizontalDivider(color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.25f))
                }
            }
        }
    }

    deleteConfirmation?.let { point ->
        AlertDialog(
            onDismissRequest = { deleteConfirmation = null },
            title = { Text("탑승 지점을 삭제할까요?") },
            text = { Text("‘${point.name}’ 탑승 지점이 삭제됩니다.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        deleteConfirmation = null
                        onDelete(point)
                    },
                ) {
                    Text("탑승 지점 삭제", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { deleteConfirmation = null }) {
                    Text("취소")
                }
            },
        )
    }
}

@Composable
private fun BoardingPointRow(
    point: BoardingPoint,
    selected: Boolean,
    canDelete: Boolean,
    onSelect: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth()
            .height(IntrinsicSize.Min)
            .background(
                if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)
                else MaterialTheme.colorScheme.background,
            ),
    ) {
        Box(
            Modifier.width(4.dp).fillMaxHeight().background(
                if (selected) MaterialTheme.colorScheme.primary else Color.Transparent,
            ),
        )
        Row(
            modifier = Modifier.weight(1f).heightIn(min = 88.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(
                modifier = Modifier.weight(1f).fillMaxHeight().clickable(onClick = onSelect)
                    .padding(start = 16.dp, top = 14.dp, bottom = 14.dp),
                verticalArrangement = Arrangement.Center,
            ) {
                Text(
                    point.name,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontSize = 20.sp,
                    lineHeight = 28.sp,
                    fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                val routes = point.routes.values.flatten().distinct()
                    .sortedWith(BusRouteNaturalComparator).map { it.number }
                Text(
                    "${routes.size}개 노선 · ${routes.joinToString(", ")}",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontSize = 16.sp,
                    lineHeight = 24.sp,
                    fontWeight = FontWeight.Normal,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            IconButton(onClick = onEdit) {
                Icon(
                    Icons.Rounded.Edit,
                    contentDescription = "${point.name} 편집",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            IconButton(onClick = onDelete, enabled = canDelete) {
                Icon(
                    Icons.Rounded.Delete,
                    contentDescription = "${point.name} 삭제",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = if (canDelete) 1f else 0.45f),
                )
            }
        }
    }
}

@Composable
private fun EmptyBoardingPoints(
    modifier: Modifier,
    onAdd: () -> Unit,
) {
    Column(
        modifier = modifier.padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            Icons.Rounded.DirectionsBus,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(
            "등록된 탑승 지점이 없습니다",
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontSize = 16.sp,
            lineHeight = 24.sp,
            textAlign = TextAlign.Center,
        )
        TextButton(onClick = onAdd) { Text("탑승 지점 추가") }
    }
}
