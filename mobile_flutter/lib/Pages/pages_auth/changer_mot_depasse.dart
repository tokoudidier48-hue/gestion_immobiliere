import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:mobile_flutter/service/auth/api_reset_password.dart';

class NouveauMotDePassePage extends StatefulWidget {
  final ApiResetPassword api;

  const NouveauMotDePassePage({super.key, required this.api});

  @override
  State<NouveauMotDePassePage> createState() => _NouveauMotDePassePageState();
}

class _NouveauMotDePassePageState extends State<NouveauMotDePassePage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  double _strength = 0;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _checkStrength(String value) {
    double s = 0;
    if (value.length >= 8) s += 0.3;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) s += 0.3;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) s += 0.4;
    setState(() => _strength = s.clamp(0, 1));
  }

  Future<void> _reinitialiser() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: Colors.red),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe doit avoir au moins 8 caractères'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.api.nouveauMotDePasse(password, confirm);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe réinitialisé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Connexion()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color get _strengthColor => _strength < 0.4
      ? Colors.red
      : _strength < 0.7
          ? Colors.orange
          : Colors.green;

  String get _strengthLabel => _strength < 0.4
      ? 'Faible'
      : _strength < 0.7
          ? 'Moyen'
          : 'Fort';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Nouveau mot de passe',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.lock_reset, size: 40, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Créez un nouveau mot de passe sécurisé',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
              const SizedBox(height: 28),

              // Champ mot de passe
              _buildPasswordField(
                controller: _passwordController,
                label: 'Nouveau mot de passe',
                obscure: _obscure1,
                onToggle: () => setState(() => _obscure1 = !_obscure1),
                onChanged: _checkStrength,
              ),
              const SizedBox(height: 10),

              // Barre de force
              if (_passwordController.text.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _strength,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(_strengthColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(_strengthLabel,
                        style: TextStyle(color: _strengthColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Champ confirmation
              _buildPasswordField(
                controller: _confirmController,
                label: 'Confirmer le mot de passe',
                obscure: _obscure2,
                onToggle: () => setState(() => _obscure2 = !_obscure2),
              ),
              const SizedBox(height: 20),

              // Règles
              const Text('EXIGENCES DE SÉCURITÉ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              _rule('Au moins 8 caractères', _passwordController.text.length >= 8),
              _rule('Majuscules et minuscules',
                  RegExp(r'[A-Z]').hasMatch(_passwordController.text) && RegExp(r'[a-z]').hasMatch(_passwordController.text)),
              _rule('Caractère spécial (!@#\$...)',
                  RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text)),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _reinitialiser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Réinitialiser le mot de passe',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _rule(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(valid ? Icons.check_circle : Icons.radio_button_unchecked,
              color: valid ? Colors.green : Colors.grey, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: valid ? Colors.green : Colors.grey)),
        ],
      ),
    );
  }
}