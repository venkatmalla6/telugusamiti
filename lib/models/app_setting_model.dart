class AppSettingModel {
  final String id;
  final bool maintenanceMode;
  final String minimumAppVersion;
  final String latestAppVersion;
  final String? alertMessage;

  AppSettingModel({
    required this.id,
    this.maintenanceMode = false,
    this.minimumAppVersion = '1.0.0',
    this.latestAppVersion = '1.0.0',
    this.alertMessage,
  });

  factory AppSettingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AppSettingModel(
      id: documentId,
      maintenanceMode: map['maintenanceMode'] ?? false,
      minimumAppVersion: map['minimumAppVersion'] ?? '1.0.0',
      latestAppVersion: map['latestAppVersion'] ?? '1.0.0',
      alertMessage: map['alertMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maintenanceMode': maintenanceMode,
      'minimumAppVersion': minimumAppVersion,
      'latestAppVersion': latestAppVersion,
      'alertMessage': alertMessage,
    };
  }

  AppSettingModel copyWith({
    String? id,
    bool? maintenanceMode,
    String? minimumAppVersion,
    String? latestAppVersion,
    String? alertMessage,
  }) {
    return AppSettingModel(
      id: id ?? this.id,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      minimumAppVersion: minimumAppVersion ?? this.minimumAppVersion,
      latestAppVersion: latestAppVersion ?? this.latestAppVersion,
      alertMessage: alertMessage ?? this.alertMessage,
    );
  }
}
