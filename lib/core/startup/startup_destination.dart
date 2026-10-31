/// Where a cold start should land.
enum StartupDestination {
  /// Keep the normal Home screen (first launch, setting off, or a deep link).
  home,

  /// Open the stored reader/mushaf position.
  resume,
}

/// Deep links win over auto-resume; otherwise resume only when enabled.
StartupDestination decideStartupDestination({
  required bool openToLastRead,
  required bool hasLastRead,
  required bool hasDeepLink,
}) {
  if (hasDeepLink) return StartupDestination.home;
  if (!openToLastRead || !hasLastRead) return StartupDestination.home;
  return StartupDestination.resume;
}
