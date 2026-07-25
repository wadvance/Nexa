import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro de evento de seguridad persistido en Firestore (colección `security_logs`).
class SecurityLog {
  final String? id;
  final DateTime timestamp;
  final GeoPoint? location;
  final String detectedThreat;
  final String iaAnalysis;

  SecurityLog({
    this.id,
    required this.timestamp,
    this.location,
    required this.detectedThreat,
    required this.iaAnalysis,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': Timestamp.fromDate(timestamp),
        'location': location,
        'detected_threat': detectedThreat,
        'ia_analysis': iaAnalysis,
      };

  factory SecurityLog.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SecurityLog(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint?,
      detectedThreat: data['detected_threat'] ?? '',
      iaAnalysis: data['ia_analysis'] ?? '',
    );
  }

  factory SecurityLog.fromMap(Map<String, dynamic> data) {
    final ts = data['timestamp'];
    return SecurityLog(
      id: data['id'] as String?,
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.parse(ts as String),
      location: data['location'] as GeoPoint?,
      detectedThreat: data['detected_threat'] ?? '',
      iaAnalysis: data['ia_analysis'] ?? '',
    );
  }
}
