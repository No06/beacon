import 'package:json_annotation/json_annotation.dart';
import 'package:one_launcher/models/game/data/os_rule.dart';
import 'package:one_launcher/models/json_map.dart';

part 'rule.g.dart';

@JsonSerializable()
class Rule {
  const Rule({required this.action});

  final RuleAction action;

  factory Rule.fromJson(JsonMap json) {
    if (json['os'] != null) {
      return OsRule.fromJson(json);
    }
    return _$RuleFromJson(json);
  }

  JsonMap toJson() => _$RuleToJson(this);
}

@JsonEnum()
enum RuleAction {
  allow("allow"),
  disallow("disallow");

  const RuleAction(this.action);
  final String action;
}
