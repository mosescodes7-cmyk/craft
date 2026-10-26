// Pure logic: model, calculations, validation, summary.
// No Flutter imports, so it can be unit tested easily.

const List<String> statuses = ['Pending', 'In Progress', 'Ready', 'Delivered'];

class Order {
  Order({
    required this.id,
    required this.customer,
    required this.phone,
    required this.item,
    required this.qty,
    required this.price,
    required this.deposit,
    required this.date,
    required this.due,
    required this.status,
    required this.notes,
  });

  String id;
  String customer;
  String phone;
  String item;
  int qty;
  int price;
  int deposit;
  String date; // yyyy-MM-dd
  String due; // yyyy-MM-dd
  String status;
  String notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer': customer,
        'phone': phone,
        'item': item,
        'qty': qty,
        'price': price,
        'deposit': deposit,
        'date': date,
        'due': due,
        'status': status,
        'notes': notes,
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String,
        customer: j['customer'] as String,
        phone: (j['phone'] ?? '') as String,
        item: j['item'] as String,
        qty: (j['qty'] as num).toInt(),
        price: (j['price'] as num).toInt(),
        deposit: (j['deposit'] as num).toInt(),
        date: j['date'] as String,
        due: j['due'] as String,
        status: j['status'] as String,
        notes: (j['notes'] ?? '') as String,
      );
}

int orderTotal(Order o) => o.qty * o.price;
int orderBalance(Order o) => orderTotal(o) - o.deposit;

String _two(int n) => n.toString().padLeft(2, '0');

String isoDate([DateTime? d]) {
  final x = d ?? DateTime.now();
  return '${x.year.toString().padLeft(4, '0')}-${_two(x.month)}-${_two(x.day)}';
}

bool isOverdue(Order o, {String? today}) =>
    o.status != 'Delivered' && o.due.compareTo(today ?? isoDate()) < 0;

String money(num n) {
  final s = n.round().toString();
  final neg = s.startsWith('-');
  final digits = neg ? s.substring(1) : s;
  final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return 'UGX ${neg ? '-' : ''}$withCommas';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// Returns a map of field name -> error message. Empty map means valid.
Map<String, String> validate(Map<String, String> f) {
  final e = <String, String>{};

  final name = (f['customer'] ?? '').trim();
  if (name.length < 2) {
    e['customer'] = 'Enter the customer name (at least 2 letters).';
  } else if (RegExp(r'^\d+$').hasMatch(name)) {
    e['customer'] = 'Customer name cannot be only numbers.';
  }

  final phone = (f['phone'] ?? '').trim();
  if (phone.isNotEmpty && !RegExp(r'^[0-9+\s-]{9,15}$').hasMatch(phone)) {
    e['phone'] = 'Phone must be 9-15 digits.';
  }

  if ((f['item'] ?? '').trim().isEmpty) {
    e['item'] = 'Enter the craft item.';
  }

  final qty = int.tryParse((f['qty'] ?? '').trim());
  if (qty == null || qty < 1) {
    e['qty'] = 'Quantity must be a whole number of 1 or more.';
  }

  final price = int.tryParse((f['price'] ?? '').trim());
  if (price == null || price < 1) {
    e['price'] = 'Price must be a whole number greater than 0.';
  }

  final depText = (f['deposit'] ?? '').trim();
  final dep = depText.isEmpty ? 0 : int.tryParse(depText);
  if (dep == null || dep < 0) {
    e['deposit'] = 'Deposit must be a number, 0 or more.';
  } else if (qty != null &&
      price != null &&
      qty >= 1 &&
      price >= 1 &&
      dep > qty * price) {
    e['deposit'] = 'Deposit cannot be more than the order total.';
  }

  final date = (f['date'] ?? '').trim();
  final due = (f['due'] ?? '').trim();
  if (date.isEmpty) e['date'] = 'Choose the order date.';
  if (due.isEmpty) {
    e['due'] = 'Choose the due date.';
  } else if (date.isNotEmpty && due.compareTo(date) < 0) {
    e['due'] = 'Due date cannot be before the order date.';
  }

  if (!statuses.contains(f['status'])) e['status'] = 'Choose a status.';
  return e;
}

class Summary {
  int count = 0;
  int total = 0;
  int deposits = 0;
  int balance = 0;
  int overdue = 0;
  final Map<String, int> byStatus = {for (final s in statuses) s: 0};
}

Summary summarise(List<Order> orders, {String? today}) {
  final s = Summary();
  s.count = orders.length;
  for (final o in orders) {
    s.total += orderTotal(o);
    s.deposits += o.deposit;
    s.balance += orderBalance(o);
    s.byStatus[o.status] = (s.byStatus[o.status] ?? 0) + 1;
    if (isOverdue(o, today: today)) s.overdue++;
  }
  return s;
}
