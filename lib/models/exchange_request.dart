import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/location_helper.dart';
import 'user_profile.dart';

enum ExchangeType {
  cashToDigital, // User holds physical cash, wants bank/UPI transfer
  digitalToCash, // User holds bank/digital funds, needs physical paper cash
}

class ExchangeRequest {
  final String id;
  final String userId;
  final String exchangeType; // 'CASH_TO_DIGITAL' or 'DIGITAL_TO_CASH'
  final double amount;
  final String currency;
  final List<String> preferredPaymentMethods;
  final String locationName;
  final double latitude;
  final double longitude;
  final String meetupPreference;
  final String notes;
  final String status; // 'ACTIVE', 'MATCHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'EXPIRED'
  final DateTime expiresAt;
  final DateTime createdAt;
  final UserProfile? userProfile;

  ExchangeRequest({
    required this.id,
    required this.userId,
    required this.exchangeType,
    required this.amount,
    this.currency = 'INR',
    this.preferredPaymentMethods = const ['UPI', 'GPay', 'PhonePe'],
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.meetupPreference = 'Public Place (Cafe, Metro, Mall)',
    this.notes = '',
    this.status = 'ACTIVE',
    required this.expiresAt,
    DateTime? createdAt,
    this.userProfile,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCashToDigital => exchangeType == 'CASH_TO_DIGITAL';
  bool get isDigitalToCash => exchangeType == 'DIGITAL_TO_CASH';

  bool get isActive => status == 'ACTIVE' && !isExpired;
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get formattedAmount => CurrencyFormatter.format(amount);

  String get actionTitle {
    if (isCashToDigital) {
      return 'Giving Cash • Needs Digital';
    } else {
      return 'Needs Cash • Sending Digital';
    }
  }

  String get actionSubheading {
    if (isCashToDigital) {
      return 'Has $formattedAmount physical cash in hand to give you. Send them UPI/Digital.';
    } else {
      return 'Needs $formattedAmount physical cash from you. Will send you UPI/Digital.';
    }
  }

  Color get themeColor => isCashToDigital ? AppColors.cashColor : AppColors.digitalColor;
  Color get themeLightColor => isCashToDigital ? AppColors.cashLight : AppColors.digitalLight;

  IconData get iconData => isCashToDigital ? Icons.payments_rounded : Icons.account_balance_wallet_rounded;

  double distanceFrom(double userLat, double userLng) {
    return LocationHelper.calculateDistanceKm(
      lat1: userLat,
      lon1: userLng,
      lat2: latitude,
      lon2: longitude,
    );
  }

  String distanceLabelFrom(double userLat, double userLng) {
    final dist = distanceFrom(userLat, userLng);
    return LocationHelper.formatDistance(dist);
  }

  factory ExchangeRequest.fromJson(Map<String, dynamic> json) {
    List<String> payments = [];
    if (json['preferred_payment_methods'] != null) {
      if (json['preferred_payment_methods'] is List) {
        payments = (json['preferred_payment_methods'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }
    if (payments.isEmpty) {
      payments = ['UPI', 'GPay', 'PhonePe'];
    }

    UserProfile? profile;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      profile = UserProfile.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    return ExchangeRequest(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      exchangeType: json['exchange_type'] as String? ?? 'CASH_TO_DIGITAL',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      currency: json['currency'] as String? ?? 'INR',
      preferredPaymentMethods: payments,
      locationName: json['location_name'] as String? ?? 'Nearby Location',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 12.9716,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 77.5946,
      meetupPreference: json['meetup_preference'] as String? ?? 'Public Place',
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString()) ??
              DateTime.now().add(const Duration(hours: 2))
          : DateTime.now().add(const Duration(hours: 2)),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userProfile: profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exchange_type': exchangeType,
      'amount': amount,
      'currency': currency,
      'preferred_payment_methods': preferredPaymentMethods,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'meetup_preference': meetupPreference,
      'notes': notes,
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  ExchangeRequest copyWith({
    String? id,
    String? userId,
    String? exchangeType,
    double? amount,
    String? currency,
    List<String>? preferredPaymentMethods,
    String? locationName,
    double? latitude,
    double? longitude,
    String? meetupPreference,
    String? notes,
    String? status,
    DateTime? expiresAt,
    DateTime? createdAt,
    UserProfile? userProfile,
  }) {
    return ExchangeRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exchangeType: exchangeType ?? this.exchangeType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      preferredPaymentMethods: preferredPaymentMethods ?? this.preferredPaymentMethods,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      meetupPreference: meetupPreference ?? this.meetupPreference,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}
