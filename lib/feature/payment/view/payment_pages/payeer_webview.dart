import 'package:e_com/core/core.dart';
import 'package:e_com/feature/check_out/providers/provider.dart';
import 'package:e_com/feature/payment/payment_gateway/payeer_ctrl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../widgets/widgets.dart';

class PayeerWebviewPage extends HookConsumerWidget {
  const PayeerWebviewPage({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethod = ref.watch(
      checkoutStateProvider.select((value) => value?.paymentLog.method),
    );

    if (paymentMethod == null) {
      return ErrorView.withScaffold('Failed to load CashMaal Information');
    }

    final payCtrl = useCallback(
        () => ref.read(payeerPaymentCtrlProvider(paymentMethod).notifier));

    final progress = useState<double?>(null);

    final webCtrl = useState<InAppWebViewController?>(null);

    useEffect(() => webCtrl.value?.clearCache);

    return Scaffold(
      backgroundColor: context.colorTheme.background,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () {
            webCtrl.value?.clearCache();
            webCtrl.value?.clearFocus();
            context.pop();
          },
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            shouldOverrideUrlLoading: (controller, action) async {
              final url = action.request.url;
              Logger(url, 'url');

              if (url.toString().contains(payCtrl().callbackUrl())) {
                await payCtrl().executePayment(context, url);
                return NavigationActionPolicy.CANCEL;
              }

              return NavigationActionPolicy.ALLOW;
            },
            initialUrlRequest: URLRequest(
              url: Uri.parse(url),
            ),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform:
                  InAppWebViewOptions(useShouldOverrideUrlLoading: true),
            ),
            onWebViewCreated: (controller) => webCtrl.value = controller,
            onCloseWindow: (controller) async {
              webCtrl.value?.clearCache();
              webCtrl.value?.clearFocus();
            },
            onProgressChanged: (controller, p) => progress.value = p / 100,
          ),
          LinearProgressIndicator(value: progress.value),
        ],
      ),
    );
  }
}

// URLRequest(
//               url: Uri.parse(
//                 'https://www.cashmaal.com/Pay',
//               ),
//               method: 'post',
//               body: utf8.encode(
//                 json.encode(
//                   {
//                     'amount': '100',
//                     'currency': 'usd',
//                     'succes_url': 'https://www.google.com/s',
//                     'cancel_url': 'https://www.google.com/f',
//                     'client_email': 'qNQpG@example.com',
//                     'web_id': '3748',
//                     'pay_method': 'cm',
//                   },
//                 ),
//               ),
//             ),
