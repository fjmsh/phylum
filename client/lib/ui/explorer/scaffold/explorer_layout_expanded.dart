import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/common/breakpoints.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/scaffold/downloads_icon_button.dart';
import 'package:phylum/ui/explorer/scaffold/nav_sidebar.dart';
import 'package:phylum/ui/explorer/scaffold/reactive_resource_info_view.dart';
import 'package:phylum/ui/explorer/scaffold/search/search.dart';
import 'package:phylum/ui/explorer/scaffold/sync/sync_status_button.dart';

class ExplorerLayoutExpanded extends StatelessWidget {
  final FocusNode _explorerFocusNode;

  const ExplorerLayoutExpanded({super.key, required this._explorerFocusNode});

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
              Expanded(
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
                        Expanded(
                          child: SearchField(
                            explorerFocusNode: _explorerFocusNode,
                          ),
                        ),
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
                      if (!kIsWeb) const DownloadsIconButton(),
                      const SyncStatusButton(),
                      // ProfileView(onTap: () => ProfileDialog.show(context)),
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
                  child: ExcludeFocusTraversal(child: const NavSidebar()),
                ),
                Expanded(
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: ExplorerView(
                      explorerFocusNode: _explorerFocusNode,
                      showSelectedItems: true,
                    ),
                  ),
                ),
                if (rightBarWidth != 0)
                  SizedBox(
                    width: rightBarWidth,
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(right: 16, bottom: 16),
                      child: ExcludeFocusTraversal(
                        child: const ReactiveResourceInfoView(),
                      ),
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
