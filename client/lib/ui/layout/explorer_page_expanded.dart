import 'package:flutter/material.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:phylum/ui/layout/nav_list.dart';
import 'package:phylum/ui/layout/responsive.dart';
import 'package:phylum/ui/layout/search.dart';
import 'package:phylum/ui/layout/sync_status_button.dart';
import 'package:phylum/ui/profile/profile_dialog.dart';
import 'package:phylum/ui/profile/profile_view.dart';

class ExplorerPageExpanded extends StatelessWidget {
  const ExplorerPageExpanded({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final leftBarWidth = width >= minViewportWidthXLarge ? 288.0 : 240.0;
    final rightBarWidth = width >= minViewportWidthXLarge
        ? 360.0
        : width >= minViewportWidthLarge
        ? 300.0
        : 0.0;

    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: leftBarWidth,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: const LogoRow(),
                ),
              ),
              const Expanded(
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: Icon(Icons.search),
                        ),
                        Expanded(child: SearchField()),
                      ],
                    ),
                  ),
                ),
              ),
              if (rightBarWidth != 0)
                SizedBox(
                  width: rightBarWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SyncStatusButton(),
                      ProfileView(onTap: () => ProfileDialog.show(context)),
                    ],
                  ),
                ),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: leftBarWidth,
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(left: 16, bottom: 16),
                    child: ExcludeFocusTraversal(child: NavList(drawer: false)),
                  ),
                ),
                Expanded(
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: const ExplorerView(),
                  ),
                ),
                if (rightBarWidth != 0)
                  SizedBox(
                    width: rightBarWidth,
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(right: 16, bottom: 16),
                      child: ReactiveResourceInfoView(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
