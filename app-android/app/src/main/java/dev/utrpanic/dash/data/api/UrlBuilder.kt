package dev.utrpanic.dash.data.api

import okhttp3.HttpUrl

internal fun HttpUrl.Builder.addServiceKey(serviceKey: String): HttpUrl.Builder = apply {
    val value = serviceKey.trim()
    if (value.isEmpty()) throw BusApiException.MissingServiceKey()
    if ('%' in value) {
        addEncodedQueryParameter("serviceKey", value)
    } else {
        addQueryParameter("serviceKey", value)
    }
}
