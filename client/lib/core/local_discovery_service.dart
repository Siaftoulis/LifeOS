import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

class LocalPeer {
  final String name;
  final String address;
  final int port;

  LocalPeer({required this.name, required this.address, required this.port});

  @override
  String toString() => '$name ($address:$port)';
}

class LocalDiscoveryService {
  static final LocalDiscoveryService instance = LocalDiscoveryService._internal();

  final String _serviceType = '_lifeos._tcp';
  final int _localSyncPort = 4444; // Port to use for P2P sync later
  
  Registration? _registration;
  Discovery? _discovery;
  
  final List<LocalPeer> _discoveredPeers = [];
  final ValueNotifier<List<LocalPeer>> peersNotifier = ValueNotifier([]);

  LocalDiscoveryService._internal();

  Future<void> start() async {
    try {
      await _registerService();
      await _startDiscovery();
      debugPrint("LocalDiscoveryService started successfully.");
    } catch (e) {
      debugPrint("LocalDiscoveryService failed to start: $e");
    }
  }

  Future<void> _registerService() async {
    // Stop any existing registration
    if (_registration != null) {
      await unregister(_registration!);
      _registration = null;
    }

    // Use a unique name for this device, e.g., "LifeOS_Phone"
    final serviceName = 'LifeOS_${DateTime.now().millisecondsSinceEpoch}';
    
    _registration = await register(
      Service(
        name: serviceName,
        type: _serviceType,
        port: _localSyncPort,
        txt: {
          'app': Uint8List.fromList(utf8.encode('lifeos')), 
          'version': Uint8List.fromList(utf8.encode('1.0'))
        },
      ),
    );
    debugPrint("mDNS Service registered: ${_registration?.service.name}");
  }

  Future<void> _startDiscovery() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
    }

    _discovery = await startDiscovery(_serviceType);
    _discovery!.addListener(() {
      _discoveredPeers.clear();
      for (final service in _discovery!.services) {
        if (service.name == _registration?.service.name) continue; // Skip self
        
        // nsd package handles IPv4/IPv6 addresses, we prefer IPv4 if possible
        final address = service.addresses?.firstWhere(
          (addr) => addr.type == InternetAddressType.IPv4,
          orElse: () => service.addresses!.first,
        );

        if (address != null && service.port != null) {
          _discoveredPeers.add(LocalPeer(
            name: service.name ?? 'Unknown Device',
            address: address.address,
            port: service.port!,
          ));
        }
      }
      peersNotifier.value = List.from(_discoveredPeers);
      debugPrint("Discovered LifeOS peers: $_discoveredPeers");
    });
  }

  Future<void> stop() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
    }
    if (_registration != null) {
      await unregister(_registration!);
      _registration = null;
    }
    _discoveredPeers.clear();
    peersNotifier.value = [];
    debugPrint("LocalDiscoveryService stopped.");
  }
}
