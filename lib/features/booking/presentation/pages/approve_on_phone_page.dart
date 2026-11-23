import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/presentation/booking_flow.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/payment_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/seat_hold_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/flow_scaffold.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/hold_expiry_guard.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/hold_timer_banner.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/info_note.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';

/// Screen 4 of 5: waiting for the payer to enter their PIN.
///
/// Listens to the live payment document. As soon as Firestore says
/// `successful` it moves to the receipt; on `failed` it explains why and
/// offers to change the method.
class ApproveOnPhonePage extends StatelessWidget {
  const ApproveOnPhonePage({super.key});

  void _onPaymentChanged(BuildContext context, PaymentState state) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final booking = context.read<SeatHoldCubit>().state.booking;
    if (state.status == PaymentFlowStatus.successful &&
        state.payment != null &&
        booking != null) {
      BookingFlow.finish(context, booking: booking, payment: state.payment!);
      return;
    }
    if (state.message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message!)));
    }
  }

  Future<void> _changeMethod(BuildContext context) async {
    final navigator = Navigator.of(context);
    await context.read<PaymentCubit>().changeMethod();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.read<BookingFlowArgs>().trip;
    final total = Formatters.money(trip.total, trip.currency);

    return HoldExpiryGuard(
      child: PopScope(
        // System back behaves like "Change Payment Method" so an abandoned
        // prompt is always cancelled first.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _changeMethod(context);
        },
        child: BlocConsumer<PaymentCubit, PaymentState>(
          listenWhen: (p, c) => p.status != c.status || p.message != c.message,
          listener: _onPaymentChanged,
          builder: (context, state) {
            final payment = state.payment;
            final phone = Formatters.phone(payment?.payerPhone ?? state.phone);
            final failed = state.status == PaymentFlowStatus.failed;
            final methodLabel = payment?.method.label ?? state.method.label;

            final heading = failed
                ? 'Payment not completed.'
                : state.isRequest
                ? 'Waiting for the payer.'
                : 'Approve on your phone.';
            final body = failed
                ? (state.message ??
                      'The payment didn\'t go through. No money was taken.')
                : state.isRequest
                ? 'We sent a secure payment link to $phone. Your seat '
                      'stays reserved while they pay $total.'
                : payment?.method.needsPhone ?? true
                ? 'We sent an $methodLabel prompt to $phone. Enter '
                      'your PIN there to pay $total.'
                : 'Confirm the $total card payment with your bank.';

            return FlowScaffold(
              title: 'Payment',
              subtitle: '$methodLabel · $total',
              bottom: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!failed) ...[
                    PrimaryButton(
                      key: const ValueKey('check-status'),
                      label: 'Check Payment Status',
                      loading: state.isChecking,
                      onPressed: context.read<PaymentCubit>().checkStatus,
                    ),
                    const SizedBox(height: 10),
                  ],
                  PrimaryButton(
                    key: const ValueKey('change-method'),
                    label: failed
                        ? 'Try Another Method'
                        : 'Change Payment Method',
                    style: failed
                        ? PrimaryButtonStyle.dark
                        : PrimaryButtonStyle.outlined,
                    onPressed: () => _changeMethod(context),
                  ),
                ],
              ),
              children: [
                const HoldTimerBanner(title: 'Your seat stays protected'),
                const SizedBox(height: 28),
                Center(child: _PhonePulse(failed: failed)),
                const SizedBox(height: 20),
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.palette.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.palette.muted,
                  ),
                ),
                const SizedBox(height: 20),
                _StatusSteps(status: state.status, isRequest: state.isRequest),
                const InfoNote(
                  tone: InfoNoteTone.caution,
                  title: 'Protected: Never charged twice',
                  message:
                      'If the connection drops, retry this payment. We '
                      'check its status before any new charge.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The phone icon in a lime circle that gently pulses while waiting.
class _PhonePulse extends StatefulWidget {
  const _PhonePulse({required this.failed});

  final bool failed;

  @override
  State<_PhonePulse> createState() => _PhonePulseState();
}

class _PhonePulseState extends State<_PhonePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.94,
    end: 1.06,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didUpdateWidget(covariant _PhonePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.failed) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: widget.failed
                ? context.palette.warningSoft
                : context.palette.limeSoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: widget.failed
                  ? context.palette.warningSoft
                  : AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.failed
                  ? Icons.phonelink_erase_outlined
                  : Icons.phone_android_rounded,
              size: 32,
              color: widget.failed
                  ? context.palette.warningText
                  : context.palette.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Seat locked → Waiting for approval → QR ticket" checklist.
class _StatusSteps extends StatelessWidget {
  const _StatusSteps({required this.status, required this.isRequest});

  final PaymentFlowStatus status;
  final bool isRequest;

  @override
  Widget build(BuildContext context) {
    final waiting =
        status == PaymentFlowStatus.awaitingApproval ||
        status == PaymentFlowStatus.submitting;
    final failed = status == PaymentFlowStatus.failed;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        children: [
          const _Step(state: _StepState.done, label: 'Seat locked'),
          _Step(
            state: failed
                ? _StepState.failed
                : waiting
                ? _StepState.working
                : _StepState.done,
            label: failed
                ? 'Payment not approved'
                : isRequest
                ? 'Waiting for the payer'
                : 'Waiting for phone approval',
          ),
          const _Step(state: _StepState.next, label: 'Your QR ticket is next'),
        ],
      ),
    );
  }
}

enum _StepState { done, working, failed, next }

class _Step extends StatelessWidget {
  const _Step({required this.state, required this.label});

  final _StepState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Widget leading = switch (state) {
      _StepState.done => const Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: 20,
      ),
      _StepState.working => SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: context.palette.warningText,
        ),
      ),
      _StepState.failed => const Icon(
        Icons.cancel,
        color: AppColors.error,
        size: 20,
      ),
      _StepState.next => Icon(
        Icons.radio_button_unchecked,
        color: context.palette.border,
        size: 20,
      ),
    };
    return ListTile(
      dense: true,
      leading: SizedBox(width: 24, child: Center(child: leading)),
      minLeadingWidth: 24,
      title: Text(
        label,
        style: TextStyle(
          color: state == _StepState.next
              ? context.palette.muted
              : context.palette.text,
          fontWeight: state == _StepState.working
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    );
  }
}
