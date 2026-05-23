import os

def fix_add_wallet_sheet():
    filepath = r'C:\Users\fajar\aplikasi_keuangan\lib\shared\bottom_sheets\add_wallet_sheet.dart'
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Dynamic GridView crossAxisCount
    old_grid = """                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 12, mainAxisSpacing: 12),"""
    
    new_grid = """                          LayoutBuilder(builder: (context, constraints) {
                            int cols = (constraints.maxWidth / 80).floor();
                            if (cols < 3) cols = 3;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, childAspectRatio: 0.85, crossAxisSpacing: 12, mainAxisSpacing: 12),"""
    
    content = content.replace(old_grid, new_grid)
    
    # close layoutbuilder
    old_grid_close = """                            },
                          ),"""
    new_grid_close = """                              },
                            );
                          }),"""
    content = content.replace(old_grid_close, new_grid_close)
    
    # 2. Keyboard-aware bottom padding for the template sheet
    old_sheet = """          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,"""
              
    new_sheet = """          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,"""
                
    content = content.replace(old_sheet, new_sheet)
    
    # close padding
    old_sheet_close = """              ),
            );
          }
        );"""
    new_sheet_close = """              ),
              ),
            );
          }
        );"""
    content = content.replace(old_sheet_close, new_sheet_close)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed add_wallet_sheet.dart")

if __name__ == '__main__':
    fix_add_wallet_sheet()
