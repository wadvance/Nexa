import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil de usuario de AETHERIS persistido en Firestore (colección `users`).
class UserProfile {
  final String uid;
  final String? voiceProfilePath;
  final int securityLevel;
  final List<String> trustedContacts;

  UserProfile({
    required this.uid,
    this.voiceProfilePath,
    this.securityLevel = 1,
    this.trustedContacts = const [],
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'voice_profile_path': voiceProfilePath,
        'security_level': securityLevel,
        'trusted_contacts': trustedContacts,
      };

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      voiceProfilePath: data['voice_profile_path'],
      securityLevel: data['security_level'] ?? 1,
      trustedContacts: List<String>.from(data['trusted_contacts'] ?? []),
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      voiceProfilePath: data['voice_profile_path'],
      securityLevel: data['security_level'] ?? 1,
      trustedContacts: List<String>.from(data['trusted_contacts'] ?? []),
    );
  }

  UserProfile copyWith({
    String? voiceProfilePath,
    int? securityLevel,
    List<String>? trustedContacts,
  }) {
    return UserProfile(
      uid: uid,
      voiceProfilePath: voiceProfilePath ?? this.voiceProfilePath,
      securityLevel: securityLevel ?? this.securityLevel,
      trustedContacts: trustedContacts ?? this.trustedContacts,
    );
  }
}
