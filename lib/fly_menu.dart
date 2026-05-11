import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class FlyAction {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  FlyAction({required this.icon, required this.onTap, required this.label});
}

class FlyMenu extends StatefulWidget {
  final List<FlyAction> actions;
  final bool showLabels;
  const FlyMenu({super.key, required this.actions, this.showLabels = false});
  @override
  State<FlyMenu> createState() => _FlyMenuState();
}

class _FlyMenuState extends State<FlyMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;
  Offset _buttonPosition = const Offset(300, 400);
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _loadAndShow();
  }

  Future<void> _loadAndShow() async {
    final prefs = await SharedPreferences.getInstance();
    _buttonPosition = Offset(prefs.getDouble('buttonX') ?? 300, prefs.getDouble('buttonY') ?? 400);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
  }

  void _showOverlay() {
    if (!mounted || _overlayEntry != null) return;
    _overlayEntry = OverlayEntry(builder: (context) {
      // Проверяваме дали маршрутът все още е активен (най-отгоре)
      final route = ModalRoute.of(this.context);
      if (route == null || !route.isCurrent) return const SizedBox.shrink();
      return _buildMenu(context);
    });
    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _savePosition(Offset pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('buttonX', pos.dx);
    await prefs.setDouble('buttonY', pos.dy);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    setState(() {
      _buttonPosition = Offset(
        (_buttonPosition.dx + details.delta.dx).clamp(30.0, size.width - 30.0),
        (_buttonPosition.dy + details.delta.dy).clamp(30.0, size.height - 30.0),
      );
    });
    _savePosition(_buttonPosition);
    _overlayEntry?.markNeedsBuild();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _controller.forward() : _controller.reverse();
    });
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Предизвикваме обновяване на Overlay, когато маршрутът се промени (напр. се върнем назад)
    WidgetsBinding.instance.addPostFrameCallback((_) => _overlayEntry?.markNeedsBuild());
    return const SizedBox.shrink();
  }

  Widget _buildMenu(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double safeX = _buttonPosition.dx.clamp(30.0, size.width - 30.0);
    double safeY = _buttonPosition.dy.clamp(30.0, size.height - 30.0);
    bool isLeft = safeX < size.width / 2;
    return Stack(
      children: [
        if (_isOpen || !_controller.isDismissed)
          ...List.generate(widget.actions.length, (index) => _buildAnimatedChild(index, isLeft, safeX, safeY)),
        Positioned(
          left: safeX - 28,
          top: safeY - 28,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _onPanUpdate,
              onTap: _toggle,
              child: Container(
                width: 56, height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.5), shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _controller, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedChild(int index, bool isLeft, double centerX, double centerY) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double fixedAngleStep = 0.16 * pi;
        double currentSweep = (widget.actions.length - 1) * fixedAngleStep;
        double startAngle = isLeft ? (-currentSweep / 2) : (pi + currentSweep / 2);
        double currentAngle = startAngle + (index * (isLeft ? fixedAngleStep : -fixedAngleStep));
        double dist = _controller.value * 105;
        double x = cos(currentAngle) * dist;
        double y = sin(currentAngle) * dist;
        return Positioned(
          left: centerX + x - (isLeft ? 27 : (widget.showLabels ? 100 : 27)),
          top: centerY + y - 27,
          child: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: _controller.value,
              child: Transform.scale(
                scale: 0.5 + (_controller.value * 0.5),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () { if (_isOpen) { _toggle(); widget.actions[index].onTap(); } },
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showLabels && !isLeft) _buildLabel(widget.actions[index].label),
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade400, shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Icon(widget.actions[index].icon, color: Colors.white, size: 22),
                        ),
                        if (widget.showLabels && isLeft) _buildLabel(widget.actions[index].label),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}