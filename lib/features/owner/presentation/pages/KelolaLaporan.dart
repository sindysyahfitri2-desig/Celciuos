
import 'package:flutter/material.dart';

class KelolaLaporanContent extends StatefulWidget {
  const KelolaLaporanContent({
    super.key,
    this.onDownload,
  });

  final VoidCallback? onDownload;

  @override
  State<KelolaLaporanContent> createState() =>
      _KelolaLaporanContentState();
}

class _KelolaLaporanContentState
    extends State<KelolaLaporanContent> {
  final TextEditingController _searchController =
      TextEditingController();

  final String _judulLaporan = 'Laporan Keuangan';
  final String _tanggalLaporan = '30 Oktober 2026';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isMatch {
    final keyword = _searchController.text.toLowerCase();

    return _judulLaporan.toLowerCase().contains(keyword) ||
        _tanggalLaporan.toLowerCase().contains(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFDCE9F4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 32,
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                isMobile
                    ? Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 20),
                          _buildSearchField(),
                        ],
                      )
                    : Row(
                        children: [
                          _buildTitle(),
                          const Spacer(),
                          SizedBox(
                            width: 230,
                            child: _buildSearchField(),
                          ),
                        ],
                      ),

                const SizedBox(height: 65),

                // KARTU LAPORAN
                if (_isMatch)
                  Align(
                    alignment: Alignment.topLeft,
                    child: _buildReportCard(
                      isMobile: isMobile,
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'Laporan tidak ditemukan',
                      style: TextStyle(
                        color: Color(0xFF102B40),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // JUDUL HALAMAN
  Widget _buildTitle() {
    return const Text(
      'Kelola Laporan',
      style: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        color: Color(0xFF082640),
        letterSpacing: 0.2,
        shadows: [
          Shadow(
            color: Color(0x40000000),
            offset: Offset(2, 3),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }

  // KOLOM PENCARIAN
  Widget _buildSearchField() {
    return Container(
      height: 37,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF102B40),
        ),
        decoration: const InputDecoration(
          hintText: 'Cari',
          hintStyle: TextStyle(
            fontSize: 12,
            color: Color(0xFF9AA9B7),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 17,
            color: Color(0xFF7891A5),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 9,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // KARTU LAPORAN EXCEL
  Widget _buildReportCard({
    required bool isMobile,
  }) {
    return Container(
      width: isMobile ? double.infinity : 300,
      constraints: const BoxConstraints(
        minHeight: 100,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF082640),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // IKON EXCEL
          Container(
            width: 51,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Center(
              child: Icon(
                Icons.grid_on_rounded,
                size: 39,
                color: Color(0xFF239653),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // INFORMASI LAPORAN
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Laporan Keuangan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  '30 Oktober 2026',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // TOMBOL UNDUH
                SizedBox(
                  height: 25,
                  child: ElevatedButton.icon(
                    onPressed: widget.onDownload ??
                        () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Hubungkan tombol ini dengan fungsi export Excel.',
                              ),
                            ),
                          );
                        },
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 13,
                    ),
                    label: const Text(
                      'Unduh Laporan',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          const Color(0xFF082640),
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
