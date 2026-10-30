import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/sos_service.dart';

class SosHomeScreen extends StatefulWidget {
  const SosHomeScreen({super.key});

  @override
  State<SosHomeScreen> createState() => _SosHomeScreenState();
}

class _SosHomeScreenState extends State<SosHomeScreen> {
  bool _isSosActive = false;
  bool _safeCheckInEnabled = false;
  bool _isCountingDown = false;
  int _countdownSeconds = 3;
  String _locationText = 'Fetching live location...';
  String _mapLink = 'https://maps.google.com';
  String _selectedAlertType = 'Medical';
  final String _userName = 'Riya Sharma';
  Timer? _countdownTimer;

  final List<Map<String, String>> _contacts = [
    {'name': 'Mom', 'phone': '+919999999999'},
    {'name': 'Brother', 'phone': '+918888888888'},
    {'name': 'Best Friend', 'phone': '+917777777777'},
  ];

  final List<String> _alertTypes = [
    'Medical',
    'Fire',
    'Security',
    'Natural Disaster',
    'Personal Safety',
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      await _requestLocationPermission();
      await _updateLocation();
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Location unavailable';
          _mapLink = 'https://maps.google.com';
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      throw Exception('Location permission denied');
    }
  }

  Future<void> _updateLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    final lat = position.latitude.toStringAsFixed(5);
    final lng = position.longitude.toStringAsFixed(5);
    final googleMapUrl = 'https://maps.google.com/?q=$lat,$lng';

    setState(() {
      _locationText = '$lat, $lng';
      _mapLink = googleMapUrl;
    });
  }

  Future<void> _startEmergencySequence() async {
    if (_isCountingDown) return;

    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _performSos();
        return;
      }

      if (mounted) {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  Future<void> _performSos() async {
    if (mounted) {
      setState(() {
        _isSosActive = true;
        _isCountingDown = false;
      });
    }

    try {
      await SosService.sendSOS(
        userName: _userName,
        location: _locationText,
        alertType: _selectedAlertType,
        mapLink: _mapLink,
      );

      for (final contact in _contacts) {
        final phone = contact['phone'] ?? '';
        if (phone.isNotEmpty) {
          await _sendMessageToContact(
            phone,
            message: 'Emergency! $_userName needs help. Alert type: $_selectedAlertType. Location: $_locationText\nMap: $_mapLink',
          );
        }
      }

      await _callNumber('112');
      _showSnack('Emergency alert sent to trusted contacts and authorities');
    } catch (_) {
      _showSnack('SOS failed. Please try again.');
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isSosActive = false;
          });
        }
      });
    }
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendMessageToContact(
    String phone, {
    String? message,
  }) async {
    final body = Uri.encodeComponent(
      message ??
          'Emergency! I need help. My location: $_locationText\nMap: $_mapLink',
    );
    final uri = Uri.parse('sms:$phone?body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMap() async {
    final uri = Uri.parse(_mapLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleCheckIn() {
    setState(() {
      _safeCheckInEnabled = !_safeCheckInEnabled;
    });

    if (_safeCheckInEnabled) {
      SosService.sendSafetyCheckIn(
        userName: _userName,
        location: _locationText,
        status: 'active',
      );
      _showSnack('Safe check-in enabled. Your contacts will be updated.');
    } else {
      SosService.sendSafetyCheckIn(
        userName: _userName,
        location: _locationText,
        status: 'stopped',
      );
      _showSnack('Safe check-in stopped.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09111F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildProfileCard(),
              const SizedBox(height: 22),
              _buildSosButton(),
              const SizedBox(height: 18),
              _buildAlertTypeSelector(),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      title: 'Police',
                      subtitle: 'Call 112',
                      icon: Icons.local_police_rounded,
                      color: const Color(0xFF3B82F6),
                      onTap: () => _callNumber('112'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      title: 'Hospital',
                      subtitle: 'Call 108',
                      icon: Icons.local_hospital_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () => _callNumber('108'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLocationCard(),
              const SizedBox(height: 20),
              _buildMedicalInfoCard(),
              const SizedBox(height: 20),
              _buildContactsCard(),
              const SizedBox(height: 20),
              _buildSafeCheckInCard(),
              const SizedBox(height: 20),
              _buildRecentAlerts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SafeGuard Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Emergency assistance dashboard',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: const Icon(Icons.notifications_none, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFF4E7BFF),
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $_userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your safety dashboard is active',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.green, size: 10),
                SizedBox(width: 6),
                Text(
                  'Safe',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSosButton() {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isSosActive ? 250 : 220,
        height: _isSosActive ? 250 : 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: _isSosActive
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.8),
                    blurRadius: 50,
                    spreadRadius: 12,
                  ),
                ]
              : [],
        ),
        child: GestureDetector(
          onTap: _startEmergencySequence,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: _isSosActive || _isCountingDown ? 0.95 : 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3D3D), Color(0xFFB30000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white24, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.45),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: _isCountingDown
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_rounded,
                              size: 42, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            '$_countdownSeconds',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Sending alert...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 48, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alert type',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _alertTypes.map((type) {
            final selected = type == _selectedAlertType;
            return ChoiceChip(
              label: Text(type),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedAlertType = type;
                });
              },
              selectedColor: Colors.redAccent,
              backgroundColor: Colors.white10,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live location',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locationText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openMap,
              icon: const Icon(Icons.map_rounded, color: Colors.white),
              label: const Text(
                'Open map',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medical profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Blood group', 'O+'),
          _infoRow('Allergies', 'None'),
          _infoRow('Condition', 'Asthma'),
          _infoRow('Emergency note', 'Needs medication if severe panic attack'),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency contacts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _contacts.length,
          itemBuilder: (context, index) {
            final contact = _contacts[index];
            final color = Colors.primaries[index % Colors.primaries.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.35),
                    child: Text(
                      contact['name']![0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact['name']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          contact['phone']!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _callNumber(contact['phone']!.replaceAll(RegExp(r'[^0-9]'), '')),
                        icon: const Icon(Icons.call, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () => _sendMessageToContact(
                          contact['phone']!,
                        ),
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSafeCheckInCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _safeCheckInEnabled ? Colors.green.withOpacity(0.1) : Colors.white10,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _safeCheckInEnabled ? Colors.green.withOpacity(0.5) : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safe check-in',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Update your family on your journey',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          Switch(
            value: _safeCheckInEnabled,
            activeColor: Colors.green,
            onChanged: (_) => _toggleCheckIn(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent SOS activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sos_requests')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.red),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text(
                'No SOS activity yet',
                style: TextStyle(color: Colors.white70),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['name'] ?? 'Emergency',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              data['alertType'] ?? 'General',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['location'] ?? 'Location unavailable',
                        style: const TextStyle(color: Colors.white70),
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

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.22),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
