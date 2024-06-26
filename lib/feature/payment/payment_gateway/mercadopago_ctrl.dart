// cspell:words mercadopago
import 'package:dio/dio.dart';
import 'package:e_com/core/core.dart';
import 'package:e_com/feature/check_out/providers/provider.dart';
import 'package:e_com/feature/payment/repository/payment_repo.dart';
import 'package:e_com/models/models.dart';
import 'package:e_com/routes/go_route_name.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final mercadoPaymentCtrlProvider = StateNotifierProvider.family<
    MercadopagoPaymentCtrl,
    Map<String, dynamic>,
    PaymentData>((ref, paymentData) {
  return MercadopagoPaymentCtrl(ref, paymentData);
});

class MercadopagoPaymentCtrl extends StateNotifier<Map<String, dynamic>> {
  MercadopagoPaymentCtrl(this._ref, this.paymentData) : super({});

  final PaymentData paymentData;

  final Ref _ref;

  String get callback => 'https://www.google.com';

  initializePayment(BuildContext context) async {
    try {
      Toaster.showLoading('Redirecting...');
      final data = await _createPayment();

      state = data;

      if (context.mounted) {
        RouteNames.mercadoPayment.goNamed(context, extra: data['init_point']);
      }

      Toaster.remove();
    } on DioException catch (e) {
      Toaster.showError(e.message);
    }
  }

  _createPayment() async {
    final headers = {
      'content-type': 'application/json',
      'Authorization': 'Bearer ${_mercadoCreds.accessToken}',
    };

    final body = {
      "items": [
        {
          "id": _order?.paymentLog.trx,
          "title": "Payment",
          "description": 'Payment from user',
          "quantity": 1,
          "currency_id": paymentData.currency.name,
          "unit_price": _order?.paymentLog.finalAmount,
        }
      ],
      "payer": {
        "email": _order?.order.billingInformation?.email,
      },
      "back_urls": {
        "success": callback,
        "pending": '',
        "failure": callback,
      },
      "notification_url": "http://notificationurl.com",
      'auto_return': 'approved',
    };
    final response = await _dio.post(
      'https://api.mercadopago.com/checkout/preferences',
      options: Options(headers: headers),
      data: body,
    );

    return response.data;
  }

  paymentConfirmation(Uri uri, BuildContext context) async {
    final body = {...uri.queryParameters, ...state};

    final callBack = '${paymentData.callbackUrl}/${_order!.paymentLog.trx}';

    await PaymentRepo().confirmPayment(context, body, callBack);
  }

  Dio get _dio => Dio()..interceptors.add(talk.dioLogger);

  MercadoCreds get _mercadoCreds =>
      MercadoCreds.fromMap(paymentData.paymentParameter);

  OrderBaseModel? get _order => _ref.read(checkoutStateProvider);
}
