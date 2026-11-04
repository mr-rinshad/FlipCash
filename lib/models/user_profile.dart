class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String avatarUrl;
  final String phoneNumber;
  final double rating;
  final int totalReviews;
  final int successfulExchanges;
  final int trustScore; // 0 to 100
  final String role; // 'user' or 'admin'
  final bool isVerified;
  final bool isBanned;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.phoneNumber,
    this.rating = 5.0,
    this.totalReviews = 0,
    this.successfulExchanges = 0,
    this.trustScore = 100,
    this.role = 'user',
    this.isVerified = false,
    this.isBanned = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role.toLowerCase() == 'admin';

  String get initials {
    if (fullName.isEmpty) return 'U';
    final parts = fullName.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'FlipCash User',
      avatarUrl: json['avatar_url'] as String? ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      phoneNumber: json['phone_number'] as String? ?? '',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 5.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      successfulExchanges: json['successful_exchanges'] as int? ?? 0,
      trustScore: json['trust_score'] as int? ?? 100,
      role: json['role'] as String? ?? 'user',
      isVerified: json['is_verified'] as bool? ?? false,
      isBanned: json['is_banned'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'rating': rating,
      'total_reviews': totalReviews,
      'successful_exchanges': successfulExchanges,
      'trust_score': trustScore,
      'role': role,
      'is_verified': isVerified,
      'is_banned': isBanned,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phoneNumber,
    double? rating,
    int? totalReviews,
    int? successfulExchanges,
    int? trustScore,
    String? role,
    bool? isVerified,
    bool? isBanned,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      successfulExchanges: successfulExchanges ?? this.successfulExchanges,
      trustScore: trustScore ?? this.trustScore,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
