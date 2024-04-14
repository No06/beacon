part of 'account_page.dart';

class _OfflineLoginForm extends HookWidget {
  late final TextEditingController uuidTextController;
  late final TextEditingController usernameTextController;

  static String getUuidFromName(String name) =>
      const Uuid().v5(Uuid.NAMESPACE_NIL, name);

  OfflineAccount submit() => OfflineAccount(
        displayName: usernameTextController.text,
        uuid: uuidTextController.text.replaceAll('-', ''),
      );

  @override
  Widget build(BuildContext context) {
    uuidTextController = useTextEditingController();
    usernameTextController = useTextEditingController();
    final rotationAnimationController = useAnimationController(
      upperBound: 0.5,
      duration: const Duration(milliseconds: 250),
    );
    // uuid 监听 用户名变化
    usernameTextController.addListener(
      () => uuidTextController.text =
          getUuidFromName(usernameTextController.text),
    );

    return Theme(
      data: simpleInputDecorationThemeData(context),
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: "用户名"),
            obscureText: false,
            readOnly: false,
            maxLength: 20,
            controller: usernameTextController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp("[\u4e00-\u9fa5_a-zA-Z0-9]"),
              ),
            ],
            validator: noEmpty,
          ),
          ObxValue(
            (isExpaned) => ExpansionListTile(
              isExpaned: isExpaned.value,
              title: ListTile(
                dense: true,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text("高级"),
                    RotationTransition(
                      turns: rotationAnimationController.view,
                      child: const Icon(Icons.expand_more),
                    ),
                  ],
                ),
                onTap: () {
                  isExpaned(!isExpaned.value);
                  if (isExpaned.value) {
                    rotationAnimationController.forward();
                  } else {
                    rotationAnimationController.reverse();
                  }
                },
              ),
              expandTile: ListTile(
                dense: true,
                leading: const Text("UUID"),
                title: TextFormField(
                  decoration: const InputDecoration(
                    constraints: BoxConstraints(maxHeight: 36),
                  ),
                  controller: uuidTextController,
                  validator: noEmpty,
                ),
              ),
            ),
            false.obs,
          ),
        ],
      ),
    );
  }
}

class _MicosoftLoginForm extends StatelessWidget {
  const _MicosoftLoginForm({required this.onSubmit});

  final void Function(MicrosoftAccount account) onSubmit;
  static const _iconSize = 36.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primaryColor = colors.primary;
    final primaryTextColor = colors.onPrimary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SelectionItem(
          onTap: () async {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: const RoundedRectangleBorder(
                  borderRadius: kDefaultBorderRadius,
                ),
                contentPadding: EdgeInsets.zero,
                content: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  // TODO: Webview对Linux、MacOS的支持
                  child: _LoginWebview(
                    onSuccess: (code) {
                      dialogPop();
                      webViewSubmit(context, code);
                    },
                    onClose: dialogPop,
                  ),
                ),
              ),
            );
          },
          cardColor: primaryColor,
          icon: Icon(Icons.public, size: _iconSize, color: primaryTextColor),
          text: Text("Webview 登录", style: TextStyle(color: primaryTextColor)),
        ),
        _SelectionItem(
          onTap: () => showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _DeviceCodeLoginDialog(
              response: (response) {
                if (response != null) {
                  dialogPop();
                  deviceCodeSubmit(context, response);
                }
              },
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
            side: BorderSide(color: primaryColor, width: 1.5),
          ),
          icon: const Icon(Icons.computer, size: _iconSize),
          text: const Text("设备授权码登录"),
        ),
      ],
    );
  }

  Future<void> webViewSubmit(BuildContext context, String code) async {
    _showMcLoginDialog(context);
    try {
      MicrosoftAccount.generateByOAuthCode(code).then((account) {
        if (account != null) {
          dialogPop();
          onSubmit(account);
        }
      });
    } on HttpException catch (e) {
      _whenRequestException(e);
    } catch (e) {
      _whenRequestException(e);
    }
  }

  Future<void> deviceCodeSubmit(
    BuildContext context,
    MicrosoftOAuthResponse response,
  ) async {
    _showMcLoginDialog(context);
    try {
      MicrosoftAccount.generateByMsOAuthResponse(response).then((account) {
        dialogPop();
        onSubmit(account);
      });
    } catch (e) {
      _whenRequestException(e);
    }
  }

  void _whenRequestException(Object e) {
    dialogPop();
    Get.showSnackbar(errorSnackBar("请求错误：${e.toString()}"));
  }

  void _showMcLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DefaultDialog(
        title: const Text("登录成功"),
        content: Row(
          children: [
            const Text("正在获取游戏授权码"),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Transform.scale(
                scale: 0.8,
                child: const CircularProgressIndicator(),
              ),
            ),
          ],
        ),
        actions: const [DialogCancelButton(onPressed: dialogPop)],
      ),
    );
  }
}

class _CustomLoginForm extends StatelessWidget {
  const _CustomLoginForm();

  @override
  Widget build(BuildContext context) {
    return nil;
  }
}

class _LoginWebview extends StatefulWidget {
  const _LoginWebview({required this.onSuccess, required this.onClose});

  final void Function(String code) onSuccess;
  final VoidCallback onClose;

  @override
  State<_LoginWebview> createState() => _LoginWebviewState();
}

class _LoginWebviewState extends State<_LoginWebview> {
  final _controller = WebviewController();
  final _subscriptions = <StreamSubscription>[];

  static const _backgroundColor = Colors.transparent;

  // Minecraft微软登录OAuth链接
  static const _loginUrl = 'https://login.live.com/oauth20_authorize.srf?'
      'client_id=00000000402b5328'
      '&response_type=code'
      '&scope=service%3A%3Auser.auth.xboxlive.com%3A%3AMBI_SSL'
      '&redirect_uri=https%3A%2F%2Flogin.live.com%2Foauth20_desktop.srf';

  // 正则用于获取授权码
  static final _codeRegex = RegExp(r"(?<=code=)[^&]+");

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    for (var s in _subscriptions) {
      s.cancel();
    }
    _controller.clearCache();
    _controller.clearCookies();
    _controller.dispose();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();

      _subscriptions
          .add(_controller.containsFullScreenElementChanged.listen((flag) {
        debugPrint('Contains fullscreen element: $flag');
        windowManager.setFullScreen(flag);
      }));

      await _controller.setBackgroundColor(_backgroundColor);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl(_loginUrl.toString());

      _controller.url.listen((url) async {
        final match = _codeRegex.firstMatch(url);
        if (match != null && match.group(0) != null) {
          final code = match.group(0)!;
          widget.onSuccess(code);
          debugPrint("授权码: $code");
        } else {
          debugPrint("未找到授权码");
        }
      });

      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code: ${e.code}'),
                  Text('Message: ${e.message}'),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Continue'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(2),
          child: IntrinsicHeight(
            child: Row(children: [
              StreamBuilder(
                stream: _controller.historyChanged,
                builder: (context, snapshot) => IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: snapshot.data?.canGoBack ?? false
                      ? _controller.goBack
                      : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _controller.reload,
              ),
              const Expanded(
                child: DragToMoveArea(
                  child: SizedBox.expand(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ]),
          ),
        ),
        Expanded(
          child: Card(
            color: Colors.transparent,
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Stack(
              children: [
                Webview(_controller),
                StreamBuilder<LoadingState>(
                  stream: _controller.loadingState,
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data == LoadingState.loading) {
                      return const LinearProgressIndicator();
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionItem extends StatelessWidget {
  const _SelectionItem({
    this.cardColor,
    required this.icon,
    required this.text,
    required this.onTap,
    this.shape,
  });

  final Color? cardColor;
  final Widget icon;
  final Widget text;
  final void Function()? onTap;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: cardColor,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [icon, text],
          ),
        ),
      ),
    );
  }
}

class _DeviceCodeLoginDialog extends StatefulWidget {
  const _DeviceCodeLoginDialog({required this.response});

  final void Function(MicrosoftOAuthResponse? accessToken) response;

  @override
  State<_DeviceCodeLoginDialog> createState() => _DeviceCodeLoginDialogState();
}

class _DeviceCodeLoginDialogState extends State<_DeviceCodeLoginDialog> {
  String? _deviceCode;
  String? _verificationUrl;
  final visible = false.obs;
  final completer = Completer<MicrosoftOAuthResponse?>(); // 返回 accessToken
  final util = MicrosoftDeviceCodeOAuth();

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.showSnackbar(errorSnackBar('跳转链接失败 $url'));
    }
  }

  Future<void> _clip() async {
    await Clipboard.setData(ClipboardData(text: _deviceCode!));
    Get.showSnackbar(successSnackBar("复制成功"));
  }

  @override
  void initState() {
    super.initState();
    util
        .getAccessTokenByUserCode(
      startPolling: (deviceCode, verificationUrl) => setState(() {
        _deviceCode = deviceCode;
        _verificationUrl = verificationUrl;
      }),
    )
        .then((value) {
      completer.complete(value);
      widget.response(value);
    });
  }

  @override
  void dispose() {
    util.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;
    return DefaultDialog(
      onCanceled: dialogPop,
      confirmText: const Text('前往登录'),
      onConfirmed: _verificationUrl == null
          ? null
          : () async {
              await _clip();
              await _launchURL(_verificationUrl!);
            },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("授权码", style: textTheme.headlineSmall),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FutureBuilder(
                  future: completer.future,
                  builder: (context, snapshot) {
                    if (_deviceCode != null && _verificationUrl != null) {
                      return Tooltip(
                        message: "点击复制",
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          color: colors.secondaryContainer,
                          elevation: 3,
                          child: InkWell(
                            onTap: _clip,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Obx(
                                    () => Text(
                                      visible.value
                                          ? _deviceCode!
                                          : _deviceCode!
                                              .replaceAll(RegExp(r'.'), '∗'),
                                      style: textTheme.titleLarge?.copyWith(
                                        letterSpacing: 8,
                                        color: colors.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                  Obx(
                                    () => IconButton(
                                      onPressed: () => visible(!visible.value),
                                      icon: visible.value
                                          ? const Icon(Icons.visibility)
                                          : const Icon(Icons.visibility_off),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.error),
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
            ],
          ),
          Text(
            "点击登录后，自动复制授权码，跳出认证页面直接粘贴",
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
