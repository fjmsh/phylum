import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/breakpoints.dart';
import 'package:phylum/ui/explorer/properties/resource_details_view.dart';
import 'package:phylum/ui/explorer/properties/resource_permissions_view.dart';
import 'package:phylum/ui/explorer/properties/resource_publinks_view.dart';
import 'package:phylum/ui/explorer/properties/resource_versions_view.dart';
import 'package:provider/provider.dart';

const tabOverview = 1;
const tabPermissions = 1;
const tabPublinks = 2;
const tabVersions = 3;

class ResourcePropertiesDialog extends StatelessWidget {
  final Resource resource;

  const ResourcePropertiesDialog({super.key, required this.resource});

  static void show(
    BuildContext context,
    Resource resource, [
    int selectedTab = tabOverview,
  ]) {
    final account = context.read<PhylumAccount>();
    showDialog(
      context: context,
      builder: (context) => MultiProvider(
        providers: [
          Provider.value(value: account),
          Provider.value(value: account.actionQueue),
        ],
        child: DefaultTabController(
          length: 4,
          initialIndex: selectedTab,
          child: ResourcePropertiesDialog(resource: resource),
        ),
      ),
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > maxViewportWidthXSmall) {
      return FocusScope(
        autofocus: true,
        child: Dialog(
          child: SizedBox(
            width: 560,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      resource.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  buildTabs(context),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(
                            child: ResourceInfoView(resource: resource),
                          ),
                          SingleChildScrollView(
                            child: ResourcePermissionsView(
                              resourceId: resource.id,
                            ),
                          ),
                          SingleChildScrollView(
                            child: ResourcePublinksView(resource: resource),
                          ),
                          SingleChildScrollView(
                            child: ResourceVersionsView(
                              resourceId: resource.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: .end,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Done'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(resource.name), bottom: buildTabs(context)),
      // body: buildTabs(context),
    );
  }

  TabBar buildTabs(BuildContext context) {
    return TabBar.secondary(
      tabs: [
        Tab(child: Text('Overview')),
        Tab(child: Text('Permissions')),
        Tab(child: Text('Publinks')),
        Tab(child: Text('Versions')),
      ],
    );
  }
}
