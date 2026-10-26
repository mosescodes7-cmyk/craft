import 'package:flutter/material.dart';

import 'logic.dart';
import 'store.dart';
import 'theme.dart';

/// Filter chosen on the Orders screen (also set from the Home chips).
final ValueNotifier<String> ordersFilter = ValueNotifier<String>('All');

void openForm(BuildContext context, {Order? order}) {
  Navigator.push(
      context, MaterialPageRoute(builder: (_) => FormScreen(order: order)));
}

void openDetail(BuildContext context, String id) {
  Navigator.push(
      context, MaterialPageRoute(builder: (_) => DetailScreen(id: id)));
}

Future<bool> confirmDialog(
    BuildContext context, String title, String body, String okLabel) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kCard,
      title: Text(title),
      content: Text(body, style: const TextStyle(color: kMuted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(okLabel, style: const TextStyle(color: kDanger)),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<void> addPaymentDialog(BuildContext context, Order o) async {
  final ctrl = TextEditingController();
  String? err;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Add payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance due: ${money(orderBalance(o))}',
                style: const TextStyle(color: kMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: 'Amount (UGX)', errorText: err),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              final a = int.tryParse(ctrl.text.trim());
              if (a == null || a < 1) {
                setS(() => err = 'Enter a whole amount greater than 0.');
                return;
              }
              if (a > orderBalance(o)) {
                setS(() => err = 'Amount is more than the balance due.');
                return;
              }
              store.addPayment(o.id, a);
              Navigator.pop(ctx);
              toast(context, 'Payment recorded');
            },
            child:
                const Text('Save payment', style: TextStyle(color: kLime)),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------- shell

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  void goTab(int i) => setState(() => tab = i);

  Widget navBtn(IconData icon, int i) {
    final on = tab == i;
    return IconButton(
      iconSize: 26,
      color: on ? kLime : kMuted,
      onPressed: () {
        if (i == 1) ordersFilter.value = 'All';
        goTab(i);
      },
      icon: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: [
            HomeScreen(onTab: goTab),
            const OrdersScreen(),
            const SummaryScreen(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF262628),
            borderRadius: BorderRadius.circular(34),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navBtn(Icons.home_rounded, 0),
              navBtn(Icons.receipt_long_rounded, 1),
              Material(
                color: kLime,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => openForm(context),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.add_rounded, color: kInk, size: 28),
                  ),
                ),
              ),
              navBtn(Icons.bar_chart_rounded, 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- shared widgets

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

Widget statusBadge(Order o, {bool light = false, bool both = false}) {
  final over = isOverdue(o);
  Color bg = light ? const Color(0xFFEEEEEE) : kCard2;
  Color fg = light ? kInk : Colors.white;
  switch (o.status) {
    case 'Pending':
      fg = light ? const Color(0xFFB07000) : kWarn;
      break;
    case 'In Progress':
      fg = light ? const Color(0xFF1F6FB0) : kBlue;
      break;
    case 'Ready':
      fg = light ? const Color(0xFF5A7A00) : kLime;
      break;
    case 'Delivered':
      bg = kLime;
      fg = kInk;
      break;
  }
  final status = StatusPill(o.status, bg: bg, fg: fg);
  final overdue = StatusPill('Overdue', bg: kDanger, fg: Colors.white);
  if (both) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      status,
      if (over) ...[const SizedBox(width: 6), overdue],
    ]);
  }
  return over ? overdue : status;
}

class OrderCard extends StatelessWidget {
  const OrderCard(this.o, {super.key});
  final Order o;

  Widget num_(String label, String value, {bool right = false, Color? color}) {
    return Column(
      crossAxisAlignment:
          right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = orderTotal(o);
    final bal = orderBalance(o);
    final pct = total == 0 ? 0.0 : (o.deposit / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => openDetail(context, o.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.item,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('${o.customer} · Qty ${o.qty}',
                              style: const TextStyle(
                                  color: kMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    statusBadge(o),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct.toDouble(),
                    minHeight: 6,
                    backgroundColor: kCard2,
                    color: kLime,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    num_('Total', money(total)),
                    num_('Deposit', money(o.deposit)),
                    num_('Balance', bal == 0 ? 'Paid' : money(bal),
                        right: true, color: bal > 0 ? kLime : Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget statCard(String label, String value,
    {bool hero = false, Color? valueColor}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: hero ? kLime : kCard,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: hero ? const Color(0xFF3B4A10) : kMuted)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: hero ? 28 : 19,
              fontWeight: FontWeight.bold,
              color: hero ? kInk : (valueColor ?? Colors.white),
            )),
      ],
    ),
  );
}

Widget twoCols(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
    );

Widget sectionTitle(String t, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          if (trailing != null) trailing,
        ],
      ),
    );

Widget chip(String label, bool on, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF12160A) : kCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: on ? kLime : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(
                  color: on ? kLime : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Text('🧶', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 8),
          const Text('No orders yet.', style: TextStyle(color: kMuted)),
          const SizedBox(height: 16),
          PillButton('Add first order', small: true, onPressed: () => openForm(context)),
          const SizedBox(height: 10),
          PillButton('Load sample data',
              small: true,
              kind: 'ghost',
              onPressed: () async {
                await store.loadSample();
                if (context.mounted) toast(context, 'Sample data loaded');
              }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- home

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onTab});
  final void Function(int) onTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = summarise(store.orders);
        final recent = [...store.orders]
          ..sort((a, b) {
            final c = b.date.compareTo(a.date);
            return c != 0 ? c : b.id.compareTo(a.id);
          });
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, Robinah',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600)),
                      Text("Let's track your craft orders",
                          style: TextStyle(color: kMuted, fontSize: 12)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    ordersFilter.value = 'All';
                    onTab(1);
                  },
                  style: OutlinedButton.styleFrom(
                    shape: const CircleBorder(),
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.search_rounded),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: kLime,
                  child: Text('NR',
                      style: TextStyle(
                          color: kInk, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            statCard('Outstanding balance', money(s.balance), hero: true),
            const SizedBox(height: 12),
            twoCols(
              statCard('Orders', '${s.count}'),
              statCard('Overdue', '${s.overdue}',
                  valueColor: s.overdue > 0 ? kDanger : Colors.white),
            ),
            const SizedBox(height: 12),
            twoCols(
              statCard('Order value', money(s.total)),
              statCard('Deposits', money(s.deposits)),
            ),
            sectionTitle('Categories'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final st in statuses)
                    chip('$st · ${s.byStatus[st]}', false, () {
                      ordersFilter.value = st;
                      onTab(1);
                    }),
                ],
              ),
            ),
            sectionTitle(
              'Recent orders',
              trailing: TextButton(
                onPressed: () {
                  ordersFilter.value = 'All';
                  onTab(1);
                },
                child: const Text('See all', style: TextStyle(color: kLime)),
              ),
            ),
            if (recent.isEmpty)
              const EmptyState()
            else
              for (final o in recent.take(3)) OrderCard(o),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- orders

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String query = '';

  List<Order> filtered(String filter) {
    final q = query.trim().toLowerCase();
    final list = store.orders.where((o) {
      final okFilter = filter == 'All' ||
          (filter == 'Overdue' ? isOverdue(o) : o.status == filter);
      final okQuery = q.isEmpty ||
          o.customer.toLowerCase().contains(q) ||
          o.item.toLowerCase().contains(q);
      return okFilter && okQuery;
    }).toList();
    list.sort((a, b) => a.due.compareTo(b.due));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, ordersFilter]),
      builder: (context, _) {
        final filter = ordersFilter.value;
        final list = filtered(filter);
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Orders',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                PillButton('+ New',
                    small: true, onPressed: () => openForm(context)),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                hintText: 'Search customer or craft item',
                prefixIcon: Icon(Icons.search_rounded, color: kMuted),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in ['All', ...statuses, 'Overdue'])
                    chip(c, filter == c, () => ordersFilter.value = c),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (list.isNotEmpty)
              for (final o in list) OrderCard(o)
            else if (store.orders.isEmpty)
              const EmptyState()
            else
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('No orders match your search or filter.',
                      style: TextStyle(color: kMuted)),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- detail

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.id});
  final String id;

  Widget kv(String k, String v) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: const TextStyle(color: Color(0xFF777777))),
            const SizedBox(width: 16),
            Flexible(child: Text(v, textAlign: TextAlign.right)),
          ],
        ),
      );

  Widget tri(String value, String label, {Color? color}) => Expanded(
        child: Column(
          children: [
            Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF777777))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final o = store.byId(id);
          if (o == null) return const SizedBox.shrink();
          final total = orderTotal(o);
          final bal = orderBalance(o);
          final pct = total == 0 ? 0.0 : (o.deposit / total).clamp(0.0, 1.0);
          return SingleChildScrollView(
            child: Stack(
              children: [
                Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A3A08), Colors.black],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: const CircleBorder(),
                              side: const BorderSide(
                                  color: Colors.white, width: 1.5),
                              minimumSize: const Size(48, 48),
                              padding: EdgeInsets.zero,
                              foregroundColor: Colors.white,
                            ),
                            child: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      ),
                      Theme(
                        data: lightTheme(),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(o.item,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                Center(
                                    child: statusBadge(o,
                                        light: true, both: true)),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    tri(money(total), 'Total'),
                                    tri(money(o.deposit), 'Deposits'),
                                    tri(bal == 0 ? 'Paid' : money(bal),
                                        'Balance',
                                        color: const Color(0xFF5A7A00)),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: pct.toDouble(),
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFE8E8E8),
                                    color: const Color(0xFF9FD000),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('${(pct * 100).round()}% paid',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Color(0xFF777777),
                                        fontSize: 12)),
                                const SizedBox(height: 14),
                                kv('Customer', o.customer),
                                if (o.phone.isNotEmpty) kv('Phone', o.phone),
                                kv('Quantity', '${o.qty}'),
                                kv('Unit price', money(o.price)),
                                kv('Order date', fmtDate(o.date)),
                                kv('Due date', fmtDate(o.due)),
                                if (o.notes.isNotEmpty) kv('Notes', o.notes),
                                const SizedBox(height: 18),
                                const Text('Update status',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: o.status,
                                  items: [
                                    for (final s in statuses)
                                      DropdownMenuItem(value: s, child: Text(s)),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    store.setStatus(o.id, v);
                                    toast(context, 'Status updated');
                                  },
                                ),
                                const SizedBox(height: 16),
                                PillButton(
                                  'Add payment',
                                  icon: Icons.payments_outlined,
                                  onPressed: bal == 0
                                      ? null
                                      : () => addPaymentDialog(context, o),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: PillButton('Edit',
                                          kind: 'ghost',
                                          onPressed: () =>
                                              openForm(context, order: o)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: PillButton('Delete',
                                          kind: 'danger', onPressed: () async {
                                        final ok = await confirmDialog(
                                          context,
                                          'Delete this order?',
                                          '${o.item} for ${o.customer} will be removed permanently.',
                                          'Delete',
                                        );
                                        if (ok && context.mounted) {
                                          final nav = Navigator.of(context);
                                          final msgCtx = nav.context;
                                          nav.pop();
                                          await store.remove(o.id);
                                          if (msgCtx.mounted) {
                                            toast(msgCtx, 'Order deleted');
                                          }
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- form

class FormScreen extends StatefulWidget {
  const FormScreen({super.key, this.order});
  final Order? order;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  late final TextEditingController customer;
  late final TextEditingController phone;
  late final TextEditingController item;
  late final TextEditingController qty;
  late final TextEditingController price;
  late final TextEditingController deposit;
  late final TextEditingController notes;
  late String date;
  late String due;
  late String status;
  Map<String, String> errors = {};

  bool get editing => widget.order != null;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    customer = TextEditingController(text: o?.customer ?? '');
    phone = TextEditingController(text: o?.phone ?? '');
    item = TextEditingController(text: o?.item ?? '');
    qty = TextEditingController(text: o != null ? '${o.qty}' : '');
    price = TextEditingController(text: o != null ? '${o.price}' : '');
    deposit = TextEditingController(text: o != null ? '${o.deposit}' : '');
    notes = TextEditingController(text: o?.notes ?? '');
    date = o?.date ?? isoDate();
    due = o?.due ?? '';
    status = o?.status ?? 'Pending';
    for (final c in [qty, price, deposit]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [customer, phone, item, qty, price, deposit, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pick(bool isDue) async {
    final init = DateTime.tryParse(isDue ? due : date) ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        if (isDue) {
          due = isoDate(d);
        } else {
          date = isoDate(d);
        }
      });
    }
  }

  Map<String, String> values() => {
        'customer': customer.text,
        'phone': phone.text,
        'item': item.text,
        'qty': qty.text,
        'price': price.text,
        'deposit': deposit.text,
        'date': date,
        'due': due,
        'status': status,
      };

  Future<void> submit() async {
    final e = validate(values());
    setState(() => errors = e);
    if (e.isNotEmpty) {
      toast(context, 'Please fix the highlighted fields', bad: true);
      return;
    }
    final rec = Order(
      id: widget.order?.id ?? OrderStore.newId(),
      customer: customer.text.trim(),
      phone: phone.text.trim(),
      item: item.text.trim(),
      qty: int.parse(qty.text.trim()),
      price: int.parse(price.text.trim()),
      deposit: deposit.text.trim().isEmpty ? 0 : int.parse(deposit.text.trim()),
      date: date,
      due: due,
      status: status,
      notes: notes.text.trim(),
    );
    final nav = Navigator.of(context);
    final msgCtx = nav.context;
    if (editing) {
      await store.update(rec);
    } else {
      await store.add(rec);
    }
    nav.pop();
    if (msgCtx.mounted) {
      toast(msgCtx, editing ? 'Order updated' : 'Order saved');
    }
  }

  Widget label(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(t,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      );

  Widget field(String l, String key, TextEditingController c,
      {String? hint, TextInputType? type, int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label(l),
        TextField(
          controller: c,
          keyboardType: type,
          maxLines: lines,
          decoration: InputDecoration(hintText: hint, errorText: errors[key]),
        ),
      ],
    );
  }

  Widget dateField(String l, String key, String value, bool isDue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label(l),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => pick(isDue),
          child: InputDecorator(
            decoration: InputDecoration(errorText: errors[key]),
            child: Text(value.isEmpty ? 'Select date' : fmtDate(value),
                style: TextStyle(
                    color: value.isEmpty ? Colors.black45 : Colors.black87)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = int.tryParse(qty.text.trim()) ?? 0;
    final p = int.tryParse(price.text.trim()) ?? 0;
    final d = int.tryParse(deposit.text.trim()) ?? 0;
    final total = q * p;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: const CircleBorder(),
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
                Text(editing ? 'Edit order' : 'New order',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 18),
            Theme(
              data: lightTheme(),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      field('Customer name *', 'customer', customer,
                          hint: 'e.g. Grace Namutebi'),
                      field('Phone (optional)', 'phone', phone,
                          hint: '0770 000 000', type: TextInputType.phone),
                      field('Craft item *', 'item', item,
                          hint: 'e.g. Raffia basket'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: field('Quantity *', 'qty', qty,
                                type: TextInputType.number),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: field('Unit price (UGX) *', 'price', price,
                                type: TextInputType.number),
                          ),
                        ],
                      ),
                      field('Deposit paid (UGX)', 'deposit', deposit,
                          hint: '0', type: TextInputType.number),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: dateField(
                                  'Order date *', 'date', date, false)),
                          const SizedBox(width: 12),
                          Expanded(
                              child:
                                  dateField('Due date *', 'due', due, true)),
                        ],
                      ),
                      label('Status'),
                      DropdownButtonFormField<String>(
                        value: status,
                        items: [
                          for (final s in statuses)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) => setState(() => status = v ?? status),
                      ),
                      field('Notes (optional)', 'notes', notes, lines: 2),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kInk,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Order total',
                                    style: TextStyle(color: Colors.white)),
                                Text(money(total),
                                    style: const TextStyle(
                                        color: kLime,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Balance',
                                    style: TextStyle(color: Colors.white)),
                                Text(money(total - d),
                                    style: const TextStyle(
                                        color: kLime,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      PillButton(editing ? 'Save changes' : 'Save order',
                          onPressed: submit),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- summary

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  Widget line(String k, String v, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kCard2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: kMuted)),
            Text(v, style: TextStyle(color: color ?? Colors.white)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = summarise(store.orders);
        final owing = <String, int>{};
        for (final o in store.orders) {
          final b = orderBalance(o);
          if (b > 0) owing[o.customer] = (owing[o.customer] ?? 0) + b;
        }
        final top = owing.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          children: [
            const Text('Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            statCard('Total outstanding balance', money(s.balance), hero: true),
            const SizedBox(height: 12),
            twoCols(
              statCard('Total order value', money(s.total)),
              statCard('Deposits received', money(s.deposits)),
            ),
            sectionTitle('By status'),
            for (final st in statuses) line(st, '${s.byStatus[st]}'),
            line('Overdue orders', '${s.overdue}', color: kDanger),
            sectionTitle('Who owes most'),
            if (top.isEmpty)
              const Text('Nobody owes anything.',
                  style: TextStyle(color: kMuted))
            else
              for (final e in top.take(5))
                line(e.key, money(e.value), color: kLime),
            sectionTitle('Data'),
            Row(
              children: [
                Expanded(
                  child: PillButton('Load sample data',
                      kind: 'ghost', onPressed: () async {
                    await store.loadSample();
                    if (context.mounted) toast(context, 'Sample data loaded');
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton('Clear all', kind: 'danger',
                      onPressed: () async {
                    if (store.orders.isEmpty) {
                      toast(context, 'Nothing to clear', bad: true);
                      return;
                    }
                    final ok = await confirmDialog(
                      context,
                      'Clear all orders?',
                      'This permanently deletes every order on this phone.',
                      'Delete all',
                    );
                    if (ok) {
                      await store.clear();
                      if (context.mounted) {
                        toast(context, 'All orders deleted');
                      }
                    }
                  }),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
