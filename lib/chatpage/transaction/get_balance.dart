import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WalletBalance extends StatefulWidget {
  @override
  _WalletBalanceState createState() => _WalletBalanceState();
}

class _WalletBalanceState extends State<WalletBalance> {
  final String _rpcUrl = "https://rpc.ankr.com/arbitrum_sepolia";
  late Web3Client _web3Client;
  EthereumAddress? _walletAddress;
  EtherAmount? _balance;
  bool _isLoading = false; // Set loading to false initially
  String? _error;

  @override
  void initState() {
    super.initState();
    _web3Client = Web3Client(_rpcUrl, http.Client());
    _fetchWalletAddress(); // Fetch the wallet address during initialization
  }

  // Fetch wallet address from SharedPreferences
  Future<void> _fetchWalletAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final privateKey = prefs.getString('privateKey');

      if (privateKey == null || privateKey.isEmpty) {
        setState(() {
          _error = "No wallet address found. Please log in again.";
        });
        return;
      }

      final credentials = EthPrivateKey.fromHex(privateKey);
      setState(() {
        _walletAddress = credentials.address;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to retrieve wallet address: $e";
      });
    }
  }

  // Fetch the balance of the wallet
  Future<void> _fetchBalance() async {
    if (_walletAddress == null) {
      setState(() {
        _error = "Wallet address is not available.";
      });
      return;
    }

    setState(() {
      _isLoading = true; // Start loading when button is pressed
    });

    try {
      // Fetch balance in Wei
      EtherAmount balanceInWei = await _web3Client.getBalance(_walletAddress!);
      // Update state with the balance
      setState(() {
        _balance = balanceInWei;
        _isLoading = false; // Stop loading when done
      });
    } catch (e) {
      setState(() {
        _error = "Error fetching balance: $e";
        _isLoading = false; // Stop loading on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container( padding: EdgeInsets.all(15),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
            ] else if (_walletAddress != null) ...[
              Text(
                "Wallet Address: ${_walletAddress!.hexEip55}",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchBalance, // Trigger balance fetch on press
                child: Text("Get Wallet Balance"),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator() // Show loading spinner
                  : _balance == null
                      ? Text("") // Message if no balance yet
                      : Text(
                          "Wallet Balance: ${_balance!.getValueInUnit(EtherUnit.ether)} ETH",
                          style: TextStyle(fontSize: 24), // Display balance
                        ),
            ] else ...[
              CircularProgressIndicator(), // Show while loading the wallet address
              SizedBox(height: 20),
              Text("Fetching wallet address..."),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _web3Client.dispose();
    super.dispose();
  }
}
