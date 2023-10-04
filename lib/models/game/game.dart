import 'dart:io';
import 'dart:convert';
import 'package:one_launcher/consts.dart';
import 'package:one_launcher/models/game/version/librarie/artifact_librarie.dart';
import 'package:one_launcher/models/game/version/librarie/librarie.dart';
import 'package:one_launcher/models/game/version/os.dart';
import 'package:one_launcher/models/game/version/os_rule.dart';
import 'package:one_launcher/models/game/version/rule.dart';
import 'package:one_launcher/models/game/version/version.dart';
import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart';

import '../game_setting_config.dart';

part 'game.g.dart';

const kLibrariesDirectoryName = "libraries";

typedef ResultMap = Map<Librarie, bool>;

@JsonSerializable()
class Game {
  Game(
    String librariesPath,
    String versionPath, {
    bool? useGlobalSetting,
    GameSettingConfig? setting,
  })  : _useGlobalSetting = ValueNotifier(useGlobalSetting ?? false),
        _setting = setting ?? GameSettingConfig(),
        _librariesPath = librariesPath,
        _versionPath = versionPath,
        _version = _getVersionFromPath(join(librariesPath, versionPath)) {
    _useGlobalSetting.addListener(saveConfig);
    _setting.addListener(saveConfig);
  }

  final String _librariesPath;
  @JsonKey(includeToJson: false)
  String get librariesPath => _librariesPath;

  final String _versionPath;
  @JsonKey(includeToJson: false)
  String get versionPath => _versionPath;

  String get path => join(_librariesPath, _versionPath);

  Version _version;
  Version get version => _version;

  ValueNotifier<bool> _useGlobalSetting;
  GameSettingConfig _setting;

  void freshVersion() => _version = _getVersionFromPath(path);

  void saveConfig() {
    final config = File(path + kGameConfigName);
    final json = const JsonEncoder.withIndent('  ').convert(this);
    config.writeAsStringSync(json);
  }

  Stream<ResultMap> get retrieveLibraries {
    return Stream.fromFutures(
      _version.libraries.map(
        (lib) async => {
          lib: await File(
            join(librariesPath, kLibrariesDirectoryName, lib.jarPath),
          ).exists(),
        },
      ),
    );
  }

  bool _isAllowed(Librarie lib) {
    if (lib is ArtifactLibrarie && lib.rules != null) {
      var osRules = <OsName>{};
      // 规则解析
      for (var rule in lib.rules!) {
        var action = rule.action;
        switch (action) {
          case RuleAction.allow:
            if (rule is OsRule) {
              osRules.add(rule.os.name);
            } else {
              osRules.addAll(OsName.values);
            }
            break;
          case RuleAction.disallow:
            if (rule is OsRule) {
              osRules.remove(rule.os.name);
            } else {
              osRules.clear();
            }
            break;
        }
      }
      var operatingSystem = Platform.operatingSystem;
      operatingSystem = operatingSystem == "macos" ? "osx" : operatingSystem;
      return osRules.isEmpty ||
          osRules.contains(OsName.fromName(operatingSystem));
    }
    return true;
  }

  Stream<Librarie> get retrieveNonExitedLibraries async* {
    await for (var e in retrieveLibraries) {
      var entry = e.entries.first;
      var lib = entry.key;
      var exited = entry.value;
      if (!exited && _isAllowed(lib)) {
        yield lib;
      }
    }
  }

  static Version _getVersionFromPath(String path) {
    return Version.fromJson(
      jsonDecode(File(join(path, "${basename(path)}.json")).readAsStringSync()),
    );
  }

  factory Game.fromJson(
    String librariesPath,
    String versionPath,
    Map<String, dynamic> json,
  ) {
    json.addAll({"librariesPath": librariesPath});
    json.addAll({"versionPath": versionPath});
    return _$GameFromJson(json);
  }

  Map<String, dynamic> toJson() => _$GameToJson(this);
}
