// BlockchainVerificationWidget.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';

const String POLYGONSCAN_API_URL = "https://api-amoy.polygonscan.com/api";
const String POLYGONSCAN_API_KEY = "GC4WK4U1PP3VHRWVSZKAMSV9YX62ZMX59G";

// Example paths to Lottie assets
const String SUCCESS_LOTTIE = "assets/successAnimation.json";
const String ERROR_LOTTIE = "assets/errorAnimation.json";
const String PENDING_LOTTIE = "assets/pendingAnimation.json";
const String BLOCKCHAIN_LOTTIE = "assets/Blockchain.json";

enum VerificationStatus { idle, pending, success, error }

class BlockchainVerificationWidget extends StatefulWidget {
  const BlockchainVerificationWidget({Key? key}) : super(key: key);

  @override
  _BlockchainVerificationWidgetState createState() => _BlockchainVerificationWidgetState();
}

class _BlockchainVerificationWidgetState extends State<BlockchainVerificationWidget> {
  String _transactionHash = "";
  Map<String, dynamic>? _transactionData;
  VerificationStatus _status = VerificationStatus.idle;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: verification UI
        Expanded(child: _buildVerificationUI()),
        // Right: optional blockchain Lottie
        Expanded(child: _buildBlockchainAnimation()),
      ],
    );
  }

  Widget _buildVerificationUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Blockchain Verification",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Verify your vote by pasting the transaction ID below."),
          const SizedBox(height: 16),

          // Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Paste your transaction ID (0x...)",
                    errorText: (_status == VerificationStatus.error && _error != null) ? _error : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _transactionHash = val;
                      _transactionData = null;
                      _status = VerificationStatus.idle;
                      _error = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _verifyTransaction,
                child: const Text("Verify"),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status indicators
          if (_status == VerificationStatus.pending)
            _buildPendingWidget(),
          if (_status == VerificationStatus.success && _transactionData != null)
            _buildSuccessWidget(),
          if (_status == VerificationStatus.error && _error != null)
            _buildErrorWidget(),
        ],
      ),
    );
  }

  Widget _buildPendingWidget() {
    return Column(
      children: [
        Lottie.asset(PENDING_LOTTIE, width: 80, height: 80),
        const SizedBox(height: 8),
        const Text("Verifying your transaction..."),
      ],
    );
  }

  Widget _buildSuccessWidget() {
    final blockNumber = _transactionData!["blockNumber"];
    final from = _transactionData!["from"];
    final to = _transactionData!["to"];
    final timestamp = _transactionData!["timestamp"];
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.green.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Lottie.asset(SUCCESS_LOTTIE, width: 60, height: 60),
          Text("Block Number: $blockNumber"),
          Text("From: $from"),
          Text("To: $to"),
          Text("Transaction Timestamp: $timestamp"),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              // open the polygonscan page
              // e.g. launchUrl("https://amoy.polygonscan.com/tx/$_transactionHash");
            },
            child: const Text(
              "🔍 View Transaction on Blockchain Explorer",
              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        Lottie.asset(ERROR_LOTTIE, width: 60, height: 60),
        const SizedBox(height: 8),
        Text("Error verifying transaction: $_error"),
      ],
    );
  }

  Widget _buildBlockchainAnimation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Lottie.asset(BLOCKCHAIN_LOTTIE, repeat: true),
          ),
          const SizedBox(height: 8),
          const Text("Secure. Immutable. Transparent.\nPowered by Blockchain.",
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _verifyTransaction() async {
    // Basic validation
    if (!_transactionHash.startsWith("0x") || _transactionHash.length != 66) {
      setState(() {
        _status = VerificationStatus.error;
        _error = "Invalid transaction format (0x... and length 66)";
      });
      return;
    }

    setState(() {
      _status = VerificationStatus.pending;
      _transactionData = null;
      _error = null;
    });

    try {
      final txUri = Uri.parse(
          "$POLYGONSCAN_API_URL?module=proxy&action=eth_getTransactionByHash&txhash=$_transactionHash&apikey=$POLYGONSCAN_API_KEY");
      final txResp = await http.get(txUri);
      final txJson = jsonDecode(txResp.body);

      if (txJson["result"] == null) {
        setState(() {
          _status = VerificationStatus.error;
          _error = "Transaction not found.";
        });
        return;
      }

      final txData = txJson["result"];
      final blockNumberHex = txData["blockNumber"];
      if (blockNumberHex == null || blockNumberHex.isEmpty) {
        setState(() {
          _status = VerificationStatus.error;
          _error = "Transaction not confirmed or missing block number.";
        });
        return;
      }

      final blockUri = Uri.parse(
          "$POLYGONSCAN_API_URL?module=proxy&action=eth_getBlockByNumber&tag=$blockNumberHex&boolean=true&apikey=$POLYGONSCAN_API_KEY");
      final blockResp = await http.get(blockUri);
      final blockJson = jsonDecode(blockResp.body);

      String theTimestamp = "Unknown";
      if (blockJson["result"] != null && blockJson["result"]["timestamp"] != null) {
        final unixHex = blockJson["result"]["timestamp"] as String;
        final timestamp = int.parse(unixHex, radix: 16);
        final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
        theTimestamp = dt.toString();
      }

      setState(() {
        _transactionData = {
          "blockNumber": txData["blockNumber"],
          "from": txData["from"],
          "to": txData["to"],
          "timestamp": theTimestamp,
        };
        _status = VerificationStatus.success;
      });
    } catch (e) {
      setState(() {
        _status = VerificationStatus.error;
        _error = "Network error. Please try again later.";
      });
    }
  }
}
