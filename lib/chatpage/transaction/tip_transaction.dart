import 'package:flutter/material.dart';
import 'package:arbichat/main.dart';
import 'package:web3dart/web3dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';

Future<void> sendTip({
  required double tipAmount,
  required String recipientAddress,
  required BuildContext context,
}) async {
  const rpcUrl = 'https://arbitrum-sepolia-rpc.publicnode.com';
  const chainId = 421614;

  // Initialize Web3 client
  final client = Web3Client(rpcUrl, Client());

  try {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey');

    if (privateKey == null || privateKey.isEmpty) {
      throw Exception("Private key not found!");
    }

    final credentials = EthPrivateKey.fromHex(privateKey);

    final senderAddress = credentials.address;

    // Convert ETH to Wei manually
    final tipInWei =
        BigInt.from((tipAmount * BigInt.from(10).pow(18).toDouble()).toInt());

    // Convert BigInt to int
    final tipInWeiInt = tipInWei.toInt();

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
          title: const Text('Transaction Successful'),
          content: Text('$tipAmount ETH tip sent successfully to $recipientAddress.\nTransaction Hash:\n$txHash'),
          actions: [
            TextButton(
              child: const Text('OK'),
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

    navigatorKey.currentState?.pop();
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transaction Failed'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  } finally {
    client.dispose();
  }
}
