package dev.utrpanic.dash.data.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.CancellationSignal
import androidx.core.content.ContextCompat
import dev.utrpanic.dash.domain.location.UserLocation
import dev.utrpanic.dash.domain.location.UserLocationProvider
import dev.utrpanic.dash.domain.location.UserLocationUnavailableException
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class AndroidUserLocationProvider(context: Context) : UserLocationProvider {
    private val applicationContext = context.applicationContext
    private val locationManager = applicationContext.getSystemService(LocationManager::class.java)

    override suspend fun currentLocation(): UserLocation {
        val hasFineLocation = ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val hasCoarseLocation = ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        if (!hasFineLocation && !hasCoarseLocation) throw SecurityException("Location permission is not granted")

        val provider = listOf(
            LocationManager.FUSED_PROVIDER,
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
        ).firstOrNull { it in locationManager.getProviders(true) }
            ?: throw UserLocationUnavailableException()

        return suspendCancellableCoroutine { continuation ->
            val cancellationSignal = CancellationSignal()
            continuation.invokeOnCancellation { cancellationSignal.cancel() }
            locationManager.getCurrentLocation(
                provider,
                cancellationSignal,
                applicationContext.mainExecutor,
            ) { location ->
                if (location == null) {
                    continuation.resumeWithException(UserLocationUnavailableException())
                } else {
                    continuation.resume(UserLocation(location.latitude, location.longitude))
                }
            }
        }
    }
}
