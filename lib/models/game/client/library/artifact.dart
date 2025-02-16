import 'package:json_annotation/json_annotation.dart';
import 'package:one_launcher/models/game/client/download_file.dart';
import 'package:one_launcher/models/json_map.dart';

part 'artifact.g.dart';

@JsonSerializable()
class Artifact extends DownloadFile {
  const Artifact(
    this.path, {
    required super.url,
    required super.sha1,
    required super.size,
  });

  factory Artifact.fromJson(JsonMap json) => _$ArtifactFromJson(json);

  final String path;
  @override
  JsonMap toJson() => _$ArtifactToJson(this);
}
