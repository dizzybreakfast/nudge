class Task {
  final int? id;
  final String title;
  final String column;
  final DateTime? startDate;
  final DateTime? endDate;

  Task({this.id, required this.title, required this.column, this.startDate, this.endDate});

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'column': column,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
  };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
  id: map['id'],
  title: map['title'],
  column: map['column'],
  startDate: map['startDate'] != null && map['startDate'] != ''
      ? DateTime.parse(map['startDate'])
      : null,
  endDate: map['endDate'] != null && map['endDate'] != ''
      ? DateTime.parse(map['endDate'])
      : null,
);
}
