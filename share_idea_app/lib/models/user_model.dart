import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { innovator, patron, both }

enum AccountStatus { active, suspended, banned }

class UserModel extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final UserRole role;
  final bool isActivePatron;
  final DateTime? subscriptionExpiry;
  final DateTime createdAt;
  final AccountStatus accountStatus;
  final bool reportReviewFlag;
  final int totalReports;
  final int falseReports;
  final int validReports;
  final int openReports;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.isActivePatron,
    this.subscriptionExpiry,
    required this.createdAt,
    this.accountStatus = AccountStatus.active,
    this.reportReviewFlag = false,
    this.totalReports = 0,
    this.falseReports = 0,
    this.validReports = 0,
    this.openReports = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final reportStats = d['reportStats'] as Map<String, dynamic>? ?? const {};
    return UserModel(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == d['role'],
        orElse: () => UserRole.innovator,
      ),
      isActivePatron: d['isActivePatron'] as bool? ?? false,
      subscriptionExpiry: (d['subscriptionExpiry'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      accountStatus: AccountStatus.values.firstWhere(
        (s) => s.name == (d['accountStatus'] as String? ?? 'active'),
        orElse: () => AccountStatus.active,
      ),
      reportReviewFlag: d['reportReviewFlag'] as bool? ?? false,
      totalReports: (reportStats['totalReports'] as num?)?.toInt() ?? 0,
      falseReports: (reportStats['falseReports'] as num?)?.toInt() ?? 0,
      validReports: (reportStats['validReports'] as num?)?.toInt() ?? 0,
      openReports: (reportStats['openReports'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'email': email,
        'role': role.name,
        'isActivePatron': isActivePatron,
        'subscriptionExpiry': subscriptionExpiry != null
            ? Timestamp.fromDate(subscriptionExpiry!)
            : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? displayName,
    UserRole? role,
    bool? isActivePatron,
    DateTime? subscriptionExpiry,
    AccountStatus? accountStatus,
    bool? reportReviewFlag,
  }) =>
      UserModel(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email,
        role: role ?? this.role,
        isActivePatron: isActivePatron ?? this.isActivePatron,
        subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
        createdAt: createdAt,
        accountStatus: accountStatus ?? this.accountStatus,
        reportReviewFlag: reportReviewFlag ?? this.reportReviewFlag,
        totalReports: totalReports,
        falseReports: falseReports,
        validReports: validReports,
        openReports: openReports,
      );

  @override
  List<Object?> get props => [
        uid,
        displayName,
        email,
        role,
        isActivePatron,
        subscriptionExpiry,
        accountStatus,
        reportReviewFlag,
        totalReports,
        falseReports,
        validReports,
        openReports,
      ];
}
