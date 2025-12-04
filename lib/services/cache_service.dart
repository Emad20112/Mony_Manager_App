import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _cachePrefix = 'cache_';
  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const Duration _defaultCacheDuration = Duration(hours: 1);

  // Cache data with timestamp
  static Future<void> cacheData(
    String key,
    dynamic data, {
    Duration? duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_cacheTimestampPrefix$key';

    final jsonData = jsonEncode(data);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString(cacheKey, jsonData);
    await prefs.setInt(timestampKey, timestamp);
  }

  // Get cached data if not expired
  static Future<T?> getCachedData<T>(String key, {Duration? duration}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_cacheTimestampPrefix$key';

    final cachedData = prefs.getString(cacheKey);
    final timestamp = prefs.getInt(timestampKey);

    if (cachedData == null || timestamp == null) {
      return null;
    }

    final cacheDuration = duration ?? _defaultCacheDuration;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (now.difference(cacheTime) > cacheDuration) {
      // Cache expired, remove it
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
      return null;
    }

    try {
      return jsonDecode(cachedData) as T;
    } catch (e) {
      // Invalid JSON, remove cache
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
      return null;
    }
  }

  // Clear specific cache
  static Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_cacheTimestampPrefix$key';

    await prefs.remove(cacheKey);
    await prefs.remove(timestampKey);
  }

  // Clear all cache
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_cachePrefix) ||
          key.startsWith(_cacheTimestampPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  // Check if cache exists and is valid
  static Future<bool> isCacheValid(String key, {Duration? duration}) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampKey = '$_cacheTimestampPrefix$key';

    final timestamp = prefs.getInt(timestampKey);
    if (timestamp == null) return false;

    final cacheDuration = duration ?? _defaultCacheDuration;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    return now.difference(cacheTime) <= cacheDuration;
  }

  // Get cache age
  static Future<Duration?> getCacheAge(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampKey = '$_cacheTimestampPrefix$key';

    final timestamp = prefs.getInt(timestampKey);
    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    return now.difference(cacheTime);
  }
}


