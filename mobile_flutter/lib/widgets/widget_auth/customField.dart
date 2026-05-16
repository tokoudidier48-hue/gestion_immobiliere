import 'package:flutter/material.dart';

// ── Widget avec état interne pour gérer l'obscure ─────────────────────────────

class _CustomFieldState extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String keyboardType;
  final IconData? icon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;

  const _CustomFieldState({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.icon,
    this.isPassword = false,
    this.validator,
    this.onChanged,
  });

  @override
  State<_CustomFieldState> createState() => __CustomFieldStateState();
}

class __CustomFieldStateState extends State<_CustomFieldState> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword; // ← initialisé une seule fois
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType == 'phone'
          ? TextInputType.phone
          : widget.keyboardType == 'email'
              ? TextInputType.emailAddress
              : TextInputType.text,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, color: Colors.blue)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// ── Widget avec état interne pour Connexion ───────────────────────────────────

class _CustomFieldConnexionState extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String keyboardType;
  final IconData? icon;
  final bool isPassword;
  final Color iconColor;
  final String? errorText;

  const _CustomFieldConnexionState({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.icon,
    this.isPassword = false,
    this.iconColor = Colors.blue,
    this.errorText,
  });

  @override
  State<_CustomFieldConnexionState> createState() =>
      __CustomFieldConnexionStateState();
}

class __CustomFieldConnexionStateState
    extends State<_CustomFieldConnexionState> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword; // ← initialisé une seule fois
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            obscureText: _obscure,
            keyboardType: widget.keyboardType == 'email'
                ? TextInputType.emailAddress
                : widget.keyboardType == 'phone'
                    ? TextInputType.phone
                    : TextInputType.text,
            decoration: InputDecoration(
              hintText: widget.hint,
              filled: true,
              fillColor: Colors.white,
              prefixIcon: widget.icon != null
                  ? Icon(widget.icon, color: widget.iconColor)
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: widget.errorText != null
                    ? const BorderSide(color: Colors.red, width: 1.5)
                    : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: widget.errorText != null
                    ? const BorderSide(color: Colors.red, width: 1.5)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: widget.errorText != null
                    ? const BorderSide(color: Colors.red, width: 1.5)
                    : const BorderSide(color: Colors.blue, width: 1.5),
              ),
            ),
          ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                widget.errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Fonctions publiques utilisées dans les pages ──────────────────────────────

Widget customField({
  required TextEditingController controller,
  required String hint,
  required String keyboardType,
  IconData? icon,
  bool isPassword = false,
  String? Function(String?)? validator,
  Function(String)? onChanged,
}) {
  return _CustomFieldState(
    controller: controller,
    hint: hint,
    keyboardType: keyboardType,
    icon: icon,
    isPassword: isPassword,
    validator: validator,
    onChanged: onChanged,
  );
}

Widget customFieldConnexion({
  required TextEditingController controller,
  required String hint,
  required String keyboardType,
  IconData? icon,
  bool isPassword = false,
  Color iconColor = Colors.blue,
  String? errorText,
}) {
  return _CustomFieldConnexionState(
    controller: controller,
    hint: hint,
    keyboardType: keyboardType,
    icon: icon,
    isPassword: isPassword,
    iconColor: iconColor,
    errorText: errorText,
  );
}