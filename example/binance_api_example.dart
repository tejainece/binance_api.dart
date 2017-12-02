import 'dart:io';
import 'dart:async';
import 'package:http/http.dart';
import 'package:binance_api/binance_api.dart';

main() async {
  BinanceOpen.init(new IOClient());
  /* TODO
  {
    final Map<String, Price> prices = await BinanceOpen.allPrices;
    stdout.write(prices[Mapping.btcUSDT.symbol].price.toString());
  }
  new Timer.periodic(const Duration(seconds: 10), (_) async {
    final Map<String, Price> prices = await BinanceOpen.allPrices;
    stdout.write('\r' + prices[Mapping.btcUSDT.symbol].price.toString());
  });
  */
  final Depth depth = await BinanceOpen.depth(Mapping.btcUSDT);
  print(depth.bids);
}
