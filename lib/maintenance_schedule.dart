import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _MaintenanceScheduleScreenState extends State<MaintenanceScheduleScreen> {
  final _mileageController = TextEditingController();
  int? _currentKm;
  bool _mileageSet = false;

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
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

  String _getStatus(int intervalKm, int lastDoneKm) {
    final nextDueKm = lastDoneKm + intervalKm;
    final remaining = nextDueKm - (_currentKm ?? 0);
    if (remaining <= 0) return 'overdue';
    if (remaining <= 1000) return 'due_soon';
    return 'ok';
  }

  int _getRemaining(int intervalKm, int lastDoneKm) {
    final nextDueKm = lastDoneKm + intervalKm;
    return nextDueKm - (_currentKm ?? 0);
  }

  String _formatKm(int km) {
    return km.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
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

            // Mileage input card
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
                  Row(
                    children: [
                      const Icon(
                        Icons.speed_rounded,
                        color: Color(0xFFE8C547),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
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
                            color: Colors.white,
                            fontSize: 14,
                          ),
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
                                color: Color(0xFFE8C547),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
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
                'Oil Change Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('maintenance_schedule')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Color(0xFFE8C547),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Error loading schedule',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    );
                  }

                  final allDocs = snapshot.data?.docs ?? [];

                  // Filter for this car and oil change only
                  final docs =
                      allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final make =
                            (data['carMake'] ?? '').toString().toLowerCase();
                        final model =
                            (data['carModel'] ?? '').toString().toLowerCase();
                        final task =
                            (data['task'] ?? '').toString().toLowerCase();
                        return make == widget.carMake.toLowerCase() &&
                            model == widget.carModel.toLowerCase() &&
                            task.contains('oil');
                      }).toList();

                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161F),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No oil change schedule found\nfor ${widget.carMake} ${widget.carModel}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children:
                        docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final task = data['task'] ?? 'Oil Change';
                          final intervalKm =
                              (data['intervalKm'] ?? 5000) as int;
                          final lastDoneKm = (data['lastDoneKm'] ?? 0) as int;
                          final status = _getStatus(intervalKm, lastDoneKm);
                          final remaining = _getRemaining(
                            intervalKm,
                            lastDoneKm,
                          );
                          final nextDueKm = lastDoneKm + intervalKm;

                          final statusColors = {
                            'ok': const Color(0xFF4CAF50),
                            'due_soon': const Color(0xFFE8C547),
                            'overdue': const Color(0xFFFF6B2B),
                          };
                          final statusLabels = {
                            'ok': 'OK',
                            'due_soon': 'Due Soon',
                            'overdue': 'Overdue',
                          };
                          final color =
                              statusColors[status] ?? const Color(0xFF4CAF50);
                          final label = statusLabels[status] ?? 'OK';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16161F),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Icon(
                                        Icons.opacity_rounded,
                                        color: color,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'Every ${_formatKm(intervalKm)} km',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.4,
                                              ),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
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
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value:
                                        status == 'overdue'
                                            ? 1.0
                                            : 1.0 -
                                                (remaining / intervalKm).clamp(
                                                  0.0,
                                                  1.0,
                                                ),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.06,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      color,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      status == 'overdue'
                                          ? '${_formatKm(remaining.abs())} km overdue'
                                          : '${_formatKm(remaining)} km remaining',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Next due: ${_formatKm(nextDueKm)} km',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
