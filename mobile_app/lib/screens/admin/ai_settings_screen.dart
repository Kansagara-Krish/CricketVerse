// lib/screens/admin/ai_settings_screen.dart
// AI & ElevenLabs Voice configuration settings

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';
import '../../services/elevenlabs_service.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final ElevenLabsService _elevenLabsService = ElevenLabsService();

  late TextEditingController _apiKeyController;
  late TextEditingController _customVoiceIdController;

  bool _isTestingConnection = false;
  String? _connectionStatusMessage;
  bool? _isConnectionValid;

  bool _isTestingVoice = false;

  // Commentary settings
  bool _aiCommentary = true;
  bool _autoPlayVoice = false;
  String _selectedVoiceId = 'JBFqnCBsd6RMkjVDRZzb';
  String _selectedModel = 'eleven_turbo_v2_5';
  String _commentaryStyle = 'Hype / Energetic';
  String _commentaryTrigger = 'Every Ball';

  double _stability = 0.50;
  double _similarityBoost = 0.80;
  double _styleExaggeration = 0.35;
  bool _useSpeakerBoost = true;

  // Prediction engine settings
  bool _winPrediction = true;
  bool _smartAlerts = true;
  bool _playerInsights = true;

  @override
  void initState() {
    super.initState();
    final s = _elevenLabsService.settings;
    _apiKeyController = TextEditingController(text: s.apiKey);
    _customVoiceIdController = TextEditingController(text: s.voiceId);

    _autoPlayVoice = s.autoPlayVoice;
    _selectedVoiceId = s.voiceId;
    _selectedModel = s.modelId;
    _commentaryStyle = s.commentaryStyle;
    _commentaryTrigger = s.commentaryTrigger;
    _stability = s.stability;
    _similarityBoost = s.similarityBoost;
    _styleExaggeration = s.style;
    _useSpeakerBoost = s.useSpeakerBoost;

    // Refresh from centralized backend database
    _elevenLabsService.loadSettings().then((remote) {
      if (mounted) {
        setState(() {
          _apiKeyController.text = remote.apiKey;
          _customVoiceIdController.text = remote.voiceId;
          _autoPlayVoice = remote.autoPlayVoice;
          _selectedVoiceId = remote.voiceId;
          _selectedModel = remote.modelId;
          _commentaryStyle = remote.commentaryStyle;
          _commentaryTrigger = remote.commentaryTrigger;
          _stability = remote.stability;
          _similarityBoost = remote.similarityBoost;
          _styleExaggeration = remote.style;
          _useSpeakerBoost = remote.useSpeakerBoost;
        });
      }
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customVoiceIdController.dispose();
    _elevenLabsService.stopAudio();
    super.dispose();
  }

  Future<void> _saveAllSettings() async {
    final s = _elevenLabsService.settings;
    s.apiKey = _apiKeyController.text.trim();
    s.voiceId = _selectedVoiceId == 'CUSTOM'
        ? _customVoiceIdController.text.trim()
        : _selectedVoiceId;
    
    // Find voice name
    final matchedPreset = ElevenLabsService.defaultVoices.where((v) => v.id == s.voiceId);
    s.voiceName = matchedPreset.isNotEmpty ? matchedPreset.first.name : 'Custom Voice';

    s.modelId = _selectedModel;
    s.stability = _stability;
    s.similarityBoost = _similarityBoost;
    s.style = _styleExaggeration;
    s.useSpeakerBoost = _useSpeakerBoost;
    s.autoPlayVoice = _autoPlayVoice;
    s.commentaryStyle = _commentaryStyle;
    s.commentaryTrigger = _commentaryTrigger;

    final ok = await _elevenLabsService.saveSettings(s);
    if (!mounted) return;

    if (ok) {
      CustomNotification.show(
        context,
        'ElevenLabs & AI Settings saved successfully! 🎙️',
        type: NotificationType.success,
      );
    } else {
      CustomNotification.show(
        context,
        'Failed to save settings.',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _testElevenLabsKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _isConnectionValid = false;
        _connectionStatusMessage = 'Please enter an ElevenLabs API Key to test.';
      });
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _connectionStatusMessage = null;
    });

    final res = await _elevenLabsService.testConnection(key);

    if (!mounted) return;
    setState(() {
      _isTestingConnection = false;
      _isConnectionValid = res['success'] == true;
      _connectionStatusMessage = res['message'] ?? '';
    });
  }

  Future<void> _testVoicePlayback() async {
    if (_isTestingVoice) {
      await _elevenLabsService.stopAudio();
      setState(() => _isTestingVoice = false);
      return;
    }

    setState(() => _isTestingVoice = true);

    // Temporarily sync active settings for preview
    final s = _elevenLabsService.settings;
    s.apiKey = _apiKeyController.text.trim();
    s.voiceId = _selectedVoiceId == 'CUSTOM'
        ? _customVoiceIdController.text.trim()
        : _selectedVoiceId;
    s.modelId = _selectedModel;
    s.stability = _stability;
    s.similarityBoost = _similarityBoost;
    s.style = _styleExaggeration;
    s.useSpeakerBoost = _useSpeakerBoost;

    const sampleText =
        "SIX! What an extraordinary shot over deep mid-wicket! That has cleared the stadium roof! Welcome to CricketVerse live commentary!";

    CustomNotification.show(
      context,
      '🎙️ Speaking with ${s.apiKey.isNotEmpty ? "ElevenLabs AI Voice" : "Device TTS Voice"}...',
      type: NotificationType.info,
    );

    await _elevenLabsService.speakCommentary(
      sampleText,
      onComplete: () {
        if (mounted) setState(() => _isTestingVoice = false);
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isTestingVoice = false);
          CustomNotification.show(context, 'Voice test error: $err', type: NotificationType.error);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: Text(
          'AI & Voice Settings',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveAllSettings,
            icon: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 18),
            label: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ElevenLabs AI Voice Commentary',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Voice narration & match commentary configuration',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Section 1: ELEVENLABS CREDENTIALS & VOICE
            const _SectionLabel('ELEVENLABS API & VOICE ENGINE'),
            const SizedBox(height: 12),

            // API Key Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgMedium,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.key_rounded, color: AppTheme.accentGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ElevenLabs API Key',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_isTestingConnection)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentGold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Get your key at beta.elevenlabs.io under Profile Settings.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. sk_1234567890abcdef...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.25),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: TextButton(
                          onPressed: _isTestingConnection ? null : _testElevenLabsKey,
                          child: Text(
                            'Test Key',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_connectionStatusMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isConnectionValid == true
                            ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                            : AppTheme.accentRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isConnectionValid == true
                              ? AppTheme.primaryGreen.withValues(alpha: 0.4)
                              : AppTheme.accentRed.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isConnectionValid == true ? Icons.check_circle : Icons.error_outline,
                            color: _isConnectionValid == true ? AppTheme.primaryGreen : AppTheme.accentRed,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _connectionStatusMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: _isConnectionValid == true ? AppTheme.primaryGreen : AppTheme.accentRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Voice Preset Selector
            _DropdownTile(
              'Voice Character / Announcer',
              _selectedVoiceId,
              [
                ...ElevenLabsService.defaultVoices.map((v) => DropdownMenuItem(
                      value: v.id,
                      child: Text('${v.name} (${v.sampleGender})'),
                    )),
                const DropdownMenuItem(value: 'CUSTOM', child: Text('Custom Voice ID...')),
              ],
              (val) => setState(() => _selectedVoiceId = val),
            ),

            if (_selectedVoiceId == 'CUSTOM') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customVoiceIdController,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Custom ElevenLabs Voice ID',
                  labelStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: AppTheme.bgMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Model Selection
            _DropdownTile(
              'ElevenLabs Model',
              _selectedModel,
              ElevenLabsService.availableModels
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                          m == 'eleven_turbo_v2_5'
                              ? 'Turbo v2.5 (Fastest & Real-time)'
                              : m == 'eleven_multilingual_v2'
                                  ? 'Multilingual v2 (High Quality)'
                                  : 'Monolingual v1',
                        ),
                      ))
                  .toList(),
              (val) => setState(() => _selectedModel = val),
            ),

            const SizedBox(height: 14),

            // Sliders (Stability, Similarity, Style)
            _SliderCard(
              label: 'Voice Stability',
              value: _stability,
              min: 0.0,
              max: 1.0,
              displayFormat: '${(_stability * 100).toInt()}%',
              subtitle: 'Higher is more consistent; lower is more emotive and dynamic',
              onChanged: (v) => setState(() => _stability = v),
            ),
            const SizedBox(height: 10),
            _SliderCard(
              label: 'Clarity / Similarity Boost',
              value: _similarityBoost,
              min: 0.0,
              max: 1.0,
              displayFormat: '${(_similarityBoost * 100).toInt()}%',
              subtitle: 'Enhances voice identity adherence and reduces background noise',
              onChanged: (v) => setState(() => _similarityBoost = v),
            ),
            const SizedBox(height: 10),
            _SliderCard(
              label: 'Style Exaggeration',
              value: _styleExaggeration,
              min: 0.0,
              max: 1.0,
              displayFormat: '${(_styleExaggeration * 100).toInt()}%',
              subtitle: 'Amplifies cricket commentator energy and excitement tone',
              onChanged: (v) => setState(() => _styleExaggeration = v),
            ),

            const SizedBox(height: 16),

            // Live Voice Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testVoicePlayback,
                icon: Icon(
                  _isTestingVoice ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  _isTestingVoice ? 'Stop Audio Preview' : 'Test ElevenLabs Voice Live 🎙️',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTestingVoice ? AppTheme.accentRed : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Section 2: SMART COMMENTARY ENGINE
            const _SectionLabel('SMART CRICKET COMMENTARY ENGINE'),
            const SizedBox(height: 12),

            _SwitchTile(
              Icons.record_voice_over_rounded,
              'AI Commentary Engine',
              'Generate contextual ball-by-ball & over finish commentary',
              _aiCommentary,
              (v) => setState(() => _aiCommentary = v),
              AppTheme.primaryBlue,
            ),

            _SwitchTile(
              Icons.volume_up_outlined,
              'Auto-Play Voice',
              'Automatically speak each ball commentary via audio',
              _autoPlayVoice,
              (v) => setState(() => _autoPlayVoice = v),
              AppTheme.primaryGreen,
            ),

            const SizedBox(height: 10),

            _DropdownTile(
              'Commentary Style',
              _commentaryStyle,
              const [
                DropdownMenuItem(value: 'Hype / Energetic', child: Text('Hype / Energetic (Stadium Announcer)')),
                DropdownMenuItem(value: 'Professional', child: Text('Professional (Broadcaster Classic)')),
                DropdownMenuItem(value: 'Technical / Tactical', child: Text('Technical / Tactical (Analysis)')),
                DropdownMenuItem(value: 'Casual Fan', child: Text('Casual Fan (Relaxed Companion)')),
              ],
              (v) => setState(() => _commentaryStyle = v),
            ),

            const SizedBox(height: 10),

            _DropdownTile(
              'Voice Narration Trigger',
              _commentaryTrigger,
              const [
                DropdownMenuItem(value: 'Every Ball', child: Text('Every Ball (Full Narration)')),
                DropdownMenuItem(value: 'Boundaries & Wickets', child: Text('Boundaries & Wickets Only')),
                DropdownMenuItem(value: 'Over Finish', child: Text('Over Finish & Milestones Only')),
              ],
              (v) => setState(() => _commentaryTrigger = v),
            ),

            const SizedBox(height: 28),

            // Section 3: PREDICTION ENGINE
            const _SectionLabel('PREDICTION & ANALYTICS ENGINE'),
            const SizedBox(height: 12),

            _SwitchTile(
              Icons.auto_awesome,
              'Live Win Probability',
              'Compute real-time win probability gauge based on CRR & RRR',
              _winPrediction,
              (v) => setState(() => _winPrediction = v),
              AppTheme.accentPurple,
            ),

            _SwitchTile(
              Icons.notifications_active_outlined,
              'Smart Momentum Alerts',
              'Alert users on major win probability swings & boundary bursts',
              _smartAlerts,
              (v) => setState(() => _smartAlerts = v),
              AppTheme.accentGold,
            ),

            _SwitchTile(
              Icons.insights_rounded,
              'Player Impact Scores',
              'Calculate real-time player contribution metrics',
              _playerInsights,
              (v) => setState(() => _playerInsights = v),
              AppTheme.accentOrange,
            ),

            const SizedBox(height: 24),

            // Final Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveAllSettings,
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text('Save All Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String displayFormat;
  final String subtitle;
  final ValueChanged<double> onChanged;

  const _SliderCard({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayFormat,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                displayFormat,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: AppTheme.primaryBlue,
              inactiveColor: Colors.white.withValues(alpha: 0.1),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;
  const _SwitchTile(this.icon, this.title, this.subtitle, this.value, this.onChanged, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.08) : AppTheme.bgMedium,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? color : Colors.white38, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String label;
  final String current;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;
  const _DropdownTile(this.label, this.current, this.items, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: items.any((it) => it.value == current) ? current : items.first.value,
        dropdownColor: AppTheme.bgMedium,
        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        items: items,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
