import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iko_reliability_flutter/settings/settings_notifier.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../bin/consts.dart';
import '../bin/db_drift.dart';
import '../bin/drawer.dart';
import '../bin/end_drawer.dart';
import '../main.dart';
import '../settings/theme_manager.dart';
import 'asset_criticality_notifier.dart';
import 'spare_criticality_notifier.dart';

@RoutePage()
class SpareCriticalityPage extends StatefulWidget {
  const SpareCriticalityPage({super.key});

  @override
  State<SpareCriticalityPage> createState() => _SpareCriticalityPageState();
}

class _SpareCriticalityPageState extends State<SpareCriticalityPage> {
  List<PlutoColumn> columns = [];
  String loadedSite = '';
  // used to track if update event is done by system or manually

  List<PlutoColumn> detailColumns = [];
  List<PlutoRow> detailRows = [];

  Key? currentRowKey;

  late PlutoGridStateManager stateManager;
  late PlutoGridStateManager detailStateManager;

  @override
  void initState() {
    super.initState();

    detailColumns.addAll([
      PlutoColumn(
        title: 'PR Number',
        field: 'prnum',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'PO Number',
        field: 'ponum',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Start Date',
        field: 'startDate',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'End Date',
        field: 'endDate',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Lead Time',
        field: 'leadTime',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Unit Cost',
        field: 'unitCost',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Included?',
        field: 'included',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
    ]);

    columns.addAll([
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.text(),
        readOnly: true,
        hide: true,
      ),
      PlutoColumn(
        title: 'Item Number',
        field: 'itemnum',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: 100,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: 600,
      ),
      PlutoColumn(
        title: 'Asset RPN',
        field: 'assetRpn',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: 100,
      ),
      PlutoColumn(
        title: 'Usage',
        field: 'usage',
        type: PlutoColumnType.number(),
        renderer: (rendererContext) {
          // change cell to dropdown button
          return DropdownButton<int>(
            value: rendererContext.cell.value,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            isExpanded: true,
            onChanged: (int? value) async {
              context.read<SpareOverrideNotifier>().updateSpareOverride(
                spares: [rendererContext.row.cells['itemnum']!.value],
                status: AssetOverride.breakdowns,
              );
              await database!.updateSpareCriticality(
                usage: value,
                manual: true,
                spareid: rendererContext.row.cells['id']!.value,
              );
              setState(() {
                stateManager.changeCellValue(rendererContext.cell, value);
              });
            },
            items: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
                .map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child:
                    Text('$value: ${usageRating[value]?["description"] ?? ""}'),
              );
            }).toList(),
          );
        },
      ),
      PlutoColumn(
        title: 'Lead Time',
        field: 'leadTime',
        type: PlutoColumnType.number(),
        renderer: (rendererContext) {
          // change cell to dropdown button
          return DropdownButton<int>(
            value: rendererContext.cell.value,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            isExpanded: true,
            onChanged: (int? value) async {
              context.read<SpareOverrideNotifier>().updateSpareOverride(
                spares: [rendererContext.row.cells['itemnum']!.value],
                status: AssetOverride.breakdowns,
              );
              await database!.updateSpareCriticality(
                leadTime: value,
                manual: true,
                spareid: rendererContext.row.cells['id']!.value,
              );
              setState(() {
                stateManager.changeCellValue(rendererContext.cell, value);
              });
            },
            items: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
                .map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(
                    '$value: ${leadTimeRating[value]?["description"] ?? ""}'),
              );
            }).toList(),
          );
        },
      ),
      PlutoColumn(
        title: 'Cost',
        field: 'cost',
        type: PlutoColumnType.number(),
        renderer: (rendererContext) {
          // change cell to dropdown button
          return DropdownButton<int>(
            value: rendererContext.cell.value,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            isExpanded: true,
            onChanged: (int? value) async {
              context.read<SpareOverrideNotifier>().updateSpareOverride(
                spares: [rendererContext.row.cells['itemnum']!.value],
                status: AssetOverride.breakdowns,
              );
              await database!.updateSpareCriticality(
                cost: value,
                manual: true,
                spareid: rendererContext.row.cells['id']!.value,
              );
              setState(() {
                stateManager.changeCellValue(rendererContext.cell, value);
              });
            },
            items: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
                .map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child:
                    Text('$value: ${costRating[value]?["description"] ?? ""}'),
              );
            }).toList(),
          );
        },
      ),
      PlutoColumn(
        title: 'RPN',
        field: 'rpn',
        type: PlutoColumnType.number(),
        readOnly: true,
        width: 100,
      ),
      PlutoColumn(
        title: 'New Priority',
        field: 'newPriority',
        type: PlutoColumnType.number(),
        width: 100,
        renderer: (rendererContext) {
          // change cell to dropdown button
          return DropdownButton<int>(
            value: rendererContext.cell.value,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            isExpanded: true,
            onChanged: (int? value) async {
              context.read<SpareOverrideNotifier>().updateSpareOverride(
                spares: [rendererContext.row.cells['itemnum']!.value],
                status: AssetOverride.priority,
              );
              await database!.updateSpareCriticality(
                newPriority: value,
                spareid: rendererContext.row.cells['id']!.value,
              );
              setState(() {
                stateManager.changeCellValue(rendererContext.cell, value);
              });
            },
            items:
                spareCriticality.keys.map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value: ${spareCriticality[value]}'),
              );
            }).toList(),
          );
        },
      ),
    ]);
  }

  void gridAHandler() {
    if (stateManager.currentRow == null) {
      return;
    }
    // if the selected row changes, load WOs for a different asset
    if (stateManager.currentRow!.key != currentRowKey) {
      currentRowKey = stateManager.currentRow!.key;

      detailStateManager.setShowLoading(true);

      fetchPurchaseHistory(
          itemnum: stateManager.currentRow!.cells['itemnum']!.value,
          siteid: context.read<SelectedSiteNotifier>().selectedSite);
    }
  }

  void fetchPurchaseHistory({
    required String itemnum,
    required String siteid,
  }) async {
    var itemPurchases =
        await database!.getItemPurchases(itemnum: itemnum, siteId: siteid);
    List<PlutoRow> rows = [];
    for (var itemPurchase in itemPurchases) {
      rows.add(PlutoRow(cells: {
        'prnum': PlutoCell(value: itemPurchase.prnum),
        'ponum': PlutoCell(value: itemPurchase.ponum),
        'startDate': PlutoCell(value: itemPurchase.startDate),
        'endDate': PlutoCell(value: itemPurchase.endDate),
        'leadTime': PlutoCell(value: itemPurchase.leadTime),
        'unitCost': PlutoCell(value: itemPurchase.unitCost),
        'included': PlutoCell(value: 'Yes'),
      }));
    }
    detailStateManager.removeRows(detailStateManager.rows);
    detailStateManager.resetCurrentState();
    detailStateManager.appendRows(rows);

    detailStateManager.setShowLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    ThemeManager themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      drawer: const Drawer(
        //navigation drawer
        child: NavDrawer(),
      ),
      appBar: AppBar(
        title: const Text('Spare Part Criticality'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
            ),
          )
        ],
      ),
      endDrawer: const EndDrawer(),
      body: FutureBuilder<List<SpareCriticalityWithItem>>(
        future: () async {
          return database!.getSpareCriticalities(
              siteid: context.watch<SelectedSiteNotifier>().selectedSite);
        }(),
        builder: (BuildContext context,
            AsyncSnapshot<List<SpareCriticalityWithItem>> snapshot) {
          List<PlutoRow> rows = [];
          if (snapshot.hasData) {
            if (snapshot.data!.isNotEmpty) {
              for (var row in snapshot.data!) {
                rows.add(PlutoRow(cells: {
                  'itemnum': PlutoCell(value: row.spareCriticality.itemnum),
                  'description': PlutoCell(value: row.item?.description ?? ''),
                  'assetRpn': PlutoCell(value: row.spareCriticality.assetRPN),
                  'usage': PlutoCell(value: row.spareCriticality.usage),
                  'leadTime': PlutoCell(value: row.spareCriticality.leadTime),
                  'cost': PlutoCell(value: row.spareCriticality.cost),
                  'rpn': PlutoCell(value: row.spareCriticality.newRPN),
                  'newPriority':
                      PlutoCell(value: row.spareCriticality.newPriority),
                  'id': PlutoCell(value: row.spareCriticality.id),
                }));
              }
              stateManager.removeAllRows();
              stateManager.appendRows(rows);
            }
          } else if (snapshot.hasError) {
            rows.add(PlutoRow(cells: {
              'itemnum': PlutoCell(value: 'Error!'),
              'description': PlutoCell(value: ''),
              'assetRpn': PlutoCell(value: snapshot.error),
              'usage': PlutoCell(value: 0),
              'leadTime': PlutoCell(value: 0),
              'cost': PlutoCell(value: 0),
              'rpn': PlutoCell(value: 0),
              'newPriority': PlutoCell(value: 0),
              'id': PlutoCell(value: 0),
            }));
          } else {
            rows.add(PlutoRow(cells: {
              'itemnum': PlutoCell(value: ''),
              'description': PlutoCell(value: ''),
              'assetRpn': PlutoCell(value: 'No Site Selected'),
              'usage': PlutoCell(value: 0),
              'leadTime': PlutoCell(value: 0),
              'cost': PlutoCell(value: 0),
              'rpn': PlutoCell(value: 0),
              'newPriority': PlutoCell(value: 0),
              'id': PlutoCell(value: 0),
            }));
          }
          return PlutoDualGrid(
            isVertical: true,
            display: PlutoDualGridDisplayRatio(ratio: 0.75),
            gridPropsA: PlutoDualGridProps(
              columns: columns,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
                event.stateManager.addListener(gridAHandler);
                stateManager.setShowColumnFilter(true);
              },
              onChanged: (PlutoGridOnChangedEvent event) async {
                // recalculate rpn number > nre priority if not overwritten
                if (![3, 4, 5].contains(event.columnIdx)) {
                  // only need to update if changes made to these columns
                  return;
                }
                debugPrint('running grid A on change event');
                final newRpn = rpnFunc(await database!
                    .getSpareCriticality(id: event.row.cells['id']!.value));
                if (newRpn > -1) {
                  await database!.updateSpareCriticality(
                    newRPN: newRpn,
                    spareid: event.row.cells['id']!.value,
                  );
                  setState(() {
                    stateManager.changeCellValue(
                        event.row.cells['rpn']!, newRpn);
                  });
                }
              },
              configuration: PlutoGridConfiguration(
                  style: themeManager.isDark
                      ? const PlutoGridStyleConfig.dark()
                      : const PlutoGridStyleConfig(),
                  shortcut: PlutoGridShortcut(actions: {
                    ...PlutoGridShortcut.defaultActions,
                    LogicalKeySet(LogicalKeyboardKey.add): CustomAddKeyAction(),
                    LogicalKeySet(LogicalKeyboardKey.numpadAdd):
                        CustomAddKeyAction(),
                    LogicalKeySet(LogicalKeyboardKey.minus):
                        CustomMinusKeyAction(),
                    LogicalKeySet(LogicalKeyboardKey.numpadSubtract):
                        CustomMinusKeyAction(),
                  })),
            ),
            gridPropsB: PlutoDualGridProps(
              configuration: PlutoGridConfiguration(
                  style: themeManager.isDark
                      ? const PlutoGridStyleConfig.dark()
                      : const PlutoGridStyleConfig()),
              columns: detailColumns,
              rows: detailRows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                detailStateManager = event.stateManager;
              },
              rowColorCallback: (rowColorContext) {
                if (rowColorContext.row.cells['included']!.value != 'Yes') {
                  return Colors.grey;
                }
                return themeManager.isDark ? Colors.black : Colors.white;
              },
            ),
            divider: themeManager.isDark
                ? PlutoDualGridDivider.dark(
                    indicatorColor: Theme.of(context).colorScheme.onBackground)
                : const PlutoDualGridDivider(),
          );
        },
      ),
    );
  }
}

class CustomAddKeyAction extends PlutoGridShortcutAction {
  @override
  void execute({
    required PlutoKeyManagerEvent keyEvent,
    required PlutoGridStateManager stateManager,
  }) {
    debugPrint('Pressed add key.');
    if (stateManager.currentColumnField != 'usage' &&
        stateManager.currentColumnField != 'leadTime' &&
        stateManager.currentColumnField != 'cost') {
      return;
    }
    if (stateManager.currentCell!.value == 10) {
      return;
    }
    stateManager.changeCellValue(
        stateManager.currentCell!, stateManager.currentCell!.value + 1);
  }
}

class CustomMinusKeyAction extends PlutoGridShortcutAction {
  @override
  void execute({
    required PlutoKeyManagerEvent keyEvent,
    required PlutoGridStateManager stateManager,
  }) {
    debugPrint('Pressed minus key.');
    if (stateManager.currentColumnField != 'usage' &&
        stateManager.currentColumnField != 'leadTime' &&
        stateManager.currentColumnField != 'cost') {
      return;
    }
    if (stateManager.currentCell!.value == 0) {
      return;
    }
    stateManager.changeCellValue(
        stateManager.currentCell!, stateManager.currentCell!.value - 1);
  }
}

class SparePartsLoadingIndicator extends StatefulWidget {
  const SparePartsLoadingIndicator({super.key});

  @override
  State<SparePartsLoadingIndicator> createState() =>
      _SparePartsLoadingIndicatorState();
}

class _SparePartsLoadingIndicatorState
    extends State<SparePartsLoadingIndicator> {
  String message = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    if (context.watch<SelectedSiteNotifier>().selectedSite.isEmpty) {
      return const SiteToggle();
    }
    sparePartLoading(
      siteid: context.read<SelectedSiteNotifier>().selectedSite,
      env: context.read<MaximoServerNotifier>().maximoServerSelected,
    );
    return Text(message);
  }

  Future<void> sparePartLoading(
      {required String siteid, required String env}) async {
    if (loading) {
      // dont load multiple times
      return;
    }
    setState(() {
      loading = true;
    });
    print('running');
    setState(() {
      message = 'Checking spare parts information...';
    });
    final dataCached = await database!.checkSpareParts(siteid: siteid);
    if (!dataCached) {
      try {
        setState(() {
          message = 'Loading item information from Maximo...';
        });
        await database!.getItemDetailsMaximo(
          siteid: siteid,
          env: env,
        );
        setState(() {
          message = 'Loading spare parts information from Maximo...';
        });
        await database!.getSparePartsMaximo(
          siteid: siteid,
          env: env,
        );
        setState(() {
          message = 'Loading purchasing information from Maximo...';
        });
        await database!.getPurchasesMaximo(
          siteid: siteid,
          env: env,
        );
      } catch (e) {
        setState(() {
          message = e.toString();
        });
        return;
      }
      try {
        setState(() {
          message =
              'Calculating spare part criticality...\nThis step can take significant time';
        });
        await database!.computeSparePartCriticality(siteid: siteid);
      } catch (e) {
        setState(() {
          message = e.toString();
        });
        return;
      }
    }
    Navigator.pop(context);
    context.router.pushNamed("/criticality/spare");
    Navigator.pop(context); // close the drawer
  }
}

double rpnFunc(SpareCriticality sparePart) {
  try {
    return sparePart.assetRPN *
        sparePart.usage *
        sparePart.leadTime *
        sparePart.cost;
  } catch (e) {
    return -1;
  }
}
