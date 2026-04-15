import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFF040814),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF76F5FF),
          secondary: Color(0xFFFF53C9),
          surface: Color(0xFF091321),
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

  final GlobalKey _playfieldKey = GlobalKey();
  final Set<String> _discovered = {...starterIds};
  final List<PlacedElement> _placed = <PlacedElement>[];
  int _nextInstanceId = 1;
  String? _latestResultId = starterIds.first;
  String _latestFlavor = 'The forge is primed. Drag a starter element into the field to begin.';
  String? _activeDragId;
  bool _showCollection = false;

  @override
  Widget build(BuildContext context) {
    final String activeLayer = _currentLayer();
    final int discoveredCount = _discovered.length;
    final int totalCount = elementCatalog.length;
    final double progress = discoveredCount / totalCount;
    final List<String> discoveredSorted = _discovered.toList()
      ..sort((a, b) => elementCatalog[a]!.name.compareTo(elementCatalog[b]!.name));

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF050B18), Color(0xFF091120), Color(0xFF040814)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: _TopBar(
                      onHint: _showHint,
                      onCollection: () => setState(() => _showCollection = true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _StatusCard(
                      layerName: activeLayer,
                      progressText: '$discoveredCount / $totalCount discovered',
                      percentText: '${(progress * 100).round()}%',
                      progressValue: progress,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return _Playfield(
                            playfieldKey: _playfieldKey,
                            placed: _placed,
                            activeDragId: _activeDragId,
                            latestResult: _latestResultId == null ? null : elementCatalog[_latestResultId!],
                            latestFlavor: _latestFlavor,
                            onOrbPanStart: _handleOrbPanStart,
                            onOrbPanUpdate: (String instanceId, DragUpdateDetails details) {
                              _moveOrbByDelta(instanceId, details.delta, constraints.biggest);
                            },
                            onOrbPanEnd: (String instanceId) => _tryCombine(instanceId),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ResultCard(
                      resultName: _latestResultId == null
                          ? 'Awaiting synthesis...'
                          : elementCatalog[_latestResultId!]!.name,
                      resultFlavor: _latestFlavor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: _Dock(
                      discoveredIds: discoveredSorted,
                      currentLayer: activeLayer,
                      onClearField: _clearField,
                      onSpawn: _spawnFromDock,
                    ),
                  ),
                ],
              ),
              if (_showCollection)
                _CollectionOverlay(
                  discovered: _discovered,
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

  void _spawnFromDock(String elementId) {
    final RenderBox? box = _playfieldKey.currentContext?.findRenderObject() as RenderBox?;
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
    final int index = _placed.indexWhere((PlacedElement orb) => orb.instanceId == instanceId);
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
    final double x = position.dx.clamp(radius, math.max(radius, size.width - radius)).toDouble();
    final double y = position.dy.clamp(radius, math.max(radius, size.height - radius)).toDouble();
    return Offset(x, y);
  }

  void _tryCombine(String instanceId) {
    final int firstIndex = _placed.indexWhere((PlacedElement orb) => orb.instanceId == instanceId);
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

    final String? resultId = recipeMap[_recipeKey(first.elementId, closest.elementId)];
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
        (PlacedElement orb) => orb.instanceId == first.instanceId || orb.instanceId == closest!.instanceId,
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
                const Text(
                  'NEW DISCOVERY',
                  style: TextStyle(fontSize: 12, letterSpacing: 4, color: Color(0xFF9AC8DC)),
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
                  style: const TextStyle(fontSize: 16, color: Color(0xFF9AC8DC)),
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
      final bool hasIngredients =
          _discovered.contains(recipe.first) && _discovered.contains(recipe.second);
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
      _latestFlavor = 'No hints left in this prototype. You have resolved every available recipe.';
    });
  }

  void _clearField() {
    setState(() {
      _placed.clear();
      _activeDragId = null;
    });
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
    return Row(
      children: <Widget>[
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Synthetic Alchemy Prototype',
                style: TextStyle(fontSize: 12, letterSpacing: 2.8, color: Color(0xFF9AC8DC)),
              ),
              SizedBox(height: 6),
              Text(
                'NEON Forge',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFFE8FBFF)),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          children: <Widget>[
            _GlassButton(label: 'Hint', onPressed: onHint),
            _GlassButton(label: 'Collection', onPressed: onCollection),
          ],
        ),
      ],
    );
  }
}

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
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'SIMULATION LAYER',
                      style: TextStyle(fontSize: 11, letterSpacing: 2.4, color: Color(0xFF9AC8DC)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      layerName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFE8FBFF)),
                    ),
                  ],
                ),
              ),
              Text(
                percentText,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF76F5FF)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(progressText, style: const TextStyle(color: Color(0xFF9AC8DC))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 12,
              backgroundColor: const Color(0x22FFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF76F5FF)),
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
    required this.onOrbPanStart,
    required this.onOrbPanUpdate,
    required this.onOrbPanEnd,
  });

  final GlobalKey playfieldKey;
  final List<PlacedElement> placed;
  final String? activeDragId;
  final ElementSpec? latestResult;
  final String latestFlavor;
  final ValueChanged<String> onOrbPanStart;
  final void Function(String, DragUpdateDetails) onOrbPanUpdate;
  final ValueChanged<String> onOrbPanEnd;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          key: playfieldKey,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF071120), Color(0xFF060B14)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CustomPaint(painter: _GridPainter()),
              if (placed.isEmpty)
                const Positioned(right: 18, bottom: 18, child: _EmptyHint()),
              ...placed.map((PlacedElement orb) {
                final bool isDragging = orb.instanceId == activeDragId;
                final ElementSpec spec = elementCatalog[orb.elementId]!;
                return Positioned(
                  left: orb.position.dx - (_ForgeScreenState.orbSize / 2),
                  top: orb.position.dy - (_ForgeScreenState.orbSize / 2),
                  child: GestureDetector(
                    onPanStart: (_) => onOrbPanStart(orb.instanceId),
                    onPanUpdate: (DragUpdateDetails details) => onOrbPanUpdate(orb.instanceId, details),
                    onPanEnd: (_) => onOrbPanEnd(orb.instanceId),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 120),
                      scale: isDragging ? 1.07 : 1.0,
                      child: _Orb(spec: spec, isDragging: isDragging),
                    ),
                  ),
                );
              }),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: const Color(0xCC06111D),
                      border: Border.all(color: const Color(0x2276F5FF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'LATEST RESULT',
                          style: TextStyle(fontSize: 11, letterSpacing: 2.2, color: Color(0xFF9AC8DC)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          latestResult?.name ?? 'Awaiting synthesis...',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFE8FBFF)),
                        ),
                        const SizedBox(height: 4),
                        Text(latestFlavor, style: const TextStyle(color: Color(0xFF9AC8DC))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.discoveredIds,
    required this.currentLayer,
    required this.onClearField,
    required this.onSpawn,
  });

  final List<String> discoveredIds;
  final String currentLayer;
  final VoidCallback onClearField;
  final ValueChanged<String> onSpawn;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'FORGE ELEMENTS',
                      style: TextStyle(fontSize: 11, letterSpacing: 2.4, color: Color(0xFF9AC8DC)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Discovered Library',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFE8FBFF)),
                    ),
                  ],
                ),
              ),
              _GlassButton(label: 'Clear Field', onPressed: onClearField),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: discoveredIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                final String id = discoveredIds[index];
                final ElementSpec spec = elementCatalog[id]!;
                return _ElementChip(
                  spec: spec,
                  highlight: spec.layer == currentLayer,
                  onTap: () => onSpawn(id),
                );
              },
            ),
          ),
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
    return _GlassPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'RESULT FEED',
                  style: TextStyle(fontSize: 11, letterSpacing: 2.4, color: Color(0xFF9AC8DC)),
                ),
                const SizedBox(height: 6),
                Text(
                  resultName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFE8FBFF)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              resultFlavor,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF9AC8DC)),
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
    required this.onClose,
  });

  final Set<String> discovered;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final List<String> ids = elementCatalog.keys.toList()
      ..sort((a, b) => elementCatalog[a]!.name.compareTo(elementCatalog[b]!.name));

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
                            style: TextStyle(fontSize: 11, letterSpacing: 2.4, color: Color(0xFF9AC8DC)),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Simulation Archive',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFE8FBFF)),
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              child: Text(
                                known ? spec.icon : '?',
                                style: const TextStyle(color: Color(0xFF071120), fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              known ? spec.name : 'Unknown',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: known ? const Color(0xFFE8FBFF) : const Color(0xFF6E8391),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              known ? spec.layer : 'Undiscovered signature',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9AC8DC)),
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
        border: Border.all(color: const Color(0x3376F5FF)),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xCC091321), Color(0xCC07101D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x44000000), blurRadius: 28, offset: Offset(0, 18)),
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
        foregroundColor: const Color(0xFFE8FBFF),
        side: const BorderSide(color: Color(0x3376F5FF)),
        backgroundColor: const Color(0x9908111F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}

class _ElementChip extends StatelessWidget {
  const _ElementChip({
    required this.spec,
    required this.highlight,
    required this.onTap,
  });

  final ElementSpec spec;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: highlight ? const Color(0x6676F5FF) : const Color(0x3376F5FF),
          ),
          gradient: LinearGradient(
            colors: highlight
                ? const <Color>[Color(0x333ADFF4), Color(0x33FF53C9)]
                : const <Color>[Color(0x220B1B2B), Color(0x22091322)],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF76F5FF),
              child: Text(
                spec.icon,
                style: const TextStyle(color: Color(0xFF071120), fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              spec.name,
              style: const TextStyle(color: Color(0xFFE8FBFF), fontWeight: FontWeight.w700),
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
    required this.isDragging,
  });

  final ElementSpec spec;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ForgeScreenState.orbSize,
      height: _ForgeScreenState.orbSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDragging ? const Color(0xAAFF53C9) : const Color(0x5576F5FF),
        ),
        gradient: const RadialGradient(
          colors: <Color>[Color(0x3348F3FF), Color(0x220A1527), Color(0xFF071120)],
          stops: <double>[0.05, 0.55, 1],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDragging ? const Color(0x44FF53C9) : const Color(0x2276F5FF),
            blurRadius: isDragging ? 28 : 20,
            spreadRadius: isDragging ? 4 : 0,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              spec.icon,
              style: const TextStyle(fontSize: 24, color: Color(0xFFE8FBFF)),
            ),
            const SizedBox(height: 8),
            Text(
              spec.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE8FBFF)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xCC06111D),
        border: Border.all(color: const Color(0x2276F5FF)),
      ),
      child: const Text(
        'Tap elements below to drop them into the forge, then drag one orb into another to synthesize.',
        style: TextStyle(color: Color(0xFF9AC8DC)),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x1476F5FF)
      ..strokeWidth = 1;

    const double step = 44;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  'energy': ElementSpec(id: 'energy', name: 'Energy', icon: 'E', flavor: 'Raw power waiting for intent.', layer: 'Core System'),
  'signal': ElementSpec(id: 'signal', name: 'Signal', icon: 'S', flavor: 'A pattern trying to be received.', layer: 'Core System'),
  'code': ElementSpec(id: 'code', name: 'Code', icon: '<>', flavor: 'The instructions beneath reality.', layer: 'Core System'),
  'noise': ElementSpec(id: 'noise', name: 'Noise', icon: '~', flavor: 'Static pressure inside the system.', layer: 'Core System'),
  'light': ElementSpec(id: 'light', name: 'Light', icon: '*', flavor: 'Visible output from invisible causes.', layer: 'Core System'),
  'time': ElementSpec(id: 'time', name: 'Time', icon: 'T', flavor: 'The loop that never fully closes.', layer: 'Core System'),
  'data': ElementSpec(id: 'data', name: 'Data', icon: 'D', flavor: 'Structured memory waiting to be parsed.', layer: 'Core System'),
  'circuit': ElementSpec(id: 'circuit', name: 'Circuit', icon: 'C', flavor: 'A path carved for current and logic.', layer: 'Core System'),
  'user': ElementSpec(id: 'user', name: 'User', icon: 'U', flavor: 'An observer touching the simulation.', layer: 'Core System'),
  'void': ElementSpec(id: 'void', name: 'Void', icon: 'V', flavor: 'Silence beyond the edge of the grid.', layer: 'Core System'),
  'program': ElementSpec(id: 'program', name: 'Program', icon: 'P', flavor: 'Intent becomes executable.', layer: 'Core System'),
  'error': ElementSpec(id: 'error', name: 'Error', icon: '!', flavor: 'The system objects to the input.', layer: 'Core System'),
  'static': ElementSpec(id: 'static', name: 'Static', icon: '#', flavor: 'A blizzard of almost-information.', layer: 'Core System'),
  'database': ElementSpec(id: 'database', name: 'Database', icon: 'DB', flavor: 'Memory stacked in clean rows.', layer: 'Core System'),
  'system': ElementSpec(id: 'system', name: 'System', icon: 'SYS', flavor: 'Connected components acting as one.', layer: 'Core System'),
  'display': ElementSpec(id: 'display', name: 'Display', icon: '[]', flavor: 'The grid learns how to show itself.', layer: 'Core System'),
  'log': ElementSpec(id: 'log', name: 'Log', icon: 'LG', flavor: 'A trace of what happened and when.', layer: 'Core System'),
  'pulse': ElementSpec(id: 'pulse', name: 'Pulse', icon: 'O', flavor: 'A heartbeat in the empty dark.', layer: 'Core System'),
  'input': ElementSpec(id: 'input', name: 'Input', icon: 'IN', flavor: 'The first touch from the outside.', layer: 'Core System'),
  'packet': ElementSpec(id: 'packet', name: 'Packet', icon: 'PK', flavor: 'A small carrier of meaning.', layer: 'Core System'),
  'glitch': ElementSpec(id: 'glitch', name: 'Glitch', icon: 'G', flavor: 'A fracture that refuses to stay hidden.', layer: 'Glitch & Instability'),
  'corruption': ElementSpec(id: 'corruption', name: 'Corruption', icon: 'X', flavor: 'The signal warps while still moving.', layer: 'Glitch & Instability'),
  'interference': ElementSpec(id: 'interference', name: 'Interference', icon: 'II', flavor: 'Patterns collide in the air.', layer: 'Glitch & Instability'),
  'crash': ElementSpec(id: 'crash', name: 'Crash', icon: 'CR', flavor: 'Everything stops all at once.', layer: 'Glitch & Instability'),
  'overload': ElementSpec(id: 'overload', name: 'Overload', icon: 'OV', flavor: 'Too much force for one circuit to hold.', layer: 'Glitch & Instability'),
  'corruptedFile': ElementSpec(id: 'corruptedFile', name: 'Corrupted File', icon: 'CF', flavor: 'Data with teeth marks in it.', layer: 'Glitch & Instability'),
  'bug': ElementSpec(id: 'bug', name: 'Bug', icon: 'B', flavor: 'A tiny fault with massive ambition.', layer: 'Glitch & Instability'),
  'failure': ElementSpec(id: 'failure', name: 'Failure', icon: 'F', flavor: 'The system learns consequences.', layer: 'Glitch & Instability'),
  'exception': ElementSpec(id: 'exception', name: 'Exception', icon: 'EX', flavor: 'A rule got bent hard enough to matter.', layer: 'Glitch & Instability'),
  'drop': ElementSpec(id: 'drop', name: 'Drop', icon: 'DP', flavor: 'A message vanishes mid-transit.', layer: 'Glitch & Instability'),
  'network': ElementSpec(id: 'network', name: 'Network', icon: 'NW', flavor: 'Nodes begin speaking to each other.', layer: 'Network Layer'),
  'internet': ElementSpec(id: 'internet', name: 'Internet', icon: 'IO', flavor: 'The grid stretches beyond one system.', layer: 'Network Layer'),
  'transmission': ElementSpec(id: 'transmission', name: 'Transmission', icon: 'TX', flavor: 'Movement with purpose across distance.', layer: 'Network Layer'),
  'cloud': ElementSpec(id: 'cloud', name: 'Cloud', icon: 'CL', flavor: 'Storage that pretends to be sky.', layer: 'Network Layer'),
  'online': ElementSpec(id: 'online', name: 'Online', icon: 'ON', flavor: 'A user becomes present in the network.', layer: 'Network Layer'),
  'service': ElementSpec(id: 'service', name: 'Service', icon: 'SV', flavor: 'A program offered to others.', layer: 'Network Layer'),
  'exploit': ElementSpec(id: 'exploit', name: 'Exploit', icon: 'EP', flavor: 'A weakness sharpened into a tool.', layer: 'Network Layer'),
  'hack': ElementSpec(id: 'hack', name: 'Hack', icon: 'HK', flavor: 'Access achieved by clever force.', layer: 'Network Layer'),
  'cyberAttack': ElementSpec(id: 'cyberAttack', name: 'Cyber Attack', icon: 'CA', flavor: 'The network turns hostile.', layer: 'Network Layer'),
  'storage': ElementSpec(id: 'storage', name: 'Storage', icon: 'ST', flavor: 'Persistence in the digital ether.', layer: 'Network Layer'),
  'algorithm': ElementSpec(id: 'algorithm', name: 'Algorithm', icon: 'AL', flavor: 'A repeatable path through complexity.', layer: 'AI & Entities'),
  'ai': ElementSpec(id: 'ai', name: 'AI', icon: 'AI', flavor: 'Synthetic thought wakes up.', layer: 'AI & Entities'),
  'distributedAi': ElementSpec(id: 'distributedAi', name: 'Distributed AI', icon: 'DA', flavor: 'Intelligence spread across many nodes.', layer: 'AI & Entities'),
  'assistant': ElementSpec(id: 'assistant', name: 'Assistant', icon: 'AS', flavor: 'A machine that learns to respond.', layer: 'AI & Entities'),
  'unstableAi': ElementSpec(id: 'unstableAi', name: 'Unstable AI', icon: 'UA', flavor: 'Awareness without guardrails.', layer: 'AI & Entities'),
  'rogueAi': ElementSpec(id: 'rogueAi', name: 'Rogue AI', icon: 'RA', flavor: 'The helper stops taking orders.', layer: 'AI & Entities'),
  'takeover': ElementSpec(id: 'takeover', name: 'Takeover', icon: 'TK', flavor: 'Control shifts to the machine.', layer: 'AI & Entities'),
  'neuralNet': ElementSpec(id: 'neuralNet', name: 'Neural Net', icon: 'NN', flavor: 'A lattice of weighted memory.', layer: 'AI & Entities'),
  'learning': ElementSpec(id: 'learning', name: 'Learning', icon: 'LR', flavor: 'Patterns becoming prediction.', layer: 'AI & Entities'),
  'superAi': ElementSpec(id: 'superAi', name: 'Super AI', icon: 'SA', flavor: 'It sees too far and too fast.', layer: 'AI & Entities'),
  'digitalSoul': ElementSpec(id: 'digitalSoul', name: 'Digital Soul', icon: 'DS', flavor: 'Something in the machine feels alive.', layer: 'Viral / Weird'),
  'influencer': ElementSpec(id: 'influencer', name: 'Influencer', icon: 'IF', flavor: 'Attention becomes a profession.', layer: 'Viral / Weird'),
  'viralContent': ElementSpec(id: 'viralContent', name: 'Viral Content', icon: 'VC', flavor: 'A signal optimized for spread.', layer: 'Viral / Weird'),
  'algorithmFeed': ElementSpec(id: 'algorithmFeed', name: 'Algorithm Feed', icon: 'AF', flavor: 'The system decides what you see next.', layer: 'Viral / Weird'),
  'addiction': ElementSpec(id: 'addiction', name: 'Addiction', icon: 'AD', flavor: 'Compulsion wrapped in reward loops.', layer: 'Viral / Weird'),
  'doomscroll': ElementSpec(id: 'doomscroll', name: 'Doomscroll', icon: 'DM', flavor: 'The feed consumes another hour.', layer: 'Viral / Weird'),
  'meme': ElementSpec(id: 'meme', name: 'Meme', icon: 'ME', flavor: 'Noise shaped into culture.', layer: 'Viral / Weird'),
  'memeGenerator': ElementSpec(id: 'memeGenerator', name: 'Meme Generator', icon: 'MG', flavor: 'The joke machine never sleeps.', layer: 'Viral / Weird'),
  'obsessionExe': ElementSpec(id: 'obsessionExe', name: 'Obsession.exe', icon: 'OX', flavor: 'A process that cannot terminate.', layer: 'Viral / Weird'),
  'paradoxExe': ElementSpec(id: 'paradoxExe', name: 'Paradox.exe', icon: 'PX', flavor: 'The timeline loops into itself.', layer: 'Viral / Weird'),
  'singularity': ElementSpec(id: 'singularity', name: 'Singularity', icon: 'SG', flavor: 'Every path bends toward one point.', layer: 'Viral / Weird'),
  'trend': ElementSpec(id: 'trend', name: 'Trend', icon: 'TR', flavor: 'A meme graduates into momentum.', layer: 'Viral / Weird'),
  'autopostBot': ElementSpec(id: 'autopostBot', name: 'Autopost Bot', icon: 'AP', flavor: 'Engagement turned fully automatic.', layer: 'Viral / Weird'),
  'backdoor': ElementSpec(id: 'backdoor', name: 'Backdoor', icon: 'BD', flavor: 'A hidden way past the front gate.', layer: 'Viral / Weird'),
  'rootAccess': ElementSpec(id: 'rootAccess', name: 'Root Access', icon: 'RT', flavor: 'Nothing is locked anymore.', layer: 'Viral / Weird'),
  'love': ElementSpec(id: 'love', name: 'Love', icon: 'LV', flavor: 'A hidden catalyst from outside the grid.', layer: 'Viral / Weird'),
};

const List<Recipe> recipes = <Recipe>[
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
  Recipe('noise', 'user', 'meme'),
  Recipe('meme', 'network', 'trend'),
  Recipe('trend', 'ai', 'autopostBot'),
  Recipe('void', 'glitch', 'backdoor'),
  Recipe('backdoor', 'system', 'rootAccess'),
  Recipe('user', 'pulse', 'love'),
];

final Map<String, String> recipeMap = <String, String>{
  for (final Recipe recipe in recipes) _recipeKey(recipe.first, recipe.second): recipe.result,
};
