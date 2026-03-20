import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpInputWidget extends StatefulWidget {
  final Function(String) onCompleted;

  const OtpInputWidget({Key? key, required this.onCompleted}) : super(key: key);

  @override
  _OtpInputWidgetState createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget>
    with CodeAutoFill {

  final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
      List.generate(6, (_) => FocusNode());

  String otpCode = "";

  @override
  void initState() {
    super.initState();
    listenForCode(); // SMS auto
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  // 🔥 SMS AUTO
  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      fillCode(code!);
    }
  }

  void fillCode(String value) {
    for (int i = 0; i < 6; i++) {
      controllers[i].text = value[i];
    }
    otpCode = value;
    widget.onCompleted(otpCode);
    setState(() {});
  }

  void updateOtp() {
    otpCode = controllers.map((c) => c.text).join();

    if (otpCode.length == 6) {
      widget.onCompleted(otpCode); // 🔥 callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
            ),

            onChanged: (value) {
              // 🔥 AUTO COLLAGE
              if (value.length > 1) {
                fillCode(value);
                return;
              }

              if (value.isNotEmpty) {
                if (index < 5) {
                  FocusScope.of(context)
                      .requestFocus(focusNodes[index + 1]);
                }
              } else {
                if (index > 0) {
                  FocusScope.of(context)
                      .requestFocus(focusNodes[index - 1]);
                }
              }

              updateOtp();
            },
          ),
        );
      }),
    );
  }
}