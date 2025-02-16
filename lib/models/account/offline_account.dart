import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:one_launcher/models/account/account.dart';
import 'package:one_launcher/models/account/skin/local_skin.dart';
import 'package:one_launcher/models/account/skin/skin.dart';
import 'package:one_launcher/models/json_map.dart';

part 'offline_account.g.dart';

@immutable
@JsonSerializable(explicitToJson: true)
class OfflineAccount extends Account {
  OfflineAccount({
    required String displayName,
    required String uuid,
    LocalSkin? skin,
  })  : _uuid = uuid,
        _displayName = displayName,
        _skin = skin;

  factory OfflineAccount.fromJson(JsonMap json) =>
      _$OfflineAccountFromJson(json);

  final String _displayName;
  final String _uuid;
  final LocalSkin? _skin;

  @override
  JsonMap toJson() => _$OfflineAccountToJson(this);

  @JsonKey(includeToJson: true)
  @override
  AccountType get type => AccountType.offline;

  @override
  String get uuid => _uuid;

  @override
  String get displayName => _displayName;

  @JsonKey(includeIfNull: false)
  Skin? get skin => _skin;

  @override
  Future<Skin> getSkin() async {
    return _skin ??
        LocalSkin(
          type: _uuid.hashCode & 1 == 1 ? SkinType.alex : SkinType.steve,
        );
  }

  @override
  Future<String> getAccessToken() async => "0";

  @override
  int get hashCode => displayName.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! OfflineAccount) return false;
    return displayName == other.displayName;
  }
}
