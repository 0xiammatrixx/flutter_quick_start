import 'package:flutter/material.dart';
import 'package:arbichat/chatpage/transaction/wallet_widget.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WalletBalance extends StatefulWidget {
  const WalletBalance({super.key});

  @override
  _WalletBalanceState createState() => _WalletBalanceState();
}

class _WalletBalanceState extends State<WalletBalance> {
  
  final String _rpcUrl = "https://arbitrum-sepolia-rpc.publicnode.com";
  late Web3Client _web3Client;
  EthereumAddress? _walletAddress;
  EtherAmount? _balance;
  String? _error;

  @override
  void initState() {
    super.initState();
    _web3Client = Web3Client(_rpcUrl, http.Client());
    _initializeWallet(); // Start whole process
  }

  DateTime today = DateTime.now();

  Future<void> _initializeWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawKey = prefs.getString('privateKey');
      print(" Raw privateKey from prefs: $rawKey");

      if (rawKey == null || rawKey.isEmpty) {
        setState(() {
          _error = "Invalid or missing private key. Please log in again.";
        });
        return;
      }
      final privateKey = rawKey.startsWith("0x") ? rawKey : "0x$rawKey";
      print(" Normalized privateKey: $privateKey");

      print(" Creating credentials from privateKey...");
      final credentials = EthPrivateKey.fromHex(privateKey);
      final address = credentials.address;
      print(" Wallet Address: ${address.hexEip55}");

      setState(() {
        _walletAddress = address;
      });

      print(" Fetching wallet balance from blockchain...");
      final balanceInWei = await _web3Client.getBalance(address);
      print(" Wallet balance (in Wei): ${balanceInWei.getInWei}");

      setState(() {
        _balance = balanceInWei;
      });
    } catch (e, stack) {
      print(" Exception caught during wallet initialization:");
      print("Error: $e");
      print("Stack Trace: $stack");
      setState(() {
        _error = "Failed to load wallet: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1), // shadow color
        spreadRadius: 4,
        blurRadius: 6,
        offset: const Offset(0, 4), // horizontal, vertical
      ),
    ],
          borderRadius: BorderRadius.circular(15), color: Colors.white),
      padding: const EdgeInsets.all(20),
      
      child: _error != null
          ? Text(_error!, style: const TextStyle(color: Colors.red))
          : _walletAddress == null || _balance == null
              ? const Center(child: CircularProgressIndicator(color: Colors.black,))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20,),
                          walletAddressPill(_walletAddress!.hexEip55),
                          const SizedBox(height: 50),
                          Text(
                            'Current Balance',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          Text('Today: $formattedDate')
                        ],
                      ),
                    ),
                    Container(
                      child: Row(
                        children: [
                          SizedBox(
                              height: 45,
                              width: 45,
                              child: Image.asset('assets/eth_logo.webp')),
                          Text(
                            '${_balance!.getValueInUnit(EtherUnit.ether).toStringAsFixed(4)}',
                            style: TextStyle(fontSize: 70),
                          ),
                          Text('ETH'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _web3Client.dispose();
    super.dispose();
  }
}
