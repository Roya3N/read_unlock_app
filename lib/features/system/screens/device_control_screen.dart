import 'package:flutter/material.dart';
import 'package:read_unlock_app/core/services/device_control_service.dart';

/// Parent-only screen (opened from the PIN-protected parent area).
/// Explains plainly what each control does and does not do.
class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({super.key});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _kidsModeOn = false;
  bool _hasUsageAccess = false;
  List<AppUsage> _usage = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from system settings: re-check the permission.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final kids = await DeviceControlService.isKidsModeOn();
    final access = await DeviceControlService.hasUsageAccess();
    final usage = access
        ? await DeviceControlService.usageToday()
        : const <AppUsage>[];
    if (!mounted) return;
    setState(() {
      _kidsModeOn = kids;
      _hasUsageAccess = access;
      _usage = usage;
      _loading = false;
    });
  }

  Future<void> _toggleKidsMode() async {
    if (_kidsModeOn) {
      await DeviceControlService.stopKidsMode();
    } else {
      await DeviceControlService.startKidsMode();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text("Device Controls"),
      ),
      body: !DeviceControlService.isSupported
          ? _buildUnsupported()
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildKidsModeCard(),
                  const SizedBox(height: 16),
                  _buildUsageCard(),
                ],
              ),
            ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static const _title = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static const _body = TextStyle(color: Colors.white70, fontSize: 14);

  Widget _buildKidsModeCard() {
    return _card(
      children: [
        Text("Kids Mode", style: _title),
        const SizedBox(height: 8),
        const Text(
          "Pins Magic Academy to the screen so your child stays in the app. "
          "Android asks you to confirm. To make leaving need your phone's "
          "PIN, turn on \"Ask for PIN before unpinning\" in Android "
          "Settings > Security > App pinning.",
          style: _body,
        ),
        const SizedBox(height: 8),
        const Text(
          "Kids Mode does not block other apps when it is off, and it "
          "does not stop someone who knows the device PIN.",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _toggleKidsMode,
            icon: Icon(_kidsModeOn ? Icons.lock_open : Icons.push_pin),
            label: Text(_kidsModeOn ? "Turn off Kids Mode" : "Start Kids Mode"),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageCard() {
    final total = _usage.fold<int>(0, (sum, a) => sum + a.minutes);
    return _card(
      children: [
        Text("App usage today", style: _title),
        const SizedBox(height: 8),
        const Text(
          "Shows how long each app was open on this device today. "
          "It only measures; it does not block apps. It counts everyone "
          "who uses this device, not only your child.",
          style: _body,
        ),
        const SizedBox(height: 16),
        if (!_hasUsageAccess) ...[
          const Text(
            "Needs \"Usage access\". Android will open its settings: find "
            "Magic Academy and allow it.",
            style: _body,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: DeviceControlService.openUsageAccessSettings,
              child: const Text("Allow usage access"),
            ),
          ),
        ] else if (_usage.isEmpty)
          const Text(
            "No app was used for a full minute yet today.",
            style: _body,
          )
        else ...[
          Text(
            "Total: $total min",
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ..._usage.map(
            (a) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(a.label, style: const TextStyle(color: Colors.white)),
              trailing: Text(
                "${a.minutes} min",
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUnsupported() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        "Device controls are available on Android for now.\n\n"
        "On iPad or iPhone, use Guided Access to keep your child in the "
        "app: Settings > Accessibility > Guided Access, then triple-click "
        "the side or Home button while Magic Academy is open.",
        style: TextStyle(color: Colors.white70, fontSize: 15),
      ),
    );
  }
}
