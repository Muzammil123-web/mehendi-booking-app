import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../utils/constants.dart';

/// Thin wrapper around the Razorpay checkout SDK.
///
/// Usage:
///   final payment = PaymentService();
///   payment.openCheckout(
///     amount: 499.0,
///     name: 'Bridal Henna Booking',
///     onSuccess: (paymentId) { ... mark booking/order as paid ... },
///     onError: (msg) { ... show error ... },
///   );
///
/// IMPORTANT: Set your real key in lib/utils/constants.dart (razorpayKeyId).
/// Order creation for signature verification should ideally happen via a
/// small backend / Cloud Function that calls Razorpay's Orders API with
/// your KEY SECRET (never put the secret in the app). This class covers
/// standard (non-order-linked) checkout, which is enough to accept
/// payments; upgrade to server-side orders for production-grade
/// verification once you have a Cloud Function deployed.
class PaymentService {
  late Razorpay _razorpay;
  Function(String paymentId)? _onSuccess;
  Function(String message)? _onError;

  PaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required double amount, // in rupees
    required String name,
    required String description,
    required String contactPhone,
    required String contactEmail,
    required Function(String paymentId) onSuccess,
    required Function(String message) onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;

    final options = {
      'key': AppConstants.razorpayKeyId,
      'amount': (amount * 100).toInt(), // Razorpay expects paise
      'name': AppConstants.appName,
      'description': description,
      'prefill': {
        'contact': contactPhone,
        'email': contactEmail,
      },
      'theme': {'color': '#8B2E3C'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _onError?.call(e.toString());
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(response.paymentId ?? '');
  }

  void _handleError(PaymentFailureResponse response) {
    _onError?.call(response.message ?? 'Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optional: handle Paytm/other external wallets here.
  }

  void dispose() {
    _razorpay.clear();
  }
}
