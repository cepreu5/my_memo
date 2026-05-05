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
  Offset buttonPosition = const Offset(300, 400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _loadButtonPosition(); // Зарежда позицията при инициализация
  }

  Future<void> _loadButtonPosition() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      buttonPosition = Offset(
        prefs.getDouble('buttonX') ?? 300.0, // Default стойности
        prefs.getDouble('buttonY') ?? 400.0,
      );
    });
  }

  Future<void> _saveButtonPosition(Offset newPosition) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('buttonX', newPosition.dx);
    await prefs.setDouble('buttonY', newPosition.dy);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final newPosition = buttonPosition + details.delta;
    _saveButtonPosition(newPosition); // Запазва новата позиция
    setState(() {
      buttonPosition = newPosition;
    });
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    bool isLeft = buttonPosition.dx < size.width / 2;

    // Дефинираме голяма интерактивна зона (250x250), за да не излизат бутоните от нея 
    return Positioned(
      left: buttonPosition.dx - 125,
      top: buttonPosition.dy - 125,
      child: SizedBox(
        width: 250,
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Под-бутони (Ветрило)
            if (_isOpen || !_controller.isDismissed)
              ...List.generate(widget.actions.length, (index) {
                return _buildAnimatedChild(index, isLeft);
              }),
            
            // Главен бутон (Център на 250x250 зоната)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _onPanUpdate,
              // onPanEnd(details) {
              //   if (!_isOpen) {
              //     setState(() {
              //       buttonPosition += details.delta;
              //     });
              //   }
              // },
              onTap: _toggle,
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                child: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _controller,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedChild(int index, bool isLeft) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Ъгли за ветрило (Хоризонтално разпъване)
        double startAngle = isLeft ? -pi / 3 : 4 * pi / 3;
        double totalSweep = isLeft ? 2 * pi / 3 : -2 * pi / 3;
        
        double angleStep = widget.actions.length > 1 
            ? totalSweep / (widget.actions.length - 1) 
            : 0;
        
        double currentAngle = widget.actions.length > 1 
            ? startAngle + (index * angleStep)
            : (isLeft ? 0 : pi);

        double dist = _controller.value * 100;
        double x = cos(currentAngle) * dist;
        double y = sin(currentAngle) * dist;

        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: _controller.value,
            child: Transform.scale(
              scale: 0.5 + (_controller.value * 0.5),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // Спира клика да не минава под бутона
                onTap: () {
                  if (_isOpen) {
                    _toggle();
                    widget.actions[index].onTap();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0), // По-голяма зона за докосване
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showLabels && !isLeft) _buildLabel(widget.actions[index].label),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade400,
                          shape: BoxShape.circle,
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
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}