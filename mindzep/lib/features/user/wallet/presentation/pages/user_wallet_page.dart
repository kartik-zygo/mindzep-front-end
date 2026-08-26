import 'package:flutter/material.dart';

import '../../../../../injection/injection_container.dart';
import '../../../data/models/user_models.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../payments/data/models/payment_models.dart';
import '../../../payments/data/repositories/payment_repository.dart';
import 'wallet_topup_page.dart';

class UserWalletPage extends StatefulWidget {
  const UserWalletPage({super.key});

  @override
  State<UserWalletPage> createState() => _UserWalletPageState();
}

class _UserWalletPageState extends State<UserWalletPage> {
  late final UserRepository _userRepository;
  late final PaymentRepository _paymentRepository;
  late Future<_WalletData> _walletFuture;

  @override
  void initState() {
    super.initState();
    _userRepository = sl<UserRepository>();
    _paymentRepository = sl<PaymentRepository>();
    _walletFuture = _loadWalletData();
  }

  Future<_WalletData> _loadWalletData() async {
    final wallet = await _userRepository.getMyWallet();

    List<PaymentRecordModel> payments = const <PaymentRecordModel>[];
    try {
      payments = await _paymentRepository.listPayments();
    } catch (_) {
      // Payment history should not block wallet screen.
    }

    return _WalletData(wallet: wallet, payments: payments);
  }

  Future<void> _openTopUp() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const WalletTopUpPage()),
    );
    // Refresh wallet data when user successfully topped up
    if (result == true && mounted) {
      setState(() {
        _walletFuture = _loadWalletData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WalletData>(
      future: _walletFuture,
      builder: (context, snapshot) {
        final wallet = snapshot.data?.wallet ??
            const WalletSummaryModel(
              balance: 0,
              totalCredits: 0,
              totalDebits: 0,
              currency: 'INR',
              raw: <String, dynamic>{},
            );
        final transactions = snapshot.data?.payments ?? const <PaymentRecordModel>[];

        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F7),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openTopUp,
            backgroundColor: const Color(0xFF34C759),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Add Money',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
                          const Text(
                            'My Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(children: [
                              const Text(
                                'Available Balance',
                                style: TextStyle(
                                  color: Color(0xCCFFFFFF),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              snapshot.connectionState == ConnectionState.waiting
                                  ? const SizedBox(
                                      height: 52,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '₹${wallet.balance.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              const SizedBox(height: 16),
                              Row(children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      'Credits ₹${wallet.totalCredits.toStringAsFixed(0)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF34C759),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      'Debits ₹${wallet.totalDebits.toStringAsFixed(0)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (transactions.isEmpty)
                        const _EmptyTransactions()
                      else
                        ...transactions.map((payment) => _TransactionTile(payment: payment)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WalletData {
  final WalletSummaryModel wallet;
  final List<PaymentRecordModel> payments;

  const _WalletData({
    required this.wallet,
    required this.payments,
  });
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'No wallet transactions yet.',
        style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PaymentRecordModel payment;
  const _TransactionTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isPositive = (payment.type ?? '').toLowerCase().contains('credit') ||
        payment.status.toLowerCase().contains('refund');
    final icon = isPositive ? Icons.add_circle_rounded : Icons.phone_rounded;
    final sign = isPositive ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isPositive ? const Color(0xFFE8FFF1) : const Color(0xFFFFF0EE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isPositive ? const Color(0xFF34C759) : const Color(0xFFFF6B6B),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (payment.type ?? 'Payment').trim().isEmpty ? 'Payment' : payment.type!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              Text(
                _formatDate(payment.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
        ),
        Text(
          '$sign₹${payment.amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPositive ? const Color(0xFF34C759) : const Color(0xFF1C1C1E),
          ),
        ),
      ]),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
