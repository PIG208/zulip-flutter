export './android_notifications.g.dart';

/// For use in [NotificationChannel.importance].
///
/// See:
///   https://developer.android.com/reference/android/app/NotificationChannel#setImportance(int)
///   https://developer.android.com/reference/android/app/NotificationChannel#getImportance()
abstract class NotificationImportance {
  /// Corresponds to `IMPORTANCE_UNSPECIFIED`:
  ///   https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#IMPORTANCE_UNSPECIFIED()
  static const unspecified = -1000;

  /// Corresponds to `IMPORTANCE_NONE`:
  ///   https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#IMPORTANCE_NONE()
  static const none = 0;

  /// Corresponds to `IMPORTANCE_MIN`:
  ///   https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#IMPORTANCE_MIN()
  static const min = 1;

  /// Corresponds to `IMPORTANCE_LOW`:
  ///   https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#IMPORTANCE_LOW()
  static const low = 2;

  /// Corresponds to `IMPORTANCE_DEFAULT`:
  ///   https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#IMPORTANCE_DEFAULT()
  static const default_ = 3;

  /// Corresponds to `IMPORTANCE_HIGH`:
  ///   https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#IMPORTANCE_HIGH()
  static const high = 4;

  /// Corresponds to `IMPORTANCE_MAX`:
  ///   https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#IMPORTANCE_MAX()
  static const max = 5;
}

/// For use in [PendingIntent.flags].
///
/// See: https://developer.android.com/reference/android/app/PendingIntent#constants_1
abstract class PendingIntentFlag {
  /// Corresponds to `FLAG_ONE_SHOT`.
  static const oneShot = 1 << 30;

  /// Corresponds to `FLAG_NO_CREATE`.
  static const noCreate = 1 << 29;

  /// Corresponds to `FLAG_CANCEL_CURRENT`.
  static const cancelCurrent = 1 << 28;

  /// Corresponds to `FLAG_UPDATE_CURRENT`.
  static const updateCurrent = 1 << 27;

  /// Corresponds to `FLAG_IMMUTABLE`.
  static const immutable = 1 << 26;

  /// Corresponds to `FLAG_MUTABLE`.
  static const mutable = 1 << 25;

  /// Corresponds to `FLAG_ALLOW_UNSAFE_IMPLICIT_INTENT`.
  static const allowUnsafeImplicitIntent = 1 << 24;
}
