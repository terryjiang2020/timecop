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

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '/global_key.dart';

class VisualExactButton extends StatefulWidget {
  final Widget? child;
  final Function setLoading;
  final BuildContext currentContext;

  const VisualExactButton({
    Key? key,
    required this.child,
    required this.setLoading,
    required this.currentContext
  }) : super(key: key);

  @override
  State<VisualExactButton> createState() => _VisualMatchButtonState();
}

class WidgetStyles {
  final String? color;
  final String? backgroundColor;
  final double? fontSize;
  final String? fontFamily;
  final int? fontWeight;
  final String? text;
  final Offset position;
  final Size size;
  final String? name;

  WidgetStyles({
    this.color,
    this.backgroundColor,
    this.fontSize,
    this.fontFamily,
    this.fontWeight,
    this.text,
    this.name,
    required this.position,
    required this.size
  });

  Map<String, dynamic> toJson() {
    return {
      'color': color, // Convert Color to its integer value
      'backgroundColor': backgroundColor, // Assuming it's serializable
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'text': text,
      'position': {'dx': position.dx, 'dy': position.dy},
      'size': {'width': size.width, 'height': size.height},
    };
  }
}

const vmPrimaryColor = Color(0xff007E60);

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

String toCssHexColor(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

List<Map<String, dynamic>> _findVisibleWidgets(BuildContext context) {
  List<WidgetItem> foundWidgets = [];
  List<WidgetStyles> foundStyles = [];
  print('_findVisibleWidgets is triggered');

  void visitor(Element element, int depth) {

    // Check if the widget is visible
    final bool condition2 = 
      element.renderObject != null &&
      element.renderObject!.attached;
    
    if (condition2) {
      foundWidgets.add(
        WidgetItem(
          widget: element.widget,
          renderObject: element.renderObject ?? null,
          depth: depth,
          used: false
        )
      );

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

  for (final widget in foundWidgets) {
    if (widget.renderObject == null || widget.renderObject is! RenderBox) {
      print('Widget: ${widget.widget} has no renderObject or is not in the correct type');
      continue;
    }
    final RenderBox renderBox = widget.renderObject as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    print('position: $position');
    print('size: $size');
    print('Widget type: ${widget.widget.runtimeType}');

    var style = WidgetStyles(
      backgroundColor: null,
      color: null,
      fontSize: null,
      fontFamily: null,
      fontWeight: null,
      text: '',
      position: position,
      size: size
    );

    if (widget.widget is Text) {
      final Text textWidget = widget.widget as Text;
      final color = textWidget.style?.color;
      print('Text color: $color');
      final backgroundColor = textWidget.style?.backgroundColor;
      final fontSize = textWidget.style?.fontSize;
      print('Text fontSize: $fontSize');
      final text = textWidget.data;
      print('Text: $text');
      final fontFamily = textWidget.style?.fontFamily;
      print('Text fontFamily: $fontFamily');
      final fontWeight = textWidget.style?.fontWeight;
      print('Text fontWeight: $fontWeight');
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: color != null ? toCssHexColor(color) : null,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight != null ? fontWeight.index * 100 : null,
        text: text,
        position: position,
        size: size,
        name: 'Text'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is SelectableText) {
      final SelectableText textWidget = widget.widget as SelectableText;
      final color = textWidget.style?.color;
      print('Text color: $color');
      final backgroundColor = textWidget.style?.backgroundColor;
      final fontSize = textWidget.style?.fontSize;
      print('Text fontSize: $fontSize');
      final text = textWidget.data;
      print('Text: $text');
      final fontFamily = textWidget.style?.fontFamily;
      print('Text fontFamily: $fontFamily');
      final fontWeight = textWidget.style?.fontWeight;
      print('Text fontWeight: $fontWeight');
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: color != null ? toCssHexColor(color) : null,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight != null ? fontWeight.index * 100 : null,
        text: text,
        position: position,
        size: size,
        name: 'SelectableText'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is TextField) {
      final TextField textWidget = widget.widget as TextField;
      final color = textWidget.style?.color;
      print('Text color: $color');
      final backgroundColor = textWidget.style?.backgroundColor;
      final fontSize = textWidget.style?.fontSize;
      print('Text fontSize: $fontSize');
      final fontFamily = textWidget.style?.fontFamily;
      print('Text fontFamily: $fontFamily');
      final fontWeight = textWidget.style?.fontWeight;
      print('Text fontWeight: $fontWeight');
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: color != null ? toCssHexColor(color) : null,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight != null ? fontWeight.index * 100 : null,
        text: '',
        position: position,
        size: size,
        name: 'TextField'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is Chip) {
      final Chip textWidget = widget.widget as Chip;
      final color = textWidget.labelStyle?.color;
      print('Text color: $color');
      final backgroundColor = textWidget.backgroundColor;
      final fontSize = textWidget.labelStyle?.fontSize;
      print('Text fontSize: $fontSize');
      final fontFamily = textWidget.labelStyle?.fontFamily;
      print('Text fontFamily: $fontFamily');
      final fontWeight = textWidget.labelStyle?.fontWeight;
      print('Text fontWeight: $fontWeight');
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: color != null ? toCssHexColor(color) : null,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight != null ? fontWeight.index * 100 : null,
        text: '',
        position: position,
        size: size,
        name: 'Chip'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is Tooltip) {
      final Tooltip textWidget = widget.widget as Tooltip;
      final color = textWidget.textStyle?.color;
      print('Text color: $color');
      final fontSize = textWidget.textStyle?.fontSize;
      print('Text fontSize: $fontSize');
      final fontFamily = textWidget.textStyle?.fontFamily;
      print('Text fontFamily: $fontFamily');
      final fontWeight = textWidget.textStyle?.fontWeight;
      print('Text fontWeight: $fontWeight');
      style = WidgetStyles(
        backgroundColor: null,
        color: color != null ? toCssHexColor(color) : null,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight != null ? fontWeight.index * 100 : null,
        text: '',
        position: position,
        size: size,
        name: 'Tooltip'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is Dialog) {
      final Dialog textWidget = widget.widget as Dialog;
      final backgroundColor = textWidget.backgroundColor;
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'Dialog'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is BottomNavigationBar) {
      final BottomNavigationBar textWidget = widget.widget as BottomNavigationBar;
      final backgroundColor = textWidget.backgroundColor;
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'BottomNavigationBar'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is ListTile) {
      final ListTile textWidget = widget.widget as ListTile;
      final backgroundColor = textWidget.tileColor;
      final color = textWidget.textColor;
      final fontSize = textWidget.titleTextStyle?.fontSize;
      final fontFamily = textWidget.titleTextStyle?.fontFamily;
      final fontWeight = textWidget.titleTextStyle?.fontWeight;
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: color != null ? toCssHexColor(color) : null,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight != null ? fontWeight.index * 100 : null,
        text: '',
        position: position,
        size: size,
        name: 'ListTile'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is Card) {
      final Card textWidget = widget.widget as Card;
      final backgroundColor = textWidget.color;
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'Card'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is TextButton) {
      final TextButton textWidget = widget.widget as TextButton;
      final MaterialStateProperty<Color?>? backgroundColorProperty = textWidget.style?.backgroundColor;

      // Resolve the background color for a specific state or the default state
      final Color? backgroundColor = backgroundColorProperty?.resolve({});

      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'TextButton'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is ElevatedButton) {
      final ElevatedButton textWidget = widget.widget as ElevatedButton;
      final MaterialStateProperty<Color?>? backgroundColorProperty = textWidget.style?.backgroundColor;

      // Resolve the background color for a specific state or the default state
      final Color? backgroundColor = backgroundColorProperty?.resolve({});
      print('Text color: $backgroundColor');
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'ElevatedButton'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is OutlinedButton) {
      final OutlinedButton textWidget = widget.widget as OutlinedButton;
      final MaterialStateProperty<Color?>? backgroundColorProperty = textWidget.style?.backgroundColor;

      // Resolve the background color for a specific state or the default state
      final Color? backgroundColor = backgroundColorProperty?.resolve({});
      print('Text color: $backgroundColor');
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'OutlinedButton'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is IconButton) {
      final IconButton textWidget = widget.widget as IconButton;
      final MaterialStateProperty<Color?>? backgroundColorProperty = textWidget.style?.backgroundColor;

      // Resolve the background color for a specific state or the default state
      final Color? backgroundColor = backgroundColorProperty?.resolve({});
      print('Text color: $backgroundColor');
      style = WidgetStyles(
        backgroundColor: backgroundColor != null ? toCssHexColor(backgroundColor) : null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'IconButton'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is Container) {
      final Container textWidget = widget.widget as Container;
      final color = textWidget.color;
      style = WidgetStyles(
        backgroundColor: color != null ? toCssHexColor(color) : null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'Container'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is DecoratedBox) {
      style = WidgetStyles(
        backgroundColor: null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'DecoratedBox'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is AppBar) {
      final AppBar textWidget = widget.widget as AppBar;
      style = WidgetStyles(
        backgroundColor: textWidget.backgroundColor != null ? toCssHexColor(textWidget.backgroundColor!) : null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'AppBar'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is Chip) {
      final Chip textWidget = widget.widget as Chip;
      style = WidgetStyles(
        backgroundColor: textWidget.backgroundColor != null ? toCssHexColor(textWidget.backgroundColor!) : null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'Chip'
      );
      foundStyles.add(style);
    }
    else if (widget.widget is SizedBox) {
      final SizedBox textWidget = widget.widget as SizedBox;
      style = WidgetStyles(
        backgroundColor: null,
        color: null,
        fontSize: null,
        fontFamily: null,
        fontWeight: null,
        text: '',
        position: position,
        size: size,
        name: 'SizedBox'
      );
      foundStyles.add(style);
    }
    else {
      print('Widget type not acceptable: ${widget.widget.runtimeType}');
    }
  }

  print('Number of widgets found: ${foundWidgets.length}');

  final List<Map<String, dynamic>> widgetJson = [];

  for (final style in foundStyles) {
    widgetJson.add({
      'color': style.color, // Convert Color to its integer value
      'backgroundColor': style.backgroundColor, // Assuming it's serializable
      'fontSize': style.fontSize,
      'fontFamily': style.fontFamily,
      'fontWeight': style.fontWeight,
      'text': style.text,
      'position': {'dx': style.position.dx, 'dy': style.position.dy},
      'size': {'width': style.size.width, 'height': style.size.height},
    });
  }

  return widgetJson;
}

bool _isDialogOpen = false;

class _VisualMatchButtonState extends State<VisualExactButton> {

  List<CampaignProjectModel> items = [];
  bool dialogOpened = false;

  Future<void> _showMyDialog() async {
    CampaignProjectModel defaultCampaign = CampaignProjectModel(id: 0, name: 'Select a Campaign');
    CampaignProjectModel defaultProject = CampaignProjectModel(id: 0, name: 'Select a Project');
    CampaignProjectModel selectedCampaign = CampaignProjectModel(id: 0, name: 'Select a Campaign');
    CampaignProjectModel selectedProject = CampaignProjectModel(id: 0, name: 'Select a Project');
    String image = '';
    int errorCode = 0;
    double width = 414.0;
    double height = 896.0;
    Widget? child = widget.child;
    List<int> targetedItemIds = [];
    int totalScreenshotsCount = 0;
    int currentNo = 0;
    int status = 0; // 0: Standby, 1: Checking size, 2: Taking screenshots
    BuildContext dialogContext = navigatorKey.currentContext!;

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
        // print('widget ${widget.key} checkpoint 1');

      if (
        widget != null &&
        widget.key != null &&
        widget.key.currentContext != null &&
        widget.key.currentContext!.findRenderObject() != null &&
        condition1 &&
        condition2
      ) {
        
        // print('widget ${widget.key} checkpoint 2');
        final dynamic renderObject = widget.key.currentContext!.findRenderObject();
        final dynamic scrollableContext = widget.key.currentContext;
        if (
          scrollableContext is BuildContext &&
          renderObject is RenderBox
        ) {
          // print('widget ${widget.key} checkpoint 3');
          // final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);
          try {
            final ScrollableState scrollableState = Scrollable.of(scrollableContext);
            final ScrollPosition position = scrollableState.position;
            final double offset = position.pixels;
            final double viewportHeight = position.viewportDimension;

            final Rect bounds = renderObject.paintBounds.shift(renderObject.localToGlobal(Offset.zero));
            // final bool inViewport = bounds.top < viewportHeight + offset && bounds.bottom > offset;
            final bool inViewport = bounds.top >= 0 && bounds.top < viewportHeight;

            // print('widget ${widget.key} checkpoint 3: condition 1: $condition1');
            // print('widget ${widget.key} checkpoint 3: condition 2: $condition2');
            // print('widget ${widget.key} checkpoint 3: inViewport: $inViewport');

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
        // print('widget ${widget.key} checkpoint 4');
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
      // print('widget ${widget.key} checkpoint 5');

      return false;
    }

    Future<int> scrollEachItem(
      dynamic child,
      int currentDepth,
      List<WidgetItem> allWidgets,
      BuildContext currentContext
    ) async {
      print('scrollEachItem is triggered');
      print('child: $child');
      print('currentDepth: $currentDepth');

      print('isScrollable(child): ${isScrollable(child)}');

      if (
        isScrollable(child) == true &&
        targetedItemIds.length > currentNo
      ) {
        print('Scrollable widget found');

        while (isScrollable(child) == true && targetedItemIds.length > currentNo) {
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
              final widgetItems = _findVisibleWidgets(currentContext);
              print('widgetItems.length: ${widgetItems.length}');

              // Convert the list to a JSON string
              String jsonString = jsonEncode(widgetItems);

              return Dio().post('https://testserver.visualexact.com/api/designcomp/extension/screenshot/base64', data: {
                'items': [
                  {
                    'name': 'scrollable_${currentNo}_${DateTime.now().millisecondsSinceEpoch}',
                    'base64': 'data:image/png;base64,$base64Value',
                    'itemId': targetedItemIds[currentNo],
                    'relevantAction': 'Scroll down at the center of Widget (key: $keyToString) for $maxScrollableExtend pixels',
                    'visibleWidgets': jsonString
                  }
                ],
              },
              options: options)
              .then((res) async {
                if (res.statusCode == 200) {
                  print('Screenshot uploaded successfully.');

                  print('currentNo: $currentNo');

                  setState(() {
                    currentNo = currentNo + 1;
                  });

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
                      await scrollEachItem(widgetItem.widget, widgetItem.depth, allWidgets, currentContext);
                    }
                  }

                  return currentNo;
                } else {
                  print('Screenshot upload failed: ${res.statusCode}');
                  return currentNo;
                }
              });
            } else {
              print('Screenshot is null, skip.');

              return currentNo;
            }
          }).catchError((onError) {
            print('Capture Error: $onError');
          });
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

      print('Number of scrollable widgets found: ${foundScrollables.length}');

      if (foundScrollables.length < 10) {
        print('Scrollable widgets key: ${foundScrollables.map((e) => e.widget.key)}');
        print('Scrollable widgets depth: ${foundScrollables.map((e) => e.depth)}');
      }

      return foundScrollables;
    }

    Future<void> pressHandler(Widget? child, BuildContext currentContext) async {
      print('Button pressed, updated 3');

      // Test Fetch All Widgets END

      int projectId = selectedProject.id;
      double requiredScreenWidth = selectedProject.width.toDouble();
      double requiredScreenHeight = selectedProject.height.toDouble();

      print('pressHandler projectId: $projectId');

      String deleteUrl = 'https://testserver.visualexact.com/api/designcomp/extension/screenshot/clear/$projectId';

      try {
        setState(() {
          status = 1;
        });

        widget.setLoading(true);

        const snackBar1 = SnackBar(
          content: Text('Checking screen size. Please wait...'),
          duration: Duration(days: 365),
        );

        ScaffoldMessenger.of(currentContext).hideCurrentSnackBar();
        ScaffoldMessenger.of(currentContext).showSnackBar(snackBar1);

        // Get the screen size
        if (!currentContext.mounted) {
          setState(() {
            status = 0;
          });
          widget.setLoading(false);

          return;
        };
        final Size screenSize = MediaQuery.of(currentContext).size;

        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;

        print('Screen size: $screenWidth x $screenHeight');

        setState(() {
          width = requiredScreenWidth;
          height = requiredScreenHeight;
        });

        if (screenWidth != requiredScreenWidth || screenHeight != requiredScreenHeight) {
          print('Screen size is not $requiredScreenWidth x $requiredScreenHeight. Abort.');
          ScaffoldMessenger.of(currentContext).hideCurrentSnackBar();
          setState(() {
            status = 0;
            errorCode = 4;
          });
          widget.setLoading(false);
          
          return;
        }

        const snackBar4 = SnackBar(
          content: Text('Fetching project items, please wait...'),
          duration: Duration(days: 365),
        );

        if (!currentContext.mounted) {
          setState(() {
            status = 0;
          });
          widget.setLoading(false);

          return;
        };

        ScaffoldMessenger.of(currentContext).hideCurrentSnackBar();
        ScaffoldMessenger.of(currentContext).showSnackBar(snackBar4);

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

            setState(() {
              targetedItemIds = newItemIds;
              currentNo = 0;
              status = 2;
              dialogOpened = false;
            });
            
            if (context.mounted) {
              Navigator.of(dialogContext).pop();
              _isDialogOpen = false;
            }
          }
          else {
            setState(() {
              status = 0;
            });
            widget.setLoading(false);
          }
        }

      } catch (e) {
        print('pressHandler fetch item list Error: $e');
        setState(() {
          status = 0;
        });
        widget.setLoading(false);
        if (!currentContext.mounted) {
          return;
        };
        ScaffoldMessenger.of(currentContext).hideCurrentSnackBar();
      }

      if (child == null) {
        print('Child is null. Abort.');
        setState(() {
          status = 0;
        });
        widget.setLoading(false);
        if (!currentContext.mounted) {
          return;
        };
        ScaffoldMessenger.of(currentContext).hideCurrentSnackBar();
        return;
      }

      print('targetedItemIds: $targetedItemIds');

      try {

        const snackBar2 = SnackBar(
          content: Text('Taking screenshots, please wait...'),
          duration: Duration(days: 365),
        );

        if (!currentContext.mounted) {
          setState(() {
            status = 0;
          });
          widget.setLoading(false);

          return;
        };

        ScaffoldMessenger.of(currentContext).hideCurrentSnackBar();
        ScaffoldMessenger.of(currentContext).showSnackBar(snackBar2);

        setState(() {
          totalScreenshotsCount = 0;
          status = 2;
        });

        await Future.delayed(const Duration(seconds: 1), () {
          print('One second has passed.'); // Prints after 1 second.
        });

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
              final widgetItems = _findVisibleWidgets(currentContext);
              print('widgetItems.length: ${widgetItems.length}');

              // Convert the list to a JSON string
              String jsonString = jsonEncode(widgetItems);

              return Dio().post(uploadUrl, data: {
                'items': [
                  {
                    'name': 'scrollable_${currentNo}_${DateTime.now().millisecondsSinceEpoch}',
                    'base64': 'data:image/png;base64,$base64Value',
                    'itemId': targetedItemIds[currentNo],
                    'relevantAction': '',
                    'projectId': projectId,
                    'visibleWidgets': jsonString
                  }
                ],
              },
              options: options)
              .then((res) async {
                print('Screenshot uploaded successfully.');
                setState(() {
                  totalScreenshotsCount = totalScreenshotsCount + 1;
                });

                setState(() {
                  currentNo = currentNo + 1;
                });

                try {
                  if (!currentContext.mounted) throw 'Context is not mounted.';
                  final foundScrollables = _findScrollableWidgets(currentContext);

                  if (foundScrollables.isNotEmpty) {
                    print('It has scrollable! Number of scrollable widgets with key: ${foundScrollables.length}');
                    // Iterate through each scrollable widget and start scrolling
                    for (final scrollable in foundScrollables) {
                      print('Scrolling each item: ${scrollable.widget.key ?? '*no key*'} at depth ${scrollable.depth}');
                      await scrollEachItem(scrollable.widget, scrollable.depth, foundScrollables, currentContext);
                    }
                  } else {
                    print('It has no scrollable!');
                  }

                  print('All screenshots taken.');

                  var snackBar3 = const SnackBar(
                    content: Text('Screenshots taken.'),
                  );

                  if (!currentContext.mounted) throw 'Context is not mounted.';
                  ScaffoldMessenger.of(currentContext).hideCurrentSnackBar();
                  ScaffoldMessenger.of(currentContext).showSnackBar(snackBar3);

                  setState(() {
                    status = 0;
                  });
                  widget.setLoading(false);
                } catch (err) {
                  print('Error: $err');
                }

                return currentNo;
              });
            });
          }
          else {
            print('Screenshot is null, skip.');

            return currentNo;
          }
        }).catchError((onError) {
          print('Capture Error: $onError');
        });
      } catch (err) {
        print('Error: $err');
      }
    }

    List<CampaignProjectModel> campaigns = [
      CampaignProjectModel(
        id: 0,
        name: 'Select a Campaign'
      ),
    ];

    List<CampaignProjectModel> newCampaigns = [
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
    } catch (e) {
      print('Error: $e');
    }
    setState(() => campaigns = newCampaigns);

    List<CampaignProjectModel> projects = [
      CampaignProjectModel(
        id: 0,
        name: 'Select a Project',
        width: 0.0,
        height: 0.0
      ),
    ];

    if (_isDialogOpen) return;

    _isDialogOpen = true;

    return showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              titlePadding: const EdgeInsets.only(left: 15.0, top: 20.0, bottom: 10.0, right: 15.0),
              contentPadding: const EdgeInsets.all(8),
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: const Text('VisualExact', textAlign: TextAlign.center, style: TextStyle(
                fontSize: 24.0, // Make the title larger
                fontWeight: FontWeight.bold,
                color: Colors.black, // You can adjust the color as needed
              )),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text(contentText),
                  // Text(selectedCampaign.name),
                  // Text(selectedProject.name),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: new Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.white,
                            ),
                            child: DropdownButton<String>(
                              hint: const Text('Select Campaign'),
                              onChanged: (newValue) {
                                final value = campaigns.firstWhere((element) => element.name == newValue);
                                setState(() {
                                  selectedCampaign = value ?? defaultCampaign;
                                  image = '';
                                  errorCode = 0;
                                });

                                var newProjects = <CampaignProjectModel>[
                                  CampaignProjectModel(
                                    id: 0,
                                    name: 'Select a Project',
                                  ),
                                ];

                                if (value != null && value.id != 0) {
                                  try {
                                    Dio().get('https://testserver.visualexact.com/api/designcomp/project/incompleted/list/${value.id}', options: options)
                                    .then((res) {
                                      print('onSelectedCampaign res.statusCode: ${res.statusCode}');
                                      if (res.statusCode == 200 && res.data != null) {
                                        print('onSelectedCampaign res.data.success: ${res.data['success']}');
                                        if (res.data['success'] != null && res.data['success'] == true) {
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
                                      setState(() {
                                        selectedProject = defaultProject;
                                        projects = newProjects;
                                      });
                                    });
                                  } catch (e) {
                                    print('onSelectedCampaign Error: $e');
                                    setState(() => projects = [
                                      CampaignProjectModel(
                                        id: 0,
                                        name: 'Select a Project'
                                      ),
                                    ]);
                                  }
                                }
                              },
                              value: selectedCampaign.name,
                              isExpanded: true, // This moves the icon to the end
                              items: [
                                for (var data in campaigns)
                                  DropdownMenuItem(
                                    value: data.name,
                                    child: Text(data.name),
                                  ),
                              ],
                              style: const TextStyle(
                                color: Colors.black,
                                backgroundColor: Colors.white
                              )
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: new Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.white,
                            ),
                            child: DropdownButton<String>(
                              hint: const Text('Select Project'),
                              onChanged: (value) {
                                final project = projects.firstWhere((element) => element.name == value);
                                setState(() {
                                  selectedProject = project;
                                  image = project.screenshot;
                                  errorCode = 0;
                                });

                                print('New Project: ${project.name}');
                              },
                              value: selectedProject.name,
                              isExpanded: true, // This moves the icon to the end
                              items: [
                                for (var data in projects)
                                  DropdownMenuItem(
                                    value: data.name,
                                    child: Text(data.name),
                                  ),
                              ],
                              style: const TextStyle(
                                color: Colors.black,
                                backgroundColor: Colors.white
                              )
                            ),
                          )
                        ),
                      ),
                      Visibility(
                        visible: errorCode != 0,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            errorCode == 0 ? '' :
                            errorCode == 1 ? 'Please select a Campaign' :
                            errorCode == 2 ? 'Please select a Project' :
                            errorCode == 3 ? 'Something is wrong!' :
                            // 'The screen size is wrong. It must be ${width} x ${height}',
                            'The screen size required is ${width} x ${height}. Please change your device or consult your designer.',
                            style: errorCode == 0 ? const TextStyle(color: Colors.black) : const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: image != '',
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 1.0), // Add black border
                            ),
                            child: SizedBox(
                              height: 300.0, // Set the height limit here
                              child: Image.network(
                                image,
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
                  ),
                  const SizedBox(height: 16),
                  ButtonTheme(
                    minWidth: 78.0,
                    height: 34.0,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  dialogOpened = false;
                                  _isDialogOpen = false;
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
                                  print('submitHandler 1 is triggered');
                                  print('Selected Campaign: ${selectedCampaign.id}');
                                  print('Selected Project: ${selectedProject.id}');
                                  if (selectedCampaign.id == 0) {
                                    setState(() {
                                      errorCode = 1;
                                    });
                                  } 
                                  else if (selectedProject.id == 0) {
                                    setState(() {
                                      errorCode = 2;
                                    });
                                  }
                                  else if (context != null && child != null && status == 0) {
                                    print('Condition passed, proceed with pressHandler');
                                    setState(() {
                                      status = 1;
                                    });
                                    
                                    pressHandler(child, widget.currentContext);
                                  }
                                  else if (!(context != null && child != null)) {
                                    setState(() {
                                      errorCode = 3;
                                    });
                                  }
                                  print('errorCode: $errorCode');
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
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      key: const Key("VisualExactButton"),
      onPressed: () {
        print('Visual Match Button Pressed');
        if (_isDialogOpen) {
          return;
        }
        _showMyDialog();
      },
      backgroundColor: vmPrimaryColor,
      child: Image.memory(
        base64Decode('iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAMAAAD04JH5AAAAAXNSR0IB2cksfwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAW5QTFRFAH5gTqWR/////P79FIhs4/Hu3O3pAn9h7/f1drqqOZuDfL2tksi71+vmlMm8G4xxNJiAM5iA7vb0x+Pc1urlSaOObbWkeLurBIBipNHGFYltGotw/v/+T6aRB4Fk9/v6uNvTvN3VrtbMWqyYXq6b+v38D4ZptdrRC4RnbLWjEIZqqdTJotDFyuTearSiRKCKJ5J4xeLb5PHuiMO1mszAe7ytQJ6IKJJ5RaGL6fTxzOXfMZd/i8S3bralYrCds9nQweDYQZ+JVamVnM3B8/n4fr6vmcu/3u7qUqeTO5yFPJyFrNXLf76vII50WKqXvd7Ww+Hat9vSZbGfc7iodLmozebgIo91S6SPMpd/g8Cy6vTykMe6j8a5rdbMdbmputzUyeTdXK2ZhsK0oM/EQp+Jo9DGYK+cv9/XsNfOOpuElsq+OJqDVqmWY7CeMJZ+ptLHSKKNqNPJ6PPxjcW4L5Z9WauYnc3CP56HhMGyyOPdEO1nxQAABMlJREFUeJztmflvFVUUx+8jpU0pS0lKuoVGWQq1C1JU0hZZqkhJIaU2KAWCAjUQl5SAuPwJbkAAg9YEaqiNBAhLA8QlCiqi7GBZWqhsUVmiVFkqhuaZPpi558ybefece2v85c4P7Tkz597zmfdm7ny/80Lif95CFsACWAALYAEsgAWwABbAAlgACxDzYAhnd+nz9ux0orh/9AESQmhwQge5f6+/3TDxlj6A6H0bZkk3yAB9b7phnz8NAJL/Qmm/68T+CUntTtj/99iliosw5Q+Y9boZVOfZBsiuKVeNAFKvwSw++TINIP2KO3/qr0YAmSE0PvMSqX9WyK3LOq+oVa0DD16A2QM/kwAGn3PDQWcNAYagloNDrRSAYWecaGDiaUMA8GlGpj5F6P9QS9gJc06oipVLcd5JmOX+RAAoaHZD9UWjBBiBWxYcVQOMPOZEyfHK20b9MCpELUceUg7oJxfMwoPKajXAqCMwe/iwcsCjkvGR/d0AMPoASh/7QTUg3n1ojt6nnJ2iB4pRy9TfFOUlsmvxd90C8PhemCnv7DHfu2HR3hh1dIDstjBMx3wTu7zoRydSSBEygBj3LczG7o5ZPGGPGyqkCB2gFLdM/yVW8RNfu6FCitAB0vK+Qi2+oNWqpAgdQDz1JcwmfhajtOxzN1RJEQbAZNyybGdwafkud2aVFGEAiEnoU4+xwA7vbHNCpRThAExB51zaejGocKxcepRShAMwdQfm2R5UWNHkRGopwgEQ01DLii0BZRk93O9dLUVYAE9vRYOCTFqVJCPqVyoAuLgiPJv8y6ZvdiKCFGEBiFwkBgNM2jOSiyBFeADPbsStPvUrqt7ghgQpwgNIqEItqz/xK5KenCJFeABidiPM4sN3okuAJ6dIESZACT6ncDi6BHhyihRhAniM8qz1UQXAk5OkCBdgTgPMfEwa8OQkKcIFiEtDT7e8494C6clpUoQLIJ5Dn/qces9h4CJpUoQNMPdjlJY34cPAk9OkCBsgKxsps+fX4sPSkxOlCBtAzF8HM49JA56cKEX4ADX4nPOPwQx4cqIU4QN4jPL8j2AmPTlVimgAzKuHGWoEPDlVimgAeJRZTZ2MgSenShENAJGPTu6FD2UsPTlZiugA5LTALCPsmjTwqCJLER2A7DBSZnLJB56cLEV0AMTCOphJkyY9OV2KaAEA69e1LVhz7z/w5HQpogWQ1o6e9E/e5wGenC5FtADEix/ArLQ5csUDT86QInoAL63BPKu7/oIvhiFF9AA8Rnlo5L6UnpwjRTQBktAvVxGTBmwTR4poAmTi94SVm5En50gRTQAxHr2m6zJp0pOzpIguwCvvo/TllcCTs6SILsDwDvS0m9kAPDlLiugCiNpVMJvRKD05T4poAyxaidISufTVLufPpvPr+eIVAQf8DON/AbAk4ESZUkQf4NVl/vuZUkQfwGOU3Y0pRQwAqnxf03GliAFAnO/VxpUiBgCicpvPTq4UMQFY+l70PrYUMQHwGOXIxpYiJgDitXejdrGliBHA6+949/CliBGAxygLHSliBvDG2555+FLEDMBjlHWkiBmAePMtlGpIEUMA8EpG6EkRQwBslHlvRboFoLs2C2ABLIAFsAAWwAJYAAtgASyABfgX+wUlkCeY9jAAAAAASUVORK5CYII='),
        width: 40,
        height: 40,
      ),
    );
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

class WidgetItem {
  WidgetItem({
    required this.widget,
    required this.depth,
    this.used = false,
    this.renderObject,
    this.style,
  });
  final dynamic widget;
  final int depth;
  bool used;
  RenderObject? renderObject;
  WidgetStyles? style;

  Map<String, dynamic> toJson() {
    return {
      'widget': widget, // Assuming widget is serializable or convert it
      'depth': depth,
      'used': used,
      'style': style?.toJson(), // Use the toJson method from WidgetStyles
    };
  }
}
