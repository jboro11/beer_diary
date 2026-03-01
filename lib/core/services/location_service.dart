import 'package:geolocator/geolocator.dart';

/// Služba pro získání GPS polohy.
///
/// Zapouzdřuje kontrolu oprávnění a zjednodušuje API pro
/// feature moduly. Vrací [Position] nebo null při chybě.
class LocationService {
  LocationService._();

  /// Zkontroluje a vyžádá oprávnění pro GPS.
  static Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Vrací aktuální GPS pozici, nebo null pokud není k dispozici.
  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }
}
