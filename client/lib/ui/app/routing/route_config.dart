part of 'router.dart';

class PhylumRouteConfig {
  Uri get uri => Uri(
    path: route.uri.path,
    queryParameters: {
      if (next != null && next != const HomeRoute())
        'next': next!.uri.path.toString(),
    },
  );

  final PhylumRoute route;
  final PhylumRoute? base;
  final PhylumRoute? next;

  const PhylumRouteConfig._({required this.route, this.next, this.base});

  PhylumRouteConfig._empty()
    : this._(route: const HomeRoute(), next: const HomeRoute());

  // PhylumRouteConfig copyWith({List<PhylumRoute>? stack, PhylumRoute? next}) =>
  //     PhylumRouteConfig._(stack: stack ?? this.stack, next: next ?? this.next);
}
