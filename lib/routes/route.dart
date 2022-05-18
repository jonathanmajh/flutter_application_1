import 'package:auto_route/auto_route.dart';

import '../admin/asset.dart';
import '../admin/contractor.dart';
import '../main.dart';
import '../reader/bookrenderer.dart';
import '../test/test.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(path: "/", page: GHFlutter, initial: true),
    AutoRoute(path: "/test", page: MyTestPage),
    AutoRoute(path: "/readbook", page: EpubPage),
    AutoRoute(path: "/asset", page: AssetPage),
    AutoRoute(path: "/contractor", page: ContractorPage),
  ],
)
class $AppRouter {}
