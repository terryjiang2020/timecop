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
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:timecop/global_key.dart';

class VisualMatchButton extends StatefulWidget {
  const VisualMatchButton({Key? key}) : super(key: key);

  @override
  State<VisualMatchButton> createState() => _VisualMatchButtonState();
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

class _VisualMatchButtonState extends State<VisualMatchButton> {

  Future<void> _showMyDialog() async {
    String contentText = "Content of Dialog";
    List<CampaignProjectModel> items = [];
    bool dialogOpened = false;
    CampaignProjectModel defaultCampaign = CampaignProjectModel(id: 0, name: 'Select a Campaign');
    CampaignProjectModel defaultProject = CampaignProjectModel(id: 0, name: 'Select a Project');
    CampaignProjectModel selectedCampaign = CampaignProjectModel(id: 0, name: 'Select a Campaign');
    CampaignProjectModel selectedProject = CampaignProjectModel(id: 0, name: 'Select a Project');
    Function submitHandlerFunc = (Widget? child, BuildContext context) {};
    String image = '';
    int errorCode = 0;
    double width = 414.0;
    double height = 896.0;
    BuildContext? currentContext;
    Widget? child;
    List<int> targetedItemIds = [];
    int currentNo = 0;
    int status = 0; // 0: Standby, 1: Checking size, 2: Taking screenshots

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

    return showDialog(
      context: navigatorKey.currentContext!,
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
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
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
                          ),
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
                                  else if (currentContext != null && child != null && status == 0) {
                                    print('Condition passed, proceed with pressHandler');
                                    setState(() {
                                      status = 1;
                                    });
                                    
                                    submitHandlerFunc(child, currentContext!);
                                  }
                                  else if (!(currentContext != null && child != null)) {
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
      key: const Key("VisualMatchButton"),
      onPressed: () {
        print('Visual Match Button Pressed');
        _showMyDialog();
      },
      backgroundColor: vmPrimaryColor,
      child: Image.memory(
        base64Decode('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'),
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
