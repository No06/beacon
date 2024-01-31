import 'package:json_annotation/json_annotation.dart';
import 'package:one_launcher/models/game/data/library/library.dart';
import 'package:one_launcher/models/json_map.dart';

part 'maven_library.g.dart';

@JsonSerializable()
class MavenLibrary extends Library {
  MavenLibrary(String name, this.url)
      : _nameSplit = name.split(":"),
        super(name: name);

  final String url;

  final List<String> _nameSplit;
  late final List<String> _domainSplit = _nameSplit[0].split('.');

  String get domain => _nameSplit[0];
  String get domainSuffix => _domainSplit[0];
  String get domainName => _domainSplit[1];
  String get packageName => _nameSplit[1];
  String get packageVersion => _nameSplit[2];
  String get downloadUrl =>
      "$url/$domainSuffix/$domainName/$packageName/$packageVersion/$packageName-$packageVersion.jar";

  factory MavenLibrary.fromJson(JsonMap json) => _$MavenLibraryFromJson(json);
}
