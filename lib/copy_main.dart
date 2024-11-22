/* import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:w3aflutter/chatpage/page/chat_page.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/output.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart' as web3dart; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp (
    options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// IMP START - Quick Start
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
// IMP END - Quick Start
  String _result = '';
  bool logoutVisible = false;
  String rpcUrl = 'https://rpc.ankr.com/arbitrum_sepolia';
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
    // IMP START - Get your Web3Auth Client ID from Dashboard
    String clientId =
        'BPi5PB_UiIZ-cPz1GtV5i1I2iOSOHuimiXBI0e-Oe_u6X3oVAbCiAZOTEBtTXw4tsluTITPqA8zMsfxIKMjiqNQ';
    if (Platform.isAndroid) {
      redirectUrl = Uri.parse('w3a://com.example.w3aflutter/auth');
    } else if (Platform.isIOS) {
      redirectUrl = Uri.parse('com.example.w3aflutter://auth');
      // IMP END - Get your Web3Auth Client ID from Dashboard
    } else {
      throw UnKnownException('Unknown platform');
    }

    // IMP START - Initialize Web3Auth
    await Web3AuthFlutter.init(Web3AuthOptions(
      clientId: clientId,
      network: Network.sapphire_mainnet,
      redirectUrl: redirectUrl,
      buildEnv: BuildEnv.production,
      // 259200 allows user to stay authenticated for 3 days with Web3Auth.
      // Default is 86400, which is 1 day.
      sessionTime: 259200,
    ));

    await Web3AuthFlutter.initialize();
    // IMP END - Initialize Web3Auth

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0364ff),
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Welcome To ArbiChat',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0364ff),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Visibility(
                    visible: !logoutVisible,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.flutter_dash,
                          size: 80,
                          color: Color(0xFF1389fd),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Web3Auth',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                            color: Color(0xFF0364ff),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Welcome to ArbiChat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Login with',
                          style: TextStyle(fontSize: 14, color: Colors.black45),
                        ),
                        const SizedBox(height: 10),
                        // Text field for entering the user's email
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Enter Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _login(
                            () => _withEmailPasswordless(emailController.text),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF1389fd),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text('Login with Email Passwordless'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Visibility(
                    visible: logoutVisible,
                    child: Card(
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: _logout(),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 24),
                              ),
                              child: const Text('Logout'),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Blockchain Calls',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0364ff),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _getUserInfo,
                              child: const Text('Get UserInfo'),
                            ),
                            ElevatedButton(
                              onPressed: _getAddress,
                              child: const Text('Get Address'),
                            ),
                            ElevatedButton(
                              onPressed: _getBalance,
                              child: const Text('Get Balance'),
                            ),
                            ElevatedButton(
                              onPressed: _sendTransaction,
                              child: const Text('Send Transaction'),
                            ),
                            Builder(
                              builder: (context) {
                                return ElevatedButton(
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
                              }
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  VoidCallback _login(Future<Web3AuthResponse> Function() method) {
    return () async {
      try {
        final Web3AuthResponse response = await method();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('privateKey', response.privKey.toString());
        Future<void> saveWalletAddress(String walletAddress) async {
  // Check if the wallet address already exists in Firestore
  final docRef = FirebaseFirestore.instance.collection('users').doc(walletAddress);
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
        // IMP START - Logout
        await Web3AuthFlutter.logout();
        // IMP END - Logout
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
  final userDocRef = FirebaseFirestore.instance.collection('users').doc(walletAddress);

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
      // IMP START - Get User Info
      TorusUserInfo userInfo = await Web3AuthFlutter.getUserInfo();
      // IMP END - Get User Info
      log(userInfo.toString());
      setState(() {
        _result = userInfo.toString();
      });
      return userInfo;
    } catch (e) {
      log("Error during email/passwordless login: $e");
      return Future.error("Login failed");
    }
  }

  // IMP START - Blockchain Calls
  Future<String> _getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey') ?? '0';
if (privateKey == '0' || privateKey.isEmpty) {
  log("Error: Private key not found in SharedPreferences.");
  return '';
}
log("Retrieved Private Key: $privateKey");

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
  // IMP END - Blockchain Calls
}
 */