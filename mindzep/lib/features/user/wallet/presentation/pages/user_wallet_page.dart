import 'package:flutter/material.dart';

class UserWalletPage extends StatelessWidget {
  const UserWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF34C759), Color(0xFF30D158)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Wallet', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(children: [
                          const Text('Available Balance', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
                          const SizedBox(height: 8),
                          const Text('₹415', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                                  child: const Text('Add Money', textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF34C759))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                                  ),
                                  child: const Text('Withdraw', textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                              ),
                            ),
                          ]),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 12),
                  ..._transactions.map((t) => _TransactionTile(transaction: t)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _transactions = [
    {'icon': Icons.phone_rounded, 'label': 'Session with Dr. Ananya', 'amount': '-₹42', 'date': 'Today', 'positive': false},
    {'icon': Icons.add_circle_rounded, 'label': 'Added to wallet', 'amount': '+₹500', 'date': 'Yesterday', 'positive': true},
    {'icon': Icons.phone_rounded, 'label': 'Session with Dr. Vikram', 'amount': '-₹68', 'date': '10 May', 'positive': false},
    {'icon': Icons.add_circle_rounded, 'label': 'Added to wallet', 'amount': '+₹200', 'date': '8 May', 'positive': true},
  ];
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction['positive'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: isPositive ? const Color(0xFFE8FFF1) : const Color(0xFFFFF0EE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(transaction['icon'] as IconData, color: isPositive ? const Color(0xFF34C759) : const Color(0xFFFF6B6B), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(transaction['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
            Text(transaction['date'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          ]),
        ),
        Text(
          transaction['amount'] as String,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isPositive ? const Color(0xFF34C759) : const Color(0xFF1C1C1E)),
        ),
      ]),
    );
  }
}
