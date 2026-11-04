import 'user_profile.dart';
import 'exchange_request.dart';
import '../core/utils/currency_formatter.dart';

class ExchangeMatch {
  final String id;
  final String requestId;
  final String requesterId;
  final String peerId;
  final String status; // 'PROPOSED', 'ACCEPTED', 'ARRIVED', 'COMPLETED', 'CANCELLED', 'DISPUTED'
  final double agreedAmount;
  final String meetupLocation;
  final String handshakeOtp;
  final double? peerLatitude;
  final double? peerLongitude;
  final DateTime createdAt;
  final UserProfile? requesterProfile;
  final UserProfile? peerProfile;
  final ExchangeRequest? request;

  ExchangeMatch({
    required this.id,
    required this.requestId,
    required this.requesterId,
    required this.peerId,
    this.status = 'PROPOSED',
    required this.agreedAmount,
    this.meetupLocation = 'Public Meeting Spot',
    this.handshakeOtp = '4829',
    this.peerLatitude,
    this.peerLongitude,
    DateTime? createdAt,
    this.requesterProfile,
    this.peerProfile,
    this.request,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isProposed => status == 'PROPOSED';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isArrived => status == 'ARRIVED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  String get formattedAmount => CurrencyFormatter.format(agreedAmount);

  factory ExchangeMatch.fromJson(Map<String, dynamic> json) {
    UserProfile? reqProfile;
    if (json['requester_profile'] != null && json['requester_profile'] is Map<String, dynamic>) {
      reqProfile = UserProfile.fromJson(json['requester_profile'] as Map<String, dynamic>);
    }

    UserProfile? pProfile;
    if (json['peer_profile'] != null && json['peer_profile'] is Map<String, dynamic>) {
      pProfile = UserProfile.fromJson(json['peer_profile'] as Map<String, dynamic>);
    }

    ExchangeRequest? req;
    if (json['exchange_requests'] != null && json['exchange_requests'] is Map<String, dynamic>) {
      req = ExchangeRequest.fromJson(json['exchange_requests'] as Map<String, dynamic>);
    }

    return ExchangeMatch(
      id: json['id'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
      requesterId: json['requester_id'] as String? ?? '',
      peerId: json['peer_id'] as String? ?? '',
      status: json['status'] as String? ?? 'PROPOSED',
      agreedAmount: (json['agreed_amount'] is num)
          ? (json['agreed_amount'] as num).toDouble()
          : 0.0,
      meetupLocation: json['meetup_location'] as String? ?? 'Public Meeting Spot',
      handshakeOtp: json['handshake_otp'] as String? ?? '4829',
      peerLatitude: (json['peer_latitude'] is num)
          ? (json['peer_latitude'] as num).toDouble()
          : null,
      peerLongitude: (json['peer_longitude'] is num)
          ? (json['peer_longitude'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      requesterProfile: reqProfile,
      peerProfile: pProfile,
      request: req,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'requester_id': requesterId,
      'peer_id': peerId,
      'status': status,
      'agreed_amount': agreedAmount,
      'meetup_location': meetupLocation,
      'handshake_otp': handshakeOtp,
      'peer_latitude': peerLatitude,
      'peer_longitude': peerLongitude,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
