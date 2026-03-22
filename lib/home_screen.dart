import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tutorials.dart';
import 'maintenance_schedule.dart';
import 'suppliers_screen.dart';

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
  int _currentKm = 0;
  bool _kmSet = false;
  final _kmController = TextEditingController();

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  String _formatKm(int km) {
    return km.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _getStatus(int intervalKm, int lastDoneKm) {
    final remaining = (lastDoneKm + intervalKm) - _currentKm;
    if (remaining <= 0) return 'overdue';
    if (remaining <= 1000) return 'due_soon';
    return 'ok';
  }

  int _getRemaining(int intervalKm, int lastDoneKm) {
    return (lastDoneKm + intervalKm) - _currentKm;
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'oil':
        return Icons.opacity_rounded;
      case 'brake':
        return Icons.album_rounded;
      case 'air':
        return Icons.air_rounded;
      case 'spark':
        return Icons.electric_bolt_rounded;
      case 'tyre':
        return Icons.tire_repair_rounded;
      default:
        return Icons.build_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildSoundDiagnostics(),
          TutorialsScreen(carMake: widget.carMake, carModel: widget.carModel),
          MaintenanceScheduleScreen(
            carMake: widget.carMake,
            carModel: widget.carModel,
          ),
          const SuppliersScreen(),
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
      {'icon': Icons.build_circle_outlined, 'label': 'Schedule'},
      {'icon': Icons.store_outlined, 'label': 'Suppliers'},
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
            children: items.asMap().entries.map((e) {
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
                            active ? const Color(0xFFE8C547) : Colors.white30,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          color:
                              active ? const Color(0xFFE8C547) : Colors.white30,
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
            const SizedBox(height: 16),
            _buildMileageInput(),
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
                _engineBadge(widget.engineType),
              ],
            ),
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

  Widget _buildMileageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8C547).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed_rounded, color: Color(0xFFE8C547), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: _kmSet
                    ? 'Current: ${_formatKm(_currentKm)} km'
                    : 'Enter current mileage (km)',
                hintStyle: TextStyle(
                  color: _kmSet
                      ? const Color(0xFF4CAF50)
                      : Colors.white.withValues(alpha: 0.25),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              final km = int.tryParse(_kmController.text.trim());
              if (km != null && km >= 0) {
                setState(() {
                  _currentKm = km;
                  _kmSet = true;
                  _kmController.clear();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8C547),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Set',
                style: TextStyle(
                  color: Color(0xFF0A0A0F),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
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
        if (!_kmSet)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16161F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Center(
              child: Text(
                'Enter your current mileage above\nto see upcoming maintenance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('maintenance_schedule')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFFE8C547)),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Error loading maintenance',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                );
              }

              final allDocs = snapshot.data?.docs ?? [];
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final make = (data['carMake'] ?? '').toString().toLowerCase();
                final model = (data['carModel'] ?? '').toString().toLowerCase();
                return make == widget.carMake.toLowerCase() &&
                    model == widget.carModel.toLowerCase();
              }).toList();

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161F),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Center(
                    child: Text(
                      'No schedule found for\n${widget.carMake} ${widget.carModel}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }

              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aR = _getRemaining(
                  (aData['intervalKm'] ?? 5000) as int,
                  (aData['lastDoneKm'] ?? 0) as int,
                );
                final bR = _getRemaining(
                  (bData['intervalKm'] ?? 5000) as int,
                  (bData['lastDoneKm'] ?? 0) as int,
                );
                return aR.compareTo(bR);
              });

              return Column(
                children: docs.take(3).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final task = data['task'] ?? 'Maintenance';
                  final intervalKm = (data['intervalKm'] ?? 5000) as int;
                  final lastDoneKm = (data['lastDoneKm'] ?? 0) as int;
                  final status = _getStatus(intervalKm, lastDoneKm);
                  final remaining = _getRemaining(intervalKm, lastDoneKm);
                  final nextDueKm = lastDoneKm + intervalKm;

                  final statusColors = {
                    'ok': Colors.white30,
                    'due_soon': const Color(0xFFE8C547),
                    'overdue': const Color(0xFFFF6B2B),
                  };
                  final color = statusColors[status] ?? Colors.white30;
                  final iconData = _getIcon(data['icon'] ?? '');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
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
                          child: Icon(iconData, color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Next due at: ${_formatKm(nextDueKm)} km',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status == 'overdue'
                                ? 'Overdue'
                                : status == 'due_soon'
                                    ? 'Due Soon'
                                    : '${_formatKm(remaining)} km',
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
                }).toList(),
              );
            },
          ),
      ],
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
        'label': 'Tutorials',
        'icon': Icons.play_circle_outline_rounded,
        'color': const Color(0xFF2196F3),
        'tab': 2,
      },
      {
        'label': 'Schedule',
        'icon': Icons.build_circle_outlined,
        'color': const Color(0xFF4CAF50),
        'tab': 3,
      },
      {
        'label': 'Suppliers',
        'icon': Icons.store_outlined,
        'color': const Color(0xFFFF6B2B),
        'tab': 4,
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
          children: actions.asMap().entries.map((e) {
            final a = e.value;
            final isLast = e.key == actions.length - 1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = a['tab'] as int),
                child: Container(
                  margin: EdgeInsets.only(right: isLast ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161F),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 4),
              child: _profileOption(
                Icons.store_outlined,
                'Nearby Suppliers',
                'Find parts & service kits',
              ),
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
