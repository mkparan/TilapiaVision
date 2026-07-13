/// A local-only identity used in place of a user account, per the
/// No-Login Architecture described in the UI/UX design philosophy.
class FarmProfile {
  const FarmProfile({
    required this.name,
    required this.createdAt,
    required this.acknowledgedStorageNotice,
  });

  final String name;
  final DateTime createdAt;
  final bool acknowledgedStorageNotice;

  Map<String, Object?> toJson() => {
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'acknowledgedStorageNotice': acknowledgedStorageNotice,
      };

  factory FarmProfile.fromJson(Map<String, Object?> json) => FarmProfile(
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        acknowledgedStorageNotice: json['acknowledgedStorageNotice'] as bool? ?? false,
      );
}
