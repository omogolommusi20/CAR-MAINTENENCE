import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TutorialsScreen extends StatefulWidget {
  final String carMake;
  final String carModel;

  const TutorialsScreen({
    super.key,
    required this.carMake,
    required this.carModel,
  });

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  String _filterMake = '';
  String _filterModel = '';

  final _makeController = TextEditingController();
  final _modelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _makeController.text = widget.carMake;
    _modelController.text = widget.carModel;
    _filterMake = widget.carMake;
    _filterModel = widget.carModel;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    setState(() {
      _filterMake = _makeController.text.trim();
      _filterModel = _modelController.text.trim();
    });
  }

  void _clearFilter() {
    _makeController.clear();
    _modelController.clear();
    setState(() {
      _filterMake = '';
      _filterModel = '';
    });
  }

  List<QueryDocumentSnapshot> _applyClientFilter(
    List<QueryDocumentSnapshot> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final make = (data['carMake'] ?? '').toString().toLowerCase();
      final model = (data['carModel'] ?? '').toString().toLowerCase();
      final makeOk =
          _filterMake.isEmpty || make.contains(_filterMake.toLowerCase());
      final modelOk =
          _filterModel.isEmpty || model.contains(_filterModel.toLowerCase());
      return makeOk && modelOk;
    }).toList();
  }

  List<String> _safeList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tutorials',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Step-by-step maintenance guides',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _filterField(
                        controller: _makeController,
                        label: 'Car Make',
                        icon: Icons.directions_car_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _filterField(
                        controller: _modelController,
                        label: 'Car Model',
                        icon: Icons.car_repair_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _applyFilter,
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8C547),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF0A0A0F),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _clearFilter,
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16161F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: const Icon(
                          Icons.clear_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_filterMake.isNotEmpty || _filterModel.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFFE8C547),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Showing: '
                        '${_filterMake.isNotEmpty ? _filterMake : ''}'
                        '${_filterModel.isNotEmpty ? ' · $_filterModel' : ''}',
                        style: const TextStyle(
                          color: Color(0xFFE8C547),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('tutorial').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8C547)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                final docs = _applyClientFilter(allDocs);

                if (allDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No tutorials in database yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Add tutorials in Firebase Console',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No tutorials found',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Try a different make or model',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _clearFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16161F),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFE8C547,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Show all tutorials',
                              style: TextStyle(
                                color: Color(0xFFE8C547),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _tutorialCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: Colors.white30, size: 16),
        filled: true,
        fillColor: const Color(0xFF16161F),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8C547), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
      ),
    );
  }

  Widget _tutorialCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Untitled';
    final level = data['level'] ?? 'Beginner';
    final carMake = data['carMake'] ?? '';
    final carModel = data['carModel'] ?? '';
    final engineType = data['engineType'] ?? '';
    final tools = _safeList(data['toolsNeeded']);
    final steps = _safeList(data['steps']);
    final videoUrl = (data['videoUrl'] ?? '').toString();
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);

    final levelColors = {
      'Beginner': const Color(0xFF4CAF50),
      'Intermediate': const Color(0xFFE8C547),
      'Advanced': const Color(0xFFFF6B2B),
    };
    final levelColor = levelColors[level] ?? const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  _badge(level, levelColor),
                  if (carMake.isNotEmpty) _badge(carMake, Colors.white30),
                  if (carModel.isNotEmpty) _badge(carModel, Colors.white30),
                  if (engineType.isNotEmpty)
                    _badge(engineType, const Color(0xFF2196F3)),
                ],
              ),
            ],
          ),
          iconColor: const Color(0xFFE8C547),
          collapsedIconColor: Colors.white30,
          children: [
            if (videoId != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(
                  controller: YoutubePlayerController(
                    initialVideoId: videoId,
                    flags: const YoutubePlayerFlags(
                      autoPlay: false,
                      mute: false,
                    ),
                  ),
                  showVideoProgressIndicator: true,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (tools.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.build_outlined,
                    color: Color(0xFFE8C547),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Tools Needed',
                    style: TextStyle(
                      color: Color(0xFFE8C547),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tools
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE8C547,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFFE8C547,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            color: Color(0xFFE8C547),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (steps.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    color: Color(0xFFE8C547),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Steps',
                    style: TextStyle(
                      color: Color(0xFFE8C547),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...steps.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8C547),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(
                                color: Color(0xFF0A0A0F),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
