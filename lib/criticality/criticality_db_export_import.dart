import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../bin/db_drift.dart';

Future<String> exportCriticalityDB(
    MyDatabase database, String selectedSite) async {
  try {
    // line for current site
    String export = '{"selectedSite":"$selectedSite"}';
    var data = await database.getSettings();
    for (Setting setting in data) {
      export = '$export\r\n${jsonEncode(setting)}';
    }
    // line for system criticalities for selected site
    var data2 = await database.getSystemCriticalitiesFiltered(selectedSite);
    for (SystemCriticality data in data2) {
      export =
          '$export\r\n${jsonEncode(data).replaceAll('"siteid":null', '"siteid":"$selectedSite"')}';
    }
    // like for selected asset values
    var data3 = await database.getAllAssetCriticalities();
    for (AssetCriticality data in data3) {
      if (data.asset.substring(0, selectedSite.length) == selectedSite) {
        export = '$export\r\n${jsonEncode(data)}';
      }
    }
    saveFile(export);
    return 'Exported Data Successfully';
  } catch (e) {
    return 'Failed to Export Data: ${e.toString()}';
  }
}

Future<void> saveFile(String saveText) async {
  const String fileName = 'AssetCriticalityDataExport.txt';

  final FileSaveLocation? result = await getSaveLocation(
    initialDirectory: null,
    suggestedName: fileName,
  );
  if (result == null) {
    // Operation was canceled by the user.
    return;
  }
  final String text = saveText;
  final Uint8List fileData = Uint8List.fromList(text.codeUnits);
  const String fileMimeType = 'text/plain';
  final XFile textFile =
      XFile.fromData(fileData, mimeType: fileMimeType, name: fileName);

  await textFile.saveTo(result.path);
}

Future<String> importCriticalityDB(MyDatabase database) async {
  try {
    ClipboardData? cdata = await Clipboard.getData(Clipboard.kTextPlain);
    String? import = cdata!.text;
    List<String> lines = import!.split('\r\n');
    List<Setting> setting = [];
    List<AssetCriticality> criticality = [];
    List<SystemCriticality> system = [];
    Map<int, int> replaceSystemID = {};
    String selectedSite = jsonDecode(lines[0])['selectedSite'];
    dynamic tempJson = {'': ''};
    int maxSystemID = await database.maxSystemID().getSingle() ?? 1;
    for (String line in lines) {
      if (line.startsWith('{"key"')) {
        setting.add(Setting.fromJson(jsonDecode(line)));
      } else if (line.startsWith('{"id"')) {
        // use new id for systems being imported
        tempJson = jsonDecode(line);
        maxSystemID++;
        replaceSystemID[tempJson['id']] = maxSystemID;
        tempJson['id'] = maxSystemID;
        system.add(SystemCriticality.fromJson(tempJson));
      } else if (line.startsWith('{"asset"')) {
        tempJson = jsonDecode(line);
        tempJson['system'] = replaceSystemID[tempJson['system']];
        criticality.add(AssetCriticality.fromJson(tempJson));
      }
    }
    await database.importCriticality(
      setting: setting,
      criticality: criticality,
      system: system,
      siteid: selectedSite,
    );
    return 'Imported Data Successfully';
  } catch (e) {
    return 'Failed to Import Data: ${e.toString()}';
  }
}
