import 'package:flutter/material.dart';
import 'package:w3aflutter/main.dart';
import 'package:web3dart/web3dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart'; // For RPC calls

Future<void> sendTip({
  required double tipAmount,
  required String recipientAddress,
  required BuildContext context,
}) async {
  // Minimum tip amount in ETH
  const double minTipAmount = 0.0001;

  if (tipAmount < minTipAmount) {
    // Show a Snackbar for invalid tip amounts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invalid tip amount: Must be at least $minTipAmount ETH'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  // RPC URL for Arbitrum Sepolia testnet
  const rpcUrl = 'https://rpc.ankr.com/arbitrum_sepolia';
  const chainId = 421614; // Chain ID for Arbitrum Sepolia

  // Initialize Web3 client
  final client = Web3Client(rpcUrl, Client());

  try {
    // Retrieve private key from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey');

    if (privateKey == null || privateKey.isEmpty) {
      throw Exception("Private key not found!");
    }

    // Create credentials
    final credentials = EthPrivateKey.fromHex(privateKey);

    // Derive sender address
    final senderAddress = credentials.address;

    // Convert ETH to wei
    //final tipInWei = BigInt.from((tipAmount * BigInt.from(10).pow(18).toDouble()).toInt());

    // Convert ETH to Wei manually
    final tipInWei =
        BigInt.from((tipAmount * BigInt.from(10).pow(18).toDouble()).toInt());

    // Convert BigInt to int (this will work only if tipInWei is within int range)
    final tipInWeiInt = tipInWei.toInt();

    if (tipInWei < BigInt.from(100000000000000)) {
      throw Exception("Tip amount is too small (minimum is 0.0001 ETH)");
    }

    final gasEstimate = await client.estimateGas(
      sender: senderAddress,
      to: EthereumAddress.fromHex(recipientAddress),
      value: EtherAmount.inWei(tipInWei),
    );

    // Create transaction
    final transaction = Transaction(
      to: EthereumAddress.fromHex(recipientAddress),
      from: senderAddress,
      value: EtherAmount.fromInt(EtherUnit.wei, tipInWeiInt),
      gasPrice:
          EtherAmount.inWei(BigInt.from(20000000000)), // Example gas price
      maxGas: gasEstimate.toInt(), // Standard gas limit for ETH transfer
    );

    // Sign and send transaction
    final txHash = await client.sendTransaction(
      credentials,
      transaction,
      chainId: chainId,
    );

    // Display transaction hash
    print('Transaction successful: $txHash');
    navigatorKey.currentState?.pop(); // Close loading dialog
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Transaction Successful'),
          content: Text('$tipAmount ETH tip sent successfully to $recipientAddress.\nTransaction Hash:\n$txHash'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  } catch (e) {
    print('Transaction failed: $e');

    navigatorKey.currentState?.pop(); // Close loading dialog
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Transaction Failed'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  } finally {
    // Dispose of the client to free resources
    client.dispose();
  }
}
