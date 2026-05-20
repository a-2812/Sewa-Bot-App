import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../providers/voice_state.dart';
import '../../services/agent_service.dart';
import '../../services/voice_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isVoiceMode = false;
  bool _isLoading = false;
  String _selectedLocale = 'ur_PK';
  int _selectedLocaleIndex = 0;
  late AnimationController _pulseController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        if (args['voiceMode'] == true) setState(() => _isVoiceMode = true);
        if (args['initialService'] != null) {
          _textController.text = '${args['initialService']} needed';
        }
      }
      if (!_isVoiceMode) {
        _addBotMessage(
            'Hello! What service do you need?\nYou can tell me in English, Urdu, or Roman Urdu.\n\nExample: "Mujhe kal subah G-13 mein AC technician chahiye"');
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _addBotMessage(String text) {
    setState(() => _messages.add({'text': text, 'isUser': false, 'time': DateTime.now()}));
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() => _messages.add({'text': text, 'isUser': true, 'time': DateTime.now()}));
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _addUserMessage(text.trim());

    setState(() => _isLoading = true);
    final appState = context.read<AppState>();

    // ── Step 1: extractIntent ────────────────────────────────
    _addBotMessage('Analysing your request...');
    final intentResult = await AgentService.extractIntent(
      text.trim(),
      sessionId: appState.sessionId,
    );

    setState(() {
      _messages.removeLast(); // remove "samajh raha hoon"
    });

    if (intentResult.containsKey('error') && !intentResult.containsKey('intent')) {
      setState(() => _isLoading = false);
      _addBotMessage(
          'Could not connect to Agents API.\n\n'
          'Make sure the agents server is running:\n'
          '  python main_api.py  (port 8001)\n\n'
          'Error: ${intentResult['error']}');
      return;
    }

    // Update session_id if API returned a new one
    final returnedSessionId = intentResult['session_id'] as String?;
    if (returnedSessionId != null && returnedSessionId != appState.sessionId) {
      appState.updateSessionId(returnedSessionId);
    }

    final activeSessionId = returnedSessionId ?? appState.sessionId;

    // Append agent log from this step
    final stepLog1 = intentResult['agent_log'] as List? ?? [];
    appState.appendAgentLog(stepLog1);

    // Handle clarification needed
    final intent = intentResult['intent'] as Map<String, dynamic>?;
    if (intent != null && intent['clarification_needed'] == true) {
      final q = intent['clarification_question'] ?? 'Thori aur detail de dein?';
      appState.setClarification(needed: true, question: q);
      setState(() => _isLoading = false);
      _addBotMessage(q);
      return;
    }
    appState.setClarification(needed: false);

    if (intent != null) {
      appState.setIntent(intent);
      setState(() => _messages.add({
            'text': '__INTENT_CARD__',
            'isUser': false,
            'time': DateTime.now(),
            'data': intent,
          }));
      _scrollToBottom();
    }

    // Show fallback banner if demo mode triggered
    if (intentResult['_fallback'] == true) {
      _addBotMessage(
          'Demo mode — showing sample data.\n'
          '${intentResult['_fallback_reason'] ?? ''}');
    }

    // ── Step 2: getProviders ────────────────────────────────
    _addBotMessage('Searching for providers...');

    final provResult = await AgentService.getProviders(
      activeSessionId,
      intent ?? {},
    );

    setState(() {
      _messages.removeLast(); // remove "providers dhundh raha hoon"
      _isLoading = false;
    });

    final stepLog2 = provResult['agent_log'] as List? ?? [];
    appState.appendAgentLog(stepLog2);

    final rawProviders = provResult['providers'] as List? ?? [];
    final providers = rawProviders
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();

    appState.setProviders(providers);

    if (providers.isEmpty) {
      _addBotMessage(
          'No providers found in this area.\n\n'
          'Try: Islamabad, G-13, F-10, Lahore, DHA, Gulberg, etc.');
      return;
    }

    final demo = provResult['_fallback'] == true ? ' (demo)' : '';
    _addBotMessage(
        '${providers.length} provider${providers.length == 1 ? '' : 's'} found$demo. Showing top matches:');

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.pushNamed(context, '/user/providers');
    }
  }


  // ─── Voice Methods ─────────────────────────────────────────
  Future<void> _toggleListening() async {
    final voiceState = context.read<VoiceState>();

    if (voiceState.isListening) {
      await VoiceService.stopListening();
      voiceState.setListening(false);

      final text = voiceState.transcribedText;
      if (text.isNotEmpty) {
        voiceState.setProcessing(true);
        voiceState.setStatus('Processing...');
        await _processVoiceInput(text);
        voiceState.setProcessing(false);
      }
      voiceState.setStatus('');
    } else {
      final granted = await _requestMicPermission();
      if (!granted) return;

      voiceState.reset();
      voiceState.setListening(true);
      voiceState.setStatus('Sun raha hoon...');

      await VoiceService.startListening(
        onResult: (text) => voiceState.setTranscribed(text),
        onSoundLevel: (level) => voiceState.setSoundLevel(level),
        localeId: _selectedLocale,
      );
    }
  }

  Future<void> _processVoiceInput(String text) async {
    final voiceState = context.read<VoiceState>();
    final appState = context.read<AppState>();
    voiceState.addToHistory(text, true);
    voiceState.setStatus('AI is thinking...');
    _addUserMessage(text);

    final result = await AgentService.chat(text, appState.sessionId);

    if (result.containsKey('error')) {
      _addBotMessage('Error: ${result['error']}');
      return;
    }

    final agentLog = result['agent_log'] as List? ?? [];
    appState.setAgentLog(agentLog);

    if (result['clarification_needed'] == true) {
      final question = result['clarification_question'] ?? 'Thori detail dein?';
      voiceState.addToHistory(question, false);
      voiceState.setStatus('Sawal pooch raha hoon...');
      _addBotMessage(question);
      await VoiceService.speak(question);
      voiceState.setStatus('Jawab dijiye...');
      return;
    }

    final intent = result['intent'] as Map<String, dynamic>?;
    if (intent != null) appState.setIntent(intent);

    final options = result['options'] as List? ?? [];
    final providers = options.map((p) => Map<String, dynamic>.from(p as Map)).toList();
    appState.setProviders(providers);

    final spokenResponse =
        "${intent?['service_type'] ?? 'Service'} ki request mil gayi. ${providers.length} providers mile.";
    voiceState.addToHistory(spokenResponse, false);
    _addBotMessage(spokenResponse);
    await VoiceService.speak(spokenResponse);

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.pushNamed(context, '/user/providers');
  }

  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.userPrimary,
        leading: Navigator.canPop(context)
            ? Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                    fixedSize: const Size(36, 36),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SewaBot',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            Text('Request a service',
                style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isVoiceMode ? Icons.mic : Icons.mic_off, color: Colors.white),
            onPressed: () => setState(() => _isVoiceMode = !_isVoiceMode),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/trace'),
          ),
        ],
      ),
      body: _isVoiceMode ? _buildVoiceMode() : _buildTextMode(),
    );
  }

  // ─── TEXT MODE ─────────────────────────────────────────────
  Widget _buildTextMode() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              if (msg['text'] == '__INTENT_CARD__') return _buildIntentCard(msg['data']);
              return _buildMessageBubble(msg);
            },
          ),
        ),
        if (_isLoading) _buildLoadingIndicator(),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['isUser'] == true;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.userPrimary : AppTheme.userSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppTheme.userBorder, width: 0.5),
        ),
        child: Text(
          msg['text'] as String,
          style: TextStyle(
            color: isUser ? Colors.white : AppTheme.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildIntentCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.userSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.userPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.psychology, color: AppTheme.userPrimary, size: 18),
            const SizedBox(width: 8),
            const Text('AI ne samjha:',
                style: TextStyle(
                    color: AppTheme.userPrimaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 10),
          _intentRow('Service', data['service_type'] ?? '—'),
          _intentRow('Location', data['location'] ?? '—'),
          _intentRow('Time', data['preferred_time'] ?? '—'),
          _intentRow('Urgency', data['urgency'] ?? '—'),
          _intentRow('Confidence',
              '${((data['confidence_score'] ?? 0) * 100).toInt()}%'),
          _intentRow('Language', data['language_detected'] ?? '—'),
        ],
      ),
    );
  }

  Widget _intentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final delay = i * 0.15;
              final val = ((_pulseController.value - delay) % 1.0).abs();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.userPrimary.withValues(alpha: 0.3 + val * 0.7),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppTheme.userInputFill,
        border: Border(top: BorderSide(color: AppTheme.userBorder, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'AC repair, plumber needed...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.userSurface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.mic, color: Colors.black),
                    onPressed: () => setState(() => _isVoiceMode = true),
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_textController.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppTheme.userPrimary),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── VOICE MODE ────────────────────────────────────────────
  Widget _buildVoiceMode() {
    return Consumer<VoiceState>(
      builder: (context, voiceState, _) {
        return Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (voiceState.isListening)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Container(
                          width: 200 + (_pulseController.value * 60),
                          height: 200 + (_pulseController.value * 60),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.userPrimary
                                .withValues(alpha: 0.05 + _pulseController.value * 0.03),
                          ),
                        );
                      },
                    ),
                  if (voiceState.isListening)
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(20, (i) {
                          final h = (voiceState.soundLevel.abs() *
                                  _random.nextDouble() *
                                  40)
                              .clamp(4.0, 60.0);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 80),
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 3,
                            height: h,
                            decoration: BoxDecoration(
                              color: AppTheme.userPrimary
                                  .withValues(alpha: (h / 60).clamp(0.3, 1.0)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        voiceState.statusMessage.isEmpty
                            ? 'Start speaking...'
                            : voiceState.statusMessage,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLangPill(0, 'اردو', 'ur_PK'),
                          const SizedBox(width: 8),
                          _buildLangPill(1, 'Roman Urdu', 'ur_PK'),
                          const SizedBox(width: 8),
                          _buildLangPill(2, 'English', 'en_US'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.userSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.userBorder, width: 0.5),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            voiceState.transcribedText.isEmpty
                                ? 'آپ کی آواز یہاں نظر آئے گی...'
                                : voiceState.transcribedText,
                            key: ValueKey(voiceState.transcribedText),
                            style: TextStyle(
                              color: voiceState.transcribedText.isEmpty
                                  ? AppTheme.textMuted
                                  : AppTheme.textPrimary,
                              fontSize: voiceState.transcribedText.isEmpty ? 14 : 16,
                              fontStyle: voiceState.transcribedText.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: _toggleListening,
                        child: _buildMicButton(voiceState),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        voiceState.isListening
                            ? 'Rokne ke liye dabao'
                            : voiceState.isProcessing
                                ? 'AI is thinking...'
                                : 'Hold to speak',
                        style: TextStyle(
                          color: voiceState.isListening
                              ? AppTheme.danger
                              : voiceState.isProcessing
                                  ? AppTheme.warning
                                  : AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          reverse: true,
                          itemCount: voiceState.conversationHistory.length,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemBuilder: (context, index) {
                            final item = voiceState.conversationHistory[
                                voiceState.conversationHistory.length - 1 - index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(item,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _isVoiceMode = false),
                      icon: const Icon(Icons.keyboard,
                          color: AppTheme.textSecondary, size: 16),
                      label: const Text('Switch to text',
                          style:
                              TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ),
                    const Spacer(),
                    Text('Language: $_selectedLocale',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMicButton(VoiceState voiceState) {
    final color = voiceState.isListening
        ? AppTheme.danger
        : voiceState.isProcessing
            ? AppTheme.warning
            : AppTheme.userPrimary;
    final child = Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)
        ],
      ),
      child: voiceState.isProcessing
          ? const Padding(
              padding: EdgeInsets.all(25),
              child:
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Icon(
              voiceState.isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 40),
    );

    if (voiceState.isListening) {
      return AvatarGlow(
        glowColor: AppTheme.userPrimary,
        endRadius: 80.0,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        child: child,
      );
    }
    return child;
  }

  Widget _buildLangPill(int index, String label, String locale) {
    final selected = _selectedLocaleIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocaleIndex = index;
          _selectedLocale = locale;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.userPrimary : AppTheme.userSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12)),
      ),
    );
  }
}
