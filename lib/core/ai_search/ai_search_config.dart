/// Feature flag and ranking constants for AI Search. Maintainer flips
/// [kAiSearchEnabled] after Phase G eval.
const bool kAiSearchEnabled = true;

const double kMinScoreKeyword = 0.25;

/// Used after GATE D0 hybrid ranking. Keyword-only until then.
// TODO(D0): hybrid scoring 0.4 * bm25_norm + 0.6 * cosine.
const double kMinScoreHybrid = 0.45;

const int kMaxResultsPerType = 5;

const String kSearchIndexAssetPath = 'assets/ai/search_index.sqlite';

const String kSearchIndexBuiltAtPrefKey = 'ai_search_index_built_at_utc';
