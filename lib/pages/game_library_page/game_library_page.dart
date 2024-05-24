import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:one_launcher/consts.dart';
import 'package:one_launcher/models/config/app_config.dart';
import 'package:one_launcher/models/game/game.dart';
import 'package:one_launcher/models/game/data/game_type.dart';
import 'package:one_launcher/models/config/game_path_config.dart';
import 'package:one_launcher/models/json_map.dart';
import 'package:one_launcher/pages/game_library_page/game_startup_dialog.dart';
import 'package:one_launcher/widgets/build_widgets_with_divider.dart';
import 'package:one_launcher/utils/file/file_picker.dart';
import 'package:one_launcher/widgets/dialog.dart';
import 'package:one_launcher/widgets/dyn_mouse_scroll.dart';
import 'package:one_launcher/pages/base_page.dart';
import 'package:one_launcher/widgets/snackbar.dart';

part 'filter_rule.dart';
part 'home_page.dart';
part 'configuration_page.dart';

class GameLibraryPage extends RoutePage {
  const GameLibraryPage({super.key, super.pageName = "开始游戏"});

  final tabs = const {
    "主页": _HomePage(),
    "配置": _ConfigurationPage(),
  };

  @override
  Widget body(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 35,
              child: TabBar(
                tabAlignment: TabAlignment.start,
                dividerHeight: 0,
                isScrollable: true,
                tabs: tabs.keys.map((text) => Tab(text: text)).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(children: tabs.values.toList()),
            )
          ],
        ),
      ),
    );
  }
}
