import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ProperGoogleMapsWidget extends StatefulWidget {
  final FirebaseFirestore firestore;
  
  const ProperGoogleMapsWidget({Key? key, required this.firestore}) : super(key: key);

  @override
  State<ProperGoogleMapsWidget> createState() => _ProperGoogleMapsWidgetState();
}

class _ProperGoogleMapsWidgetState extends State<ProperGoogleMapsWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  StreamSubscription<QuerySnapshot>? _officersSubscription;

  static const CameraPosition _mumbai = CameraPosition(
    target: LatLng(19.0760, 72.8777),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _createStaticMarkers();
    _listenToOfficers();
  }

  @override
  void dispose() {
    _officersSubscription?.cancel();
    super.dispose();
  }

  void _createStaticMarkers() {
    // Mumbai Police HQ - always visible
    _markers.add(
      Marker(
        markerId: const MarkerId('police-hq'),
        position: const LatLng(19.0760, 72.8777),
        infoWindow: const InfoWindow(
          title: 'Mumbai Police HQ',
          snippet: 'Headquarters',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  void _listenToOfficers() {
    // Real-time listener for officers collection
    // ONLY show officers who have a userId (linked to Firebase Auth)
    _officersSubscription = widget.firestore
        .collection('officers')
        .where('userId', isNotEqualTo: null) // Only authenticated officers
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      setState(() {
        // Remove old officer markers (keep HQ)
        _markers.removeWhere((marker) => marker.markerId.value != 'police-hq');

        // Add markers for each AUTHENTICATED officer from Firebase
        for (var doc in snapshot.docs) {
          final data = doc.data();
          
          // Double-check userId exists
          if (data['userId'] == null || data['userId'].toString().isEmpty) {
            continue; // Skip officers without authentication
          }
          
          final name = data['name'] ?? 'Unknown Officer';
          final status = data['status'] ?? 'off_duty';
          final email = data['email'] ?? '';
          
          // Get coordinates (use defaults if not set)
          final latitude = data['latitude'] ?? (19.0760 + (snapshot.docs.indexOf(doc) * 0.02));
          final longitude = data['longitude'] ?? (72.8777 + (snapshot.docs.indexOf(doc) * 0.02));

          // Determine marker color based on status
          double hue;
          String statusText;
          if (status == 'on_patrol') {
            hue = BitmapDescriptor.hueGreen;
            statusText = 'On Patrol';
          } else if (status == 'responding') {
            hue = BitmapDescriptor.hueOrange;
            statusText = 'Responding';
          } else {
            hue = BitmapDescriptor.hueRed;
            statusText = 'Off Duty';
          }

          _markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                title: name,
                snippet: '$statusText${email.isNotEmpty ? ' • $email' : ''}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _mumbai,
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              zoomControlsEnabled: true,
              mapToolbarEnabled: true,
              myLocationButtonEnabled: false,
            ),
            // Real-time indicator
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
}
