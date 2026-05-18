// lib/shared/widgets/account_manager_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/user_model.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';

class AccountManagerSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _AccountContent(),
    );
  }
}

class _AccountContent extends StatefulWidget {
  const _AccountContent();

  @override
  State<_AccountContent> createState() => _AccountContentState();
}

class _AccountContentState extends State<_AccountContent> {
  bool _isCreating = false;
  String _newName = '';
  String? _editingId;
  String _editName = '';

  UserModel? _userToDelete;
  int _deleteStep = 0; // 0: Normal, 1: Peringatan, 2: Final

  void _handleCreate(FinanceProvider finance) {
    if (_newName.trim().isNotEmpty) {
      HapticFeedback.mediumImpact();
      finance.registerUser(UserModel(
        id: 'u_${DateTime.now().millisecondsSinceEpoch}', 
        name: _newName.trim()
      )); 
      Navigator.pop(context);
    }
  }

  void _resetDelete() {
    setState(() {
      _userToDelete = null;
      _deleteStep = 0;
    });
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: finance.themeBg, // 🟢 Pakai Tema
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: finance.themeBorder), // 🟢 Pakai Tema
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 24, left: 16, right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Atas
          Container(width: 40, height: 4, decoration: BoxDecoration(color: finance.themeBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),

          // --- LOGIKA DELETE 2 LAPIS ---
          if (_userToDelete != null && _deleteStep == 1)
            _buildDeleteWarning1(finance)
          else if (_userToDelete != null && _deleteStep == 2)
            _buildDeleteWarning2(finance)
          else if (!_isCreating)
            _buildUserList(finance)
          else
            _buildCreateForm(finance),
        ],
      ),
    );
  }

  Widget _buildDeleteWarning1(FinanceProvider finance) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.amber.withValues(alpha:0.1), shape: BoxShape.circle),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 32),
        ),
        const SizedBox(height: 16),
        Text("Hapus Akun?", style: TextStyle(color: finance.themeText, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Kamu yakin mau hapus akun '${_userToDelete!.name}'?", style: TextStyle(color: finance.themeTextSub, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: CustomButton(text: "Batal", variant: ButtonVariant.secondary, onPressed: _resetDelete)),
            const SizedBox(width: 12),
            Expanded(child: CustomButton(text: "Lanjut", variant: ButtonVariant.danger, onPressed: () { HapticFeedback.heavyImpact(); setState(() => _deleteStep = 2); })),
          ],
        ),
      ],
    );
  }

  Widget _buildDeleteWarning2(FinanceProvider finance) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha:0.1), shape: BoxShape.circle),
          child: const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 40),
        ),
        const SizedBox(height: 16),
        const Text("BAHAYA, JAR!", style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Semua data transaksi di '${_userToDelete!.name}' bakal musnah permanen.", style: TextStyle(color: finance.themeTextSub, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        CustomButton(
          text: "YA, HAPUS PERMANEN!",
          variant: ButtonVariant.danger,
          fullWidth: true,
          onPressed: () {
            HapticFeedback.heavyImpact();
            finance.deleteUser(_userToDelete!.id); 
            Navigator.pop(context);
            _showToast(context, "Akun dan datanya sukses dimusnahkan!");
          },
        ),
        TextButton(onPressed: _resetDelete, child: Text("Gak jadi deh", style: TextStyle(color: finance.themeTextSub))),
      ],
    );
  }

  Widget _buildUserList(FinanceProvider finance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text("PILIH PROFIL", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
        ...finance.users.map((user) {
          final isActive = finance.currentUser?.id == user.id;
          final isEditing = _editingId == user.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isActive ? finance.themeAccent.withValues(alpha:0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isActive ? finance.themeAccent.withValues(alpha:0.3) : Colors.transparent),
            ),
            child: isEditing
                ? _buildEditField(user, finance)
                : ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: CircleAvatar(
                      backgroundColor: isActive ? finance.themeAccent : finance.themeCard,
                      foregroundColor: isActive ? Colors.white : finance.themeTextSub,
                      child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(user.name, style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: isActive ? Text("AKTIF", style: TextStyle(color: finance.themeAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)) : null,
                    onTap: () {
                      if (!isActive) {
                        HapticFeedback.lightImpact();
                        finance.switchUser(user.id); 
                        Navigator.pop(context);
                      }
                    },
                    trailing: finance.users.length > 1 ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_rounded, color: finance.themeTextSub, size: 18),
                          onPressed: () { HapticFeedback.lightImpact(); setState(() { _editingId = user.id; _editName = user.name; }); },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: finance.themeTextSub, size: 18),
                          onPressed: () { HapticFeedback.lightImpact(); setState(() { _userToDelete = user; _deleteStep = 1; }); },
                        ),
                      ],
                    ) : null,
                  ),
          );
        }),
        Divider(color: finance.themeBorder, height: 24),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: finance.themeBorder)), child: Icon(Icons.add_rounded, color: finance.themeTextSub, size: 20)),
          title: Text("AKUN BARU", style: TextStyle(color: finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          onTap: () { HapticFeedback.lightImpact(); setState(() => _isCreating = true); },
        )
      ],
    );
  }

  Widget _buildEditField(UserModel user, FinanceProvider finance) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => _editName = val,
              controller: TextEditingController(text: _editName)..selection = TextSelection.collapsed(offset: _editName.length),
              style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true, 
                fillColor: finance.themeCard, 
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: finance.themeBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: finance.themeBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: finance.themeAccent)),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.check_rounded, color: Colors.greenAccent), onPressed: () {
            if (_editName.trim().isNotEmpty) {
              finance.editUser(user.id, _editName.trim());
            }
            setState(() => _editingId = null);
          }),
          IconButton(icon: Icon(Icons.close_rounded, color: finance.themeTextSub), onPressed: () => setState(() => _editingId = null)),
        ],
      ),
    );
  }

  Widget _buildCreateForm(FinanceProvider finance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("NAMA USER BARU", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => _newName = val,
                style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true, 
                  fillColor: finance.themeCard,
                  hintText: "Contoh: Ahmad", 
                  hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha:0.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeAccent)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _handleCreate(finance),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: finance.themeAccent, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        Center(child: TextButton(onPressed: () => setState(() => _isCreating = false), child: Text("Kembali ke Daftar", style: TextStyle(color: finance.themeTextSub)))),
      ],
    );
  }
}