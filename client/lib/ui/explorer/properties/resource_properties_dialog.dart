import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/breakpoints.dart';
import 'package:phylum/ui/explorer/properties/resource_details_view.dart';
import 'package:phylum/ui/explorer/properties/resource_permissions_view.dart';
import 'package:phylum/ui/explorer/properties/resource_publinks_view.dart';
import 'package:phylum/ui/explorer/properties/resource_versions_view.dart';
import 'package:provider/provider.dart';

const tabDetails = 0;
const tabPermissions = 1;
const tabPublinks = 2;
const tabVersions = 3;

class ResourcePropertiesDialog extends StatelessWidget {
  final Resource resource;

  const ResourcePropertiesDialog({super.key, required this.resource});

  static void show(
    BuildContext context,
    Resource resource, [
    int selectedTab = tabDetails,
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
          length: resource.dir ? 3 : 4,
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
            height: 900,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: .max,
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
                      padding: const EdgeInsets.all(12),
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(
                            child: ResourceInfoView(
                              resource: resource,
                              onPermissionsTap: () {
                                DefaultTabController.of(
                                  context,
                                ).animateTo(tabPermissions);
                              },
                              onPublinksTap: () {
                                DefaultTabController.of(
                                  context,
                                ).animateTo(tabPublinks);
                              },
                              onVersionsTap: () {
                                DefaultTabController.of(
                                  context,
                                ).animateTo(tabVersions);
                              },
                            ),
                          ),
                          ResourcePermissionsView(resourceId: resource.id),
                          ResourcePublinksView(resource: resource),
                          if (!resource.dir)
                            ResourceVersionsView(resourceId: resource.id),
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
      body: TabBarView(
        children: [
          SingleChildScrollView(
            child: ResourceInfoView(
              resource: resource,
              onPermissionsTap: () {
                DefaultTabController.of(context).animateTo(tabPermissions);
              },
              onPublinksTap: () {
                DefaultTabController.of(context).animateTo(tabPublinks);
              },
              onVersionsTap: () {
                DefaultTabController.of(context).animateTo(tabVersions);
              },
            ),
          ),
          ResourcePermissionsView(resourceId: resource.id),
          ResourcePublinksView(resource: resource),
          if (!resource.dir) ResourceVersionsView(resourceId: resource.id),
        ],
      ),
      // body: buildTabs(context),
    );
  }

  TabBar buildTabs(BuildContext context) {
    final scrollable = MediaQuery.sizeOf(context).width < maxViewportWidthSmall;
    return TabBar.secondary(
      isScrollable: scrollable,
      tabAlignment: scrollable ? TabAlignment.center : TabAlignment.fill,
      tabs: [
        const Tab(
          child: Row(
            mainAxisSize: .min,
            spacing: 6,
            children: [Icon(Icons.info_outline, size: 16), Text('Overview')],
          ),
        ),
        const Tab(
          child: Row(
            mainAxisSize: .min,
            spacing: 6,
            children: [
              Icon(Icons.people_alt_outlined, size: 16),
              Text('Permissions'),
            ],
          ),
        ),
        const Tab(
          child: Row(
            mainAxisSize: .min,
            spacing: 6,
            children: [
              Icon(Icons.public_outlined, size: 16),
              Text('Public Share'),
            ],
          ),
        ),
        if (!resource.dir)
          const Tab(
            child: Row(
              mainAxisSize: .min,
              spacing: 6,
              children: [
                Icon(Icons.history_outlined, size: 16),
                Text('Versions'),
              ],
            ),
          ),
      ],
    );
  }
}
