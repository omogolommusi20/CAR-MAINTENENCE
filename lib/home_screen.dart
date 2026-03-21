import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String carMake;
  final String carModel;
  final String carYear;
  final String engineType;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.engineType,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _maintenanceItems = [
    {
      'task': 'Oil Filter Replacement',
      'due': '500 km',
      'status': 'due_soon',
      'icon': Icons.opacity_rounded,
    },
    {
      'task': 'Brake Pad Check',
      'due': '1,200 km',
      'status': 'ok',
      'icon': Icons.album_rounded,
    },
    {
      'task': 'Spark Plug Replacement',
      'due': '3,000 km',
      'status': 'ok',
      'icon': Icons.electric_bolt_rounded,
    },
    {
      'task': 'Tyre Rotation',
      'due': 'Overdue',
      'status': 'overdue',
      'icon': Icons.tire_repair_rounded,
    },
    {
      'task': 'Air Filter Check',
      'due': '2,500 km',
      'status': 'ok',
      'icon': Icons.air_rounded,
    },
  ];

  final List<Map<String, dynamic>> _tutorials = [
    {
      'title': 'Oil Change Guide',
      'duration': '15 min',
      'level': 'Beginner',
      'ar': true,
      'icon': Icons.opacity_rounded,
    },
    {
      'title': 'Brake Pad Replacement',
      'duration': '30 min',
      'level': 'Intermediate',
      'ar': true,
      'icon': Icons.album_rounded,
    },
    {
      'title': 'Spark Plug Change',
      'duration': '20 min',
      'level': 'Beginner',
      'ar': false,
      'icon': Icons.electric_bolt_rounded,
    },
    {
      'title': 'Air Filter Replacement',
      'duration': '10 min',
      'level': 'Beginner',
      'ar': false,
      'icon': Icons.air_rounded,
    },
    {
      'title': 'Tyre Change',
      'duration': '25 min',
      'level': 'Beginner',
      'ar': true,
      'icon': Icons.tire_repair_rounded,
    },
  ];

  final List<Map<String, dynamic>> _maintenanceLog = [
    {
      'task': 'Oil Change',
      'date': '12 Jan 2025',
      'cost': 'P 250',
      'parts': 'Oil filter, Engine oil',
    },
    {
      'task': 'Tyre Rotation',
      'date': '05 Nov 2024',
      'cost': 'P 80',
      'parts': 'None',
    },
    {
      'task': 'Brake Fluid Top-up',
      'date': '20 Sep 2024',
      'cost': 'P 60',
      'parts': 'Brake fluid',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildSoundDiagnostics(),
          _buildTutorials(),
          _buildMaintenanceLog(),
          _buildProfile(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Home'},
      {'icon': Icons.mic_rounded, 'label': 'Diagnose'},
      {'icon': Icons.play_circle_outline_rounded, 'label': 'Tutorials'},
      {'icon': Icons.history_rounded, 'label': 'History'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children:
                items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final active = _currentIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 22,
                            color:
                                active
                                    ? const Color(0xFFE8C547)
                                    : Colors.white30,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  active
                                      ? const Color(0xFFE8C547)
                                      : Colors.white30,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildGreeting(),
            const SizedBox(height: 20),
            _buildCarCard(),
            const SizedBox(height: 20),
            _buildHealthStatus(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildUpcomingMaintenance(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${widget.userName} 👋',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Check your car\'s health today',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF16161F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white54,
                size: 20,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B2B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1A08), Color(0xFF16161F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C547).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8C547).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Color(0xFFE8C547),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.carYear} ${widget.carMake} ${widget.carModel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _engineBadge(widget.engineType),
                    const SizedBox(width: 8),
                    Text(
                      'Last service: Jan 2025',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white30,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _engineBadge(String type) {
    final colors = {
      'Electric': const Color(0xFF4CAF50),
      'Hybrid': const Color(0xFF2196F3),
      'Diesel': const Color(0xFFFF9800),
      'Petrol': const Color(0xFFE8C547),
    };
    final color = colors[type] ?? const Color(0xFFE8C547);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHealthStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Health',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _healthCard(
              'Engine',
              '85%',
              Icons.settings_rounded,
              const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 10),
            _healthCard(
              'Brakes',
              '72%',
              Icons.album_rounded,
              const Color(0xFFE8C547),
            ),
            const SizedBox(width: 10),
            _healthCard(
              'Tyres',
              '60%',
              Icons.tire_repair_rounded,
              const Color(0xFFFF6B2B),
            ),
          ],
        ),
      ],
    );
  }

  Widget _healthCard(String label, String percent, IconData icon, Color color) {
    final value = int.parse(percent.replaceAll('%', '')) / 100;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16161F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              percent,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Sound\nDiagnose',
        'icon': Icons.mic_rounded,
        'color': const Color(0xFFE8C547),
        'tab': 1,
      },
      {
        'label': 'AR\nGuide',
        'icon': Icons.view_in_ar_rounded,
        'color': const Color(0xFF2196F3),
        'tab': 2,
      },
      {
        'label': 'Find\nParts',
        'icon': Icons.location_on_rounded,
        'color': const Color(0xFF4CAF50),
        'tab': 4,
      },
      {
        'label': 'Schedule',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFFFF6B2B),
        'tab': 3,
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children:
              actions.asMap().entries.map((e) {
                final a = e.value;
                final isLast = e.key == actions.length - 1;
                return Expanded(
                  child: GestureDetector(
                    onTap:
                        () => setState(() => _currentIndex = a['tab'] as int),
                    child: Container(
                      margin: EdgeInsets.only(right: isLast ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161F),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            a['icon'] as IconData,
                            color: a['color'] as Color,
                            size: 22,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildUpcomingMaintenance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Maintenance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 3),
              child: const Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFFE8C547),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._maintenanceItems.take(3).map((item) => _maintenanceTile(item)),
      ],
    );
  }

  Widget _maintenanceTile(Map<String, dynamic> item) {
    final statusColors = {
      'ok': Colors.white30,
      'due_soon': const Color(0xFFE8C547),
      'overdue': const Color(0xFFFF6B2B),
    };
    final color = statusColors[item['status']] ?? Colors.white30;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item['icon'] as IconData, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['task'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item['due'] as String,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundDiagnostics() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Sound Diagnostics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Record your car\'s sound to detect faults',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF16161F),
                      border: Border.all(
                        color: const Color(0xFFE8C547).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Color(0xFFE8C547),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap to Record',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hold phone near the engine while idling',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Detectable Faults',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              {
                'fault': 'Engine Knock',
                'icon': Icons.settings_rounded,
                'color': const Color(0xFFFF6B2B),
              },
              {
                'fault': 'Belt Squeal',
                'icon': Icons.electric_bolt_rounded,
                'color': const Color(0xFFE8C547),
              },
              {
                'fault': 'Brake Screech',
                'icon': Icons.album_rounded,
                'color': const Color(0xFF2196F3),
              },
              {
                'fault': 'Suspension Rattle',
                'icon': Icons.car_repair_rounded,
                'color': const Color(0xFF4CAF50),
              },
              {
                'fault': 'Transmission Whine',
                'icon': Icons.settings_input_component_rounded,
                'color': const Color(0xFF9C27B0),
              },
            ].map(
              (f) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      color: f['color'] as Color,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      f['fault'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorials() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Tutorials',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Step-by-step guides for your ${widget.carMake}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _tutorials.length,
                itemBuilder: (_, i) {
                  final t = _tutorials[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE8C547,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            t['icon'] as IconData,
                            color: const Color(0xFFE8C547),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    t['duration'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t['level'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (t['ar'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2196F3,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: const Text(
                                        'AR',
                                        style: TextStyle(
                                          color: Color(0xFF2196F3),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_rounded,
                          color: Color(0xFFE8C547),
                          size: 28,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceLog() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Maintenance Log',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Full service history',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upcoming',
              style: TextStyle(
                color: Color(0xFFE8C547),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ..._maintenanceItems.map((item) => _maintenanceTile(item)),
            const SizedBox(height: 16),
            const Text(
              'Past Services',
              style: TextStyle(
                color: Color(0xFFE8C547),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ..._maintenanceLog.map(
              (log) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['task'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log['parts'] as String,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            log['date'] as String,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      log['cost'] as String,
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C547).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE8C547).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFFE8C547),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildCarCard(),
            const SizedBox(height: 20),
            _profileOption(
              Icons.directions_car_rounded,
              'My Vehicle',
              'Manage car details',
            ),
            _profileOption(
              Icons.notifications_outlined,
              'Notifications',
              'Maintenance reminders',
            ),
            _profileOption(
              Icons.location_on_outlined,
              'Nearby Suppliers',
              'Find parts & service kits',
            ),
            _profileOption(
              Icons.security_rounded,
              'Privacy & Security',
              'Account settings',
            ),
            _profileOption(
              Icons.help_outline_rounded,
              'Help & Support',
              'FAQs and contact',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _profileOption(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white30,
            size: 18,
          ),
        ],
      ),
    );
  }
}
