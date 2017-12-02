import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:http/http.dart';

class Mapping {
  final String source;

  final String target;

  const Mapping(this.source, this.target);

  String get symbol => '$source$target';

  static const Mapping btcUSDT = const Mapping('BTC', 'USDT');

  static const Mapping wtcBTC = const Mapping('WTC', 'BTC');

  static const Mapping ethUSDT = const Mapping('ETH', 'USDT');

  static const Mapping neoUSDT = const Mapping('NEO', 'USDT');

  static Map<String, T> filter<T>(Map<String, T> items, List<Mapping> filter) {
    final ret = <String, T>{};
    for (Mapping map in filter) {
      ret[map.symbol] = items[map.symbol];
    }
    return ret;
  }

  String toString() => '$source -> $target';
}

/// Contains price of one currency-to-currency mapping
class Price {
  /// Name of the currency-to-currency mapping
  final String symbol;

  /// Price of the currency-to-currency mapping
  final double price;

  const Price(this.symbol, this.price);

  factory Price.fromApiMap(Map map) {
    final String symbol = map['symbol'];
    final double price = double.parse(map['price']);

    return new Price(symbol, price);
  }

  String toString() {
    final sb = new StringBuffer();
    sb.writeln('Symbol: $symbol');
    sb.writeln('Price: $price');
    return sb.toString();
  }
}

/// Contains order book of one currency-to-currency mapping
class Ticker {
  /// Name of the currency-to-currency mapping
  final String symbol;

  /// Bid price of the currency-to-currency mapping
  final double bidPrice;

  /// Bid quantity of the currency-to-currency mapping
  final double bidQty;

  /// Ask price of the currency-to-currency mapping
  final double askPrice;

  /// Ask quantity of the currency-to-currency mapping
  final double askQty;

  const Ticker(
      this.symbol, this.bidPrice, this.bidQty, this.askPrice, this.askQty);

  factory Ticker.fromApiMap(Map map) {
    final String symbol = map['symbol'];
    final double bidPrice = double.parse(map['bidPrice']);
    final double bidQty = double.parse(map['bidQty']);
    final double askPrice = double.parse(map['askPrice']);
    final double askQty = double.parse(map['askQty']);

    return new Ticker(symbol, bidPrice, bidQty, askPrice, askQty);
  }

  String toString() {
    final sb = new StringBuffer();

    sb.writeln('Symbol: $symbol');
    sb.writeln('Bid price: $bidPrice');
    sb.writeln('Bid quantity: $bidQty');
    sb.writeln('Ask price: $askPrice');
    sb.writeln('Ask quantity: $askQty');

    return sb.toString();
  }
}

/// Contain endpoint access of open API
abstract class BinanceOpen {
  /// HTTP client instance used to place REST calls to Cryptonator server
  static BaseClient _client;

  static void init(BaseClient client) {
    _client = client;
  }

  static Future<Map<String, Price>> get allPrices async {
    final resp =
        await _client.get('https://api.binance.com/api/v1/ticker/allPrices');
    final List<Map> body = JSON.decode(resp.body);
    final ret = <String, Price>{};
    body.map((map) => new Price.fromApiMap(map)).forEach((Price p) {
      ret[p.symbol] = p;
    });
    return ret;
  }

  static Future<Map<String, Ticker>> get tickers async {
    final resp = await _client
        .get('https://api.binance.com/api/v1/ticker/allBookTickers');
    final List<Map> body = JSON.decode(resp.body);
    final ret = <String, Ticker>{};
    body.map((map) => new Ticker.fromApiMap(map)).forEach((Ticker p) {
      ret[p.symbol] = p;
    });
    return ret;
  }

  static Future<Klines> klines(Mapping mapping, Interval interval) async {
    final resp = await _client.get(
        'https://api.binance.com/api/v1/klines?symbol=${mapping.symbol}&interval=${interval.value}');
    final List<List> body = JSON.decode(resp.body);

    final List<Kline> ret =
        body.map((map) => new Kline.fromApiList(map)).toList();
    return new Klines(mapping, interval.duration, ret);
  }

  static Future<Depth> depth(Mapping mapping) async {
    final resp = await _client
        .get('https://api.binance.com/api/v1/depth?symbol=${mapping.symbol}');
    final Map<String, dynamic> body = JSON.decode(resp.body);
    return new Depth.fromApiMap(mapping, body);
  }
}

class Interval {
  final int id;

  final String value;

  final Duration duration;

  const Interval(this.id, this.value, this.duration);

  static const Interval m1 =
      const Interval(0, '1m', const Duration(minutes: 1));
  static const Interval m3 =
      const Interval(1, '3m', const Duration(minutes: 3));
  static const Interval m5 =
      const Interval(2, '5m', const Duration(minutes: 5));
  static const Interval m15 =
      const Interval(3, '15m', const Duration(minutes: 15));
  static const Interval m30 =
      const Interval(4, '30m', const Duration(minutes: 30));
  static const Interval h1 = const Interval(5, '1h', const Duration(hours: 1));
  static const Interval h2 = const Interval(6, '2h', const Duration(hours: 2));
  static const Interval h4 = const Interval(7, '4h', const Duration(hours: 4));
  static const Interval h6 = const Interval(8, '6h', const Duration(hours: 6));
  static const Interval h8 = const Interval(9, '8h', const Duration(hours: 8));
  static const Interval h12 =
      const Interval(10, '12h', const Duration(hours: 12));
  static const Interval d1 = const Interval(11, '1d', const Duration(days: 1));
  static const Interval d3 = const Interval(12, '3d', const Duration(days: 3));
  static const Interval w1 = const Interval(13, '1w', const Duration(days: 7));
  static const Interval month1 =
      const Interval(14, '1M', const Duration(days: 30));
}

class Kline {
  /// Open time
  final DateTime openTime;

  /// Open price
  final double openPrice;

  /// High price
  final double highPrice;

  /// Low price
  final double lowPrice;

  // Close price
  final double closePrice;

  /// Volume
  final double volume;

  /// Close time
  final DateTime closeTime;

  /// Quote asset volume
  final double quoteAssetVolume;

  // Number of trades
  final int numTrades;

  /// Taker buy base asset volume
  final double takerBuyBaseAssetVolume;

  /// Taker buy quote asset volume
  final double takerBuyQuoteAssetVolume;

  const Kline(
      {@required this.openTime,
      @required this.openPrice,
      @required this.highPrice,
      @required this.lowPrice,
      @required this.closePrice,
      @required this.volume,
      @required this.closeTime,
      @required this.quoteAssetVolume,
      @required this.numTrades,
      @required this.takerBuyBaseAssetVolume,
      @required this.takerBuyQuoteAssetVolume});

  factory Kline.fromApiList(List list) {
    final openTime = new DateTime.fromMillisecondsSinceEpoch(list[0]);
    final openPrice = double.parse(list[1]);
    final highPrice = double.parse(list[2]);
    final lowPrice = double.parse(list[3]);
    final closePrice = double.parse(list[4]);
    final volume = double.parse(list[5]);
    final closeTime = new DateTime.fromMillisecondsSinceEpoch(list[6]);
    final quoteAssetVolume = double.parse(list[7]);
    final int numTrades = list[8];
    final takerBuyBaseAssetVolume = double.parse(list[9]);
    final takerBuyQuoteAssetVolume = double.parse(list[10]);

    return new Kline(
        openTime: openTime,
        openPrice: openPrice,
        highPrice: highPrice,
        lowPrice: lowPrice,
        closePrice: closePrice,
        volume: volume,
        closeTime: closeTime,
        numTrades: numTrades,
        quoteAssetVolume: quoteAssetVolume,
        takerBuyBaseAssetVolume: takerBuyBaseAssetVolume,
        takerBuyQuoteAssetVolume: takerBuyQuoteAssetVolume);
  }

  String toString() {
    final sb = new StringBuffer();
    sb.writeln(
        'Time span: ${openTime.toIso8601String()} ${closeTime.toIso8601String()}');
    sb.writeln('Price span: $openPrice $closePrice');
    sb.writeln('Price extent: $lowPrice $highPrice');
    sb.writeln('Volume: $volume');
    return sb.toString();
  }
}

class Klines {
  final Mapping mapping;

  final Duration interval;

  final UnmodifiableListView<Kline> klines;

  Klines(this.mapping, this.interval, Iterable<Kline> klines)
      : klines = klines is UnmodifiableListView<Kline>
            ? klines
            : new UnmodifiableListView(klines);

  DateTime get openingTime => klines.first.openTime;

  double get openingPrice => klines.first.openPrice;

  DateTime get closingTime => klines.first.closeTime;

  double get closePrice => klines.first.closePrice;

  String toString() {
    final sb = new StringBuffer();
    sb.writeln('$mapping:');
    sb.write(klines.join('\n\n'));
    return sb.toString();
  }
}

class Depth {
  final Mapping mapping;

  final int id;

  final UnmodifiableListView<DepthItem> bids;

  final UnmodifiableListView<DepthItem> asks;

  Depth(this.mapping, this.id, Iterable<DepthItem> bids, Iterable<DepthItem> asks)
      : bids = bids is UnmodifiableListView<DepthItem>
            ? bids
            : new UnmodifiableListView<DepthItem>(bids),
        asks = asks is UnmodifiableListView<DepthItem>
            ? asks
            : new UnmodifiableListView<DepthItem>(asks);

  factory Depth.fromApiMap(Mapping mapping, Map map) {
    final List<DepthItem> bids = (map['bids'] as List<List>)
        .map((i) => new DepthItem.fromApiList(i))
        .toList();
    final List<DepthItem> asks = (map['asks'] as List<List>)
        .map((i) => new DepthItem.fromApiList(i))
        .toList();
    return new Depth(mapping, map['lastUpdateId'], bids, asks);
  }
}

class DepthItem {
  final double price;

  final double quantity;

  const DepthItem(this.price, this.quantity);

  factory DepthItem.fromApiList(List list) {
    final price = double.parse(list[0]);
    final quantity = double.parse(list[1]);
    return new DepthItem(price, quantity);
  }

  String toString() {
    final sb = new StringBuffer();
    sb.writeln('Price: $price');
    sb.writeln('Quantity: $quantity');
    return sb.toString();
  }
}
