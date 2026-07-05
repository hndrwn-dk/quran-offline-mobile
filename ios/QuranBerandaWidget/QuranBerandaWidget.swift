import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.tursinalabs.quranoffline"
private let payloadKey = "beranda_payload"

struct BerandaWidgetPayload {
  let tagline: String
  let reflectionLabel: String
  let reflectionTitle: String
  let reflectionRef: String
  let reflectionBadge: String
  let continueLabel: String
  let surahName: String
  let ayahNo: Int
  let surahPercent: Int
  let juzLabel: String
  let juzPercent: Int
  let readDeepLink: String
  let reflectionDeepLink: String
  let hasContinue: Bool

  static func load(from defaults: UserDefaults?) -> BerandaWidgetPayload {
    guard
      let raw = defaults?.string(forKey: payloadKey),
      let data = raw.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return .placeholder
    }

    return BerandaWidgetPayload(
      tagline: json["tagline"] as? String ?? "",
      reflectionLabel: json["reflectionLabel"] as? String ?? "Renungan",
      reflectionTitle: json["reflectionTitle"] as? String ?? "",
      reflectionRef: json["reflectionRef"] as? String ?? "",
      reflectionBadge: json["reflectionBadge"] as? String ?? "",
      continueLabel: json["continueLabel"] as? String ?? "Lanjutkan baca",
      surahName: json["surahName"] as? String ?? "",
      ayahNo: json["ayahNo"] as? Int ?? 0,
      surahPercent: json["surahPercent"] as? Int ?? -1,
      juzLabel: json["juzLabel"] as? String ?? "",
      juzPercent: json["juzPercent"] as? Int ?? -1,
      readDeepLink: json["readDeepLink"] as? String ?? "quranoffline://home",
      reflectionDeepLink: json["reflectionDeepLink"] as? String ?? "quranoffline://reflection",
      hasContinue: json["hasContinue"] as? Bool ?? false
    )
  }

  static let placeholder = BerandaWidgetPayload(
    tagline: "Baca, renungkan, lanjutkan tilawah",
    reflectionLabel: "Renungan",
    reflectionTitle: "Ketika ujian datang",
    reflectionRef: "Al-Baqarah 2:155-157",
    reflectionBadge: "Kesabaran",
    continueLabel: "Lanjutkan baca",
    surahName: "Al-Kahf",
    ayahNo: 45,
    surahPercent: 41,
    juzLabel: "Juz 15",
    juzPercent: 58,
    readDeepLink: "quranoffline://read?surah=18&ayah=45",
    reflectionDeepLink: "quranoffline://reflection",
    hasContinue: true
  )
}

struct BerandaEntry: TimelineEntry {
  let date: Date
  let payload: BerandaWidgetPayload
}

struct BerandaProvider: TimelineProvider {
  func placeholder(in context: Context) -> BerandaEntry {
    BerandaEntry(date: Date(), payload: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (BerandaEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<BerandaEntry>) -> Void) {
    let entry = loadEntry()
    completion(Timeline(entries: [entry], policy: .atEnd))
  }

  private func loadEntry() -> BerandaEntry {
    let defaults = UserDefaults(suiteName: widgetGroupId)
    let payload = BerandaWidgetPayload.load(from: defaults)
    return BerandaEntry(date: Date(), payload: payload)
  }
}

struct QuranBerandaWidgetEntryView: View {
  var entry: BerandaProvider.Entry
  @Environment(\.widgetFamily) private var family

  private let sage = Color(red: 0.35, green: 0.45, blue: 0.35)
  private let sageDark = Color(red: 0.29, green: 0.42, blue: 0.28)
  private let muted = Color(red: 0.36, green: 0.42, blue: 0.35)
  private let textPrimary = Color(red: 0.18, green: 0.25, blue: 0.19)

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      header
      reflectionSection
      if entry.payload.hasContinue {
        continueSection
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(red: 0.99, green: 0.99, blue: 0.99))
    .widgetURL(
      URL(
        string: entry.payload.hasContinue
          ? entry.payload.readDeepLink
          : entry.payload.reflectionDeepLink
      )
    )
  }

  private var header: some View {
    HStack(spacing: 5) {
      Text("Q")
        .font(.system(size: 8, weight: .bold))
        .foregroundColor(.white)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(sage)
        .cornerRadius(4)
      Text("Quran Offline")
        .font(.system(size: 8, weight: .semibold))
        .foregroundColor(muted)
      Text("— \(entry.payload.tagline)")
        .font(.system(size: 7))
        .foregroundColor(muted)
        .lineLimit(1)
    }
  }

  private var reflectionSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(entry.payload.reflectionLabel.uppercased())
          .font(.system(size: 8, weight: .semibold))
          .foregroundColor(muted)
        Spacer()
        if !entry.payload.reflectionBadge.isEmpty {
          Text(entry.payload.reflectionBadge)
            .font(.system(size: 7, weight: .semibold))
            .foregroundColor(sage)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.7))
            .cornerRadius(5)
        }
      }
      if !entry.payload.reflectionTitle.isEmpty {
        Text(entry.payload.reflectionTitle)
          .font(.system(size: family == .systemSmall ? 11 : 12, weight: .semibold))
          .foregroundColor(textPrimary)
          .lineLimit(family == .systemLarge ? 2 : 1)
      }
      if !entry.payload.reflectionRef.isEmpty {
        Text(entry.payload.reflectionRef)
          .font(.system(size: 8, weight: .semibold))
          .foregroundColor(sage)
      }
    }
  }

  private var continueSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Divider().overlay(Color.black.opacity(0.08))
      Text(entry.payload.continueLabel.uppercased())
        .font(.system(size: 8, weight: .semibold))
        .foregroundColor(muted)
      HStack {
        Text(entry.payload.surahName)
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(textPrimary)
          .lineLimit(1)
        Spacer()
        if entry.payload.ayahNo > 0 {
          Text("Ayat \(entry.payload.ayahNo)")
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(sage)
        }
      }
      if entry.payload.surahPercent >= 0 {
        ProgressRow(label: "SURAH", percent: entry.payload.surahPercent, color: sage)
      }
      if entry.payload.juzPercent >= 0, !entry.payload.juzLabel.isEmpty {
        ProgressRow(
          label: entry.payload.juzLabel.uppercased(),
          percent: entry.payload.juzPercent,
          color: sageDark
        )
      }
    }
  }
}

private struct ProgressRow: View {
  let label: String
  let percent: Int
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      HStack {
        Text(label)
          .font(.system(size: 7, weight: .semibold))
          .foregroundColor(Color(red: 0.36, green: 0.42, blue: 0.35))
        Spacer()
        Text("\(percent)%")
          .font(.system(size: 7, weight: .semibold))
          .foregroundColor(color)
      }
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 2)
            .fill(Color(red: 0.35, green: 0.45, blue: 0.35).opacity(0.12))
          RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: geo.size.width * CGFloat(max(0, min(100, percent))) / 100.0)
        }
      }
      .frame(height: 4)
    }
  }
}

@main
struct QuranBerandaWidget: Widget {
  let kind: String = "QuranBerandaWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: BerandaProvider()) { entry in
      QuranBerandaWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Quran Offline — Beranda")
    .description("Renungan harian dan lanjutkan baca Al-Qur'an offline.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct QuranBerandaWidget_Previews: PreviewProvider {
  static var previews: some View {
    QuranBerandaWidgetEntryView(entry: BerandaEntry(date: Date(), payload: .placeholder))
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
