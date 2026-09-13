package dev.utrpanic.dash.ui.boardingpoint

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
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
    onAdd: () -> Unit,
) {
    BackHandler(onBack = onBack)
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("탑승 지점") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, "뒤로") } },
                actions = { IconButton(onClick = onAdd) { Icon(Icons.Rounded.Add, "탑승 지점 추가") } },
            )
        },
    ) { insets ->
        LazyColumn(Modifier.fillMaxSize().padding(insets)) {
            items(points, key = BoardingPoint::id) { point ->
                val selected = point.id == currentId
                Row(
                    modifier = Modifier.fillMaxWidth()
                        .height(IntrinsicSize.Min)
                        .background(if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f) else MaterialTheme.colorScheme.background),
                ) {
                    Box(
                        Modifier.width(4.dp).fillMaxHeight().background(
                            if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.background,
                        ),
                    )
                    Row(
                        Modifier.weight(1f).clickable { onSelect(point) }.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(Modifier.weight(1f)) {
                            Text(point.name, style = MaterialTheme.typography.titleLarge, fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium)
                            val routes = point.routes.values.flatten().distinct()
                                .sortedWith(BusRouteNaturalComparator).map { it.number }
                            Text(
                                "${routes.size}개 노선 · ${routes.joinToString(" · ")}",
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                        IconButton(onClick = { onEdit(point) }) { Icon(Icons.Rounded.Edit, "${point.name} 편집") }
                    }
                }
                HorizontalDivider()
            }
        }
    }
}
