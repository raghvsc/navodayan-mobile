import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_item.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/events_service.dart';
import '../theme/app_theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventsService _eventsService = EventsService();
  final _searchController = TextEditingController();

  List<EventItem> _events = [];
  bool _loading = true;
  String? _rsvpingId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final events = await _eventsService.getEvents(token: token);
      if (mounted) {
        setState(() {
          _events = events;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleRsvp(String eventId) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to RSVP to events')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _rsvpingId = eventId);

    try {
      await _eventsService.rsvpEvent(
        eventId: eventId,
        token: auth.token!,
      );
      if (mounted) {
        final targetEvent = _events.where((e) => e.id == eventId).firstOrNull;
        if (targetEvent != null) {
          context.read<NotificationProvider>().scheduleEventReminder(
            eventId: targetEvent.id,
            eventTitle: targetEvent.title,
            eventDate: targetEvent.eventDate ?? DateTime.now().add(const Duration(days: 1)),
            location: targetEvent.location,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RSVP successful! Reminder scheduled.')),
        );
        _fetchEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _rsvpingId = null);
      }
    }
  }

  void _showHostEventDialog() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to host an event')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _HostEventDialog(
        onEventCreated: () {
          _fetchEvents();
        },
      ),
    );
  }

  List<EventItem> get _filteredEvents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _events;
    return _events.where((e) {
      return e.title.toLowerCase().contains(query) ||
          e.description.toLowerCase().contains(query) ||
          e.location.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredEvents;
    final featured = filtered.isNotEmpty ? filtered.first : null;
    final otherEvents = filtered.length > 1 ? filtered.sublist(1) : <EventItem>[];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Navodayan Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchEvents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showHostEventDialog,
        backgroundColor: colors.primary,
        icon: Icon(Icons.add_rounded, color: isDark ? const Color(0xFF0B1120) : Colors.white),
        label: Text(
          'Host Event',
          style: TextStyle(
            color: isDark ? const Color(0xFF0B1120) : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchEvents,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Header
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search events by name or location...',
                    hintStyle: TextStyle(color: colors.textSecondary),
                    prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: colors.textSecondary),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: colors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchEvents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event_busy_rounded,
                            size: 48,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Events Scheduled',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to organize a meetup or reunion for the Navodayan community!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showHostEventDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Host an Event'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Featured Event Card
                if (featured != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'FEATURED EVENT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildFeaturedEventCard(featured),
                  const SizedBox(height: 24),
                ],

                // Other events
                if (otherEvents.isNotEmpty) ...[
                  Text(
                    'All Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: otherEvents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) => _buildEventCard(otherEvents[i]),
                  ),
                ],
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedEventCard(EventItem event) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (event.image != null && event.image!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(
                event.image!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholderImage(),
              ),
            )
          else
            _buildPlaceholderImage(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'UPCOMING',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${event.rsvpCount} Attending',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      event.eventDate != null
                          ? '${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year}'
                          : 'Date TBA',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on_outlined, size: 16, color: colors.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _rsvpingId == event.id ? null : () => _handleRsvp(event.id),
                  child: _rsvpingId == event.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('RSVP Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventItem event) {
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            event.eventDate != null
                                ? '${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year}'
                                : 'Date TBA',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on_outlined, size: 14, color: colors.secondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                event.description,
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${event.rsvpCount} Attending',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.bold),
                ),
                OutlinedButton(
                  onPressed: _rsvpingId == event.id ? null : () => _handleRsvp(event.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: _rsvpingId == event.id
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('RSVP'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    final colors = AppColors.of(context);

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Center(
        child: Icon(Icons.celebration_rounded, size: 48, color: colors.primary),
      ),
    );
  }
}

class _HostEventDialog extends StatefulWidget {
  final VoidCallback onEventCreated;

  const _HostEventDialog({required this.onEventCreated});

  @override
  State<_HostEventDialog> createState() => _HostEventDialogState();
}

class _HostEventDialogState extends State<_HostEventDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final EventsService _eventsService = EventsService();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleCreateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final token = context.read<AuthProvider>().token!;
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await _eventsService.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: eventDateTime.toIso8601String(),
        location: _locationController.text.trim(),
        image: _imageController.text.trim().isNotEmpty ? _imageController.text.trim() : null,
        token: token,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onEventCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Host an Event',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    hintText: 'Ex. Batch 2015 Reunion',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'City, venue, or online link',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a location' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: "What's this event about?",
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(
                    labelText: 'Cover Image URL (Optional)',
                    hintText: 'https://images.unsplash.com/...',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _handleCreateEvent,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Event'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
