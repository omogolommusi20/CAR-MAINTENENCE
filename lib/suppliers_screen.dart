import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _search = '';
  String? _selectedSupplier;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('suppliers').get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      setState(() {
        _suppliers = list;
        _filtered = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterSuppliers(String query) {
    setState(() {
      _search = query;
      if (query.isEmpty) {
        _filtered = _suppliers;
      } else {
        _filtered = _suppliers.where((s) {
          final name = (s['name'] ?? '').toString().toLowerCase();
          final address = (s['address'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              address.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _openInGoogleMaps(double lat, double lng, String name) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  void _showMapDialog(Map<String, dynamic> supplier) {
    final double lat = (supplier['latitude'] ?? 0).toDouble();
    final double lng = (supplier['longitude'] ?? 0).toDouble();
    final String name = supplier['name'] ?? 'Supplier';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF12121A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Map view
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 280,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: 16,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('supplier'),
                      position: LatLng(lat, lng),
                      infoWindow: InfoWindow(title: name),
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(supplier['address'] ?? '',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _openInGoogleMaps(lat, lng, name);
                          },
                          icon: const Icon(Icons.open_in_new,
                              size: 16, color: Color(0xFFE8C547)),
                          label: const Text('Open Maps',
                              style: TextStyle(color: Color(0xFFE8C547))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE8C547)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _callPhone(supplier['phone'] ?? '');
                          },
                          icon: const Icon(Icons.call, size: 16),
                          label: const Text('Call Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8C547),
                            foregroundColor: const Color(0xFF0A0A0F),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nearby Suppliers',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_filtered.length} supplier${_filtered.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Search bar
                TextField(
                  onChanged: _filterSuppliers,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name or location...',
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF16161F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Supplier list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8C547)))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) =>
                            _buildSupplierCard(_filtered[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> supplier) {
    final double lat = (supplier['latitude'] ?? 0).toDouble();
    final double lng = (supplier['longitude'] ?? 0).toDouble();
    final bool hasLocation = lat != 0 && lng != 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
      ),
      child: Column(
        children: [
          // Map preview (if location available)
          if (hasLocation)
            GestureDetector(
              onTap: () => _showMapDialog(supplier),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: SizedBox(
                  height: 140,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(lat, lng),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(supplier['id'] ?? ''),
                            position: LatLng(lat, lng),
                          ),
                        },
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                      // Tap overlay
                      Positioned.fill(
                        child: Container(color: Colors.transparent),
                      ),
                      // "Tap to expand" hint
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Tap to expand',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + category badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        supplier['name'] ?? 'Unknown Supplier',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C547).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color:
                                const Color(0xFFE8C547).withValues(alpha: 0.3)),
                      ),
                      child: const Text('Auto Parts',
                          style: TextStyle(
                              color: Color(0xFFE8C547),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Address
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Color(0xFFE8C547), size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        supplier['address'] ?? 'No address',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Phone
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        color: Color(0xFFE8C547), size: 15),
                    const SizedBox(width: 6),
                    Text(
                      supplier['phone'] ?? 'No phone',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: hasLocation
                            ? () => _openInGoogleMaps(
                                lat, lng, supplier['name'] ?? '')
                            : null,
                        icon: const Icon(Icons.map_outlined,
                            size: 15, color: Color(0xFFE8C547)),
                        label: const Text('Directions',
                            style: TextStyle(
                                color: Color(0xFFE8C547), fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: const Color(0xFFE8C547)
                                  .withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callPhone(supplier['phone'] ?? ''),
                        icon: const Icon(Icons.call, size: 15),
                        label:
                            const Text('Call', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8C547),
                          foregroundColor: const Color(0xFF0A0A0F),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined,
              size: 56, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            _search.isEmpty
                ? 'No suppliers found'
                : 'No results for "$_search"',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Add suppliers in Firestore',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
