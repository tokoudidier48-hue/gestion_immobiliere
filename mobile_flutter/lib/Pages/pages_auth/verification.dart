import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/changer_mot_depasse.dart';
import 'package:mobile_flutter/service/auth/api_reset_password.dart';

class VerificationOtpPage extends StatefulWidget {
  final String email;
  final ApiResetPassword api;

  const VerificationOtpPage({super.key, required this.email, required this.api});

  @override
  State<VerificationOtpPage> createState() => _VerificationOtpPageState();
}

class _VerificationOtpPageState extends State<VerificationOtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 120;
  bool _canResend = false;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() { _secondsRemaining = 120; _canResend = false; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining == 0) {
        setState(() => _canResend = true);
        t.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verifier() async {
    if (_code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez le code complet à 6 chiffres')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.api.verifierOtp(widget.email, _code);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NouveauMotDePassePage(api: widget.api),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      // Vide les champs
      for (var c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _renvoyer() async {
    if (!_canResend) return;
    try {
      await widget.api.demanderOtp(widget.email);
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code renvoyé !'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A90E2),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Text('Vérification',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user, color: Colors.blue, size: 30),
                      ),
                      const SizedBox(height: 20),
                      const Text('Code de vérification',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('Code envoyé à',
                          style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text(widget.email,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),

                      // Champs OTP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) => SizedBox(
                          width: 46, height: 54,
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && i < 5) {
                                _focusNodes[i + 1].requestFocus();
                              } else if (val.isEmpty && i > 0) {
                                _focusNodes[i - 1].requestFocus();
                              }
                              setState(() {});
                            },
                          ),
                        )),
                      ),
                      const SizedBox(height: 24),

                      // Timer + Renvoyer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_formatTime(_secondsRemaining),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _canResend ? _renvoyer : null,
                            child: Text('Renvoyer',
                                style: TextStyle(
                                    color: _canResend ? Colors.blue : Colors.grey,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Bouton Vérifier
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading || _code.length < 6 ? null : _verifier,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Vérifier', style: TextStyle(fontSize: 16, color: Colors.white)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: Colors.white),
                                  ],
                                ),
                        ),
                      ),
                    ],
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