import 'package:flutter/material.dart';

class LazyRoutes {
  static final Map<String, WidgetBuilder> _routeCache = {};

  static void register(String routeName, WidgetBuilder builder) {
    _routeCache[routeName] = builder;
  }

  static WidgetBuilder? getBuilder(String routeName) {
    return _routeCache[routeName];
  }

  static Future<T?> push<T>(BuildContext context, String routeName, {Object? arguments}) async {
    final builder = _routeCache[routeName];
    if (builder == null) throw Exception('Rota $routeName não registrada');

    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: builder,
        settings: RouteSettings(name: routeName, arguments: arguments),
      ),
    );
  }

  static void clearUnusedRoutes(List<String> activeRoutes) {
    _routeCache.removeWhere((key, value) => !activeRoutes.contains(key));
  }
}

class LazyFeature extends StatefulWidget {
  final Future<Widget> Function() loader;
  final Widget? placeholder;

  const LazyFeature({super.key, required this.loader, this.placeholder});

  @override
  State<LazyFeature> createState() => _LazyFeatureState();
}

class _LazyFeatureState extends State<LazyFeature> {
  Widget? _loadedWidget;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadFeature();
  }

  Future<void> _loadFeature() async {
    try {
      final loadedWidget = await widget.loader();
      if (mounted) {
        setState(() {
          _loadedWidget = loadedWidget;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Erro ao carregar: $_error'));
    }
    return _loadedWidget!;
  }
}