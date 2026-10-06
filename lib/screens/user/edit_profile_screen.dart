// ============================================================
// lib/screens/user/edit_profile_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name    = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current values
    _name.text    = widget.user.fullName;
    _contact.text = widget.user.contactNumber;
    _address.text = widget.user.fullAddress;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final res = await ApiService.updateProfile(
        userId: widget.user.id,
        fullName: _name.text.trim(),
        contactNumber: _contact.text.trim(),
        fullAddress: _address.text.trim(),
      );

      if (!mounted) return;

      if (res['success'] == true) {
        // Rebuild the UserModel from the server's response
        final updated = UserModel.fromJson(
          Map<String, dynamic>.from(res['user']),
        );

        // Persist locally so it's used everywhere
        await Session.saveUser(updated);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.green700,
          ),
        );
        Navigator.pop(context, updated); // return the new user
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Update failed'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot reach server.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        automaticallyImplyLeading: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.primary),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.soft),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 80,
            20,
            24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Avatar hero ───
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.lg,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '@${widget.user.username}',
                    style: AppText.muted,
                  ),
                ),
                const SizedBox(height: 32),

                // ─── Form card ───
                SoftCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Personal Information'),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Juan Dela Cruz',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Enter full name'
                                : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _contact,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          hintText: '09171234567',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter contact number';
                          }
                          if (v.trim().length < 10) {
                            return 'Invalid contact number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _address,
                        maxLines: 3,
                        textCapitalization:
                            TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Full Address',
                          hintText:
                              'Purok 1, Brgy. Example, Bacolod City',
                          prefixIcon: Icon(Icons.home_outlined),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Enter address'
                                : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Save button ───
                PillButton(
                  label: _saving ? 'SAVING…' : 'SAVE CHANGES',
                  icon: Icons.check_circle_outline,
                  onPressed: _saving ? null : _save,
                  isLoading: _saving,
                  gradient: AppGradients.primary,
                ),
                const SizedBox(height: 12),

                // ─── Cancel ───
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}