import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget walletAddressPill(String fullAddress) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;

      
      const iconWidth = 30.0;
      const charWidth = 8.0;
      final availableWidth = maxWidth - iconWidth;

      final maxChars = (availableWidth / charWidth).floor();

      String displayAddress;
      if (fullAddress.length <= maxChars) {
        displayAddress = fullAddress;
      } else {
        final frontLength = (maxChars / 2).floor();
        final endLength = 4;
        displayAddress = '${fullAddress.substring(0, frontLength)}...${fullAddress.substring(fullAddress.length - endLength)}';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Only take remaining space (minus the icon)
            Expanded(
              child: Text(
                displayAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: fullAddress));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wallet address copied')),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
