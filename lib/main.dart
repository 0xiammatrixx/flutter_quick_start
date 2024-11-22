import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:w3aflutter/chatpage/transaction/get_balance.dart';
import 'package:w3aflutter/firebase_options.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/output.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart' as web3dart;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:w3aflutter/chatpage/page/chat_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
  String rpcUrl = 'https://rpc.ankr.com/eth_sepolia';
  // TextEditingController for handling input from the text field
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
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

  // Platform messages are asynchronous, so we initialize in an async method.
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
      // 259200 allows user to stay authenticated for 3 days with Web3Auth.
      // Default is 86400, which is 1 day.
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
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Welcome to ArbiChat',
            style: TextStyle(
                fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
              ),
              Visibility(
                visible: !logoutVisible,
                child: Column(
                  children: [
                    const Icon(
                      Icons.flutter_dash,
                      size: 80,
                      color: Color(0xFF1389fd),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    const Text(
                      'Web3Auth',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                        color: Color(0xFF0364ff),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'Welcome to Web3Auth x Flutter Quick Start Demo',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      'Login with',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    // Text field for entering the user's email
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Email',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _login(
                        () => _withEmailPasswordless(emailController.text),
                      ),
                      child: const Text('Login with Email Passwordless'),
                    ),
                  ],
                ),
              ),
              ElevatedButtonTheme(
                data: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 195, 47, 233),
                    foregroundColor: Colors.white,
                  ),
                ),
                child: Visibility(
                  visible: logoutVisible,
                  child: Column(
                    children: [
                      Center(
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _logout(),
                            child: const Column(
                              children: [
                                Text('Logout'),
                              ],
                            )),
                      ),
                      SizedBox(
                          height: 0.2 * (MediaQuery.of(context).size.height)),
                      
                      WalletBalance(),
                      Builder(builder: (context) {
                        return ElevatedButton(
                          
                          style: ButtonStyle(
                              elevation: WidgetStatePropertyAll(10),
                              backgroundColor: WidgetStateProperty.all(Colors.grey[800]),
                              ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatsPage(),
                              ),
                            );
                          },
                          child: const Text('Enter ArbiChat'),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_result),
              )
            ],
          )),
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
            // Optionally, you can log or handle the case when it already exists
            log("Wallet address already exists in Firestore: $walletAddress");
          }
        }

        // Retrieve wallet address (for example, from `_getAddress`)
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
      // Handle the error as needed
      // You might want to show a user-friendly message or log the error
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
        // If it exists, you can update the document with the email
        await userDocRef.update({'email': email});
        log("Email updated in Firestore for wallet address: $walletAddress");
      }
    } catch (e) {
      log("Error saving email to Firestore: $e");
    }
  }

  Future<TorusUserInfo> _getUserInfo() async {
    try {
      TorusUserInfo userInfo = await Web3AuthFlutter.getUserInfo();
      log(userInfo.toString());
      setState(() {
        _result = userInfo.toString();
      });
      return userInfo;
    } catch (e) {
      log("Error during email/passwordless login: $e");
      // Handle the error as needed
      // You might want to show a user-friendly message or log the error
      return Future.error("Login failed");
    }
  }

  Future<String> _getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey') ?? '0';

    final credentials = web3dart.EthPrivateKey.fromHex(privateKey);
    final address = credentials.address;
    log("Account, ${address.hexEip55}");
    setState(() {
      _result = address.hexEip55.toString();
    });
    return address.hexEip55;
  }

  Future<web3dart.EtherAmount> _getBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final privateKey = prefs.getString('privateKey') ?? '0';

      final client = web3dart.Web3Client(rpcUrl, Client());
      final credentials = web3dart.EthPrivateKey.fromHex(privateKey);
      final address = credentials.address;

      // Get the balance in wei
      final weiBalance = await client.getBalance(address);

      // Convert wei to ether
      final etherBalance = web3dart.EtherAmount.fromBigInt(
        web3dart.EtherUnit.ether,
        weiBalance.getInEther,
      );

      log(etherBalance.toString());

      setState(() {
        _result = etherBalance.toString();
      });

      return etherBalance;
    } catch (e) {
      // Handle errors as needed
      log("Error getting balance: $e");
      return web3dart.EtherAmount.zero();
    }
  }

  Future<String> _sendTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey') ?? '0';

    final client = web3dart.Web3Client(rpcUrl, Client());
    final credentials = web3dart.EthPrivateKey.fromHex(privateKey);
    final address = credentials.address;
    try {
      final receipt = await client.sendTransaction(
        credentials,
        web3dart.Transaction(
          from: address,
          to: web3dart.EthereumAddress.fromHex(
            '0xeaA8Af602b2eDE45922818AE5f9f7FdE50cFa1A8',
          ),
          // gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 100),
          value: web3dart.EtherAmount.fromInt(
            web3dart.EtherUnit.gwei,
            5000000,
          ), // 0.005 ETH
        ),
        chainId: 11155111,
      );
      log(receipt);
      setState(() {
        _result = receipt;
      });
      return receipt;
    } catch (e) {
      setState(() {
        _result = e.toString();
      });
      return e.toString();
    }
  }
}
