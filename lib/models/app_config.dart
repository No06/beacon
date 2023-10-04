import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:one_launcher/consts.dart';
import 'package:one_launcher/models/game/game.dart';
import 'package:one_launcher/models/game_setting_config.dart';
import 'package:one_launcher/models/game_path_config.dart';
import 'package:one_launcher/models/theme_config.dart';
import 'package:one_launcher/models/account/account.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart';

part 'app_config.g.dart';

final appConfig = AppConfig.instance;
const kGameDirectoryName = '.minecraft';
const _kAccountDelimiter = "@";
final _kDefaultGamePaths = {
  GamePath(
    name: "启动器目录",
    path:
        join(File(Platform.resolvedExecutable).parent.path, kGameDirectoryName),
  ),
  GamePath(
    name: "官方启动器目录",
    path: () {
      if (Platform.isWindows) {
        if (Platform.environment['APPDATA'] == null) {
          throw Exception("未找到环境变量 'APPDATE'");
        }
        return join(Platform.environment['APPDATA']!, kGameDirectoryName);
      }
      if (Platform.isLinux || Platform.isMacOS) {
        if (Platform.environment['HOME'] == null) {
          throw Exception("未找到环境变量 'HOME'");
        }
        if (Platform.isLinux) {
          return join(Platform.environment['HOME']!, kGameDirectoryName);
        }
        if (Platform.isMacOS) {
          return join(Platform.environment['HOME']!, "Library",
              "Application Support", "minecraft");
        }
      }
      throw Exception("不支持的系统类型");
    }(),
  ),
};

@JsonSerializable()
final class AppConfig {
  AppConfig({
    AppThemeConfig? theme,
    Set<GamePath>? paths,
    String? selectedAccount,
    Set<Account>? accounts,
    GameSettingConfig? gameSetting,
  })  : theme = theme ?? AppThemeConfig(),
        _paths = RxSet(paths ?? _kDefaultGamePaths),
        _selectedAccount =
            ValueNotifier(_selectedAccountFromJson(selectedAccount, accounts)),
        _accounts = RxSet(accounts ?? {}),
        gameSetting = gameSetting ?? GameSettingConfig(),
        super() {
    this.theme.addListener(save);
    for (var e in _paths) {
      e.addListener(save);
    }
    _selectedAccount.addListener(save);
    this.gameSetting.addListener(save);
    everAll([_paths, _accounts], (_) => save());
  }

  AppThemeConfig theme;
  RxSet<GamePath> _paths;
  ValueNotifier<Account?> _selectedAccount;
  RxSet<Account> _accounts;
  GameSettingConfig gameSetting;

  @JsonKey(includeFromJson: null, includeToJson: null)
  Future<List<Game>> get getGamesOnPaths async {
    var games = <Game>[];
    for (var path in _paths) {
      games.addAll(await path.getGamesOnVersion);
    }
    return games;
  }

  Set<GamePath> get paths => _paths;
  void resetPaths() => _paths.assignAll(_kDefaultGamePaths);

  ValueNotifier<Account?> get selectedAccountNotifier => _selectedAccount;
  @JsonKey(toJson: _selectedAccounttoString)
  Account? get selectedAccount => _selectedAccount.value;
  set selectedAccount(Account? newVal) => _selectedAccount.value = newVal;
  static String? _selectedAccounttoString(Account? account) {
    final selectedAccount = account;
    if (selectedAccount == null) return null;

    return selectedAccount.type.name +
        _kAccountDelimiter +
        selectedAccount.uuid;
  }

  static Account? _selectedAccountFromJson(
      String? str, Set<Account>? accounts) {
    if (str == null) return null;

    final parts = str.split(_kAccountDelimiter);
    final sType = parts[0];
    final sUuid = parts[1];
    for (AccountType type in AccountType.values) {
      if (type.name == sType) {
        for (Account account in accounts ?? []) {
          if (account.type == type && account.uuid == sUuid) {
            return account;
          }
        }
        throw Exception("已有账号中未找到目标");
      }
    }
    throw Exception("未知的账号类型");
  }

  Set<Account> get accounts => _accounts;

  static AppConfig? _instance;

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig is not initialized');
    }
    return _instance!;
  }

  static Future<String> _getConfigPath() async {
    return join((await kConfigPath).path, kConfigName);
  }

  static Future<void> init() async {
    final config = File(await _getConfigPath());
    if (!await config.exists() || (await config.length()) == 0) {
      await save();
    }
    final content = await config.readAsString();
    _instance = AppConfig.fromJson(json.decode(content));
  }

  static Future<void> save([AppConfig? appConfig]) async {
    final config = File(await _getConfigPath());
    final json = const JsonEncoder.withIndent('  ').convert(
      appConfig ?? _instance ?? AppConfig().toJson(),
    );
    await config.writeAsString(json);
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigToJson(this);
}
