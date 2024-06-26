// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:e_com/core/core.dart';
import 'package:e_com/feature/check_out/providers/provider.dart';
import 'package:e_com/feature/payment/repository/payment_repo.dart';
import 'package:e_com/models/models.dart';
import 'package:e_com/models/payment_credentials/payeer_cred.dart';
import 'package:e_com/routes/go_route_name.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pointycastle/export.dart';

final payeerPaymentCtrlProvider =
    NotifierProviderFamily<PayEerPaymentCtrlNotifier, String, PaymentData>(
        PayEerPaymentCtrlNotifier.new);

class PayEerPaymentCtrlNotifier extends FamilyNotifier<String, PaymentData> {
  String callbackUrl([String type = '']) => 'https://callback.com/?type=$type';

  Future<void> initializePayment(BuildContext context) async {
    final data = await _createPayment();

    Toaster.remove();
    RouteNames.payeerPayment.goNamed(context, extra: data);
  }

  Future<void> executePayment(BuildContext context, Uri? url) async {
    final body = url?.queryParameters ?? {};

    final trx = _order!.paymentLog.trx;
    final callbackUrl = '${arg.callbackUrl}/$trx';

    await PaymentRepo().confirmPayment(context, body, callbackUrl);
  }

  Dio get _dio => Dio(); // ..interceptors.add(talk.dioLogger);

  PayeerCred get _cred => PayeerCred.fromMap(arg.paymentParameter);

  int get _finalAmount => _order!.paymentLog.finalAmount.round();

  _createPayment() async {
    try {
      String shop = _cred.merchantId;
      String orderId = _order!.paymentLog.trx;
      String amount = _finalAmount.toString();
      String currency = _order!.paymentLog.method.currency.name;
      String desc = 'Payment for order ${_order!.paymentLog.trx}';
      String key = _cred.secretKey;
      String desc64 = base64.encode(utf8.encode(desc));
      final successUrl = callbackUrl('success');
      final cancelUrl = callbackUrl('fail');

      final signString = "$shop:$orderId:$amount:$currency:$desc64:$key";

      final sha256 = SHA256Digest();
      final hash = sha256.process(utf8.encode(signString));
      final sign = base64Encode(hash).toUpperCase();

      final queryParameters = {
        'm_shop': shop,
        'm_orderid': orderId,
        'm_amount': amount,
        'm_curr': currency,
        'm_desc': desc64,
        'm_sign': sign,
        'success_url': successUrl,
        'fail_url': cancelUrl,
      };

      final uri = Uri(
        scheme: 'https',
        host: 'payeer.com',
        path: '/merchant/',
        queryParameters: queryParameters,
      );
      return uri.toString();
    } catch (e, s) {
      talk.ex(e, s);
      rethrow;
    }
  }

  OrderBaseModel? get _order => ref.read(checkoutStateProvider);

  @override
  String build(PaymentData arg) {
    return '';
  }
}
