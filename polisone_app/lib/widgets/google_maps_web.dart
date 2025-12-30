import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

// Register the view factory globally once
void _ensureMapViewFactoryRegistered(String viewId) {
  try {
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) {
        final mapDiv = html.DivElement()
          ..id = 'map-$id'
          ..style.width = '100%'
          ..style.height = '100%';

        // Add loading indicator
        mapDiv.innerHtml = '''
          <div style="display:flex;align-items:center;justify-content:center;height:100%;color:#666;font-family:sans-serif;flex-direction:column;">
            <div style="font-size:48px;margin-bottom:16px;">🗺️</div>
            <div>Initializing Google Maps...</div>
          </div>
        ''';

        // Initialize map after a delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          final script = html.ScriptElement()
            ..text = '''
              (function() {
                function tryInitMap(attempts) {
                  const mapElement = document.getElementById('map-$id');
                  if (!mapElement) return;
                  
                  if (typeof google === 'undefined' || !google.maps) {
                    if (attempts < 30) {
                      setTimeout(() => tryInitMap(attempts + 1), 200);
                    }
                    return;
                  }
                  
                  try {
                    const map = new google.maps.Map(mapElement, {
                      center: { lat: 19.0760, lng: 72.8777 },
                      zoom: 12,
                    });

                    new google.maps.Marker({
                      position: { lat: 19.0760, lng: 72.8777 },
                      map: map,
                      title: 'Mumbai Police HQ',
                    });

                    const officers = [
                      { lat: 19.0860, lng: 72.8877, name: 'Unit-12', color: '#10B981' },
                      { lat: 19.0660, lng: 72.8677, name: 'Unit-08', color: '#F59E0B' },
                      { lat: 19.0760, lng: 72.8977, name: 'Unit-15', color: '#10B981' },
                    ];

                    officers.forEach(o => {
                      new google.maps.Marker({
                        position: { lat: o.lat, lng: o.lng },
                        map: map,
                        title: o.name,
                      });
                    });
                  } catch (e) {
                    console.error('Map error:', e);
                  }
                }
                tryInitMap(0);
              })();
            ''';
          html.document.body?.append(script);
        });

        return mapDiv;
      },
    );
  } catch (e) {
    // View factory already registered, ignore
  }
}

class GoogleMapsWidget extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String viewId = 'google-maps-view';
  
  const GoogleMapsWidget({Key? key, required this.firestore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure factory is registered before building
    _ensureMapViewFactoryRegistered(viewId);
    
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(viewType: viewId),
      ),
    );
  }
}
