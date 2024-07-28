// Copyright 2020 Kenton Hamaluik
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';

import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timecop/blocs/locale/locale_bloc.dart';
import 'package:timecop/blocs/notifications/notifications_bloc.dart';
import 'package:timecop/blocs/projects/bloc.dart';
import 'package:timecop/blocs/settings/settings_bloc.dart';
import 'package:timecop/blocs/settings/settings_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timecop/blocs/settings/settings_state.dart';
import 'package:timecop/blocs/theme/theme_bloc.dart';
import 'package:timecop/blocs/timers/bloc.dart';
import 'package:timecop/data_providers/data/data_provider.dart';
import 'package:timecop/data_providers/notifications/notifications_provider.dart';
import 'package:timecop/data_providers/settings/settings_provider.dart';
import 'package:timecop/fontlicenses.dart';
import 'package:timecop/l10n.dart';
import 'package:timecop/models/theme_type.dart';
import 'package:timecop/screens/dashboard/DashboardScreen.dart';
import 'package:timecop/themes.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

import 'package:timecop/data_providers/data/database_provider.dart';
import 'package:timecop/data_providers/settings/shared_prefs_settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SettingsProvider settings = await SharedPrefsSettingsProvider.load();

  // get a path to the database file
  if (Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final databaseFile = await DatabaseProvider.getDatabaseFile();
  await databaseFile.parent.create(recursive: true);

  final DataProvider data = await DatabaseProvider.open(databaseFile.path);
  final NotificationsProvider notifications =
      await NotificationsProvider.load();
  await runMain(settings, data, notifications);
}

/*import 'package:timecop/data_providers/data/mock_data_provider.dart';
import 'package:timecop/data_providers/settings/mock_settings_provider.dart';
Future<void> main() async {
  final SettingsProvider settings = MockSettingsProvider();
  final DataProvider data = MockDataProvider(Locale.fromSubtags(languageCode: "en"));
  await runMain(settings, data);
}*/

Future<void> runMain(SettingsProvider settings, DataProvider data,
    NotificationsProvider notifications) async {
  // setup intl date formats?
  //await initializeDateFormatting();
  LicenseRegistry.addLicense(getFontLicenses);

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider<ThemeBloc>(
        create: (_) => ThemeBloc(settings),
      ),
      BlocProvider<LocaleBloc>(
        create: (_) => LocaleBloc(settings),
      ),
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(settings, data),
      ),
      BlocProvider<TimersBloc>(
        create: (_) => TimersBloc(data, settings),
      ),
      BlocProvider<ProjectsBloc>(
        create: (_) => ProjectsBloc(data),
      ),
      BlocProvider<NotificationsBloc>(
        create: (_) => NotificationsBloc(notifications),
      ),
    ],
    child: TimeCopApp(settings: settings),
  ));
}

class TimeCopApp extends StatefulWidget {
  final SettingsProvider settings;
  const TimeCopApp({Key? key, required this.settings}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TimeCopAppState();
}

class _TimeCopAppState extends State<TimeCopApp> with WidgetsBindingObserver {
  late Timer _updateTimersTimer;
  Brightness? brightness;
  bool loading = false;
  int totalScreenshotsCount = 0;

  final screenshotController = ScreenshotController();

  Future<void> pressHandler(Widget? child, BuildContext context) async {
    print('Button pressed, updated 3');

    final controller = Get.find<DropdownController>();
    int projectId = controller.getSelectedProject().id;
    double requiredScreenWidth = controller.getSelectedProject().width.toDouble();
    double requiredScreenHeight = controller.getSelectedProject().height.toDouble();

    print('pressHandler projectId: $projectId');

    String deleteUrl = 'https://testserver.visualexact.com/api/designcomp/extension/screenshot/clear/$projectId';
    String endUrl = 'https://testserver.visualexact.com/api/designcomp/project/loading/update/$projectId/3';

    try {
      setState(() {
        loading = true;
      });
      controller.setStatus(1);

      const snackBar1 = SnackBar(
        content: Text('Checking screen size. Please wait...'),
        duration: Duration(days: 365),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(snackBar1);

      // Get the screen size
      if (!context.mounted) {
        controller.setStatus(0);
        setState(() {
          loading = false;
        });
        return;
      };
      final Size screenSize = MediaQuery.of(context).size;

      final screenWidth = screenSize.width;
      final screenHeight = screenSize.height;

      print('Screen size: $screenWidth x $screenHeight');

      controller.setWidth(requiredScreenWidth);
      controller.setHeight(requiredScreenHeight);

      if (screenWidth != requiredScreenWidth || screenHeight != requiredScreenHeight) {
        print('Screen size is not $requiredScreenWidth x $requiredScreenHeight. Abort.');
        controller.setStatus(0);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        setState(() {
          loading = false;
        });
        controller.setErrorCode(4);
        return;
      }

      const snackBar4 = SnackBar(
        content: Text('Fetching project items, please wait...'),
        duration: Duration(days: 365),
      );

      if (!context.mounted) {
        controller.setStatus(0);
        setState(() {
          loading = false;
        });

        return;
      };

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(snackBar4);

      final res = await Dio().get('https://testserver.visualexact.com/api/designcomp/item/list/$projectId', options: options);

      if (res.statusCode == 200 && res.data != null) {

        print('pressHandler fetch item list res.data.success: ${res.data['success']}');
        if (res.data['success'] != null && res.data['success'] == true) {
          
          final List<int> newItemIds = [];
          
          for (final item in res.data['result']['items']) {
            newItemIds.add(item['id']);
          }

          newItemIds.sort();

          print('pressHandler fetch item list newItemIds: $newItemIds');

          controller.setTargetedItemIds(newItemIds);
          controller.setCurrentNo(0);
          controller.setStatus(2);
          controller.setDialogOpened(false);
          Get.back();
        }
        else {
          controller.setStatus(0);
          setState(() {
            loading = false;
          });
        }
      }

    } catch (e) {
      print('pressHandler fetch item list Error: $e');
      controller.setStatus(0);
      setState(() {
        loading = false;
      });
      if (!context.mounted) {
        controller.setStatus(0);
        setState(() {
          loading = false;
        });
        return;
      };
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (child == null) {
      print('Child is null. Abort.');
      controller.setStatus(0);
      setState(() {
        loading = false;
      });
      if (!context.mounted) {
        controller.setStatus(0);
        setState(() {
          loading = false;
        });
        return;
      };
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      return;
    }

    print('targetedItemIds: ${controller.getTargetedItemIds}');

    try {

      const snackBar2 = SnackBar(
        content: Text('Taking screenshots, please wait...'),
        duration: Duration(days: 365),
      );

      if (!context.mounted) {
        controller.setStatus(0);
        setState(() {
          loading = false;
        });

        return;
      };

      setState(() => totalScreenshotsCount = 0);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(snackBar2);
      controller.setStatus(2);

      // Initial screenshot
      await screenshotController
      .capture(delay: const Duration(milliseconds: 1000))
      .then((capturedImage) {
        if (capturedImage != null) {
          print('Screenshot not null, proceed to upload.');
          final base64Value = uint8ListToBase64(capturedImage);

          return Dio().delete(deleteUrl, options: options)
          .then((res) {
            print('Screenshot deleted successfully.');

            return Dio().post(uploadUrl, data: {
              'items': [
                {
                  'name': 'scrollable_${controller.getCurrentNo()}_${DateTime.now().millisecondsSinceEpoch}',
                  'base64': 'data:image/png;base64,$base64Value',
                  'itemId': controller.getTargetedItemIds()[controller.getCurrentNo()],
                  'relevantAction': '',
                  'projectId': projectId
                }
              ],
            },
            options: options)
            .then((res) {
              print('Screenshot uploaded successfully.');
              setState(() => totalScreenshotsCount = totalScreenshotsCount + 1);

              return controller.getCurrentNo();
            });
          });
        }
        else {
          print('Screenshot is null, skip.');

          return controller.getCurrentNo();
        }
      }).catchError((onError) {
        print('Capture Error: $onError');
      });
    } catch (err) {
      print('Error: $err');
    }

    controller.setCurrentNo(controller.getCurrentNo() + 1);

    try {
      if (!context.mounted) return;
      final foundScrollables = _findScrollableWidgets(context);

      if (foundScrollables.isNotEmpty) {
        print('It has scrollable! Number of scrollable widgets with key: ${foundScrollables.length}');
        // Iterate through each scrollable widget and start scrolling
        for (final scrollable in foundScrollables) {
          print('Scrolling each item: ${scrollable.widget.key ?? '*no key*'} at depth ${scrollable.depth}');
          await scrollEachItem(scrollable.widget, screenshotController, scrollable.depth, foundScrollables);
        }
      } else {
        print('It has no scrollable!');
      }

      print('All screenshots taken.');

      var snackBar3 = const SnackBar(
        content: Text('Screenshots taken.'),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(snackBar3);

      controller.setStatus(0);
      setState(() {
        loading = false;
      });
    } catch (err) {
      print('Error: $err');
    }
  }

  bool isScrollable(dynamic widget) {
  // Check if the widget is a scrollable type and if it has a controller
  final bool condition1 = 
    (widget is ListView ||
    widget is ScrollView ||
    widget is SingleChildScrollView ||
    widget is CustomScrollView ||
    widget is NestedScrollView) &&
    widget.controller != null &&
    widget.controller!.hasClients &&
    widget.controller!.position.maxScrollExtent > 0 &&
    widget.controller!.offset < widget.controller!.position.maxScrollExtent &&
    widget.scrollDirection == Axis.vertical;

  // Check if the widget is visible
  final bool condition2 = 
    widget.key != null &&
    widget.key is GlobalKey &&
    (widget.key as GlobalKey).currentContext != null &&
    (widget.key as GlobalKey).currentContext!.findRenderObject() != null &&
    (widget.key as GlobalKey).currentContext!.findRenderObject()!.attached;
    print('widget ${widget.key} checkpoint 1');

    if (
      widget != null &&
      widget.key != null &&
      widget.key.currentContext != null &&
      widget.key.currentContext!.findRenderObject() != null &&
      condition1 &&
      condition2
    ) {
      
      print('widget ${widget.key} checkpoint 2');
      final dynamic renderObject = widget.key.currentContext!.findRenderObject();
      final dynamic scrollableContext = widget.key.currentContext;
      if (
        scrollableContext is BuildContext &&
        renderObject is RenderBox
      ) {
        print('widget ${widget.key} checkpoint 3');
        // final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);
        try {
          final ScrollableState scrollableState = Scrollable.of(scrollableContext);
          final ScrollPosition position = scrollableState.position;
          final double offset = position.pixels;
          final double viewportHeight = position.viewportDimension;

          final Rect bounds = renderObject.paintBounds.shift(renderObject.localToGlobal(Offset.zero));
          // final bool inViewport = bounds.top < viewportHeight + offset && bounds.bottom > offset;
          final bool inViewport = bounds.top >= 0 && bounds.top < viewportHeight;

          print('widget ${widget.key} checkpoint 3: condition 1: $condition1');
          print('widget ${widget.key} checkpoint 3: condition 2: $condition2');
          print('widget ${widget.key} checkpoint 3: inViewport: $inViewport');

          if (!inViewport) {
            print('widget ${widget.key} is not in viewport');
            print('widget ${widget.key} bounds.top: ${bounds.top}');
            print('widget ${widget.key} bounds.bottom: ${bounds.bottom}');
            print('widget ${widget.key} viewportHeight: $viewportHeight');
            print('widget ${widget.key} offset: $offset');
            print('widget ${widget.key} viewportHeight + offset: ${viewportHeight + offset}');
            return false;
          }
          return true;
        }
        catch (err) {
          print('isScrollable failed. Error: $err');
          return true;
        }
      }
    }
    else {
      print('widget ${widget.key} checkpoint 4');
      if (widget == null) {
        print('widget is null');
      }
      else if (widget.key == null) {
        print('widget.key is null');
      }
      else if (widget.key.currentContext == null) {
        print('widget.key.currentContext is null');
      }
      else if (widget.key.currentContext!.findRenderObject() == null) {
        print('widget.key.currentContext.findRenderObject() is null');
      }
      else if (condition1 == false) {
        print('condition1 is false');
        final isValidScrollable = (widget is ListView ||
        widget is ScrollView ||
        widget is SingleChildScrollView ||
        widget is CustomScrollView ||
        widget is NestedScrollView);
        if (isValidScrollable) {
          print('widget ${widget.key} controller: ${widget.controller}');
          print('widget ${widget.key} controller.hasClients: ${widget.controller?.hasClients}');
          print('widget ${widget.key} controller.position.maxScrollExtent: ${widget.controller?.position?.maxScrollExtent}');
          print('widget ${widget.key} controller.offset: ${widget.controller?.offset}');
          print('widget ${widget.key} scrollDirection: ${widget.scrollDirection}');
        }
        else {
          print('widget ${widget.key} is not a valid scrollable');
        }
      }
      else if (condition2 == false) {
        print('condition2 is false');
      }
    }
    print('widget ${widget.key} checkpoint 5');

    return false;
  }

  Future<int> scrollEachItem(
    dynamic child,
    ScreenshotController screenshotController,
    int currentDepth,
    List<WidgetItem> allWidgets
  ) async {
    print('scrollEachItem is triggered');
    print('child: $child');
    print('currentDepth: $currentDepth');
    
    final controller = Get.find<DropdownController>();
    final targetedItemIds = controller.getTargetedItemIds();

    print('isScrollable(child): ${isScrollable(child)}');

    if (
      isScrollable(child) == true &&
      targetedItemIds.length > controller.getCurrentNo()
    ) {
      print('Scrollable widget found');

      while (isScrollable(child) == true && targetedItemIds.length > controller.getCurrentNo()) {
        final num widgetHeight = (child.key.currentContext!.findRenderObject() as RenderBox).size.height;
        print('${child.key} widgetHeight: $widgetHeight');

        final position = child.controller!.position;
        print('${child.key} position: $position');

        final num maxScrollExtent = child.controller!.position.maxScrollExtent as num;
        print('${child.key} maxScrollExtent: $maxScrollExtent');

        final num pixels = child.controller!.position.pixels as num;
        print('${child.key} pixels: $pixels');

        final num nextPosition = pixels + widgetHeight < maxScrollExtent
          ? pixels + widgetHeight
          : maxScrollExtent;
        print('${child.key} nextPosition: $nextPosition');

        final num maxScrollableExtend = min(
          nextPosition,
          maxScrollExtent
        );
        print('${child.key} maxScrollableExtend: $maxScrollableExtend');

        // Scroll down
        child.controller?.jumpTo(
          maxScrollableExtend
        );

        // Wait for the screenshot making to be finished
        await screenshotController
        .capture(delay: const Duration(milliseconds: 100))
        .then((capturedImage) async {
          if (capturedImage != null) {
            print('Capture Done');
            print('Screenshot not null, proceed to upload.');
            final base64Value = uint8ListToBase64(capturedImage);
            final key = child.key;
            final keyToString = key != null ? key.toString().replaceFirst('[String <', '').replaceFirst('>]', '') : 'null';
            print('keyToString: $keyToString');
            return Dio().post('https://testserver.visualexact.com/api/designcomp/extension/screenshot/base64', data: {
              'items': [
                {
                  'name': 'scrollable_${controller.getCurrentNo()}_${DateTime.now().millisecondsSinceEpoch}',
                  'base64': 'data:image/png;base64,$base64Value',
                  'itemId': targetedItemIds[controller.getCurrentNo()],
                  'relevantAction': 'Scroll down at the center of Widget (key: $keyToString) for $maxScrollableExtend pixels'
                }
              ],
            },
            options: options)
            .then((res) {
              print('Screenshot uploaded successfully.');

              return controller.getCurrentNo();
            });
          } else {
            print('Screenshot is null, skip.');

            return controller.getCurrentNo();
          }
        }).catchError((onError) {
          print('Capture Error: $onError');
        });

        controller.setCurrentNo(controller.getCurrentNo() + 1);

        print('allWidgets.length: ${allWidgets.length}');
        print('currentDepth: $currentDepth');
        // Check for a new widget with a higher depth
        for (var widgetItem in allWidgets) {
          print('widgetItem.depth: ${widgetItem.depth}');
          print('widgetItem.widget.key: ${widgetItem.widget.key}');
          print('widgetItem.widget.key: ${widgetItem.widget.key}');
          print('isScrollable(widgetItem.widget): ${isScrollable(widgetItem.widget)}');
          if (widgetItem.depth > currentDepth && isScrollable(widgetItem.widget)) {
            print('Switching to widget with higher depth: ${widgetItem.depth}');
            await scrollEachItem(widgetItem.widget, screenshotController, widgetItem.depth, allWidgets);
          }
        }
      }
    }

    print('scrollEachItem is done');
    
    return 0;
  }

  List<WidgetItem> _findScrollableWidgets(BuildContext context) {
      final List<WidgetItem> foundScrollables = [];
      print('_findScrollableWidgets is triggered');

      void visitor(Element element, int depth) {
        if (element.widget is Scrollable ||
            element.widget is ListView ||
            element.widget is PageView ||
            element.widget is SingleChildScrollView ||
            element.widget is CustomScrollView ||
            element.widget is NestedScrollView) {
          if (element.widget.key != null) {
            final key = element.widget.key;
            print('Scrollable found with key: $key at depth: $depth');
            foundScrollables.add(
              WidgetItem(
                widget: element.widget,
                depth: depth,
                used: false
              )
            );
          } else {
            print('Scrollable found without key: ${element.widget} at depth: $depth, abort');
          }
        }
        element.visitChildren((child) {
          visitor(child, depth + 1);
        });
      }

      try {
        context.visitChildElements((element) {
          visitor(element, 1); // Start with depth 1
        });
      } on Exception catch (e) {
        print('_findScrollableWidgets visitChildElements error: $e');
      }

      foundScrollables.sort((a, b) => b.depth.compareTo(a.depth));

      return foundScrollables;
    }

  @override
  void initState() {
    _updateTimersTimer = Timer.periodic(const Duration(seconds: 1),
        (_) => BlocProvider.of<TimersBloc>(context).add(const UpdateNow()));
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

    final settingsBloc = BlocProvider.of<SettingsBloc>(context);
    final timersBloc = BlocProvider.of<TimersBloc>(context);
    settingsBloc.stream.listen((settingsState) => _updateNotificationBadge(
        settingsState, timersBloc.state.countRunningTimers()));
    timersBloc.stream.listen((timersState) => _updateNotificationBadge(
        settingsBloc.state, timersState.countRunningTimers()));

    // send commands to our top-level blocs to get them to initialize
    settingsBloc.add(LoadSettingsFromRepository());
    timersBloc.add(LoadTimers());
    BlocProvider.of<ProjectsBloc>(context).add(LoadProjects());
    BlocProvider.of<ThemeBloc>(context).add(const LoadThemeEvent());
    BlocProvider.of<LocaleBloc>(context).add(const LoadLocaleEvent());
  }

  void _updateNotificationBadge(SettingsState settingsState, int count) async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (!settingsState.hasAskedNotificationPermissions &&
          !settingsState.showBadgeCounts) {
        // they haven't set the permission yet
        return;
      } else if (settingsState.showBadgeCounts) {
        // need to ask permission
        if (count > 0) {
          FlutterAppBadger.updateBadgeCount(count);
        } else {
          FlutterAppBadger.removeBadge();
        }
      } else {
        // remove any and all badges if we disable the option
        FlutterAppBadger.removeBadge();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // print("application lifecycle changed to: " + state.toString());
    if (state == AppLifecycleState.paused) {
      final settings = BlocProvider.of<SettingsBloc>(context).state;
      final timers = BlocProvider.of<TimersBloc>(context).state;

      // TODO: fix this ugly hack. The L10N we load is part of the material app
      // that we build in build(); so we don't have access to it here
      final localeState = BlocProvider.of<LocaleBloc>(context).state;
      final locale = localeState.locale ?? const Locale("en");
      final notificationsBloc = BlocProvider.of<NotificationsBloc>(context);
      final l10n = await L10N.load(locale);

      if (settings.showRunningTimersAsNotifications &&
          timers.countRunningTimers() > 0) {
        // print("showing notification");
        notificationsBloc.add(ShowNotification(
            title: l10n.tr.runningTimersNotificationTitle,
            body: l10n.tr.runningTimersNotificationBody));
      } else {
        // print("not showing notification");
      }
    } else if (state == AppLifecycleState.resumed) {
      BlocProvider.of<NotificationsBloc>(context)
          .add(const RemoveNotifications());
    }
  }

  @override
  void dispose() {
    _updateTimersTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() => brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }

  ThemeData getTheme(
      ThemeType? type, ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    if (type == ThemeType.autoMaterialYou) {
      if (brightness == Brightness.dark) {
        type = ThemeType.darkMaterialYou;
      } else {
        type = ThemeType.lightMaterialYou;
      }
    }
    switch (type) {
      case ThemeType.light:
        return ThemeUtil.lightTheme;
      case ThemeType.dark:
        return ThemeUtil.darkTheme;
      case ThemeType.black:
        return ThemeUtil.blackTheme;
      case ThemeType.lightMaterialYou:
        return ThemeUtil.getThemeFromColors(
            brightness: Brightness.light,
            colors: lightDynamic ?? ThemeUtil.lightColors,
            appBarBackground:
                lightDynamic?.background ?? ThemeUtil.lightColors.background,
            appBarForeground: lightDynamic?.onBackground ??
                ThemeUtil.lightColors.onBackground);
      case ThemeType.darkMaterialYou:
        return ThemeUtil.getThemeFromColors(
            brightness: Brightness.dark,
            colors: darkDynamic ?? ThemeUtil.darkColors,
            appBarBackground:
                darkDynamic?.background ?? ThemeUtil.darkColors.background,
            appBarForeground:
                darkDynamic?.onBackground ?? ThemeUtil.darkColors.onBackground);
      case ThemeType.auto:
      default:
        return brightness == Brightness.dark
            ? ThemeUtil.darkTheme
            : ThemeUtil.lightTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.put(DropdownController());
    return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SettingsProvider>.value(value: widget.settings),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (BuildContext context, ThemeState themeState) =>
                BlocBuilder<LocaleBloc, LocaleState>(
                    builder: (BuildContext context, LocaleState localeState) =>
                        DynamicColorBuilder(
                          builder: (ColorScheme? lightDynamic,
                                  ColorScheme? darkDynamic) =>
                              GetMaterialApp(
                            title: 'Time Cop',
                            home: const DashboardScreen(),
                            theme: getTheme(
                                themeState.theme, lightDynamic, darkDynamic),
                            localizationsDelegates: const [
                              L10N.delegate,
                              GlobalMaterialLocalizations.delegate,
                              GlobalWidgetsLocalizations.delegate,
                              GlobalCupertinoLocalizations.delegate,
                            ],
                            locale: localeState.locale,
                            supportedLocales: const [
                              Locale('en'),
                              Locale('ar'),
                              Locale('cs'),
                              Locale('da'),
                              Locale('de'),
                              Locale('es'),
                              Locale('fr'),
                              Locale('hi'),
                              Locale('id'),
                              Locale('it'),
                              Locale('ja'),
                              Locale('ko'),
                              Locale('nb', 'NO'),
                              Locale('pt'),
                              Locale('ru'),
                              Locale('tr'),
                              Locale('zh', 'CN'),
                              Locale('zh', 'TW'),
                            ],
                            // VM Setup
                            builder: (context, child) {
                              return Scaffold(
                                body: 
                                Stack(
                                  children: [
                                    Screenshot(
                                      controller: screenshotController,
                                      child: child,
                                    ),
                                    Visibility(
                                      visible: loading,
                                      child: Container(
                                        color: Colors.black.withOpacity(0.5),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                floatingActionButton: FloatingActionButton(
                                  onPressed: () {
                                    _dialogBuilder(context, child, pressHandler);
                                  },
                                  // child: const Icon(Icons.add),
                                  // backgroundColor: Colors.green.shade700,
                                  backgroundColor: vmPrimaryColor,
                                  child: Image.memory(
                                    base64Decode('iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAMAAAD04JH5AAAAAXNSR0IB2cksfwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAW5QTFRFAH5gTqWR/////P79FIhs4/Hu3O3pAn9h7/f1drqqOZuDfL2tksi71+vmlMm8G4xxNJiAM5iA7vb0x+Pc1urlSaOObbWkeLurBIBipNHGFYltGotw/v/+T6aRB4Fk9/v6uNvTvN3VrtbMWqyYXq6b+v38D4ZptdrRC4RnbLWjEIZqqdTJotDFyuTearSiRKCKJ5J4xeLb5PHuiMO1mszAe7ytQJ6IKJJ5RaGL6fTxzOXfMZd/i8S3bralYrCds9nQweDYQZ+JVamVnM3B8/n4fr6vmcu/3u7qUqeTO5yFPJyFrNXLf76vII50WKqXvd7Ww+Hat9vSZbGfc7iodLmozebgIo91S6SPMpd/g8Cy6vTykMe6j8a5rdbMdbmputzUyeTdXK2ZhsK0oM/EQp+Jo9DGYK+cv9/XsNfOOpuElsq+OJqDVqmWY7CeMJZ+ptLHSKKNqNPJ6PPxjcW4L5Z9WauYnc3CP56HhMGyyOPdEO1nxQAABMlJREFUeJztmflvFVUUx+8jpU0pS0lKuoVGWQq1C1JU0hZZqkhJIaU2KAWCAjUQl5SAuPwJbkAAg9YEaqiNBAhLA8QlCiqi7GBZWqhsUVmiVFkqhuaZPpi558ybefece2v85c4P7Tkz597zmfdm7ny/80Lif95CFsACWAALYAEsgAWwABbAAlgACxDzYAhnd+nz9ux0orh/9AESQmhwQge5f6+/3TDxlj6A6H0bZkk3yAB9b7phnz8NAJL/Qmm/68T+CUntTtj/99iliosw5Q+Y9boZVOfZBsiuKVeNAFKvwSw++TINIP2KO3/qr0YAmSE0PvMSqX9WyK3LOq+oVa0DD16A2QM/kwAGn3PDQWcNAYagloNDrRSAYWecaGDiaUMA8GlGpj5F6P9QS9gJc06oipVLcd5JmOX+RAAoaHZD9UWjBBiBWxYcVQOMPOZEyfHK20b9MCpELUceUg7oJxfMwoPKajXAqCMwe/iwcsCjkvGR/d0AMPoASh/7QTUg3n1ojt6nnJ2iB4pRy9TfFOUlsmvxd90C8PhemCnv7DHfu2HR3hh1dIDstjBMx3wTu7zoRydSSBEygBj3LczG7o5ZPGGPGyqkCB2gFLdM/yVW8RNfu6FCitAB0vK+Qi2+oNWqpAgdQDz1JcwmfhajtOxzN1RJEQbAZNyybGdwafkud2aVFGEAiEnoU4+xwA7vbHNCpRThAExB51zaejGocKxcepRShAMwdQfm2R5UWNHkRGopwgEQ01DLii0BZRk93O9dLUVYAE9vRYOCTFqVJCPqVyoAuLgiPJv8y6ZvdiKCFGEBiFwkBgNM2jOSiyBFeADPbsStPvUrqt7ghgQpwgNIqEItqz/xK5KenCJFeABidiPM4sN3okuAJ6dIESZACT6ncDi6BHhyihRhAniM8qz1UQXAk5OkCBdgTgPMfEwa8OQkKcIFiEtDT7e8494C6clpUoQLIJ5Dn/qces9h4CJpUoQNMPdjlJY34cPAk9OkCBsgKxsps+fX4sPSkxOlCBtAzF8HM49JA56cKEX4ADX4nPOPwQx4cqIU4QN4jPL8j2AmPTlVimgAzKuHGWoEPDlVimgAeJRZTZ2MgSenShENAJGPTu6FD2UsPTlZiugA5LTALCPsmjTwqCJLER2A7DBSZnLJB56cLEV0AMTCOphJkyY9OV2KaAEA69e1LVhz7z/w5HQpogWQ1o6e9E/e5wGenC5FtADEix/ArLQ5csUDT86QInoAL63BPKu7/oIvhiFF9AA8Rnlo5L6UnpwjRTQBktAvVxGTBmwTR4poAmTi94SVm5En50gRTQAxHr2m6zJp0pOzpIguwCvvo/TllcCTs6SILsDwDvS0m9kAPDlLiugCiNpVMJvRKD05T4poAyxaidISufTVLufPpvPr+eIVAQf8DON/AbAk4ESZUkQf4NVl/vuZUkQfwGOU3Y0pRQwAqnxf03GliAFAnO/VxpUiBgCicpvPTq4UMQFY+l70PrYUMQHwGOXIxpYiJgDitXejdrGliBHA6+949/CliBGAxygLHSliBvDG2555+FLEDMBjlHWkiBmAePMtlGpIEUMA8EpG6EkRQwBslHlvRboFoLs2C2ABLIAFsAAWwAJYAAtgASyABfgX+wUlkCeY9jAAAAAASUVORK5CYII='),
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                                floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
                              );
                            },
                          ),
                        )
                  )
        )
    );
  }
}


// VM

class WidgetItem {
  WidgetItem({required this.widget, required this.depth, this.used = false});
  final dynamic widget;
  final int depth;
  bool used;
}

class ApiRes {
  ApiRes({required this.success, this.result = const <CampaignProjectModel>[]});
  final bool success;
  final List<CampaignProjectModel> result;
}

const apiToken = '2957b7c0-2dc0-11ef-940e-f98a7ded80891718748882236'; // Use a valid API Token here

final options = Options(
  headers: {
    'api-token': apiToken,
  }
);

const uploadUrl = 'https://testserver.visualexact.com/api/designcomp/extension/screenshot/base64';
  
Future<void> _dialogBuilder(BuildContext context, Widget? child, Function pressHandler) {

  final controller = Get.find<DropdownController>();

  print('controller.getDialogOpened(): ${controller.getDialogOpened()}');

  if (controller.getDialogOpened()) {
    return Future.value();
  }
  else {
    controller.reset();
  }
  
  return Get.defaultDialog(
    title: 'VisualMatch',
    titlePadding: const EdgeInsets.only(left: 15.0, top: 20.0, bottom: 10.0, right: 15.0), // Adjust padding as needed
    titleStyle: const TextStyle(
      fontSize: 24.0, // Make the title larger
      fontWeight: FontWeight.bold,
      color: Colors.black, // You can adjust the color as needed
    ),
    backgroundColor: Colors.white,
    content: GetBuilder<DropdownController>(builder: (controller) {

      controller.setContext(context);
      controller.setChild(child);
      controller.setSubmitHandlerFunc(pressHandler);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: DropdownButton<String>(
                hint: const Text('Select Campaign'),
                onChanged: (newValue) {
                  final campaign = controller.campaigns.firstWhere((element) => element.name == newValue);
                  controller.onSelectedCampaign(campaign);
                },
                value: controller.selectedCampaign.name,
                isExpanded: true, // This moves the icon to the end
                items: [
                  for (var data in controller.campaigns)
                    DropdownMenuItem(
                      value: data.name,
                      child: Text(data.name),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: DropdownButton<String>(
                hint: const Text('Select Project'),
                onChanged: (newValue) {
                  final project = controller.projects.firstWhere((element) => element.name == newValue);
                  controller.onSelectedProject(project);
                },
                value: controller.selectedProject.name,
                isExpanded: true, // This moves the icon to the end
                items: [
                  for (var data in controller.projects)
                    DropdownMenuItem(
                      value: data.name,
                      child: Text(data.name),
                    ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: controller.getErrorCode() != 0,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                controller.getErrorCode() == 0 ? '' :
                controller.getErrorCode() == 1 ? 'Please select a Campaign' :
                controller.getErrorCode() == 2 ? 'Please select a Project' :
                controller.getErrorCode() == 3 ? 'Something is wrong!' :
                // 'The screen size is wrong. It must be ${controller.getWidth()} x ${controller.getHeight()}',
                'The screen size required is ${controller.getWidth()} x ${controller.getHeight()}. Please change your device or consult your designer.',
                style: controller.getErrorCode() == 0 ? const TextStyle(color: Colors.black) : const TextStyle(color: Colors.red),
              ),
            ),
          ),
          Visibility(
            visible: controller.image != '',
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.0), // Add black border
                ),
                child: SizedBox(
                  height: 300.0, // Set the height limit here
                  child: Image.network(
                    controller.image,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Failed to load image');
                    },
                  ),
                ),
              ),
            ),
          )
        ],
      );
    }),
    actions: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                final controller = Get.find<DropdownController>();
                controller.setDialogOpened(false);
                Get.back();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: vmPrimaryColor,
                ),
              ),
            ),
            ElevatedButton(
              key: const Key('vm_submit_button'),
              onPressed: () {
                final controller = Get.find<DropdownController>();
                controller.submitHandler();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: vmPrimaryColor,
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
    ],
    onWillPop: () {
      print('onWillPop is triggered');
      final controller = Get.find<DropdownController>();
      controller.setDialogOpened(false);

      return Future.value(true);
    }, 
  );
}

class DropdownController extends GetxController {
  
  final defaultCampaign = CampaignProjectModel(id: 0, name: 'Select a Campaign');
  final defaultProject = CampaignProjectModel(id: 0, name: 'Select a Project');
    
  List<CampaignProjectModel> campaigns = [
    CampaignProjectModel(
      id: 0,
      name: 'Select a Campaign'
    ),
  ];

  List<CampaignProjectModel> projects = [
    CampaignProjectModel(
      id: 0,
      name: 'Select a Project',
      width: 0.0,
      height: 0.0
    ),
  ];

  final List<CampaignProjectModel> items = [];
  
  CampaignProjectModel selectedCampaign = CampaignProjectModel(id: 0, name: 'Select a Campaign');
  CampaignProjectModel selectedProject = CampaignProjectModel(id: 0, name: 'Select a Project');
  Function submitHandlerFunc = (Widget? child, BuildContext context) {};
  int errorCode = 0;
  BuildContext? context;
  Widget? child;
  List<int> targetedItemIds = [];
  int currentNo = 0;
  double width = 414.0;
  double height = 896.0;
  int status = 0; // 0: Standby, 1: Checking size, 2: Taking screenshots
  bool dialogOpened = false;
  String image = '';

  Future<void> onSelectedCampaign(CampaignProjectModel? value) async {
    print('onSelectedCampaign is triggered');
    selectedCampaign = value ?? defaultCampaign;
    selectedProject = defaultProject;
    errorCode = 0;
    var newProjects = <CampaignProjectModel>[
      CampaignProjectModel(
        id: 0,
        name: 'Select a Project',
      ),
    ];

    if (value != null && value.id != 0) {
      try {
        final res = await Dio().get('https://testserver.visualexact.com/api/designcomp/project/incompleted/list/${value.id}', options: options);

        print('onSelectedCampaign res.statusCode: ${res.statusCode}');
        if (res.statusCode == 200 && res.data != null) {
          print('onSelectedCampaign res.data.success: ${res.data['success']}');
          if (res.data['success'] != null && res.data['success'] == true) {
            // print('onSelectedCampaign res.data.projects.length: ${res.data['result']['projects']['length'].toString()}');
            newProjects = [
              CampaignProjectModel(
                id: 0,
                name: 'Select a Project',
              ),
            ];
            
            for (final item in res.data['result']['projects']) {
              print('onSelectedCampaign item.width: ${item['width'].toString()}');
              print('onSelectedCampaign item.height: ${item['height'].toString()}');
              print('onSelectedCampaign item.screenshot: ${item['screenshot']}');
              newProjects.add(
                CampaignProjectModel(
                  id: item['id'],
                  name: item['name'],
                  width: item['width'] != null ? double.parse(item['width'].toString()) : 0.0,
                  height: item['height'] != null ? double.parse(item['height'].toString()) : 0.0,
                  screenshot: item['screenshot'] != null ? 'https://testserver.visualexact.com/api/general/files/${(item['screenshot'] as String).replaceAll('/', '%2F')}' : '',
                ),
              );
            }
          }
        }
        projects = newProjects;
        update();

      } catch (e) {
        print('onSelectedCampaign Error: $e');
        projects = [
          CampaignProjectModel(
            id: 0,
            name: 'Select a Project'
          ),
        ];
      }

    }

    if (selectedCampaign != null) {
      print('New Campaign: ${selectedCampaign!.name}');
    }
  }

  void onSelectedProject(CampaignProjectModel? value) {
    selectedProject = value ?? defaultProject;
    image = value?.screenshot ?? '';
    errorCode = 0;

    update();

    if (selectedProject != null) {
      print('New Project: ${selectedProject!.name}');
    }
  }

  void setSubmitHandlerFunc(Function newFunc) {
    submitHandlerFunc = newFunc;

    update();
  }

  void setContext(BuildContext? newContext) {
    context = newContext;

    update();
  }

  void setChild(Widget? newChild) {
    child = newChild;

    update();
  }

  void setTargetedItemIds(List<int> newIds) {
    targetedItemIds = newIds;

    update();
  }

  void setCurrentNo(int newNo) {
    currentNo = newNo;

    update();
  }

  void setErrorCode(int newErrorCode) {
    errorCode = newErrorCode;

    update();
  }

  void setWidth(double newWidth) {
    width = newWidth;

    update();
  }

  void setHeight(double newHeight) {
    height = newHeight;

    update();
  }

  void setStatus(int newStatus) {
    status = newStatus;

    update();
  }

  void setDialogOpened(bool newDialogOpened) {
    print('setDialogOpened is triggered, newDialogOpened: $newDialogOpened');
    dialogOpened = newDialogOpened;

    update();
  }

  CampaignProjectModel getSelectedCampaign() {
    return selectedCampaign;
  }

  CampaignProjectModel getSelectedProject() {
    return selectedProject;
  }

  int getErrorCode() {
    return errorCode;
  }

  List<int> getTargetedItemIds() {
    return targetedItemIds;
  }

  int getCurrentNo() {
    return currentNo;
  }

  double getWidth() {
    return width;
  }

  double getHeight() {
    return height;
  }

  int getStatus() {
    return status;
  }

  bool getDialogOpened() {
    return dialogOpened;
  }

  Future<void> reset() async {
    print('reset is triggered');
    selectedCampaign = defaultCampaign;
    selectedProject = defaultProject;
    projects = [
      CampaignProjectModel(
        id: 0,
        name: 'Select a Project',
        width: 0.0,
        height: 0.0
      ),
    ];
    errorCode = 0;
    status = 0;
    dialogOpened = true;
    image = '';
    var newCampaigns = <CampaignProjectModel>[
      CampaignProjectModel(
        id: 0,
        name: 'Select a Campaign',
      ),
    ];
    try {
      final res = await Dio().get('https://testserver.visualexact.com/api/designcomp/campaign/list', options: options);

      print('res.statusCode: ${res.statusCode}');
      print('res.data: ${res.data}');
      if (res.statusCode == 200 && res.data != null) {
        print('res.data.success: ${res.data['success']}');
        if (res.data['success'] != null && res.data['success'] == true) {
          newCampaigns = [
            CampaignProjectModel(
              id: 0,
              name: 'Select a Campaign',
            ),
          ];
          
          for (final item in res.data['result']) {
            newCampaigns.add(
              CampaignProjectModel(
                id: item['id'],
                name: item['name'] + (
                  item['incompletedProjects'] != 0 &&
                  item['incompletedProjects'] != null ?
                  ' (${item['incompletedProjects']})' :
                  ''
                ),
              ),
            );
          }
        }
      }
      campaigns = newCampaigns;
      update();

    } catch (e) {
      print('Error: $e');
      campaigns = [
        CampaignProjectModel(
          id: 0,
          name: 'Select a Campaign'
        ),
      ];
    }
    update();
  }

  void submitHandler() {
    print('submitHandler is triggered');
    print('Selected Campaign: ${selectedCampaign.id}');
    print('Selected Project: ${selectedProject.id}');
    if (selectedCampaign.id == 0) {
      errorCode = 1;
    } 
    else if (selectedProject.id == 0) {
      errorCode = 2;
    }
    else if (context != null && child != null && status == 0) {
      print('Condition passed, proceed with pressHandler');
      status = 1;
      
      submitHandlerFunc(child, context!);
    }
    else if (!(context != null && child != null)) {
      errorCode = 3;
    }
    print('errorCode: $errorCode');

    update();

    return;
  }
}

class CampaignProjectModel {
  CampaignProjectModel({required this.id, required this.name, this.width = 0.0, this.height = 0.0, this.screenshot = ''});
  final int id;
  final String name;
  double width = 0.0;
  double height = 0.0;
  String screenshot = '';
}

String uint8ListToBase64(Uint8List uint8List) {
  // Encode the uint8List to Base64
  String base64String = base64Encode(uint8List);
  return base64String;
}

const vmPrimaryColor = Color(0xff007E60);


class LoadingAnimationExample extends StatefulWidget {
  const LoadingAnimationExample({super.key});

  @override
  _LoadingAnimationExampleState createState() => _LoadingAnimationExampleState();
}

class _LoadingAnimationExampleState extends State<LoadingAnimationExample> {
  bool _isLoading = false;

  void _showLoading() {
    setState(() {
      _isLoading = true;
    });

    // Simulate a network call or a long-running task
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: ElevatedButton(
            onPressed: _showLoading,
            child: const Text('Show Loading Animation'),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
