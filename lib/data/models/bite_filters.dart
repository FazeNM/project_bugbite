/// Shared vocabulary for visual-guide filters and community observations.
///
/// IDs are persisted; labels may change without losing older post matches.
class BiteFilterOption {
  const BiteFilterOption(this.id, this.label);

  final String id;
  final String label;
}

abstract final class BiteFilters {
  static const symptoms = <BiteFilterOption>[
    BiteFilterOption('red', 'Color changed'),
    BiteFilterOption('itchy', 'Itchy'),
    BiteFilterOption('raised', 'Raised'),
    BiteFilterOption('cluster', 'Clustered'),
    BiteFilterOption('line', 'In a line'),
    BiteFilterOption('painful', 'Painful or burning'),
    BiteFilterOption('swollen', 'Swollen'),
    BiteFilterOption('blister', 'Blister or white tip'),
    BiteFilterOption('scalp', 'Scalp or hairline'),
    BiteFilterOption('lower-leg', 'Ankles or lower legs'),
    BiteFilterOption('tick', 'Attached tick'),
    BiteFilterOption('stinger', 'Stinger visible'),
  ];

  static const postOptions = <BiteFilterOption>[
    ...symptoms,
    BiteFilterOption('outdoors', 'Outdoors'),
    BiteFilterOption('improving', 'Improving'),
    BiteFilterOption('checked-with-clinician', 'Checked with clinician'),
  ];

  /// Accepts canonical IDs and legacy display tags such as Red/Itchy/Cluster.
  static String? normalize(String value) {
    final cleaned = value.trim().toLowerCase();
    for (final option in postOptions) {
      if (cleaned == option.id || cleaned == option.label.toLowerCase()) {
        return option.id;
      }
    }
    return null;
  }

  static Set<String> normalizeAll(Iterable<String> values) =>
      values.map(normalize).whereType<String>().toSet();

  static String labelFor(String value) {
    final id = normalize(value);
    for (final option in postOptions) {
      if (option.id == id) return option.label;
    }
    return value;
  }

  /// Only known symptom filters may enter the screen through a deep link.
  static Set<String> fromUri(Uri uri) {
    final selected = normalizeAll(uri.queryParametersAll['tag'] ?? const []);
    return symptoms
        .where((option) => selected.contains(option.id))
        .map((option) => option.id)
        .toSet();
  }

  static String communityLocation(Iterable<String> values) {
    final selected = normalizeAll(values);
    final tags = symptoms
        .where((option) => selected.contains(option.id))
        .map((option) => option.id)
        .toList(growable: false);
    return Uri(
      path: '/community',
      queryParameters: tags.isEmpty ? null : <String, Object>{'tag': tags},
    ).toString();
  }
}
