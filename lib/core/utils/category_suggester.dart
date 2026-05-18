// lib/core/utils/category_suggester.dart

class CategorySuggester {
  /// ==========================================
  /// 🧠 AI ENGINE SEDERHANA (AUTO-CATEGORY)
  /// ==========================================
  /// File ini bertugas sebagai "Otak" yang membaca teks catatan dari user,
  /// lalu menebak secara otomatis transaksi ini masuk kategori apa.

  static final Map<String, List<String>> _keywordDatabase = {
    'Makanan & Minuman': [
      'makan', 'minum', 'kopi', 'warteg', 'nasi', 'seblak', 'haus', 'bakso', 'mie', 'sate', 
      'gofood', 'grabfood', 'shopeefood', 'rokok', 'jajan', 'ngopi', 'cemilan', 'indomie', 
      'kfc', 'mcd', 'starbucks', 'mixue', 'chatime', 'sarapan', 'dinner', 'lunch', 'lauk', 
      'galon', 'geprek', 'padang', 'martabak', 'dimsum', 'cilok', 'jus', 'boba', 'gorengan', 
      'roti', 'kantin', 'burjo', 'warmindo', 'takjil', 'takoyaki', 'ramen', 'sushi', 'steak', 
      'pizza', 'burger', 'katsu', 'kebab', 'donat', 'eskrim', 'ice cream', 'teh', 'susu', 'ojol'
    ],
    'Transportasi': [
      'bensin', 'parkir', 'ojek', 'gojek', 'grab', 'maxim', 'indrive', 'tol', 'kereta', 
      'krl', 'mrt', 'lrt', 'busway', 'angkot', 'pertamax', 'pertalite', 'shell', 'bengkel', 
      'service', 'servis', 'tambal ban', 'cuci motor', 'cuci mobil', 'travel', 'tiket', 
      'pesawat', 'bus', 'helm', 'oli', 'aki', 'etoll', 'e-toll', 'flazz', 'emoney', 'bluebird'
    ],
    'Kesehatan': [
      'obat', 'dokter', 'apotek', 'rumah sakit', 'klinik', 'vitamin', 'puskesmas', 'sakit', 
      'kontrol', 'checkup', 'periksa', 'masker', 'rs', 'bpjs', 'koyo', 'tolak angin', 
      'kacamata', 'lensa', 'softlens', 'betadine', 'hansaplast', 'gym', 'fitness', 'yoga', 'renang'
    ],
    'Belanja': [
      'indomaret', 'alfamart', 'supermarket', 'shopee', 'tokopedia', 'lazada', 'tiktok shop', 
      'baju', 'sepatu', 'sabun', 'shampoo', 'skincare', 'makeup', 'parfum', 'belanja', 
      'groceries', 'pasar', 'sayur', 'buah', 'kado', 'hadiah', 'kaos', 'celana', 'jaket', 
      'hoodie', 'tas', 'dompet', 'sendal', 'sunblock', 'lotion'
    ],
    'Tagihan': [
      'listrik', 'token', 'air', 'pdam', 'internet', 'wifi', 'pulsa', 'kuota', 'bpjs', 
      'kosan', 'kontrakan', 'cicilan', 'paylater', 'spaylater', 'pinjol', 'kartu kredit', 
      'asuransi', 'pajak', 'stnk', 'indihome', 'biznet', 'first media', 'pbb', 'gas', 'elpiji'
    ],
    'Hiburan': [
      'nonton', 'bioskop', 'game', 'topup', 'netflix', 'spotify', 'langganan', 'main', 
      'jalan', 'healing', 'liburan', 'hotel', 'staycation', 'karaoke', 'billiard', 
      'warnet', 'konser', 'tiket', 'disney', 'youtube', 'ps5', 'steam', 'mabar', 'diamond'
    ],
    'Pendidikan': [
      'ukt', 'spp', 'kuliah', 'sekolah', 'buku', 'alat tulis', 'fotocopy', 'print', 
      'skripsi', 'wisuda', 'kursus', 'les', 'seminar', 'workshop', 'pendaftaran', 'atbm'
    ],
    'Perawatan': [
      'barbershop', 'potong rambut', 'salon', 'facial', 'spa', 'massage', 'pijat', 
      'eyelash', 'waxing', 'skincare', 'creambath', 'manicure', 'pedicure'
    ],
    'Rumah Tangga': [
      'laundry', 'cuci baju', 'cuci sepatu', 'tukang', 'ledeng', 'cat', 'sapu', 'pel', 
      'deterjen', 'art', 'perbaikan', 'perabot', 'mebel'
    ],
    'Donasi / Amal': [
      'sedekah', 'zakat', 'infaq', 'amal', 'sumbangan', 'ngamen', 'pengamen', 'parkir liar',
      'masjid', 'gereja', 'panti', 'kondangan', 'nyumbang', 'melayat', 'tip'
    ],
    'Transfer Temen': [
      'bayar utang', 'bayar hutang', 'patungan', 'split bill', 'pinjem', 'pinjam', 
      'nalangin', 'talangan', 'arisan', 'kas', 'iuran', 'ganti duit', 'transfer balik'
    ]
  };

  /// ⚡ FUNGSI UTAMA PENGECEKAN KATA
  static String? suggestCategory(String keterangan) {
    if (keterangan.trim().isEmpty) return null;
    
    final lowerText = keterangan.toLowerCase();

    for (var entry in _keywordDatabase.entries) {
      String category = entry.key;
      List<String> keywords = entry.value;

      bool isMatch = keywords.any((keyword) {
        // 1. Cek pakai Word Boundary (\b) dulu biar akurat.
        RegExp regex = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
        if (regex.hasMatch(lowerText)) return true;

        // 2. Fallback untuk bahasa Indonesia yang pakai imbuhan.
        if (keyword.length > 4 && lowerText.contains(keyword)) {
          return true;
        }

        return false;
      });

      if (isMatch) return category;
    }

    return null;
  }
}