import 'package:equatable/equatable.dart';

class Ibtihal extends Equatable {
  const Ibtihal({
    required this.id,
    required this.title,
    required this.url,
    required this.artistName,
    this.duration,
  });
  final String id;
  final String title;
  final String url;
  final String artistName;
  final String? duration;

  @override
  List<Object?> get props => [id, title, url, artistName, duration];
}
