class GroupModel {
  final String id;
  final String title;
  final String? description;
  final String authorName;

  GroupModel({
    required this.id,
    required this.title,
    this.description,
    required this.authorName,
  });
}