import 'package:flutter/material.dart';

import '../../../core/widgets/page_header.dart';
import 'refund_policy_card.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: const [
            PageHeader(
              title: 'Full refund policy',
              subtitle: 'Your protection, explained clearly',
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: RefundPolicyCard(),
            ),
          ],
        ),
      ),
    );
  }
}
