package dev.utrpanic.dash.data.api

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.HttpUrl
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit

fun interface HttpTransport {
    suspend fun get(url: HttpUrl): String
}

class OkHttpTransport(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(15, TimeUnit.SECONDS)
        .build(),
) : HttpTransport {
    override suspend fun get(url: HttpUrl): String = withContext(Dispatchers.IO) {
        val request = Request.Builder().url(url).get().build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw BusApiException.HttpStatus(response.code)
            }
            response.body.string()
        }
    }
}
