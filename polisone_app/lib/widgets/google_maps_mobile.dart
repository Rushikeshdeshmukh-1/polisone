
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleMapsWidget extends StatefulWidget {
  final FirebaseFirestore firestore;
  
  const GoogleMapsWidget({Key? key, required this.firestore}) : super(key: key);

  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777), // Mumbai Police HQ
    zoom: 12,
  );

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers = {
      const Marker(
        markerId: MarkerId('hq'),
        position: LatLng(19.0760, 72.8777),
        infoWindow: InfoWindow(title: 'Mumbai Police HQ'),
      ),
      Marker(
        markerId: const MarkerId('unit12'),
        position: const LatLng(19.0860, 72.8877),
        infoWindow: const InfoWindow(title: 'Unit-12'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('unit08'),
        position: const LatLng(19.0660, 72.8677),
        infoWindow: const InfoWindow(title: 'Unit-08'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('unit15'),
        position: const LatLng(19.0760, 72.8977),
        infoWindow: const InfoWindow(title: 'Unit-15'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: _initialPosition,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
      ),
    );
  }
}
