import 'package:flutter/material.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:mobile_flutter/Pages/pages_auth/onboarding_pages.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:mobile_flutter/Pages/pages_auth/home.dart';
import 'package:provider/provider.dart';

class DecisionPage extends StatefulWidget {
  const DecisionPage({Key? key}) : super(key: key);

  @override
  State<DecisionPage> createState() => _DecisionPageState();
}

class _DecisionPageState extends State<DecisionPage> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      decideNavigation();
    });
  }

  void decideNavigation() async {
    final firstLaunch = await LocalStorage.isFirstLaunch();

    await Future.delayed(Duration(seconds: 2));

    final auth = Provider.of<UtilisateurProvider>(context, listen: false);

    if (firstLaunch) {
      await LocalStorage.setFirstLaunch(false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OnboarningPages()),
      );
    } else if (auth.token != null && auth.token!.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Home(role: auth.role!)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Connexion()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}