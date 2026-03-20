import 'package:flutter/material.dart';


// CustomField pour Inscription
Widget customField({
  required TextEditingController controller,
  required String hint,
  IconData? icon,
  bool isPassword = false,
  String? Function(String?)? validator,
  Function(String)? onChanged, 
}) {
  bool obscure = isPassword;

  return StatefulBuilder(
    builder: (context, setState) {
      return TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        onChanged: onChanged,
        keyboardType: icon == Icons.phone
            ? TextInputType.phone
            : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon,color: Colors.blue,) : null,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscure = !obscure;
                    });
                  },
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
        ),
      );
    },
  );
}

/// CustomField pour Connexion
Widget customFieldConnexion({
  required TextEditingController controller,
  required String hint,
  IconData? icon,
  bool isPassword = false,
  Color iconColor = Colors.blue,
  void Function()? togglePassword,
}) {
  bool obscurePassword = isPassword;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: icon != null ? Icon(icon, color: iconColor) : null,
        suffixIcon: obscurePassword
            ? IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: togglePassword, // ✅ ICI
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}