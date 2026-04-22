import 'package:flutter/material.dart';

class MaintenanceScheduleScreen extends StatefulWidget {
  final String carMake;
  final String carModel;

  const MaintenanceScheduleScreen({
    super.key,
    required this.carMake,
    required this.carModel,
  });

  @override
  State<MaintenanceScheduleScreen> createState() =>
      _MaintenanceScheduleScreenState();
}

// Data model for a service item
class _ServiceItem {
  final String title;
  final String subtitle;
  final int intervalKm;
  final IconData icon;
  final List<String> signs;

  // Controller for the "Last serviced at" field
  final TextEditingController lastServiceController;
  int? lastServiceKm;

  _ServiceItem({
    required this.title,
    required this.subtitle,
    required this.intervalKm,
    required this.icon,
    required this.signs,
  }) : lastServiceController = TextEditingController();

  void dispose() => lastServiceController.dispose();
}

class _MaintenanceScheduleScreenState extends State<MaintenanceScheduleScreen> {
  final _mileageController = TextEditingController();
  int? _currentKm;
  bool _mileageSet = false;

  late final List<_ServiceItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      _ServiceItem(
        title: 'Oil Change',
        // Conservative default: 5,000 km (safe for both synthetic & conventional)
        subtitle: 'Recommended every 5,000 km',
        intervalKm: 5000,
        icon: Icons.opacity_rounded,
        signs: const [
          'Engine oil looks dark or dirty on the dipstick',
          'Engine feels rough, ticking, or noisier than usual',
          'Oil pressure / warning light appears',
          'Driving frequently in dusty, stop-start, or towing conditions',
        ],
      ),
      _ServiceItem(
        title: 'Air Filter',
        subtitle: 'Recommended every 15,000 km',
        intervalKm: 15000,
        icon: Icons.air_rounded,
        signs: const [
          'Noticeable drop in engine power or throttle response',
          'Filter looks visibly dirty or dark when inspected',
          'Fuel consumption has increased unexpectedly',
          'Driving frequently on dusty or unpaved roads',
        ],
      ),
      _ServiceItem(
        title: 'Spark Plugs',
        // Conservative default: 30,000 km (copper). Iridium/platinum: 100,000+ km.
        subtitle: 'Every 30,000 km (copper) · 100,000 km (iridium/platinum)',
        intervalKm: 30000,
        icon: Icons.electric_bolt_rounded,
        signs: const [
          'Rough idle or noticeable engine shaking',
          'Poor fuel economy without another obvious cause',
          'Sluggish or hesitant acceleration',
          'Engine misfire or check engine light is on',
        ],
      ),
      _ServiceItem(
        title: 'Tyres',
        subtitle: 'Recommended every 40,000 – 80,000 km',
        intervalKm: 40000,
        icon: Icons.tire_repair_rounded,
        signs: const [
          'Tread depth is at or below 1.6 mm (legal minimum)',
          'Visible cracks, bulges, or uneven wear on the sidewall',
          'Vibration or pulling to one side while driving',
          'Reduced grip, especially in wet conditions',
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _mileageController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatKm(int km) {
    return km.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  void _setMileage() {
    final km = int.tryParse(_mileageController.text.trim());
    if (km == null || km < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid mileage'),
          backgroundColor: Color(0xFFFF6B2B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _currentKm = km;
      _mileageSet = true;
    });
  }

  void _setLastService(_ServiceItem item) {
    final km = int.tryParse(item.lastServiceController.text.trim());
    if (km == null || km < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid last-service mileage'),
          backgroundColor: Color(0xFFFF6B2B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_currentKm != null && km > _currentKm!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Last service cannot be higher than current mileage'),
          backgroundColor: Color(0xFFFF6B2B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => item.lastServiceKm = km);
  }

  // ── Schedule calculations ──────────────────────────────────────────────────

  /// Next due mileage.
  /// If the user provided a lastServiceKm, uses: lastServiceKm + intervalKm
  /// Otherwise falls back to the modulo approach from current mileage.
  int _nextDueKm(_ServiceItem item) {
    final current = _currentKm ?? 0;
    if (item.lastServiceKm != null) {
      return item.lastServiceKm! + item.intervalKm;
    }
    // Fallback: round up to next interval multiple from current
    if (current == 0) return item.intervalKm;
    final remainder = current % item.intervalKm;
    if (remainder == 0) return current + item.intervalKm;
    return current + (item.intervalKm - remainder);
  }

  int _remainingKm(_ServiceItem item) {
    final current = _currentKm ?? 0;
    final next = _nextDueKm(item);
    return (next - current).clamp(0, item.intervalKm);
  }

  /// 'due_now' | 'due_soon' | 'ok'
  String _status(_ServiceItem item) {
    final remaining = _remainingKm(item);
    if (remaining == 0) return 'due_now';
    if (remaining <= 1000) return 'due_soon';
    return 'ok';
  }

  double _progress(_ServiceItem item) {
    final remaining = _remainingKm(item);
    final status = _status(item);
    if (status == 'due_now') return 1.0;
    return (1.0 - remaining / item.intervalKm).clamp(0.0, 1.0);
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _scheduleCard(_ServiceItem item) {
    const statusColors = {
      'ok': Color(0xFF4CAF50),
      'due_soon': Color(0xFFE8C547),
      'due_now': Color(0xFFFF6B2B),
    };
    const statusLabels = {
      'ok': 'OK',
      'due_soon': 'Due Soon',
      'due_now': 'Due Now',
    };

    final status = _status(item);
    final color = statusColors[status] ?? const Color(0xFF4CAF50);
    final label = statusLabels[status] ?? 'OK';
    final remaining = _remainingKm(item);
    final nextDue = _nextDueKm(item);
    final progress = _progress(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(item.icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // ── Last-service input ──────────────────────────────────────────
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.lastServiceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Last serviced at (km) — optional',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0F),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFFE8C547), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _setLastService(item),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8C547).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE8C547).withValues(alpha: 0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Set',
                    style: TextStyle(
                      color: Color(0xFFE8C547),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (item.lastServiceKm != null) ...[
            const SizedBox(height: 6),
            Text(
              'Last serviced at ${_formatKm(item.lastServiceKm!)} km  ·  next due based on actual service record',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // ── Progress bar ────────────────────────────────────────────────
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                status == 'due_now'
                    ? 'Service due now'
                    : '${_formatKm(remaining)} km remaining',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Next due: ${_formatKm(nextDue)} km',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),

          // ── Early-warning signs ─────────────────────────────────────────
          const SizedBox(height: 14),
          Text(
            'Check sooner if:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...item.signs.map(
            (sign) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child:
                        Icon(Icons.circle, size: 6, color: Color(0xFFE8C547)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sign,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Title ──────────────────────────────────────────────────────
            const Text(
              'Maintenance Schedule',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${widget.carMake} ${widget.carModel}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // ── Current mileage input ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16161F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE8C547).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed_rounded,
                          color: Color(0xFFE8C547), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Enter Current Mileage (km)',
                        style: TextStyle(
                          color: Color(0xFFE8C547),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mileageController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. 45000',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0A0A0F),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE8C547), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _setMileage,
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8C547),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Set',
                            style: TextStyle(
                              color: Color(0xFF0A0A0F),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_mileageSet && _currentKm != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Current mileage: ${_formatKm(_currentKm!)} km',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Empty state / cards ────────────────────────────────────────
            if (!_mileageSet)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.speed_rounded,
                      color: Colors.white.withValues(alpha: 0.15),
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter your current mileage above\nto see your schedule',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              const Text(
                'Service Items',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ..._items.map(_scheduleCard),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
