import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:katara/app/theme/katara_colors.dart';

enum KButtonVariant {
  primary,
  secondary,
  outline,
  danger,
}

/// Tombol bergaya 3D taktil dengan tepi bawah (`bottomLip`), memenuhi ukuran tap >= 48px (R-03)
/// serta indikator fokus & kursor aksesibel (R-32, R-39).
class KButton extends StatefulWidget {
  const KButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final KButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  State<KButton> createState() => _KButtonState();
}

class _KButtonState extends State<KButton> {
  bool _isPressed = false;
  bool _isFocused = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final p = KataraPalette.of(context);

    final (Color face, Color lip, Color fg, Color? border) = switch (widget.variant) {
      KButtonVariant.primary => (p.primary, p.primaryDark, p.onPrimary, null),
      KButtonVariant.secondary => (
          p.secondary,
          const Color(0xFFC28E00),
          p.onSecondary,
          null
        ),
      KButtonVariant.outline => (p.surface, p.outline, p.ink, p.outline),
      KButtonVariant.danger => (
          p.error,
          const Color(0xFF9C2920),
          Colors.white,
          null
        ),
    };

    final effectiveFace = _enabled ? face : p.surfaceAlt;
    final effectiveLip = _enabled ? lip : p.outline;
    final effectiveFg = _enabled ? fg : p.inkMuted;

    const lipHeight = 4.0;
    final currentOffset = (_isPressed && _enabled) ? lipHeight : 0.0;

    final buttonContent = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 88),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        margin: EdgeInsets.only(top: currentOffset),
        padding: EdgeInsets.only(bottom: lipHeight - currentOffset),
        decoration: BoxDecoration(
          color: effectiveLip,
          borderRadius: BorderRadius.circular(14),
          border: _isFocused
              ? Border.all(color: p.secondary, width: 2.5)
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: effectiveFace,
            borderRadius: BorderRadius.circular(13),
            border: border != null
                ? Border.all(color: border, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: effectiveFg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: effectiveFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (_enabled) widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _isPressed = false) : null,
          onTap: _enabled ? widget.onPressed : null,
          child: widget.expand
              ? SizedBox(width: double.infinity, child: buttonContent)
              : buttonContent,
        ),
      ),
    );
  }
}
