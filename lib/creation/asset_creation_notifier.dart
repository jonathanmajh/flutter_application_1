import 'package:flutter/material.dart';

import '../admin/consts.dart';
import '../admin/db_drift.dart';
import '../main.dart';

class AssetCreationNotifier extends ChangeNotifier {
  String selectedSite = 'NONE';

  Map<String, Asset> siteAssets = {};
  Map<String, Asset> pendingAssets = {};
  Map<String, List<Asset>> parentAssets = {};

  Future<void> setSite(String site, [bool notify = true]) async {
    if (site == 'NONE') {
      return;
    }

    siteAssets.clear();
    parentAssets.clear();
    pendingAssets.clear();

    final dbrows = await database!
        .getSiteAssets(site); //todo make it able to load other sites
    for (var row in dbrows) {
      if (row.newAsset) {
        pendingAssets[row.assetnum] = row;
      }
      siteAssets[row.assetnum] = row;
      if (parentAssets.containsKey(row.parent)) {
        parentAssets[row.parent]!.add(row);
      } else {
        parentAssets[row.parent ?? "Top"] = [row];
      }
    }

    selectedSite = site;

    if (notify) {
      notifyListeners();
    }

    return;
  }

  Future<int> addAsset(String assetNum, String description, String parent,
      [String? site]) async {
    if (siteAssets.containsKey(assetNum)) {
      throw ('Upload Fail! Asset $assetNum already exists');
    }

    var id = await database!
        .addNewAsset(assetNum, (site ?? selectedSite), description, parent);
    notifyListeners();
    return id;
  }

  Future<int> deleteAsset(String assetNum, String site) async {
    if (!siteAssets.containsKey(assetNum)) {
      throw 'Asset $assetNum does not exist';
    }
    if (parentAssets.containsKey(assetNum)) {
      throw 'Asset $assetNum has children';
    }
    if (!siteAssets[assetNum]!.newAsset) {
      throw 'Asset already exists in Maximo, cannot delete';
    }

    var parent = siteAssets[assetNum]!.parent;
    parentAssets[parent]!.remove(siteAssets[assetNum]!);
    if (parentAssets[parent]!.isEmpty) {
      parentAssets.remove(parent);
    }
    siteAssets.remove(assetNum);

    var id = await database!.deleteAsset(assetNum, site);
    return id;
  }

  Set<String> getChildAssetnums(String assetnum) {
    List<Asset>? directChilds = parentAssets[assetnum];

    //exit condition

    if (directChilds == null || directChilds.isEmpty) {
      return <String>{};
    }

    Set<String> childSet = {};

    for (Asset child in directChilds) {
      childSet.add(child.assetnum);
      childSet.addAll(getChildAssetnums(child.assetnum));
    }

    return childSet;
  }

  String getSiteDescription([String? siteid]) {
    siteid ??= selectedSite;
    if (siteid == 'NONE') {
      return 'No Site Selected';
    } else {
      return 'Site ${siteIDAndDescription[siteid]!}';
    }
  }

  void doNotify() {
    notifyListeners();
  }
}
