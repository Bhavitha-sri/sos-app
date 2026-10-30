import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class SosHomeScreen extends StatefulWidget {
  const SosHomeScreen({super.key});

  @override
  State<SosHomeScreen> createState() => _SosHomeScreenState();
}

class _SosHomeScreenState extends State<SosHomeScreen> {
  bool _isSosActive = false;
  String _locationText = 'Fetching live location...';
  final String _userName = 'Riya';

  final List<Map<String, String>> _contacts = [
    {'name': 'Mom', 'phone': '+919999999999'},
    {'name': 'Brother', 'phone': '+918888888888'},
    {'name': 'Best Friend', 'phone': '+917777777777'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
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

    setState(() {
      _locationText =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    });
  }

  Future<void> _triggerSOS() async {
    setState(() {
      _isSosActive = true;
    });

    try {
      await SosService.sendSOS(_userName, _locationText);
      _showSnack('SOS alert sent successfully');
      await _callNumber('112');
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
      await launchUrl(uri);
    }
  }

  Future<void> _sendMessageToContact(String phone) async {
    final message = Uri.encodeComponent(
      'Emergency! I need help. My location: $_locationText',
    );
    final uri = Uri.parse('sms:$phone?body=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF09111F),
              Color(0xFF101A30),
              Color(0xFF1F2A44),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SafeGuard',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Emergency assistance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.notifications_none, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF4E7BFF),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Welcome, Riya',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your safety dashboard',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isSosActive ? 260 : 220,
                    height: _isSosActive ? 260 : 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _isSosActive
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.8),
                                blurRadius: 45,
                                spreadRadius: 12,
                              ),
                            ]
                          : [],
                    ),
                    child: GestureDetector(
                      onTap: _triggerSOS,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: _isSosActive ? 0.96 : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF3D3D),
                                Color(0xFFB30000),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white24, width: 6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Column(
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
                ),
                const SizedBox(height: 28),
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
                        subtitle: 'Nearest help',
                        icon: Icons.local_hospital_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () => _callNumber('108'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
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
                        'Live Location',
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
                    ],
                  ),
                ),
                const SizedBox(height: 22),
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
                          IconButton(
                            onPressed: () => _sendMessageToContact(contact['phone']!),
                            icon: const Icon(Icons.send_rounded, color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
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
                              Text(
                                data['name'] ?? 'Emergency',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
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
            ),
          ),
        ),
      ),
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

class SosService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> sendSOS(String userName, String location) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ??
        (await FirebaseAuth.instance.signInAnonymously()).user!.uid;

    await _db.collection('sos_requests').add({
      'userId': uid,
      'name': userName,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }
}
