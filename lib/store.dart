import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Holds all orders and saves them on the phone (SharedPreferences) as JSON,
/// so records are still there after the app is closed and reopened.
class OrderStore extends ChangeNotifier {
  static const _key = 'craftOrders.v1';

  List<Order> orders = [];
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        orders = (jsonDecode(raw) as List)
            .map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        orders = [];
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await _prefs?.setString(
        _key, jsonEncode(orders.map((o) => o.toJson()).toList()));
  }

  Order? byId(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  Future<void> add(Order o) async {
    orders.add(o);
    notifyListeners();
    await _save();
  }

  Future<void> update(Order o) async {
    final i = orders.indexWhere((x) => x.id == o.id);
    if (i >= 0) orders[i] = o;
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    orders.removeWhere((o) => o.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> setStatus(String id, String status) async {
    final o = byId(id);
    if (o == null) return;
    o.status = status;
    notifyListeners();
    await _save();
  }

  Future<void> addPayment(String id, int amount) async {
    final o = byId(id);
    if (o == null) return;
    o.deposit += amount;
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    orders = [];
    notifyListeners();
    await _save();
  }

  Future<void> loadSample() async {
    String d(int offset) =>
        isoDate(DateTime.now().add(Duration(days: offset)));
    Order mk(String customer, String phone, String item, int qty, int price,
            int deposit, int dt, int due, String status,
            [String notes = '']) =>
        Order(
          id: newId() + item.length.toString() + customer.length.toString(),
          customer: customer,
          phone: phone,
          item: item,
          qty: qty,
          price: price,
          deposit: deposit,
          date: d(dt),
          due: d(due),
          status: status,
          notes: notes,
        );
    final samples = [
      mk('Grace Namutebi', '0770123456', 'Raffia basket', 4, 25000, 40000,
          -10, 4, 'In Progress'),
      mk('Moses Okello', '0701234567', 'Beaded necklace', 10, 12000, 120000,
          -20, -3, 'Ready', 'Gift packs'),
      mk('Sarah Nakato', '', 'Woven floor mat', 2, 60000, 30000, -6, 8,
          'Pending'),
      mk('Peter Kato', '0755987654', 'Wooden carved bowl', 6, 18000, 108000,
          -30, -15, 'Delivered'),
      mk('Grace Namutebi', '0770123456', 'Bark cloth wall hanging', 1, 150000,
          50000, -2, 14, 'Pending', 'Custom size'),
    ];
    // make ids unique even when created in the same microsecond
    for (var i = 0; i < samples.length; i++) {
      samples[i].id = '${samples[i].id}_$i';
    }
    orders.addAll(samples);
    notifyListeners();
    await _save();
  }
}

final OrderStore store = OrderStore();
