class Event {
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;

  Event({
    required this.title,
    this.description,
    required this.start,
    required this.end,
  });
}