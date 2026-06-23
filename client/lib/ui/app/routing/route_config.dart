part of 'router.dart';

class PhylumRouteConfig {
  Uri get uri => Uri(
    path: stack.last.uri.path,
    queryParameters: {
      if (next != null && next != const HomeRoute())
        'next': next!.uri.path.toString(),
    },
  );

  final List<PhylumRoute> stack;
  final PhylumRoute? next;

  const PhylumRouteConfig._({required this.stack, this.next});

  PhylumRouteConfig._empty()
    : this._(stack: [const HomeRoute()], next: const HomeRoute());

  // PhylumRouteConfig copyWith({List<PhylumRoute>? stack, PhylumRoute? next}) =>
  //     PhylumRouteConfig._(stack: stack ?? this.stack, next: next ?? this.next);
}
