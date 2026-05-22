// lib/shared/widgets/edit_profile_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/user_model.dart';
import 'package:aplikasi_keuangan/core/constants/app_constants.dart';

class EditProfileSheet {
  static void show(BuildContext context, UserModel userToEdit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EditProfileContent(user: userToEdit),
    );
  }
}

class _EditProfileContent extends StatefulWidget {
  final UserModel user;
  const _EditProfileContent({required this.user});

  @override
  State<_EditProfileContent> createState() => _EditProfileContentState();
}

class _EditProfileContentState extends State<_EditProfileContent> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showComingSoonSnackBar() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.build_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Fitur ini sedang dalam tahap pengembangan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _confirmDelete(FinanceProvider finance) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: finance.themeBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
        title: Text("Hapus Akun?", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold)),
        content: Text("Semua data transaksi di akun ini akan musnah permanen. Yakin?", style: TextStyle(color: finance.themeTextSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: Text("Batal", style: TextStyle(color: finance.themeTextSub))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              finance.deleteUser(widget.user.id);
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close sheet
            },
            child: const Text("Ya, Hapus"),
          )
        ],
      ),
    );
  }

  void _showEmojiPicker(FinanceProvider finance) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: finance.themeCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: finance.themeBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text("Pilih Avatar Emoji", style: TextStyle(color: finance.themeText, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: AvatarConstants.emojis.length,
                  itemBuilder: (context, index) {
                    final emoji = AvatarConstants.emojis[index];
                    final isSelected = widget.user.avatar == emoji;
                    
                    return _EmojiItem(
                      emoji: emoji,
                      isSelected: isSelected,
                      finance: finance,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        finance.editUser(widget.user.id, newAvatar: emoji);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return Scaffold(
      backgroundColor: finance.themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: finance.themeText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile", 
          style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Card Profil
            Container(
              decoration: BoxDecoration(
                color: finance.themeCard,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: finance.themeBorder),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Foto Profil (Emoji)
                  GestureDetector(
                    onTap: () => _showEmojiPicker(finance),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: finance.themeAccent.withValues(alpha: 0.1),
                          child: Text(widget.user.avatar, style: const TextStyle(fontSize: 48)),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: finance.themeAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: finance.themeCard, width: 3),
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Field Nama
                  Material(
                    color: Colors.transparent,
                    child: TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: finance.themeText, fontWeight: FontWeight.w900, fontSize: 18),
                      cursorColor: finance.themeAccent,
                      onTap: () => HapticFeedback.lightImpact(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: finance.themeCard,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeAccent, width: 2.0)),
                        hintText: "Nama Akun",
                        hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha: 0.5)),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.edit_rounded, color: finance.themeAccent, size: 24),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty) {
                           finance.editUser(widget.user.id, newName: val.trim());
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Shared ID (Read-only)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: finance.themeBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: finance.themeBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined, color: finance.themeTextSub),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Shared ID", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                "ID-${widget.user.id}", 
                                style: TextStyle(color: finance.themeText, fontFamily: 'monospace', fontWeight: FontWeight.w900, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _showComingSoonSnackBar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.copy_rounded, color: finance.themeAccent, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Member Since
                  Text("Member since: ${DateTime.now().year}", style: TextStyle(color: finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: TextButton.icon(
            onPressed: () => _confirmDelete(finance),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            label: const Text("Delete Account", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _EmojiItem extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final FinanceProvider finance;
  final VoidCallback onTap;

  const _EmojiItem({
    required this.emoji,
    required this.isSelected,
    required this.finance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        splashColor: finance.themeAccent.withValues(alpha: 0.3),
        highlightColor: finance.themeAccent.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? finance.themeAccent.withValues(alpha: 0.2) : finance.themeCard,
            shape: BoxShape.circle,
            border: Border.all(color: isSelected ? finance.themeAccent : finance.themeBorder, width: isSelected ? 2.0 : 1.0),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
      ),
    );
  }
}
