import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/care_session.dart';
import '../providers/auth_provider.dart';
import '../services/care_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  final CareService _careService = CareService();

  bool _loading = true;
  String? _error;
  List<CareSession> _sessions = [];
  String _selectedAudience = 'ANY';

  final List<String> _audiences = ['ANY', 'STUDENTS', 'ALUMNI', 'TEACHERS'];

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessions = await _careService.getSessions(audience: _selectedAudience);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleConsent(CareSession session) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to mark interest in CARE sessions')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    try {
      final newConsented = await _careService.toggleConsent(session.id, session.consented);
      setState(() {
        final index = _sessions.indexWhere((s) => s.id == session.id);
        if (index != -1) {
          final countDelta = newConsented ? 1 : -1;
          _sessions[index] = _sessions[index].copyWith(
            consented: newConsented,
            consentCount: (_sessions[index].consentCount + countDelta).clamp(0, 99999),
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newConsented
                  ? 'Thanks for showing interest! We will notify you when a date is set.'
                  : 'Interest removed.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update interest: $e')),
        );
      }
    }
  }

  void _showRequestSessionDialog() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to request a CARE session')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    final titleController = TextEditingController();
    final noteController = TextEditingController();
    List<String> targetAudiences = ['STUDENTS', 'ALUMNI'];
    bool wantsToLearn = true;
    bool canLead = false;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Request a CARE Session',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Text(
                      'An admin reviews this topic before it appears for other members.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g. UPSC Preparation, Machine Learning, Starting a Business',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Note / Topic Details *',
                        hintText: 'Explain what will be covered and what questions you want answered...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Who it is for',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['STUDENTS', 'ALUMNI', 'TEACHERS', 'ALL'].map((aud) {
                        final isSelected = targetAudiences.contains(aud);
                        return FilterChip(
                          label: Text(aud[0] + aud.substring(1).toLowerCase()),
                          selected: isSelected,
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                targetAudiences.add(aud);
                              } else {
                                targetAudiences.remove(aud);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'This request is:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: wantsToLearn,
                      title: const Text('I want to learn this'),
                      onChanged: (val) => setModalState(() => wantsToLearn = val ?? true),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: canLead,
                      title: const Text('I can lead or help conduct this session'),
                      onChanged: (val) => setModalState(() => canLead = val ?? false),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (titleController.text.trim().isEmpty || noteController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill in title and note')),
                                );
                                return;
                              }

                              setModalState(() => submitting = true);
                              try {
                                await _careService.requestSession(
                                  title: titleController.text.trim(),
                                  note: noteController.text.trim(),
                                  audiences: targetAudiences,
                                  wantsToLearn: wantsToLearn,
                                  canLead: canLead,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchSessions();
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text('CARE session requested! Admin will review shortly.'),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => submitting = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(content: Text('Request failed: $e')),
                                );
                              }
                            },
                      child: submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Submit Request'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Navodayan CARE'),
        actions: const [
          CommonAppBarActions(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestSessionDialog,
        backgroundColor: colors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Request Session', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSessions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero banner card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: colors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CAREERS AND REAL EXPERIENCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Navodayan CARE',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Alumni-led knowledge sessions through the year on competitive exams, career transitions, and practical skills. Request a topic, mark interest, and attend when scheduled.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // How it works card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.border),
                ),
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How a CARE session works',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildStepRow('1', 'A member requests a topic.', colors),
                      _buildStepRow('2', 'An admin reviews it. After approval, it opens for interest.', colors),
                      _buildStepRow('3', 'Members mark that they want to attend.', colors),
                      _buildStepRow('4', 'Date, time and session coordinator are set.', colors),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Audience filter tabs
              Row(
                children: [
                  Text(
                    'Target Audience: ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _audiences.map((aud) {
                          final selected = _selectedAudience == aud;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                aud == 'ANY' ? 'Any' : aud[0] + aud.substring(1).toLowerCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected ? Colors.white : colors.textPrimary,
                                ),
                              ),
                              selected: selected,
                              selectedColor: colors.primary,
                              onSelected: (_) {
                                setState(() => _selectedAudience = aud);
                                _fetchSessions();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(_error!, style: TextStyle(color: colors.error)),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _fetchSessions, child: const Text('Retry')),
                    ],
                  ),
                )
              else if (_sessions.isEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colors.border),
                  ),
                  color: colors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.school_outlined, size: 48, color: colors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'No CARE sessions for this audience yet.',
                          style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Request a new topic and an admin will review it.',
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _showRequestSessionDialog,
                          child: const Text('Request Topic'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sessions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return _buildSessionCard(session, colors);
                  },
                ),
              const SizedBox(height: 80), // spacing for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text, ThemePalette colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(CareSession session, ThemePalette colors) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (session.status == 'OPEN')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.successBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Open for interest',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.success),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (session.note != null && session.note!.isNotEmpty) ...[
              Text(
                session.note!,
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
            ],

            // Audiences badges
            if (session.audiences.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: session.audiences.map((aud) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      aud[0] + aud.substring(1).toLowerCase(),
                      style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            const Divider(),
            const SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.people_outline_rounded, size: 16, color: colors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${session.consentCount} alumni interested',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _toggleConsent(session),
                  icon: Icon(
                    session.consented ? Icons.check_circle_rounded : Icons.star_border_rounded,
                    size: 16,
                  ),
                  label: Text(session.consented ? 'Interested' : 'I want to attend'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: session.consented ? colors.success : colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

