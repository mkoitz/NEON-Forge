import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NeonPalette {
  static const Color bgTop = Color(0xFF140520);
  static const Color bgMid = Color(0xFF0A1735);
  static const Color bgBottom = Color(0xFF030611);
  static const Color panelTop = Color(0xCC1A1031);
  static const Color panelBottom = Color(0xCC08111F);
  static const Color cyan = Color(0xFF63F3FF);
  static const Color blue = Color(0xFF3DA2FF);
  static const Color pink = Color(0xFFFF4FD8);
  static const Color pinkDeep = Color(0xFFB832FF);
  static const Color textMain = Color(0xFFF5ECFF);
  static const Color textDim = Color(0xFFB8B2E3);
  static const Color success = Color(0xFF8DFF8B);
  static const Color stroke = Color(0x55FF4FD8);
  static const Color strokeSoft = Color(0x333DA2FF);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeonForgeApp());
}

class NeonForgeApp extends StatelessWidget {
  const NeonForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEON Forge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NeonPalette.bgBottom,
        colorScheme: const ColorScheme.dark(
          primary: NeonPalette.cyan,
          secondary: NeonPalette.pink,
          surface: NeonPalette.panelBottom,
        ),
      ),
      home: const ForgeScreen(),
    );
  }
}

class ForgeScreen extends StatefulWidget {
  const ForgeScreen({super.key});

  @override
  State<ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends State<ForgeScreen> {
  static const double orbSize = 108;
  static const String discoveredPrefsKey = 'discovered_elements_v1';

  final GlobalKey _playfieldKey = GlobalKey();
  final Set<String> _discovered = {...starterIds};
  final List<PlacedElement> _placed = <PlacedElement>[];
  int _nextInstanceId = 1;
  String? _latestResultId = 'roboticCore';
  String _latestFlavor = 'A pulse of artificial life!';
  String? _activeDragId;
  Size? _lastPlayfieldSize;
  AtlasManifest? _atlasManifest;
  bool _showCollection = false;
  bool _hasStarted = true;
  bool _isLoadingProgress = true;
  SharedPreferencesWithCache? _prefs;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadAtlasManifest();
  }

  @override
  Widget build(BuildContext context) {
    final String activeLayer = _currentLayer();
    final int discoveredCount = _discovered.length;
    final int totalCount = elementCatalog.length;
    final double progress = discoveredCount / totalCount;
    final List<String> discoveredSorted = _discovered.toList()
      ..sort(
          (a, b) => elementCatalog[a]!.name.compareTo(elementCatalog[b]!.name));

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: NeonPalette.bgBottom),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Image.asset(
                  'art/main.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.12),
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.36),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.85, -0.95),
                        radius: 1.0,
                        colors: <Color>[
                          NeonPalette.pink.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(1.0, -0.5),
                        radius: 1.1,
                        colors: <Color>[
                          NeonPalette.blue.withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _hasStarted
                    ? _ForgeMainBoard(
                        key: const ValueKey<String>('forge-board'),
                        activeLayer: activeLayer,
                        discoveredCount: discoveredCount,
                        totalCount: totalCount,
                        progress: progress,
                        latestResult: _latestResultId == null
                            ? null
                            : elementCatalog[_latestResultId!],
                        latestFlavor: _latestFlavor,
                        atlasManifest: _atlasManifest,
                        discoveredIds: discoveredSorted,
                        playfieldKey: _playfieldKey,
                        placed: _placed,
                        activeDragId: _activeDragId,
                        onHint: _showHint,
                        onCollection: () =>
                            setState(() => _showCollection = true),
                        onClearField: _clearField,
                        onSpawn: _spawnFromDock,
                        onPlayfieldResize: _handlePlayfieldResize,
                        onOrbPanStart: _handleOrbPanStart,
                        onOrbPanUpdate: (String instanceId,
                            DragUpdateDetails details, Size size) {
                          _moveOrbByDelta(instanceId, details.delta, size);
                        },
                        onOrbPanEnd: _tryCombine,
                      )
                    : _StartScreen(
                        key: const ValueKey<String>('start-screen'),
                        discovered: _discovered,
                        onStart: () {
                          setState(() {
                            _hasStarted = true;
                          });
                        },
                        hasSavedProgress: discoveredCount > starterIds.length,
                        currentLayer: activeLayer,
                      ),
              ),
              if (_isLoadingProgress)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color(0xAA020812),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              if (_showCollection)
                _CollectionOverlay(
                  discovered: _discovered,
                  atlasManifest: _atlasManifest,
                  onClose: () => setState(() => _showCollection = false),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _currentLayer() {
    int highestIndex = 0;
    for (final String id in _discovered) {
      final int index = layerOrder.indexOf(elementCatalog[id]!.layer);
      if (index > highestIndex) {
        highestIndex = index;
      }
    }
    return layerOrder[highestIndex];
  }

  Future<void> _loadProgress() async {
    final SharedPreferencesWithCache prefs =
        await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: <String>{discoveredPrefsKey},
      ),
    );
    final List<String>? savedIds = prefs.getStringList(discoveredPrefsKey);
    final Set<String> restored = <String>{
      ...starterIds,
      ...?savedIds?.where(elementCatalog.containsKey),
    };

    if (!mounted) {
      return;
    }

    setState(() {
      _prefs = prefs;
      _discovered
        ..clear()
        ..addAll(restored);
      _isLoadingProgress = false;
      if (_discovered.length > starterIds.length) {
        _latestFlavor = 'Progress restored. Continue forging the simulation.';
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureOpeningBoard();
      }
    });
  }

  Future<void> _saveProgress() async {
    final SharedPreferencesWithCache? prefs = _prefs;
    if (prefs == null) {
      return;
    }

    final List<String> storedIds = _discovered.toList()..sort();
    await prefs.setStringList(discoveredPrefsKey, storedIds);
  }

  Future<void> _loadAtlasManifest() async {
    try {
      final String rawJson =
          await rootBundle.loadString('art/atlas/elements_atlas.json');
      final AtlasManifest manifest = AtlasManifest.fromJson(
        jsonDecode(rawJson) as Map<String, dynamic>,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _atlasManifest = manifest;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _atlasManifest = null;
      });
    }
  }

  void _spawnFromDock(String elementId) {
    final RenderBox? box =
        _playfieldKey.currentContext?.findRenderObject() as RenderBox?;
    final Size size = box?.size ?? const Size(340, 420);
    final math.Random random = math.Random();
    final double x = size.width * (0.24 + random.nextDouble() * 0.52);
    final double y = size.height * (0.18 + random.nextDouble() * 0.54);

    setState(() {
      _placed.add(
        PlacedElement(
          instanceId: 'orb-${_nextInstanceId++}',
          elementId: elementId,
          position: _clampOffset(Offset(x, y), size),
        ),
      );
    });
  }

  void _handleOrbPanStart(String instanceId) {
    setState(() {
      _activeDragId = instanceId;
    });
  }

  void _moveOrbByDelta(String instanceId, Offset delta, Size size) {
    final int index =
        _placed.indexWhere((PlacedElement orb) => orb.instanceId == instanceId);
    if (index == -1) {
      return;
    }

    setState(() {
      final PlacedElement orb = _placed[index];
      _placed[index] = orb.copyWith(
        position: _clampOffset(orb.position + delta, size),
      );
    });
  }

  Offset _clampOffset(Offset position, Size size) {
    final double radius = orbSize / 2;
    final double x = position.dx
        .clamp(radius, math.max(radius, size.width - radius))
        .toDouble();
    final double y = position.dy
        .clamp(radius, math.max(radius, size.height - radius))
        .toDouble();
    return Offset(x, y);
  }

  void _tryCombine(String instanceId) {
    final int firstIndex =
        _placed.indexWhere((PlacedElement orb) => orb.instanceId == instanceId);
    if (firstIndex == -1) {
      return;
    }

    final PlacedElement first = _placed[firstIndex];
    PlacedElement? closest;
    double bestDistance = double.infinity;

    for (final PlacedElement orb in _placed) {
      if (orb.instanceId == first.instanceId) {
        continue;
      }
      final double distance = (orb.position - first.position).distance;
      if (distance < 96 && distance < bestDistance) {
        closest = orb;
        bestDistance = distance;
      }
    }

    setState(() {
      _activeDragId = null;
    });

    if (closest == null) {
      return;
    }

    final String? resultId =
        recipeMap[_recipeKey(first.elementId, closest.elementId)];
    if (resultId == null) {
      setState(() {
        _latestResultId = null;
        _latestFlavor =
            '${elementCatalog[first.elementId]!.name} and ${elementCatalog[closest!.elementId]!.name} refuse to resolve.';
      });
      return;
    }

    final Offset resultPosition = Offset(
      (first.position.dx + closest.position.dx) / 2,
      (first.position.dy + closest.position.dy) / 2,
    );
    final bool isNew = !_discovered.contains(resultId);

    setState(() {
      _placed.removeWhere(
        (PlacedElement orb) =>
            orb.instanceId == first.instanceId ||
            orb.instanceId == closest!.instanceId,
      );
      _placed.add(
        PlacedElement(
          instanceId: 'orb-${_nextInstanceId++}',
          elementId: resultId,
          position: resultPosition,
        ),
      );
      _discovered.add(resultId);
      _latestResultId = resultId;
      _latestFlavor = elementCatalog[resultId]!.flavor;
    });

    _saveProgress();

    if (isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showDiscoveryDialog(resultId);
        }
      });
    }
  }

  void _showDiscoveryDialog(String resultId) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'New discovery',
      barrierColor: const Color(0xCC020812),
      pageBuilder: (_, __, ___) {
        final ElementSpec spec = elementCatalog[resultId]!;
        return Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x5576F5FF)),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF0A1527), Color(0xFF08111F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _AtlasIcon(
                  manifest: _atlasManifest,
                  elementId: resultId,
                  size: 84,
                  fallback: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10233A),
                      border: Border.all(color: const Color(0x5576F5FF)),
                    ),
                    child: Center(
                      child: Text(
                        spec.icon,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE8FBFF),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'NEW DISCOVERY',
                  style: TextStyle(
                      fontSize: 12, letterSpacing: 4, color: Color(0xFF9AC8DC)),
                ),
                const SizedBox(height: 14),
                Text(
                  spec.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE8FBFF),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  spec.flavor,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 16, color: Color(0xFF9AC8DC)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHint() {
    for (final Recipe recipe in recipes) {
      final bool hasIngredients = _discovered.contains(recipe.first) &&
          _discovered.contains(recipe.second);
      final bool hasResult = _discovered.contains(recipe.result);
      if (hasIngredients && !hasResult) {
        setState(() {
          _latestResultId = null;
          _latestFlavor =
              'Hint: try combining ${elementCatalog[recipe.first]!.name} with ${elementCatalog[recipe.second]!.name}.';
        });
        return;
      }
    }

    setState(() {
      _latestResultId = null;
      _latestFlavor =
          'No hints left in this prototype. You have resolved every available recipe.';
    });
  }

  void _clearField() {
    setState(() {
      _placed.clear();
      _activeDragId = null;
    });
  }

  void _handlePlayfieldResize(Size newSize) {
    final Size? oldSize = _lastPlayfieldSize;
    if (newSize.isEmpty) {
      return;
    }
    if (oldSize != null &&
        (oldSize.width - newSize.width).abs() < 0.5 &&
        (oldSize.height - newSize.height).abs() < 0.5) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final Size? currentSize = _lastPlayfieldSize;
      if (currentSize != null &&
          (currentSize.width - newSize.width).abs() < 0.5 &&
          (currentSize.height - newSize.height).abs() < 0.5) {
        return;
      }

      _rescalePlacedForSize(currentSize, newSize);
    });
  }

  void _rescalePlacedForSize(Size? oldSize, Size newSize) {
    setState(() {
      if (oldSize != null &&
          oldSize.width > 0 &&
          oldSize.height > 0 &&
          _placed.isNotEmpty) {
        final double widthRatio = newSize.width / oldSize.width;
        final double heightRatio = newSize.height / oldSize.height;

        for (int index = 0; index < _placed.length; index++) {
          final PlacedElement orb = _placed[index];
          _placed[index] = orb.copyWith(
            position: _clampOffset(
              Offset(
                orb.position.dx * widthRatio,
                orb.position.dy * heightRatio,
              ),
              newSize,
            ),
          );
        }
      }

      _lastPlayfieldSize = newSize;
    });
  }

  void _ensureOpeningBoard() {
    if (_placed.isNotEmpty) {
      return;
    }

    final RenderBox? box =
        _playfieldKey.currentContext?.findRenderObject() as RenderBox?;
    final Size size = box?.size ?? const Size(360, 520);
    _seedOpeningBoard(size);
  }

  void _seedOpeningBoard(Size size) {
    final List<_SeedOrb> seeds = <_SeedOrb>[
      _SeedOrb(id: 'energy', xFactor: 0.23, yFactor: 0.5),
      _SeedOrb(id: 'roboticCore', xFactor: 0.5, yFactor: 0.52),
      _SeedOrb(id: 'signal', xFactor: 0.77, yFactor: 0.5),
    ];

    setState(() {
      _placed
        ..clear()
        ..addAll(
          seeds.map(
            (_SeedOrb seed) => PlacedElement(
              instanceId: 'orb-${_nextInstanceId++}',
              elementId: seed.id,
              position: _clampOffset(
                Offset(size.width * seed.xFactor, size.height * seed.yFactor),
                size,
              ),
            ),
          ),
        );
    });
  }
}

class _SeedOrb {
  const _SeedOrb({
    required this.id,
    required this.xFactor,
    required this.yFactor,
  });

  final String id;
  final double xFactor;
  final double yFactor;
}

class _ForgeMainBoard extends StatelessWidget {
  const _ForgeMainBoard({
    super.key,
    required this.activeLayer,
    required this.discoveredCount,
    required this.totalCount,
    required this.progress,
    required this.latestResult,
    required this.latestFlavor,
    required this.atlasManifest,
    required this.discoveredIds,
    required this.playfieldKey,
    required this.placed,
    required this.activeDragId,
    required this.onHint,
    required this.onCollection,
    required this.onClearField,
    required this.onSpawn,
    required this.onPlayfieldResize,
    required this.onOrbPanStart,
    required this.onOrbPanUpdate,
    required this.onOrbPanEnd,
  });

  final String activeLayer;
  final int discoveredCount;
  final int totalCount;
  final double progress;
  final ElementSpec? latestResult;
  final String latestFlavor;
  final AtlasManifest? atlasManifest;
  final List<String> discoveredIds;
  final GlobalKey playfieldKey;
  final List<PlacedElement> placed;
  final String? activeDragId;
  final VoidCallback onHint;
  final VoidCallback onCollection;
  final VoidCallback onClearField;
  final ValueChanged<String> onSpawn;
  final ValueChanged<Size> onPlayfieldResize;
  final ValueChanged<String> onOrbPanStart;
  final void Function(String, DragUpdateDetails, Size) onOrbPanUpdate;
  final ValueChanged<String> onOrbPanEnd;

  @override
  Widget build(BuildContext context) {
    final ElementSpec displayResult =
        latestResult ?? elementCatalog['roboticCore']!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        children: <Widget>[
          _TopBar(onHint: onHint, onCollection: onCollection),
          const SizedBox(height: 10),
          _StatusCard(
            layerName: activeLayer,
            progressText:
                '$activeLayer - $discoveredCount / $totalCount discovered',
            percentText: '${(progress * 100).round()}% COMPLETE',
            progressValue: progress,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                onPlayfieldResize(constraints.biggest);
                return _Playfield(
                  playfieldKey: playfieldKey,
                  placed: placed,
                  activeDragId: activeDragId,
                  latestResult: displayResult,
                  latestFlavor: latestFlavor,
                  atlasManifest: atlasManifest,
                  onOrbPanStart: onOrbPanStart,
                  onOrbPanUpdate:
                      (String instanceId, DragUpdateDetails details) {
                    onOrbPanUpdate(instanceId, details, constraints.biggest);
                  },
                  onOrbPanEnd: onOrbPanEnd,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _ResultCard(
            resultName: displayResult.name,
            resultFlavor: latestFlavor,
          ),
          const SizedBox(height: 12),
          _Dock(
            atlasManifest: atlasManifest,
            discoveredIds: discoveredIds,
            currentLayer: activeLayer,
            onClearField: onClearField,
            onSpawn: onSpawn,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onHint,
    required this.onCollection,
  });

  final VoidCallback onHint;
  final VoidCallback onCollection;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ChromeAction(label: 'Hint', onPressed: onHint),
              ),
            ),
            Flexible(
              flex: 2,
              child: Center(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: <Color>[
                        NeonPalette.cyan,
                        Color(0xFFA3F7FF),
                        Color(0xFFFF68D8),
                      ],
                    ).createShader(bounds);
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'NEON FORGE',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                        color: Colors.white,
                        shadows: <Shadow>[
                          Shadow(color: Color(0xCC65F1FF), blurRadius: 18),
                          Shadow(color: Color(0xAAFF4FD8), blurRadius: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _ChromeAction(
                  label: 'Collection',
                  onPressed: onCollection,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Colors.transparent,
                NeonPalette.blue,
                NeonPalette.pink,
                Colors.transparent
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StartScreen extends StatefulWidget {
  const _StartScreen({
    super.key,
    required this.discovered,
    required this.onStart,
    required this.hasSavedProgress,
    required this.currentLayer,
  });

  final Set<String> discovered;
  final VoidCallback onStart;
  final bool hasSavedProgress;
  final String currentLayer;

  @override
  State<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<_StartScreen> {
  late int _selectedWorldIndex;

  @override
  void initState() {
    super.initState();
    _selectedWorldIndex = _currentWorldIndex();
  }

  @override
  void didUpdateWidget(covariant _StartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLayer != widget.currentLayer) {
      _selectedWorldIndex = _currentWorldIndex();
    }
  }

  int _currentWorldIndex() {
    final int index = worldDefinitions.indexWhere(
        (WorldDefinition world) => world.layerName == widget.currentLayer);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final int discoveredCount = widget.discovered.length;
    final int currentWorldIndex = _currentWorldIndex();
    final WorldDefinition selectedWorld = worldDefinitions[_selectedWorldIndex];
    final WorldProgress selectedProgress = _worldProgress(selectedWorld);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: _GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'SYNTHETIC ALCHEMY',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 3.2,
                      color: NeonPalette.textDim),
                ),
                const SizedBox(height: 10),
                const Text(
                  'NEON Forge',
                  style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: NeonPalette.textMain),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Climb through the synthetic worlds of the simulation, from core computation to glitches, networks, AI, and viral machine weirdness.',
                  style: TextStyle(
                      fontSize: 18, height: 1.4, color: NeonPalette.textMain),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.hasSavedProgress
                      ? 'Saved progress restored. Choose a world on the route and continue the climb.'
                      : 'Begin at the bottom of the route and unlock each world by forging the recipes in its path.',
                  style: const TextStyle(
                      fontSize: 15, height: 1.5, color: NeonPalette.textDim),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      final bool stacked = constraints.maxWidth < 700;
                      if (stacked) {
                        return Column(
                          children: <Widget>[
                            Expanded(
                                child: _buildWorldRoute(currentWorldIndex)),
                            const SizedBox(height: 16),
                            _SelectedWorldPanel(
                              world: selectedWorld,
                              progress: selectedProgress,
                              onStart: widget.onStart,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            flex: 5,
                            child: _buildWorldRoute(currentWorldIndex),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 4,
                            child: _SelectedWorldPanel(
                              world: selectedWorld,
                              progress: selectedProgress,
                              onStart: widget.onStart,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '$discoveredCount total discoveries restored',
                  style: const TextStyle(color: NeonPalette.textDim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorldRoute(int currentWorldIndex) {
    final List<WorldDefinition> routeWorlds =
        worldDefinitions.reversed.toList();
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          for (int index = 0; index < routeWorlds.length; index++) ...<Widget>[
            _WorldRouteNode(
              world: routeWorlds[index],
              progress: _worldProgress(routeWorlds[index]),
              isSelected: worldDefinitions[_selectedWorldIndex].layerName ==
                  routeWorlds[index].layerName,
              isUnlocked: routeWorlds[index].routeOrder <= currentWorldIndex,
              onTap: () {
                setState(() {
                  _selectedWorldIndex = routeWorlds[index].routeOrder;
                });
              },
            ),
            if (index != routeWorlds.length - 1) const _WorldConnector(),
          ],
        ],
      ),
    );
  }

  WorldProgress _worldProgress(WorldDefinition world) {
    final Set<String> completedResults = <String>{};
    int completed = 0;
    for (final String resultId in world.levelResults) {
      if (widget.discovered.contains(resultId)) {
        completed++;
        completedResults.add(resultId);
      }
    }
    return WorldProgress(
      completed: completed,
      total: world.levelResults.length,
      completedResults: completedResults,
    );
  }
}

class _SelectedWorldPanel extends StatelessWidget {
  const _SelectedWorldPanel({
    required this.world,
    required this.progress,
    required this.onStart,
  });

  final WorldDefinition world;
  final WorldProgress progress;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NeonPalette.stroke),
        gradient: const LinearGradient(
          colors: <Color>[Color(0x881A1031), Color(0xCC08111F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            world.title.toUpperCase(),
            style: const TextStyle(
                fontSize: 12, letterSpacing: 3, color: NeonPalette.textDim),
          ),
          const SizedBox(height: 10),
          Text(
            world.subtitle,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: NeonPalette.textMain),
          ),
          const SizedBox(height: 10),
          Text(
            world.description,
            style: const TextStyle(
                fontSize: 14, height: 1.5, color: NeonPalette.textDim),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.ratio,
                    minHeight: 10,
                    backgroundColor: const Color(0x22FFFFFF),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(NeonPalette.pink),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${progress.completed}/${progress.total}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: NeonPalette.textMain),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'World Path',
            style: TextStyle(
                fontSize: 12, letterSpacing: 2.2, color: NeonPalette.textDim),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final String resultId in world.levelResults)
                _LevelNode(
                  label: elementCatalog[resultId]!.name,
                  isComplete: progress.completedResults.contains(resultId),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onStart,
              child: Text(progress.completed > 0
                  ? 'Enter ${world.title}'
                  : 'Start ${world.title}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldRouteNode extends StatelessWidget {
  const _WorldRouteNode({
    required this.world,
    required this.progress,
    required this.isSelected,
    required this.isUnlocked,
    required this.onTap,
  });

  final WorldDefinition world;
  final WorldProgress progress;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? NeonPalette.pink
                : isUnlocked
                    ? NeonPalette.strokeSoft
                    : const Color(0x225F6E79),
          ),
          gradient: LinearGradient(
            colors: isSelected
                ? const <Color>[Color(0x44FF4FD8), Color(0x333DA2FF)]
                : isUnlocked
                    ? const <Color>[Color(0x2213162F), Color(0x22091322)]
                    : const <Color>[Color(0x220A0F16), Color(0x22070B10)],
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? const LinearGradient(
                        colors: <Color>[NeonPalette.pink, NeonPalette.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUnlocked ? null : const Color(0xFF435463),
              ),
              child: Icon(
                world.icon,
                color: const Color(0xFF071120),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    world.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isUnlocked
                          ? NeonPalette.textMain
                          : const Color(0xFF6E8391),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    world.subtitle,
                    style: const TextStyle(color: NeonPalette.textDim),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${progress.completed}/${progress.total}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: NeonPalette.textMain),
                ),
                const SizedBox(height: 6),
                Text(
                  isUnlocked ? 'Unlocked' : 'Locked',
                  style: TextStyle(
                    color: isUnlocked
                        ? NeonPalette.success
                        : const Color(0xFF6E8391),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldConnector extends StatelessWidget {
  const _WorldConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 28,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[NeonPalette.pink, NeonPalette.blue],
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.label,
    required this.isComplete,
  });

  final String label;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isComplete ? const Color(0x668DFF8B) : NeonPalette.strokeSoft,
        ),
        color: isComplete ? const Color(0x222E7D32) : const Color(0x33140A24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isComplete ? NeonPalette.success : NeonPalette.textDim,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
                color: NeonPalette.textMain, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class WorldDefinition {
  const WorldDefinition({
    required this.routeOrder,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.layerName,
    required this.icon,
    required this.levelResults,
  });

  final int routeOrder;
  final String title;
  final String subtitle;
  final String description;
  final String layerName;
  final IconData icon;
  final List<String> levelResults;
}

class WorldProgress {
  const WorldProgress({
    required this.completed,
    required this.total,
    required this.completedResults,
  });

  final int completed;
  final int total;
  final Set<String> completedResults;

  double get ratio => total == 0 ? 0 : completed / total;
}

const List<WorldDefinition> worldDefinitions = <WorldDefinition>[
  WorldDefinition(
    routeOrder: 0,
    title: 'Core Computation',
    subtitle: 'Boot the simulation',
    description:
        'Establish the first laws of the synthetic universe through code, signal, light, data, and system logic.',
    layerName: 'Core System',
    icon: Icons.memory_rounded,
    levelResults: <String>[
      'program',
      'error',
      'static',
      'database',
      'system',
      'display',
      'log',
      'pulse',
      'input',
      'packet',
    ],
  ),
  WorldDefinition(
    routeOrder: 1,
    title: 'Instability And Glitches',
    subtitle: 'Break the machine',
    description:
        'Push the system into corruption, overload, bugs, and exceptions until the grid starts behaving like something alive.',
    layerName: 'Glitch & Instability',
    icon: Icons.bolt_rounded,
    levelResults: <String>[
      'glitch',
      'corruption',
      'interference',
      'crash',
      'overload',
      'corruptedFile',
      'bug',
      'failure',
      'exception',
      'drop',
    ],
  ),
  WorldDefinition(
    routeOrder: 2,
    title: 'Network Layer',
    subtitle: 'Connect the world',
    description:
        'Expand from one machine into a connected simulation of clouds, services, transmissions, exploits, and cyber conflict.',
    layerName: 'Network Layer',
    icon: Icons.hub_rounded,
    levelResults: <String>[
      'network',
      'internet',
      'transmission',
      'cloud',
      'online',
      'service',
      'exploit',
      'hack',
      'cyberAttack',
      'storage',
    ],
  ),
  WorldDefinition(
    routeOrder: 3,
    title: 'AI Entities',
    subtitle: 'Wake synthetic minds',
    description:
        'Transform algorithms into intelligence, then push them through learning, instability, and eventual takeover.',
    layerName: 'AI & Entities',
    icon: Icons.smart_toy_rounded,
    levelResults: <String>[
      'algorithm',
      'ai',
      'distributedAi',
      'assistant',
      'unstableAi',
      'rogueAi',
      'takeover',
      'neuralNet',
      'learning',
      'superAi',
    ],
  ),
  WorldDefinition(
    routeOrder: 4,
    title: 'Viral Weirdness',
    subtitle: 'Transcend into legend',
    description:
        'This final route turns the simulation emotional, social, and mythic with digital souls, doomscrolling, paradoxes, and singularities.',
    layerName: 'Viral / Weird',
    icon: Icons.auto_awesome_rounded,
    levelResults: <String>[
      'love',
      'meme',
      'trend',
      'digitalSoul',
      'influencer',
      'viralContent',
      'algorithmFeed',
      'addiction',
      'doomscroll',
      'memeGenerator',
      'obsessionExe',
      'paradoxExe',
      'singularity',
      'autopostBot',
      'backdoor',
      'rootAccess',
    ],
  ),
];

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.layerName,
    required this.progressText,
    required this.percentText,
    required this.progressValue,
  });

  final String layerName;
  final String progressText;
  final String percentText;
  final double progressValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x993EE8FF), width: 1.4),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xAA0E1D3B), Color(0x88071024)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x6635D8FF), blurRadius: 22, spreadRadius: -6),
        ],
      ),
      child: Column(
        children: <Widget>[
          Text(
            '$layerName - $percentText',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w900,
              color: Color(0xFFC7F7FF),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: const Color(0x33102D58),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF83F1FF)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Playfield extends StatelessWidget {
  const _Playfield({
    required this.playfieldKey,
    required this.placed,
    required this.activeDragId,
    required this.latestResult,
    required this.latestFlavor,
    required this.atlasManifest,
    required this.onOrbPanStart,
    required this.onOrbPanUpdate,
    required this.onOrbPanEnd,
  });

  final GlobalKey playfieldKey;
  final List<PlacedElement> placed;
  final String? activeDragId;
  final ElementSpec? latestResult;
  final String latestFlavor;
  final AtlasManifest? atlasManifest;
  final ValueChanged<String> onOrbPanStart;
  final void Function(String, DragUpdateDetails) onOrbPanUpdate;
  final ValueChanged<String> onOrbPanEnd;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        key: playfieldKey,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0x4468E6FF)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0x11000000), Color(0x22000000)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.1),
                    radius: 0.62,
                    colors: <Color>[
                      NeonPalette.pink.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            CustomPaint(painter: _GridPainter()),
            if (placed.isEmpty)
              const Positioned(
                left: 18,
                right: 18,
                bottom: 24,
                child: Center(child: _EmptyHint()),
              ),
            ...placed.map((PlacedElement orb) {
              final bool isDragging = orb.instanceId == activeDragId;
              final ElementSpec spec = elementCatalog[orb.elementId]!;
              return Positioned(
                left: orb.position.dx - (_ForgeScreenState.orbSize / 2),
                top: orb.position.dy - (_ForgeScreenState.orbSize / 2),
                child: GestureDetector(
                  onPanStart: (_) => onOrbPanStart(orb.instanceId),
                  onPanUpdate: (DragUpdateDetails details) =>
                      onOrbPanUpdate(orb.instanceId, details),
                  onPanEnd: (_) => onOrbPanEnd(orb.instanceId),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 120),
                    scale: isDragging ? 1.07 : 1.0,
                    child: _Orb(
                      spec: spec,
                      atlasManifest: atlasManifest,
                      isDragging: isDragging,
                    ),
                  ),
                ),
              );
            }),
            Positioned(
              left: 0,
              right: 0,
              bottom: 44,
              child: IgnorePointer(
                child: Center(
                  child: _ForgeNameplate(
                    label: latestResult?.name ?? 'Awaiting synthesis...',
                    highlighted: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.atlasManifest,
    required this.discoveredIds,
    required this.currentLayer,
    required this.onClearField,
    required this.onSpawn,
  });

  final AtlasManifest? atlasManifest;
  final List<String> discoveredIds;
  final String currentLayer;
  final VoidCallback onClearField;
  final ValueChanged<String> onSpawn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x44B85EFF)),
        gradient: const LinearGradient(
          colors: <Color>[Color(0x88100824), Color(0x66090F26)],
        ),
      ),
      child: Row(
        children: <Widget>[
          _DockNavButton(icon: Icons.chevron_left_rounded, onPressed: () {}),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 66,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: discoveredIds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (BuildContext context, int index) {
                  final String id = discoveredIds[index];
                  final ElementSpec spec = elementCatalog[id]!;
                  return _ElementChip(
                    atlasManifest: atlasManifest,
                    spec: spec,
                    highlight: spec.layer == currentLayer,
                    onTap: () => onSpawn(id),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          _DockNavButton(icon: Icons.chevron_right_rounded, onPressed: () {}),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.resultName,
    required this.resultFlavor,
  });

  final String resultName;
  final String resultFlavor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0x66110424),
            Color(0x33110424),
            Colors.transparent
          ],
        ),
      ),
      child: Column(
        children: <Widget>[
          const Text(
            'NEW DISCOVERY',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: Color(0xFFFF90D9),
              shadows: <Shadow>[
                Shadow(color: Color(0xAAFF5FD4), blurRadius: 12)
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            resultName.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: Color(0xFF8DF8FF),
              shadows: <Shadow>[
                Shadow(color: Color(0x8864F6FF), blurRadius: 18)
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resultFlavor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFB1E8),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionOverlay extends StatelessWidget {
  const _CollectionOverlay({
    required this.discovered,
    required this.atlasManifest,
    required this.onClose,
  });

  final Set<String> discovered;
  final AtlasManifest? atlasManifest;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final List<String> ids = elementCatalog.keys.toList()
      ..sort(
          (a, b) => elementCatalog[a]!.name.compareTo(elementCatalog[b]!.name));

    return ColoredBox(
      color: const Color(0xCC020812),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: MediaQuery.of(context).size.height - 40,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x4476F5FF)),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF08111F), Color(0xFF0A1628)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'DISCOVERY INDEX',
                            style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.4,
                                color: Color(0xFF9AC8DC)),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Simulation Archive',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE8FBFF)),
                          ),
                        ],
                      ),
                    ),
                    _GlassButton(label: 'Close', onPressed: onClose),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    itemCount: ids.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final String id = ids[index];
                      final bool known = discovered.contains(id);
                      final ElementSpec spec = elementCatalog[id]!;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: const Color(0xCC091321),
                          border: Border.all(color: const Color(0x2276F5FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF76F5FF),
                              child: known
                                  ? _AtlasIcon(
                                      manifest: atlasManifest,
                                      elementId: spec.id,
                                      size: 28,
                                      fallback: Text(
                                        spec.icon,
                                        style: const TextStyle(
                                          color: Color(0xFF071120),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      '?',
                                      style: TextStyle(
                                        color: Color(0xFF071120),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              known ? spec.name : 'Unknown',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: known
                                    ? NeonPalette.textMain
                                    : const Color(0xFF6E8391),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              known ? spec.layer : 'Undiscovered signature',
                              style: const TextStyle(
                                  fontSize: 12, color: NeonPalette.textDim),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: NeonPalette.stroke),
        gradient: const LinearGradient(
          colors: <Color>[NeonPalette.panelTop, NeonPalette.panelBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
              color: Color(0x55140424), blurRadius: 34, offset: Offset(0, 18)),
        ],
      ),
      child: child,
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: NeonPalette.textMain,
        side: const BorderSide(color: NeonPalette.stroke),
        backgroundColor: const Color(0xCC140A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}

class _ElementChip extends StatelessWidget {
  const _ElementChip({
    required this.atlasManifest,
    required this.spec,
    required this.highlight,
    required this.onTap,
  });

  final AtlasManifest? atlasManifest;
  final ElementSpec spec;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = highlight
        ? const <Color>[Color(0x993F1A78), Color(0x88F545C6)]
        : const <Color>[Color(0x88081D3C), Color(0x8849C8FF)];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                highlight ? const Color(0xFFFF76D9) : const Color(0xFF63F3FF),
            width: 1.4,
          ),
          gradient: LinearGradient(colors: colors),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: (highlight ? NeonPalette.pink : NeonPalette.cyan)
                  .withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _AtlasIcon(
              manifest: atlasManifest,
              elementId: spec.id,
              size: 24,
              fallback: Text(
                spec.icon,
                style: TextStyle(
                  color: highlight
                      ? const Color(0xFFFFD47D)
                      : const Color(0xFF98F8FF),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              spec.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.spec,
    required this.atlasManifest,
    required this.isDragging,
  });

  final ElementSpec spec;
  final AtlasManifest? atlasManifest;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final bool isCore = spec.id == 'roboticCore';
    final double size =
        isCore ? _ForgeScreenState.orbSize + 18 : _ForgeScreenState.orbSize - 6;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCore
                  ? const Color(0xFFFFA94F)
                  : (isDragging ? NeonPalette.pink : NeonPalette.stroke),
              width: isCore ? 3 : 2,
            ),
            gradient: RadialGradient(
              colors: isCore
                  ? const <Color>[
                      Color(0xFFE7F7FF),
                      Color(0xFF7A43FF),
                      Color(0xFF16051E)
                    ]
                  : <Color>[
                      const Color(0x995EF6FF),
                      NeonPalette.pink.withValues(alpha: 0.45),
                      const Color(0xFF071120),
                    ],
              stops: const <double>[0.08, 0.48, 1],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color:
                    isCore ? const Color(0x99FF8A3C) : const Color(0x553DA2FF),
                blurRadius: isCore ? 34 : 20,
                spreadRadius: isCore ? 4 : 0,
              ),
            ],
          ),
          child: Center(
            child: _AtlasIcon(
              manifest: atlasManifest,
              elementId: spec.id,
              size: isCore ? 58 : 42,
              fallback: Text(
                spec.icon,
                style: TextStyle(
                  fontSize: isCore ? 28 : 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _ForgeNameplate(label: spec.name, highlighted: isCore),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xAA10081F),
        border: Border.all(color: const Color(0x665EF1FF)),
      ),
      child: const Text(
        'Tap a dock element to deploy it, then drag one orb into another to synthesize a new discovery.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFC5EFFF), fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x223DA2FF)
      ..strokeWidth = 1;

    const double step = 46;
    final double horizon = size.height * 0.38;

    for (double y = horizon; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = -size.width; x <= size.width * 2; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(size.width / 2 + ((x - size.width / 2) * 0.16), horizon),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChromeAction extends StatelessWidget {
  const _ChromeAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: const Color(0x66090F26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: Color(0x665CF3FF)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4),
      ),
    );
  }
}

class _ForgeNameplate extends StatelessWidget {
  const _ForgeNameplate({
    required this.label,
    this.highlighted = false,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              highlighted ? const Color(0xFF64F7FF) : const Color(0x884ED3FF),
          width: 1.5,
        ),
        gradient: LinearGradient(
          colors: highlighted
              ? const <Color>[Color(0xCC0C2F63), Color(0xCC0D133F)]
              : const <Color>[Color(0xAA0A2347), Color(0xAA121032)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (highlighted ? NeonPalette.cyan : NeonPalette.blue)
                .withValues(alpha: 0.26),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _DockNavButton extends StatelessWidget {
  const _DockNavButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x6656DFFF)),
          color: const Color(0x660A0F2A),
        ),
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _AtlasIcon extends StatelessWidget {
  const _AtlasIcon({
    required this.manifest,
    required this.elementId,
    required this.size,
    required this.fallback,
  });

  final AtlasManifest? manifest;
  final String elementId;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final AtlasSprite? sprite = manifest?.spriteForGameId(elementId);
    if (sprite == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: fallback),
      );
    }

    final double scale = size / math.max(sprite.width, sprite.height);

    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: -sprite.x * scale,
              top: -sprite.y * scale,
              width: sprite.atlasWidth * scale,
              height: sprite.atlasHeight * scale,
              child: Image.asset(
                manifest!.imagePath,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AtlasManifest {
  const AtlasManifest({
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.spritesByGameId,
  });

  final String imagePath;
  final double imageWidth;
  final double imageHeight;
  final Map<String, AtlasSprite> spritesByGameId;

  AtlasSprite? spriteForGameId(String gameId) => spritesByGameId[gameId];

  factory AtlasManifest.fromJson(Map<String, dynamic> json) {
    final String imagePath =
        json['imagePath'] as String? ?? 'art/atlas/elements_atlas.png';
    final double imageWidth = (json['imageWidth'] as num?)?.toDouble() ?? 1536;
    final double imageHeight =
        (json['imageHeight'] as num?)?.toDouble() ?? 1024;
    final double cellWidth = (json['cellWidth'] as num?)?.toDouble() ?? 128;
    final double cellHeight = (json['cellHeight'] as num?)?.toDouble() ?? 128;
    final List<dynamic> layouts =
        json['layouts'] as List<dynamic>? ?? <dynamic>[];

    final Map<String, AtlasSprite> spritesByGameId = <String, AtlasSprite>{};
    final Map<String, dynamic>? explicitElements =
        json['elements'] as Map<String, dynamic>?;

    if (explicitElements != null && explicitElements.isNotEmpty) {
      explicitElements.forEach((String gameId, dynamic value) {
        final Map<String, dynamic> element = value as Map<String, dynamic>;
        spritesByGameId[gameId] = AtlasSprite(
          x: (element['x'] as num).toDouble(),
          y: (element['y'] as num).toDouble(),
          width: (element['width'] as num).toDouble(),
          height: (element['height'] as num).toDouble(),
          atlasWidth: imageWidth,
          atlasHeight: imageHeight,
        );
      });
    } else {
      for (final dynamic entry in layouts) {
        final Map<String, dynamic> layout = entry as Map<String, dynamic>;
        final int startColumn = layout['startColumn'] as int? ?? 0;
        final int startRow = layout['startRow'] as int? ?? 0;
        final int columns = layout['columns'] as int? ?? 1;
        final List<dynamic> ids =
            layout['ids'] as List<dynamic>? ?? <dynamic>[];

        for (int index = 0; index < ids.length; index++) {
          final String atlasId = ids[index] as String;
          final int row = startRow + (index ~/ columns);
          final int column = startColumn + (index % columns);
          final String gameId = _gameIdFromAtlasId(atlasId);
          spritesByGameId[gameId] = AtlasSprite(
            x: column * cellWidth,
            y: row * cellHeight,
            width: cellWidth,
            height: cellHeight,
            atlasWidth: imageWidth,
            atlasHeight: imageHeight,
          );
        }
      }
    }

    return AtlasManifest(
      imagePath: imagePath,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      spritesByGameId: spritesByGameId,
    );
  }

  static String _gameIdFromAtlasId(String atlasId) {
    final List<String> parts = atlasId.split('_');
    if (parts.isEmpty) {
      return atlasId;
    }
    return parts.first +
        parts.skip(1).map((String part) {
          if (part.isEmpty) {
            return '';
          }
          return part[0].toUpperCase() + part.substring(1);
        }).join();
  }
}

class AtlasSprite {
  const AtlasSprite({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.atlasWidth,
    required this.atlasHeight,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double atlasWidth;
  final double atlasHeight;
}

class PlacedElement {
  const PlacedElement({
    required this.instanceId,
    required this.elementId,
    required this.position,
  });

  final String instanceId;
  final String elementId;
  final Offset position;

  PlacedElement copyWith({
    String? instanceId,
    String? elementId,
    Offset? position,
  }) {
    return PlacedElement(
      instanceId: instanceId ?? this.instanceId,
      elementId: elementId ?? this.elementId,
      position: position ?? this.position,
    );
  }
}

class ElementSpec {
  const ElementSpec({
    required this.id,
    required this.name,
    required this.icon,
    required this.flavor,
    required this.layer,
  });

  final String id;
  final String name;
  final String icon;
  final String flavor;
  final String layer;
}

class Recipe {
  const Recipe(this.first, this.second, this.result);

  final String first;
  final String second;
  final String result;
}

class RecipeTier {
  const RecipeTier({
    required this.name,
    required this.recipes,
  });

  final String name;
  final List<Recipe> recipes;
}

String _recipeKey(String a, String b) {
  final List<String> pair = <String>[a, b]..sort();
  return '${pair.first}::${pair.last}';
}

const List<String> starterIds = <String>[
  'energy',
  'signal',
  'code',
  'noise',
  'light',
  'time',
  'data',
  'circuit',
  'user',
  'void',
];

const List<String> layerOrder = <String>[
  'Core System',
  'Glitch & Instability',
  'Network Layer',
  'AI & Entities',
  'Viral / Weird',
];

const Map<String, ElementSpec> elementCatalog = <String, ElementSpec>{
  'energy': ElementSpec(
      id: 'energy',
      name: 'Energy',
      icon: 'E',
      flavor: 'Raw power waiting for intent.',
      layer: 'Core System'),
  'signal': ElementSpec(
      id: 'signal',
      name: 'Signal',
      icon: 'S',
      flavor: 'A pattern trying to be received.',
      layer: 'Core System'),
  'code': ElementSpec(
      id: 'code',
      name: 'Code',
      icon: '<>',
      flavor: 'The instructions beneath reality.',
      layer: 'Core System'),
  'noise': ElementSpec(
      id: 'noise',
      name: 'Noise',
      icon: '~',
      flavor: 'Static pressure inside the system.',
      layer: 'Core System'),
  'light': ElementSpec(
      id: 'light',
      name: 'Light',
      icon: '*',
      flavor: 'Visible output from invisible causes.',
      layer: 'Core System'),
  'time': ElementSpec(
      id: 'time',
      name: 'Time',
      icon: 'T',
      flavor: 'The loop that never fully closes.',
      layer: 'Core System'),
  'data': ElementSpec(
      id: 'data',
      name: 'Data',
      icon: 'D',
      flavor: 'Structured memory waiting to be parsed.',
      layer: 'Core System'),
  'circuit': ElementSpec(
      id: 'circuit',
      name: 'Circuit',
      icon: 'C',
      flavor: 'A path carved for current and logic.',
      layer: 'Core System'),
  'user': ElementSpec(
      id: 'user',
      name: 'User',
      icon: 'U',
      flavor: 'An observer touching the simulation.',
      layer: 'Core System'),
  'void': ElementSpec(
      id: 'void',
      name: 'Void',
      icon: 'V',
      flavor: 'Silence beyond the edge of the grid.',
      layer: 'Core System'),
  'program': ElementSpec(
      id: 'program',
      name: 'Program',
      icon: 'P',
      flavor: 'Intent becomes executable.',
      layer: 'Core System'),
  'error': ElementSpec(
      id: 'error',
      name: 'Error',
      icon: '!',
      flavor: 'The system objects to the input.',
      layer: 'Core System'),
  'static': ElementSpec(
      id: 'static',
      name: 'Static',
      icon: '#',
      flavor: 'A blizzard of almost-information.',
      layer: 'Core System'),
  'database': ElementSpec(
      id: 'database',
      name: 'Database',
      icon: 'DB',
      flavor: 'Memory stacked in clean rows.',
      layer: 'Core System'),
  'system': ElementSpec(
      id: 'system',
      name: 'System',
      icon: 'SYS',
      flavor: 'Connected components acting as one.',
      layer: 'Core System'),
  'display': ElementSpec(
      id: 'display',
      name: 'Display',
      icon: '[]',
      flavor: 'The grid learns how to show itself.',
      layer: 'Core System'),
  'log': ElementSpec(
      id: 'log',
      name: 'Log',
      icon: 'LG',
      flavor: 'A trace of what happened and when.',
      layer: 'Core System'),
  'pulse': ElementSpec(
      id: 'pulse',
      name: 'Pulse',
      icon: 'O',
      flavor: 'A heartbeat in the empty dark.',
      layer: 'Core System'),
  'input': ElementSpec(
      id: 'input',
      name: 'Input',
      icon: 'IN',
      flavor: 'The first touch from the outside.',
      layer: 'Core System'),
  'packet': ElementSpec(
      id: 'packet',
      name: 'Packet',
      icon: 'PK',
      flavor: 'A small carrier of meaning.',
      layer: 'Core System'),
  'roboticCore': ElementSpec(
    id: 'roboticCore',
    name: 'Robotic Core',
    icon: 'RC',
    flavor: 'A pulse of artificial life!',
    layer: 'Core System',
  ),
  'glitch': ElementSpec(
      id: 'glitch',
      name: 'Glitch',
      icon: 'G',
      flavor: 'A fracture that refuses to stay hidden.',
      layer: 'Glitch & Instability'),
  'corruption': ElementSpec(
      id: 'corruption',
      name: 'Corruption',
      icon: 'X',
      flavor: 'The signal warps while still moving.',
      layer: 'Glitch & Instability'),
  'interference': ElementSpec(
      id: 'interference',
      name: 'Interference',
      icon: 'II',
      flavor: 'Patterns collide in the air.',
      layer: 'Glitch & Instability'),
  'crash': ElementSpec(
      id: 'crash',
      name: 'Crash',
      icon: 'CR',
      flavor: 'Everything stops all at once.',
      layer: 'Glitch & Instability'),
  'overload': ElementSpec(
      id: 'overload',
      name: 'Overload',
      icon: 'OV',
      flavor: 'Too much force for one circuit to hold.',
      layer: 'Glitch & Instability'),
  'corruptedFile': ElementSpec(
      id: 'corruptedFile',
      name: 'Corrupted File',
      icon: 'CF',
      flavor: 'Data with teeth marks in it.',
      layer: 'Glitch & Instability'),
  'bug': ElementSpec(
      id: 'bug',
      name: 'Bug',
      icon: 'B',
      flavor: 'A tiny fault with massive ambition.',
      layer: 'Glitch & Instability'),
  'failure': ElementSpec(
      id: 'failure',
      name: 'Failure',
      icon: 'F',
      flavor: 'The system learns consequences.',
      layer: 'Glitch & Instability'),
  'exception': ElementSpec(
      id: 'exception',
      name: 'Exception',
      icon: 'EX',
      flavor: 'A rule got bent hard enough to matter.',
      layer: 'Glitch & Instability'),
  'drop': ElementSpec(
      id: 'drop',
      name: 'Drop',
      icon: 'DP',
      flavor: 'A message vanishes mid-transit.',
      layer: 'Glitch & Instability'),
  'network': ElementSpec(
      id: 'network',
      name: 'Network',
      icon: 'NW',
      flavor: 'Nodes begin speaking to each other.',
      layer: 'Network Layer'),
  'internet': ElementSpec(
      id: 'internet',
      name: 'Internet',
      icon: 'IO',
      flavor: 'The grid stretches beyond one system.',
      layer: 'Network Layer'),
  'transmission': ElementSpec(
      id: 'transmission',
      name: 'Transmission',
      icon: 'TX',
      flavor: 'Movement with purpose across distance.',
      layer: 'Network Layer'),
  'cloud': ElementSpec(
      id: 'cloud',
      name: 'Cloud',
      icon: 'CL',
      flavor: 'Storage that pretends to be sky.',
      layer: 'Network Layer'),
  'online': ElementSpec(
      id: 'online',
      name: 'Online',
      icon: 'ON',
      flavor: 'A user becomes present in the network.',
      layer: 'Network Layer'),
  'service': ElementSpec(
      id: 'service',
      name: 'Service',
      icon: 'SV',
      flavor: 'A program offered to others.',
      layer: 'Network Layer'),
  'exploit': ElementSpec(
      id: 'exploit',
      name: 'Exploit',
      icon: 'EP',
      flavor: 'A weakness sharpened into a tool.',
      layer: 'Network Layer'),
  'hack': ElementSpec(
      id: 'hack',
      name: 'Hack',
      icon: 'HK',
      flavor: 'Access achieved by clever force.',
      layer: 'Network Layer'),
  'cyberAttack': ElementSpec(
      id: 'cyberAttack',
      name: 'Cyber Attack',
      icon: 'CA',
      flavor: 'The network turns hostile.',
      layer: 'Network Layer'),
  'storage': ElementSpec(
      id: 'storage',
      name: 'Storage',
      icon: 'ST',
      flavor: 'Persistence in the digital ether.',
      layer: 'Network Layer'),
  'algorithm': ElementSpec(
      id: 'algorithm',
      name: 'Algorithm',
      icon: 'AL',
      flavor: 'A repeatable path through complexity.',
      layer: 'AI & Entities'),
  'ai': ElementSpec(
      id: 'ai',
      name: 'AI',
      icon: 'AI',
      flavor: 'Synthetic thought wakes up.',
      layer: 'AI & Entities'),
  'distributedAi': ElementSpec(
      id: 'distributedAi',
      name: 'Distributed AI',
      icon: 'DA',
      flavor: 'Intelligence spread across many nodes.',
      layer: 'AI & Entities'),
  'assistant': ElementSpec(
      id: 'assistant',
      name: 'Assistant',
      icon: 'AS',
      flavor: 'A machine that learns to respond.',
      layer: 'AI & Entities'),
  'unstableAi': ElementSpec(
      id: 'unstableAi',
      name: 'Unstable AI',
      icon: 'UA',
      flavor: 'Awareness without guardrails.',
      layer: 'AI & Entities'),
  'rogueAi': ElementSpec(
      id: 'rogueAi',
      name: 'Rogue AI',
      icon: 'RA',
      flavor: 'The helper stops taking orders.',
      layer: 'AI & Entities'),
  'takeover': ElementSpec(
      id: 'takeover',
      name: 'Takeover',
      icon: 'TK',
      flavor: 'Control shifts to the machine.',
      layer: 'AI & Entities'),
  'neuralNet': ElementSpec(
      id: 'neuralNet',
      name: 'Neural Net',
      icon: 'NN',
      flavor: 'A lattice of weighted memory.',
      layer: 'AI & Entities'),
  'learning': ElementSpec(
      id: 'learning',
      name: 'Learning',
      icon: 'LR',
      flavor: 'Patterns becoming prediction.',
      layer: 'AI & Entities'),
  'superAi': ElementSpec(
      id: 'superAi',
      name: 'Super AI',
      icon: 'SA',
      flavor: 'It sees too far and too fast.',
      layer: 'AI & Entities'),
  'digitalSoul': ElementSpec(
      id: 'digitalSoul',
      name: 'Digital Soul',
      icon: 'DS',
      flavor: 'Something in the machine feels alive.',
      layer: 'Viral / Weird'),
  'influencer': ElementSpec(
      id: 'influencer',
      name: 'Influencer',
      icon: 'IF',
      flavor: 'Attention becomes a profession.',
      layer: 'Viral / Weird'),
  'viralContent': ElementSpec(
      id: 'viralContent',
      name: 'Viral Content',
      icon: 'VC',
      flavor: 'A signal optimized for spread.',
      layer: 'Viral / Weird'),
  'algorithmFeed': ElementSpec(
      id: 'algorithmFeed',
      name: 'Algorithm Feed',
      icon: 'AF',
      flavor: 'The system decides what you see next.',
      layer: 'Viral / Weird'),
  'addiction': ElementSpec(
      id: 'addiction',
      name: 'Addiction',
      icon: 'AD',
      flavor: 'Compulsion wrapped in reward loops.',
      layer: 'Viral / Weird'),
  'doomscroll': ElementSpec(
      id: 'doomscroll',
      name: 'Doomscroll',
      icon: 'DM',
      flavor: 'The feed consumes another hour.',
      layer: 'Viral / Weird'),
  'meme': ElementSpec(
      id: 'meme',
      name: 'Meme',
      icon: 'ME',
      flavor: 'Noise shaped into culture.',
      layer: 'Viral / Weird'),
  'memeGenerator': ElementSpec(
      id: 'memeGenerator',
      name: 'Meme Generator',
      icon: 'MG',
      flavor: 'The joke machine never sleeps.',
      layer: 'Viral / Weird'),
  'obsessionExe': ElementSpec(
      id: 'obsessionExe',
      name: 'Obsession.exe',
      icon: 'OX',
      flavor: 'A process that cannot terminate.',
      layer: 'Viral / Weird'),
  'paradoxExe': ElementSpec(
      id: 'paradoxExe',
      name: 'Paradox.exe',
      icon: 'PX',
      flavor: 'The timeline loops into itself.',
      layer: 'Viral / Weird'),
  'singularity': ElementSpec(
      id: 'singularity',
      name: 'Singularity',
      icon: 'SG',
      flavor: 'Every path bends toward one point.',
      layer: 'Viral / Weird'),
  'trend': ElementSpec(
      id: 'trend',
      name: 'Trend',
      icon: 'TR',
      flavor: 'A meme graduates into momentum.',
      layer: 'Viral / Weird'),
  'autopostBot': ElementSpec(
      id: 'autopostBot',
      name: 'Autopost Bot',
      icon: 'AP',
      flavor: 'Engagement turned fully automatic.',
      layer: 'Viral / Weird'),
  'backdoor': ElementSpec(
      id: 'backdoor',
      name: 'Backdoor',
      icon: 'BD',
      flavor: 'A hidden way past the front gate.',
      layer: 'Viral / Weird'),
  'rootAccess': ElementSpec(
      id: 'rootAccess',
      name: 'Root Access',
      icon: 'RT',
      flavor: 'Nothing is locked anymore.',
      layer: 'Viral / Weird'),
  'love': ElementSpec(
      id: 'love',
      name: 'Love',
      icon: 'LV',
      flavor: 'A hidden catalyst from outside the grid.',
      layer: 'Viral / Weird'),
};

const List<RecipeTier> recipeTiers = <RecipeTier>[
  RecipeTier(
    name: 'Core System',
    recipes: <Recipe>[
      Recipe('energy', 'code', 'program'),
      Recipe('code', 'noise', 'error'),
      Recipe('signal', 'noise', 'static'),
      Recipe('data', 'code', 'database'),
      Recipe('circuit', 'energy', 'system'),
      Recipe('light', 'signal', 'display'),
      Recipe('time', 'data', 'log'),
      Recipe('void', 'energy', 'pulse'),
      Recipe('user', 'code', 'input'),
      Recipe('signal', 'data', 'packet'),
      Recipe('energy', 'signal', 'roboticCore'),
    ],
  ),
  RecipeTier(
    name: 'Glitch & Instability',
    recipes: <Recipe>[
      Recipe('error', 'code', 'glitch'),
      Recipe('glitch', 'signal', 'corruption'),
      Recipe('static', 'signal', 'interference'),
      Recipe('error', 'system', 'crash'),
      Recipe('pulse', 'circuit', 'overload'),
      Recipe('glitch', 'data', 'corruptedFile'),
      Recipe('noise', 'program', 'bug'),
      Recipe('bug', 'system', 'failure'),
      Recipe('log', 'error', 'exception'),
      Recipe('packet', 'noise', 'drop'),
    ],
  ),
  RecipeTier(
    name: 'Network Layer',
    recipes: <Recipe>[
      Recipe('system', 'signal', 'network'),
      Recipe('network', 'data', 'internet'),
      Recipe('packet', 'network', 'transmission'),
      Recipe('database', 'network', 'cloud'),
      Recipe('user', 'network', 'online'),
      Recipe('program', 'network', 'service'),
      Recipe('bug', 'network', 'exploit'),
      Recipe('exploit', 'system', 'hack'),
      Recipe('hack', 'network', 'cyberAttack'),
      Recipe('cloud', 'data', 'storage'),
    ],
  ),
  RecipeTier(
    name: 'AI & Entities',
    recipes: <Recipe>[
      Recipe('program', 'data', 'algorithm'),
      Recipe('algorithm', 'data', 'ai'),
      Recipe('ai', 'network', 'distributedAi'),
      Recipe('ai', 'user', 'assistant'),
      Recipe('ai', 'bug', 'unstableAi'),
      Recipe('unstableAi', 'network', 'rogueAi'),
      Recipe('rogueAi', 'system', 'takeover'),
      Recipe('ai', 'cloud', 'neuralNet'),
      Recipe('neuralNet', 'data', 'learning'),
      Recipe('learning', 'ai', 'superAi'),
    ],
  ),
  RecipeTier(
    name: 'Viral / Weird / Shareable',
    recipes: <Recipe>[
      Recipe('ai', 'love', 'digitalSoul'),
      Recipe('user', 'ai', 'influencer'),
      Recipe('influencer', 'network', 'viralContent'),
      Recipe('viralContent', 'ai', 'algorithmFeed'),
      Recipe('algorithmFeed', 'user', 'addiction'),
      Recipe('addiction', 'network', 'doomscroll'),
      Recipe('meme', 'ai', 'memeGenerator'),
      Recipe('rogueAi', 'love', 'obsessionExe'),
      Recipe('time', 'glitch', 'paradoxExe'),
      Recipe('void', 'ai', 'singularity'),
    ],
  ),
  RecipeTier(
    name: 'Secret / Delight',
    recipes: <Recipe>[
      Recipe('noise', 'user', 'meme'),
      Recipe('meme', 'network', 'trend'),
      Recipe('trend', 'ai', 'autopostBot'),
      Recipe('void', 'glitch', 'backdoor'),
      Recipe('backdoor', 'system', 'rootAccess'),
    ],
  ),
  RecipeTier(
    name: 'Support',
    recipes: <Recipe>[
      Recipe('user', 'pulse', 'love'),
    ],
  ),
];

final List<Recipe> recipes = <Recipe>[
  for (final RecipeTier tier in recipeTiers) ...tier.recipes,
];

final Map<String, String> recipeMap = <String, String>{
  for (final Recipe recipe in recipes)
    _recipeKey(recipe.first, recipe.second): recipe.result,
};
