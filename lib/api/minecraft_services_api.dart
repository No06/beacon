import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:one_launcher/models/account/skin/online_skin.dart';
import 'package:one_launcher/models/json_map.dart';

part 'minecraft_services_api.g.dart';

class MinecraftServicesApi {
  MinecraftServicesApi(String mcAccessToken)
      : dio = Dio(
          BaseOptions(
            baseUrl: "https://api.minecraftservices.com",
            headers: {"Authorization": "Bearer $mcAccessToken"},
          ),
        );

  final Dio dio;

  Future<Profile> requestProfile() async {
    const path = "/minecraft/profile";
    final response = await dio.get(path);
    return Profile.fromJson(response.data);
  }
}

@JsonSerializable(includeIfNull: false, createToJson: false)
class Profile {
  Profile(this.id, this.name, this.skins);

  final String id;
  final String name;
  final List<OnlineSkin> skins;

  factory Profile.fromJson(JsonMap json) => _$ProfileFromJson(json);
  JsonMap toJson() => _$ProfileToJson(this);
}
