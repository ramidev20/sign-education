class DeliveryModel {
  final String? deliveryId;
  final String assignmentId;
  final String userId;
  final String username;
  final String fileUrl;
  final Map<String, dynamic>? answersJson;
  final DateTime deliveryDate;
  final String status;
  final String statusComment;

  DeliveryModel({
    this.deliveryId,
    required this.assignmentId,
    required this.userId,
    required this.username,
    required this.fileUrl,
    this.answersJson,
    required this.deliveryDate,
    required this.status,
    required this.statusComment,
  });

  factory DeliveryModel.fromMap(Map<String, dynamic> map) {
    return DeliveryModel(
      deliveryId: map['delivery_id'],
      assignmentId: map['assignment_id'],
      userId: map['user_id'],
      username: map['username'],
      fileUrl: map['file_url'] ?? '',
      answersJson: map['answers_json'] is Map
          ? Map<String, dynamic>.from(map['answers_json'])
          : null,
      deliveryDate: DateTime.parse(map['delivery_date']),
      status: map['status'] ?? 'pending',
      statusComment: map['status_comment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'delivery_id': deliveryId,
      'assignment_id': assignmentId,
      'user_id': userId,
      'username': username,
      'file_url': fileUrl,
      'answers_json': answersJson,
      'delivery_date': deliveryDate.toIso8601String(),
      'status': status,
      'status_comment': statusComment,
    };
  }
}
