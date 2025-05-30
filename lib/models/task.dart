class Task {
  final int? id;
  final String title;
  final String column;
  final DateTime? startDate;
  final DateTime? endDate;
  final int order;
  final String? description;

  Task({
    this.id,
    required this.title,
    required this.column,
    this.startDate,
    this.endDate,
    required this.order,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'column': column,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'order': order,
      'description': description, 
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      column: map['column'] as String,
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      order: map['order'] as int,
      description: map['description'] as String?,
    );
  }
}
