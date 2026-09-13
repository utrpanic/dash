package dev.utrpanic.dash.data.api

import com.google.gson.JsonElement
import com.google.gson.JsonObject

internal fun JsonObject.string(name: String): String =
    get(name)?.takeUnless(JsonElement::isJsonNull)?.asJsonPrimitive?.asString?.trim().orEmpty()

internal fun JsonObject.long(name: String): Long? = string(name).toLongOrNull()

internal fun JsonObject.int(name: String): Int? = string(name).toIntOrNull()

internal fun JsonObject.double(name: String): Double? = string(name).toDoubleOrNull()

internal fun JsonObject.items(name: String): List<JsonObject> {
    val value = get(name) ?: return emptyList()
    if (value.isJsonNull) return emptyList()
    if (value.isJsonObject) return listOf(value.asJsonObject)
    if (value.isJsonArray) return value.asJsonArray.mapNotNull { it.takeIf(JsonElement::isJsonObject)?.asJsonObject }
    throw BusApiException.MalformedResponse("Invalid $name field")
}

internal fun JsonObject.requiredObject(name: String): JsonObject =
    get(name)?.takeIf(JsonElement::isJsonObject)?.asJsonObject
        ?: throw BusApiException.MalformedResponse("Missing $name field")
