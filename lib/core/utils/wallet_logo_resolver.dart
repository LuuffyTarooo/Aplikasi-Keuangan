// lib/core/utils/wallet_logo_resolver.dart

class WalletLogoResolver {
  static const List<String> popularWallets = [
    'BCA', 'Mandiri', 'BRI', 'BNI', 'BTN', 'CIMB', 'Danamon', 'Permata', 'OCBC', 'Maybank',
    'Jago', 'blu', 'SeaBank', 'Neo', 'Allo', 'Saqu',
    'GoPay', 'OVO', 'DANA', 'ShopeePay', 'LinkAja', 'Tunai'
  ];

  static const Map<String, String> _logoMappings = {
    'blu': 'blu_by_bca.svg',
    'e-money': 'mandiri_e_money.svg',
    'emoney': 'mandiri_e_money.svg',
    'livin': 'livin_by_mandiri.svg',
    'mandiri': 'mandiri.svg',
    'dki': 'bank_dki.svg',
    'i.saku': 'i_saku.svg',
    'isaku': 'i_saku.svg',
    'saku': 'i_saku.svg',
    'jenius': 'jenius.svg',
    'ocbc': 'ocbc_bank.svg',
    'maybank': 'maybank.svg',
    'allo': 'allobank.svg',
    'super': 'superbank.svg',
    'sea': 'seabank.svg',
    'permata': 'permata_bank.svg',
    'cimb': 'cimb_niaga.svg',
    'niaga': 'cimb_niaga.svg',
    'saqu': 'bank_saqu.svg',
    'danamon': 'bank_danamon.svg',
    'bsi': 'bsi.svg',
    'syariah': 'bsi.svg',
    'btn': 'btn.svg',
    'doku': 'doku.svg',
    'link aja': 'linkaja.svg',
    'linkaja': 'linkaja.svg',
    'ovo': 'ovo.svg',
    'bni': 'bni.svg',
    'dana': 'dana.svg',
    'jago': 'bank_jago.svg',
    'shopee': 'shopeepay.svg',
    'spay': 'shopeepay.svg',
    'bca': 'bca.svg',
    'neo': 'neobank.svg',
    'gopay': 'gopay.svg',
  };

  // Cache to store resolved logo paths for O(1) lookups on subsequent builds
  static final Map<String, String?> _resolvedCache = {};

  static String _normalize(String name) {
    return name.trim().toLowerCase();
  }

  static String? resolveLogoPath(String? walletName) {
    if (walletName == null || walletName.isEmpty) return null;
    
    final normalized = _normalize(walletName);
    
    // Check cache first
    if (_resolvedCache.containsKey(normalized)) {
      return _resolvedCache[normalized];
    }
    
    // 1. Exact alias lookup
    if (_logoMappings.containsKey(normalized)) {
      final path = _logoMappings[normalized];
      _resolvedCache[normalized] = path;
      return path;
    }
    
    // 2. Exact word match (e.g. 'Bank Mandiri' contains 'mandiri' as a word)
    final words = normalized.split(RegExp(r'\s+'));
    for (final word in words) {
      if (_logoMappings.containsKey(word)) {
        final path = _logoMappings[word];
        _resolvedCache[normalized] = path;
        return path;
      }
    }
    
    // 3. Fallback to fuzzy matching if exact word doesn't match
    String? svgFile;
    for (final entry in _logoMappings.entries) {
      if (normalized.contains(entry.key)) {
        svgFile = entry.value;
        break;
      }
    }
    
    _resolvedCache[normalized] = svgFile;
    return svgFile;
  }

  static bool hasLogo(String? walletName) {
    if (walletName == null || walletName.isEmpty) return false;
    final normalized = _normalize(walletName);
    
    if (normalized.contains('tunai') || normalized.contains('cash') || normalized.contains('bri') || normalized.contains('rakyat')) return true;
    
    return resolveLogoPath(walletName) != null;
  }
}
