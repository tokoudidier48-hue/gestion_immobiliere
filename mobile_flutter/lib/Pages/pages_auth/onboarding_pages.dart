import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:mobile_flutter/widgets/widget_auth/onboarding.dart';

class OnboarningPages extends StatefulWidget {
  @override
  _OnboarningPagesState createState() => _OnboarningPagesState();
}

class _OnboarningPagesState extends State<OnboarningPages> {

  final PageController _controller = PageController();
  int currentPage = 0;

  final List<Map<String, String>> data = [
    {
      "image": "assets/images/chambre.jpg",
      "title": "Smarter Real Estate\nManagement in Benin",
      "description":
          "Effortlessly manage your properties, track tenant payments, and stay ahead with AI-powered financial predictions."
    },
    {
      "image": "assets/images/appartement.jpeg",
      "title": "Track Everything Easily",
      "description":
          "Follow rent, tenants and payments in real time."
    },
    {
      "image": "assets/images/boutique.jpg",
      "title": "Grow Your Business",
      "description":
          "Make smarter decisions with powerful insights."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () {
                _controller.jumpToPage(data.length - 1);
              },
              child: Text("Skip"),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          /// PAGEVIEW
          PageView.builder(
            controller: _controller,
            itemCount: data.length,
            onPageChanged: (index) {
              setState(() => currentPage = index);
            },
            itemBuilder: (context, index) {
              return OnboardingWidget(
                image: data[index]["image"]!,
                title: data[index]["title"]!,
                description: data[index]["description"]!,
              );
            },
          ),

          

          /// BOTTOM PART
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              children: [

                /// DOTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(data.length, (index) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: currentPage == index ? 20 : 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: currentPage == index
                            ? Colors.blue
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                /// BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async{
                      if (currentPage < data.length - 1) {
                        _controller.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      } else {
                        // FIN onboarding
                        await LocalStorage.setFirstLaunch(false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Connexion(),
                          ),
                        );
                      }
                    },
                    child: Text(
                      currentPage == data.length - 1 ? "Start" : "Next →",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Step ${currentPage + 1} of ${data.length}",
                  style: TextStyle(color: Colors.grey),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}