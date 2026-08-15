/// What the round button in recitation chrome does for the current state.
///
/// The close (X) button ends the session; this one only pauses and resumes so
/// the listener keeps their place in the surah.
enum RecitationPrimaryAction {
  pause,
  resume;

  String get tooltipKey => this == pause ? 'pause' : 'play';
}

RecitationPrimaryAction recitationPrimaryAction({required bool isPlaying}) {
  return isPlaying
      ? RecitationPrimaryAction.pause
      : RecitationPrimaryAction.resume;
}
