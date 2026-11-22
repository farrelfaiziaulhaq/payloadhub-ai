import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/mahasiswa.dart';
import '../theme/app_theme.dart';
import 'mahasiswa_form_page.dart';

class MahasiswaListPage extends StatefulWidget {
  const MahasiswaListPage({super.key});

  @override
  State<MahasiswaListPage> createState() => _MahasiswaListPageState();
}

class _MahasiswaListPageState extends State<MahasiswaListPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Mahasiswa> _items = const <Mahasiswa>[];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _db.getMahasiswa();
      if (!mounted) return;
      setState(() => _items = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Data tidak dapat dimuat. Coba lagi.');
      _showMessage('Gagal memuat data: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([Mahasiswa? mahasiswa]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MahasiswaFormPage(initial: mahasiswa),
      ),
    );
    if (saved == true && mounted) {
      await _loadData();
      _showMessage(
        mahasiswa == null
            ? 'Data mahasiswa berhasil ditambahkan'
            : 'Data mahasiswa berhasil diperbarui',
      );
    }
  }

  Future<void> _confirmDelete(Mahasiswa mahasiswa) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus data mahasiswa?'),
        content: Text(
          '${mahasiswa.nama} dengan NIM ${mahasiswa.nim} akan dihapus dari '
          'basis data lokal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _db.deleteMahasiswa(mahasiswa.id!);
      await _loadData();
      _showMessage('Data ${mahasiswa.nama} berhasil dihapus');
    } catch (error) {
      _showMessage('Gagal menghapus data: $error');
    }
  }

  List<Mahasiswa> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items
        .where((item) {
          return item.nama.toLowerCase().contains(query) ||
              item.nim.toLowerCase().contains(query) ||
              item.prodi.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  int get _programCount {
    return _items.map((item) => item.prodi.trim().toLowerCase()).toSet().length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(onRefresh: _loadData),
            if (_loading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primary,
                backgroundColor: AppColors.border,
              ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _SummaryCard(
                          total: _items.length,
                          programCount: _programCount,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Cari nama, NIM, atau program studi',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.muted,
                            ),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Hapus pencarian',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.muted,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Text(
                              'Daftar mahasiswa',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            Text(
                              '${filtered.length} data',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_loading && _items.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _LoadingState(),
                      )
                    else if (_error != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ErrorState(onRetry: _loadData),
                      )
                    else if (_items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(onAdd: () => _openForm()),
                      )
                    else if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoResultsState(
                          query: _query,
                          onClear: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final mahasiswa = filtered[index];
                            return _MahasiswaCard(
                              mahasiswa: mahasiswa,
                              onTap: () => _openForm(mahasiswa),
                              onEdit: () => _openForm(mahasiswa),
                              onDelete: () => _confirmDelete(mahasiswa),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah'),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Mahasiswa',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 23),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelola data akademik secara lokal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Muat ulang data',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.programCount});

  final int total;
  final int programCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Stat(
                  label: 'Total mahasiswa',
                  value: '$total',
                  note: 'tersimpan di perangkat',
                ),
              ),
              Container(
                width: 1,
                height: 58,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _Stat(
                  label: 'Program studi',
                  value: '$programCount',
                  note: 'unik',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.note});

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        Text(
          note,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.64),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MahasiswaCard extends StatelessWidget {
  const _MahasiswaCard({
    required this.mahasiswa,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Mahasiswa mahasiswa;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _initials {
    final parts = mahasiswa.nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts[1].characters.first : '';
    return '$first$second'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mahasiswa.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mahasiswa.nim,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mahasiswa.prodi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ubah data ${mahasiswa.nama}',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.primary,
              ),
              IconButton(
                tooltip: 'Hapus data ${mahasiswa.nama}',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: 14),
          Text(
            'Memuat data mahasiswa',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Belum ada data mahasiswa',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan mahasiswa pertama untuk mulai mengelola data di '
            'perangkat ini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah mahasiswa'),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada hasil untuk "$query"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Coba kata kunci lain atau hapus pencarian.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onClear, child: const Text('Hapus pencarian')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          Text(
            'Data tidak dapat dimuat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Periksa penyimpanan perangkat, lalu coba lagi.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
