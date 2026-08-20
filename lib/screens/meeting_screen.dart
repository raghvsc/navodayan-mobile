import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../providers/auth_provider.dart';

class MeetingScreen extends StatefulWidget {
  final String? customRoomName;

  const MeetingScreen({super.key, this.customRoomName});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  bool _loading = true;
  bool _checkingPermissions = true;
  bool _showPermissionPrompt = false;
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _needsSettings = false;
  bool _requestInProgress = false;

  // Global persistent room name for alumni lounge
  static const String _defaultRoom = 'navodayan-alumni-community-lounge-live';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _showPermissionPrompt) {
      _refreshPermissionStatus();
    }
  }

  Future<void> _checkInitialPermissions() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _checkingPermissions = false;
          _showPermissionPrompt = false;
        });
        _initWebView();
      }
      return;
    }

    try {
      final camStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      if (camStatus.isGranted && micStatus.isGranted) {
        if (mounted) {
          setState(() {
            _cameraGranted = true;
            _micGranted = true;
            _checkingPermissions = false;
            _showPermissionPrompt = false;
          });
          _initWebView();
        }
        return;
      }

      // Request system permissions directly
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final newCam = statuses[Permission.camera]?.isGranted ?? false;
      final newMic = statuses[Permission.microphone]?.isGranted ?? false;

      if (newCam && newMic) {
        if (mounted) {
          setState(() {
            _cameraGranted = true;
            _micGranted = true;
            _checkingPermissions = false;
            _showPermissionPrompt = false;
          });
          _initWebView();
        }
      } else {
        if (mounted) {
          setState(() {
            _cameraGranted = newCam;
            _micGranted = newMic;
            _checkingPermissions = false;
            _showPermissionPrompt = true;
            _needsSettings = (statuses[Permission.camera]?.isPermanentlyDenied ??
                    false) ||
                (statuses[Permission.microphone]?.isPermanentlyDenied ?? false);
          });
        }
      }
    } on MissingPluginException catch (_) {
      debugPrint('PermissionHandler plugin requires app rebuild.');
      if (mounted) {
        setState(() {
          _checkingPermissions = false;
          _showPermissionPrompt = false;
        });
        _initWebView();
      }
    } catch (e) {
      debugPrint('Permission check error: $e');
      if (mounted) {
        setState(() {
          _checkingPermissions = false;
          _showPermissionPrompt = true;
        });
      }
    }
  }

  Future<void> _handlePermissionAction() async {
    if (_requestInProgress) return;
    setState(() => _requestInProgress = true);

    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final newCam = statuses[Permission.camera]?.isGranted ?? false;
      final newMic = statuses[Permission.microphone]?.isGranted ?? false;

      if (newCam && newMic) {
        if (mounted) {
          setState(() {
            _cameraGranted = true;
            _micGranted = true;
            _showPermissionPrompt = false;
            _requestInProgress = false;
          });
          _initWebView();
        }
        return;
      }

      // If still not granted after request, open app settings
      try {
        await openAppSettings();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _needsSettings = true;
          _requestInProgress = false;
        });
      }
    } on MissingPluginException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please restart/rebuild the app with "flutter run" to enable device permissions.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _requestInProgress = false;
        });
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      try {
        await openAppSettings();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _needsSettings = true;
          _requestInProgress = false;
        });
      }
    }
  }

  Future<void> _refreshPermissionStatus() async {
    try {
      final cam = await Permission.camera.status;
      final mic = await Permission.microphone.status;
      if (mounted) {
        setState(() {
          _cameraGranted = cam.isGranted;
          _micGranted = mic.isGranted;
        });
        if (cam.isGranted && mic.isGranted) {
          setState(() {
            _showPermissionPrompt = false;
          });
          _initWebView();
        }
      }
    } catch (_) {}
  }

  void _proceedIntoMeeting() {
    if (mounted) {
      setState(() {
        _showPermissionPrompt = false;
      });
      _initWebView();
    }
  }

  void _leaveMeeting() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  void _initWebView() {
    if (_controller != null) return;

    final roomName = widget.customRoomName ?? _defaultRoom;
    final auth = context.read<AuthProvider>();
    final userName = auth.user?.profile?.fullName ??
        auth.user?.email.split('@').first ??
        'Navodayan';
    final safeUserName = jsonEncode(userName);

    final htmlContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Community Lounge</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; background-color: #0B1120; }
    #jitsi-container { width: 100%; height: 100%; }
    iframe { border: none !important; width: 100% !important; height: 100% !important; }
  </style>
  <script src="https://jitsi.riot.im/external_api.js"></script>
</head>
<body>
  <div id="jitsi-container"></div>
  <script>
    (function() {
      let attempts = 0;
      function initJitsi() {
        if (!window.JitsiMeetExternalAPI) {
          attempts++;
          if (attempts < 50) {
            setTimeout(initJitsi, 150);
          }
          return;
        }

        try {
          const domain = "jitsi.riot.im";
          const options = {
            roomName: "$roomName",
            parentNode: document.getElementById("jitsi-container"),
            width: "100%",
            height: "100%",
            userInfo: {
              displayName: $safeUserName
            },
            configOverwrite: {
              prejoinPageEnabled: false,
              prejoinConfig: {
                enabled: false,
                hideDisplayName: true
              },
              startWithAudioMuted: false,
              startWithVideoMuted: false,
              enableWelcomePage: false,
              disableModeratorIndicator: true,
              disableDeepLinking: true,
              enableFeaturesBasedOnToken: false,
              enableUserRolesBasedOnToken: false,
              hideConferenceSubject: true,
              lobbyModeEnabled: false,
              enableLobbyChat: false,
              enableInsecureRoomNameWarning: false,
              requireDisplayName: false,
              enableClosePage: false
            },
            interfaceConfigOverwrite: {
              PREJOIN_PAGE_ENABLED: false,
              SHOW_JITSI_WATERMARK: false,
              SHOW_POWERED_BY: false,
              MOBILE_APP_PROMO: false,
              HIDE_DEEP_LINKING_LOGO: true,
              DISABLE_JOIN_LEAVE_NOTIFICATIONS: true,
              TOOLBAR_BUTTONS: [
                'microphone', 'camera', 'chat', 'raisehand', 'tileview', 'hangup', 'toggle-camera'
              ]
            }
          };

          const api = new window.JitsiMeetExternalAPI(domain, options);

          api.addListener("videoConferenceJoined", function() {
            if (window.FlutterMeetingBridge) {
              window.FlutterMeetingBridge.postMessage("ready");
            }
          });

          api.addListener("videoConferenceLeft", function() {
            if (window.FlutterMeetingBridge) {
              window.FlutterMeetingBridge.postMessage("leave");
            }
          });

          api.addListener("readyToClose", function() {
            if (window.FlutterMeetingBridge) {
              window.FlutterMeetingBridge.postMessage("leave");
            }
          });

          setTimeout(function() {
            if (window.FlutterMeetingBridge) {
              window.FlutterMeetingBridge.postMessage("ready");
            }
          }, 3500);

        } catch (err) {
          console.error("Jitsi Init Error:", err);
          if (window.FlutterMeetingBridge) {
            window.FlutterMeetingBridge.postMessage("ready");
          }
        }
      }

      if (document.readyState === "complete" || document.readyState === "interactive") {
        initJitsi();
      } else {
        window.addEventListener("DOMContentLoaded", initJitsi);
      }
    })();
  </script>
</body>
</html>
''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..addJavaScriptChannel(
        'FlutterMeetingBridge',
        onMessageReceived: (message) {
          if (message.message == 'ready') {
            if (mounted) setState(() => _loading = false);
          } else if (message.message == 'leave' || message.message == 'hangup') {
            _leaveMeeting();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _loading) {
                setState(() => _loading = false);
              }
            });
          },
          onWebResourceError: (error) {
            debugPrint('Jitsi WebView Error: ${error.description}');
            if (mounted) setState(() => _loading = false);
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setOnPlatformPermissionRequest(
        (request) => request.grant(),
      );
    }

    if (!kIsWeb) {
      controller.setUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      );
    }

    controller.loadHtmlString(htmlContent, baseUrl: 'https://jitsi.riot.im');

    setState(() {
      _controller = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: _leaveMeeting,
          tooltip: 'Back',
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Community Lounge',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Live Audio & Video Space',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                backgroundColor: Colors.red.shade500.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.call_end_rounded, size: 16),
              label: const Text(
                'Leave',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: _leaveMeeting,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_checkingPermissions) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF3B82F6),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Connecting to Community Lounge...',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_showPermissionPrompt) {
      return _buildLobbyPermissionView();
    }

    return Stack(
      children: [
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (_loading)
          Container(
            color: const Color(0xFF0B1120),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Entering Community Lounge...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Connecting your video & audio stream',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLobbyPermissionView() {
    final auth = context.read<AuthProvider>();
    final userName = auth.user?.profile?.fullName ??
        auth.user?.email.split('@').first ??
        'Navodayan';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'N';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clean preview box
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF1E293B),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF93C5FD),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _cameraGranted
                                  ? Icons.videocam_rounded
                                  : Icons.videocam_off_rounded,
                              size: 14,
                              color: _cameraGranted
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _micGranted
                                  ? Icons.mic_rounded
                                  : Icons.mic_off_rounded,
                              size: 14,
                              color: _micGranted
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Headline and description
              const Text(
                'Camera & Microphone Access',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Allow access so you can speak and share video with other alumni in this live space.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // Permissions List items
              _buildPermissionRow(
                icon: Icons.videocam_rounded,
                title: 'Camera',
                subtitle: 'For video sharing',
                isGranted: _cameraGranted,
              ),
              const SizedBox(height: 8),
              _buildPermissionRow(
                icon: Icons.mic_rounded,
                title: 'Microphone',
                subtitle: 'For speaking in the lounge',
                isGranted: _micGranted,
              ),

              const SizedBox(height: 24),

              // Primary Grant / Settings Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed:
                    _requestInProgress ? null : _handlePermissionAction,
                child: _requestInProgress
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _needsSettings
                                ? Icons.settings_rounded
                                : Icons.lock_open_rounded,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _needsSettings
                                ? 'Open Settings to Allow'
                                : 'Grant Permissions',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 8),

              // Secondary Join Button
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: _proceedIntoMeeting,
                child: const Text(
                  'Join without camera & mic',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isGranted
                ? const Color(0xFF22C55E)
                : const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isGranted ? 'Allowed' : 'Not Allowed',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isGranted
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
