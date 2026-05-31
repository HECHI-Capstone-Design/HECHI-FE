class GroupModel {
  final String id;
  final String title;
  final String? description;
  final String authorName;
  String leaderName;

  GroupModel({
    required this.id,
    required this.title,
    this.description,
    required this.authorName,
    this.leaderName = '방장 미상',
  });
}