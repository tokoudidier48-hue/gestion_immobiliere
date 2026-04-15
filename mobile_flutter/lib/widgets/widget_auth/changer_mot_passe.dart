import 'package:flutter/material.dart';

/// 🔐 Champ mot de passe
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final Function(String)? onChanged;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: obscure,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  obscure = !obscure;
                });
              },
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// 💪 Barre de force
class PasswordStrengthBar extends StatelessWidget {
  final double strength;

  const PasswordStrengthBar({
    super.key, required this.strength
    });

  Color getColor() {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.7) return Colors.orange;
    return Colors.green;
  }

  String getText() {
    if (strength < 0.3) return "Faible";
    if (strength < 0.7) return "Moyen";
    return "Fort";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: strength,
          minHeight: 6,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(getColor()),
        ),
        const SizedBox(height: 5),
        Text(
          "Force du mot de passe: ${getText()}",
          style: TextStyle(color: getColor()),
        ),
      ],
    );
  }
}

/// ✅ Règle de sécurité
class PasswordRule extends StatelessWidget {
  final String text;
  final bool valid;

  const PasswordRule({
    super.key,
    required this.text,
    required this.valid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 10,
          color: valid ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: valid ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}