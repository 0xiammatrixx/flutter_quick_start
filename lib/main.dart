import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:arbichat/chatpage/model/message_model.dart';
import 'package:arbichat/on_chain/widget/trust_calculator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:arbichat/chatpage/transaction/get_balance.dart';
import 'package:arbichat/firebase_options.dart';
import 'package:arbichat/profilepage/page/profile_page.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/output.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/web3dart.dart' as web3dart;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arbichat/chatpage/page/chat_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();

  Hive.registerAdapter(ChatMessageAdapter());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String _result = '';
  bool logoutVisible = false;
  String rpcUrl = 'https://rpc.ankr.com/arbitrum_sepolia';
  // TextEditingController for handling input from the text field
  final TextEditingController emailController = TextEditingController();
  double trustScorePercent = 0.0;
  String trustRank = "Unranked";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
    loadTrustScore();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    // This is important to trigger the on Android.
    if (state == AppLifecycleState.resumed) {
      Web3AuthFlutter.setCustomTabsClosed();
    }
  }

  Future<void> loadTrustScore() async {
    final ownAddress = await _getAddress();
    final score =
        await TrustScoreService.calculateTrustScore(ownAddress);
    final rank = _getRankFromScore(score.toDouble());

    setState(() {
      trustScorePercent = score / 100.0; // For CircularPercentIndicator
      trustRank = rank;
    });
  }

  String _getRankFromScore(double score) {
  if (score >= 80) return "Vanguard";
  if (score >= 60) return "Elite";
  if (score >= 40) return "Trusted";
  if (score >= 20) return "Contributor";
  if (score >= 0) return "Newbie";
  return "Unranked";
}

  String _getBadgeAsset(String rank) {
    switch (rank) {
      case "Newbie":
        return "assets/rank1.gif";
      case "Contributor":
        return "assets/rank2.gif";
      case "Trusted":
        return "assets/rank3.gif";
      case "Elite":
        return "assets/rank4.gif";
      case "Vanguard":
        return "assets/rank5.gif";
      default:
        return "assets/rank1.gif";
    }
  }

  Future<void> initPlatformState() async {
    Uri redirectUrl;
    String clientId =
        'BPi5PB_UiIZ-cPz1GtV5i1I2iOSOHuimiXBI0e-Oe_u6X3oVAbCiAZOTEBtTXw4tsluTITPqA8zMsfxIKMjiqNQ';
    if (Platform.isAndroid) {
      redirectUrl = Uri.parse('w3a://com.example.w3aflutter/auth');
    } else if (Platform.isIOS) {
      redirectUrl = Uri.parse('com.example.w3aflutter://auth');
    } else {
      throw UnKnownException('Unknown platform');
    }

    await Web3AuthFlutter.init(Web3AuthOptions(
      clientId: clientId,
      network: Network.sapphire_mainnet,
      redirectUrl: redirectUrl,
      buildEnv: BuildEnv.production,
      // 259200 to stay authenticated for 3 days.
      sessionTime: 259200,
    ));
    try {
      await Web3AuthFlutter.initialize();
    } catch (e) {
      print("Initialization Error: $e");
    }
    final String res = await Web3AuthFlutter.getPrivKey();
    log(res);
    if (res.isNotEmpty) {
      setState(() {
        logoutVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var bgcol = const Color.fromARGB(255, 235, 235, 235).withOpacity(1);
    var textcol = const Color.fromARGB(255, 17, 24, 39);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: logoutVisible
            ? AppBar(
                leading: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    height: 10,
                    width: 15,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/ArbiChat_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                elevation: 0,
                title: Text(
                  'Dashboard',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: textcol),
                ),
                actions: <Widget>[
                  IconButton(
                      padding: EdgeInsets.only(right: screenWidth * 0.05),
                      onPressed: () async {
                        final walletAddress = await _getAddress();
                        navigatorKey.currentState?.push(MaterialPageRoute(
                            builder: (context) => ProfilePage(walletAddress: walletAddress, isOwnProfile: true,)));
                      },
                      icon: const Icon(Icons.person))
                ],
                backgroundColor: Colors.white,
              )
            : AppBar(
                backgroundColor: bgcol,
              ),
        backgroundColor: bgcol,
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
              ),
              Visibility(
                visible: !logoutVisible,
                child: Column(
                  children: [
                    Center(
                      child: SizedBox(
                          height: screenHeight * 0.08,
                          width: screenWidth * 0.6,
                          child: Image.asset('assets/ArbiChat_logo.png')),
                    ),
                    SizedBox(
                      height: screenHeight * 0.2,
                    ),
                    const Text(
                      'Log in or sign up',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Container(
                      width: screenWidth * 0.7,
                      height: screenHeight * 0.06,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20)),
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textAlign: TextAlign.start,
                        enableInteractiveSelection: true,
                        enableSuggestions: true,
                        decoration: const InputDecoration(
                          fillColor: Color.fromARGB(231, 221, 220, 220),
                          filled: true,
                          hintText: 'Input Email',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: screenWidth * 0.7,
                      height: screenHeight * 0.06,
                      child: ElevatedButton(
                        onPressed: _login(
                          () => _withEmailPasswordless(emailController.text),
                        ),
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                            if (states.contains(
                              WidgetState.pressed,
                            )) {
                              return Colors.black;
                            }
                            return Colors.grey;
                          }),
                          foregroundColor: WidgetStateProperty.all(
                              const Color.fromARGB(255, 255, 255, 255)),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                          textStyle: WidgetStateProperty.all(const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButtonTheme(
                data: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                child: Visibility(
                  visible: logoutVisible,
                  child: Column(
                    children: [
                      Stack(children: [
                        Container(
                          height: screenHeight * 0.41,
                          width: screenWidth * 0.9,
                          color: Colors.transparent,
                        ),
                        Container(
                            height: screenHeight * 0.4,
                            width: screenWidth * 0.9,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15)),
                            child: WalletBalance()),
                        Positioned(
                            bottom: 0.0,
                            left: screenWidth * 0.05,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.transparent),
                                boxShadow: [
                                  BoxShadow(
                                      blurRadius: 6,
                                      spreadRadius: 4,
                                      color: Colors.black.withOpacity(0.1),
                                      offset: Offset(0, 4))
                                ],
                                color: bgcol,
                              ),
                              height: screenHeight * 0.03,
                              width: screenWidth * 0.8,
                            )),
                        Positioned(
                            bottom: 9,
                            left: screenWidth * 0.03,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.transparent),
                                color: Colors.white,
                              ),
                              height: screenHeight * 0.03,
                              width: screenWidth * 0.84,
                            )),
                      ]),
                      Row(
                        children: [
                          SizedBox(width: screenWidth * 0.08),
                          Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              height: screenHeight * 0.2,
                              width: screenWidth * 0.43,
                              child: CircularPercentIndicator(
                                radius: 60.0,
                                lineWidth: 15.0,
                                percent: trustScorePercent.clamp(0.0, 1.0),
                                center: Text(
                                    "${(trustScorePercent * 100).toInt()}%"),
                                progressColor:
                                    Color.fromARGB(255, 16, 185, 129),
                                footer: Text("Trust Score",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              )),
                          SizedBox(
                            width: screenWidth * 0.03,
                          ),
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.transparent,
                            ),
                            height: screenHeight * 0.2,
                            width: screenWidth * 0.43,
                            child: Column(
                              children: [
                                SizedBox(
                                    height: screenHeight * 0.13,
                                    width: screenWidth * 0.43,
                                    child:
                                        Image.asset(_getBadgeAsset(trustRank))),
                                Text(
                                  trustRank,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Builder(builder: (context) {
                          return Container(
                            height: screenHeight * 0.15,
                            width: screenWidth * 0.9,
                            decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.1), // shadow color
                                    spreadRadius: 4,
                                    blurRadius: 6,
                                    offset: const Offset(
                                        0, 4), // horizontal, vertical
                                  ),
                                ],
                                color: textcol,
                                borderRadius: BorderRadius.circular(15)),
                            child: ElevatedButton(
                              style: ButtonStyle(
                                shadowColor: WidgetStateProperty.all(
                                    Color.fromARGB(20, 0, 0, 0)),
                                elevation: const WidgetStatePropertyAll(8),
                                backgroundColor:
                                    WidgetStateProperty.all(Colors.white),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChatsPage(),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: screenHeight * 0.025,
                                  ),
                                  Text(
                                    'Enter ArbiChat',
                                    style: TextStyle(color: textcol),
                                  ),
                                  SizedBox(
                                    height: screenHeight * 0.02,
                                  ),
                                  Divider(
                                    color: Color.fromARGB(255, 229, 231, 235),
                                  ),
                                  SizedBox(
                                    height: screenHeight * 0.02,
                                  ),
                                  Icon(
                                    Icons.arrow_right_alt,
                                    color: textcol,
                                  )
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      Container(
                        height: screenHeight * 0.05,
                        width: screenWidth * 0.9,
                        decoration: BoxDecoration(boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 4,
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ], borderRadius: BorderRadius.circular(15)),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(202, 189, 4, 4),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _logout(),
                            child: Text('Logout')),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_result),
              )
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback _login(Future<Web3AuthResponse> Function() method) {
    return () async {
      try {
        final Web3AuthResponse response = await method();
        Future<void> saveWalletAddress(String walletAddress) async {
          // Check if the wallet address already exists in Firestore
          final docRef =
              FirebaseFirestore.instance.collection('users').doc(walletAddress);
          final docSnapshot = await docRef.get();

          if (!docSnapshot.exists) {
            // If it doesn't exist, save the wallet address
            await docRef.set({
              'walletAddress': walletAddress,
            });
          } else {
            //log when it already exists
            log("Wallet address already exists in Firestore: $walletAddress");
          }
        }

        // Retrieve wallet address
        final walletAddress = await _getAddress();

        // Save the wallet address to Firestore
        await saveWalletAddress(walletAddress);

        setState(() {
          _result = response.toString();
          logoutVisible = true;
        });
      } on UserCancelledException {
        log("User cancelled.");
      } on UnKnownException {
        log("Unknown exception occurred");
      }
    };
  }

  VoidCallback _logout() {
    return () async {
      try {
        setState(() {
          _result = '';
          logoutVisible = false;
        });
        await Web3AuthFlutter.logout();
      } on UserCancelledException {
        log("User cancelled.");
      } on UnKnownException {
        log("Unknown exception occurred");
      }
    };
  }

  Future<Web3AuthResponse> _withEmailPasswordless(String userEmail) async {
    try {
      log(userEmail);
      // IMP START - Login
      Web3AuthResponse response = await Web3AuthFlutter.login(LoginParams(
        loginProvider: Provider.email_passwordless,
        extraLoginOptions: ExtraLoginOptions(login_hint: userEmail),
      ));

      final String privateKey = await Web3AuthFlutter.getPrivKey();
      log("Private Key for $userEmail: $privateKey");

      // Save the private key to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('privateKey', privateKey);

      final walletAddress = await _getAddress();
      await _saveEmailToFirestore(walletAddress, userEmail);
      return response;
      // IMP END - Login
    } catch (e) {
      log("Error during email/passwordless login: $e");
      // Handle the error
      return Future.error("Login failed");
    }
  }

  Future<void> _saveEmailToFirestore(String walletAddress, String email) async {
    // Reference to the Firestore document using the wallet address
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(walletAddress);

    try {
      // Check if the document already exists
      final docSnapshot = await userDocRef.get();
      if (!docSnapshot.exists) {
        // If it doesn't exist, create a new document
        await userDocRef.set({'email': email});
      } else {
        // If it exists, update the document with the email
        await userDocRef.update({'email': email});
        log("Email updated in Firestore for wallet address: $walletAddress");
      }
    } catch (e) {
      log("Error saving email to Firestore: $e");
    }
  }

  // Future<TorusUserInfo> _getUserInfo() async {
  //   try {
  //     TorusUserInfo userInfo = await Web3AuthFlutter.getUserInfo();
  //     //log(userInfo.toString());
  //     //setState(() {
  //     // _result = userInfo.toString();
  //     //});
  //     return userInfo;
  //   } catch (e) {
  //     log("Error during email/passwordless login: $e");
  //     // Handle the error as needed
  //     // You might want to show a user-friendly message or log the error
  //     return Future.error("Login failed");
  //   }
  // }

  Future<String> _getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey');
    print("Private key from SharedPreferences: $privateKey");
    if (privateKey == null || privateKey.isEmpty || privateKey.length < 64) {
      throw Exception("Invalid or missing private key");
    }

    final credentials = web3dart.EthPrivateKey.fromHex(privateKey);
    final address = credentials.address;
    log("Account, ${address.hexEip55}");
    setState(() {
      _result = address.hexEip55.toString();
    });
    return address.hexEip55;
  }
}
