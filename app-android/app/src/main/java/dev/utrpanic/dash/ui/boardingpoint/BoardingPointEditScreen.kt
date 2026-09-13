package dev.utrpanic.dash.ui.boardingpoint

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
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
) {
    if (draft == null) return
    var confirmingDelete by remember { mutableStateOf(false) }
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (draft.originalId == null) "탑승 지점 추가" else "탑승 지점 편집") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, "뒤로") } },
                actions = {
                    TextButton(onClick = onSave, enabled = draft.name.trim().isNotEmpty() && !isSaving) { Text("저장") }
                },
            )
        },
    ) { insets ->
        LazyColumn(
            Modifier.fillMaxSize().padding(insets),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item {
                OutlinedTextField(
                    value = draft.name,
                    onValueChange = onNameChange,
                    label = { Text("이름") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                )
            }
            item {
                Text("정류장", style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp))
            }
            items(draft.routes.keys.toList(), key = { it.id.storageKey }) { stop ->
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f)) {
                        Text(stop.name, style = MaterialTheme.typography.titleMedium)
                        Text("정류장 번호 ${stop.id.stopId}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text(
                            draft.routes[stop].orEmpty().joinToString(" · ") { it.number }.ifEmpty { "선택 노선 없음" },
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    IconButton(onClick = { onRemoveStop(stop) }) { Icon(Icons.Rounded.Delete, "${stop.name} 제거") }
                }
            }
            item {
                TextButton(onClick = { }, modifier = Modifier.padding(horizontal = 8.dp)) {
                    Icon(Icons.Rounded.Add, null)
                    Text("정류장 추가")
                }
            }
            errorMessage?.let { message -> item { Text(message, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(16.dp)) } }
            if (draft.originalId != null) {
                item {
                    Button(
                        onClick = { confirmingDelete = true },
                        enabled = canDelete && !isSaving,
                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                    ) { Text("탑승 지점 삭제") }
                }
            }
        }
    }
    if (confirmingDelete) {
        AlertDialog(
            onDismissRequest = { confirmingDelete = false },
            title = { Text("탑승 지점을 삭제할까요?") },
            confirmButton = { TextButton(onClick = { confirmingDelete = false; onDelete() }) { Text("삭제", color = Color.Red) } },
            dismissButton = { TextButton(onClick = { confirmingDelete = false }) { Text("취소") } },
        )
    }
}
