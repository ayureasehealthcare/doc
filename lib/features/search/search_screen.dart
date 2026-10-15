import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:doctro/widgets/osler_tag.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/features/search/models/search_result.dart';
import 'package:doctro/features/search/search_filter.dart';

/// The kit's global "Search Screen": a category-filterable search over the
/// app's own real destinations (the doctor's own profile, consultation and
/// appointment history, notifications, settings), each result opening the
/// actual screen on tap - rather than a single-purpose in-page search box.
class SearchScreen extends StatefulWidget {
  /// Overridable for tests; defaults to the app's own feature index.
  final List<SearchResult> results;

  const SearchScreen({super.key, this.results = _defaultIndex});

  static const _defaultIndex = <SearchResult>[
    SearchResult(
      title: 'My Profile',
      subtitle: 'View and edit your professional profile',
      category: SearchResultCategory.doctor,
      matchPercent: 92,
      routeName: 'profile',
    ),
    SearchResult(
      title: 'Consultation History',
      subtitle: 'Review past video consultations',
      category: SearchResultCategory.consultation,
      matchPercent: 78,
      routeName: 'VideoCallHistory',
    ),
    SearchResult(
      title: 'Appointment History',
      subtitle: 'Browse your past appointments',
      category: SearchResultCategory.consultation,
      matchPercent: 68,
      routeName: 'AppointmentHistoryScreen',
    ),
    SearchResult(
      title: 'Notifications',
      subtitle: 'Stay updated on appointment activity',
      category: SearchResultCategory.resources,
      matchPercent: 60,
      routeName: 'notifications',
    ),
    SearchResult(
      title: 'Settings',
      subtitle: 'Language, password and app preferences',
      category: SearchResultCategory.resources,
      matchPercent: 50,
      routeName: 'Settings',
    ),
  ];

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  SearchResultCategory? _category;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results =
        filterSearchResults(widget.results, query: _query, category: _category);

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                  AyurezeTheme.spaceXl,
                  AyurezeTheme.spaceLg,
                  AyurezeTheme.spaceXl,
                  AyurezeTheme.spaceXl),
              decoration:
                  const BoxDecoration(color: AyurezeTheme.healingGreen50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: Navigator.of(context).canPop()
                            ? () => Navigator.of(context).pop()
                            : null,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Search',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AyurezeTheme.spaceSm),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: (value) => setState(() => _query = value),
                    style: const TextStyle(color: AyurezeTheme.forestDeep),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                          color: AyurezeTheme.forestDeep.withValues(
                        alpha: 0.6,
                      )),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AyurezeTheme.spaceLg, vertical: 14),
                      prefixIcon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        color: AyurezeTheme.healingGreen100,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AyurezeTheme.radiusPill),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AyurezeTheme.spaceLg),
                  _CategoryChips(
                    selected: _category,
                    onSelected: (category) =>
                        setState(() => _category = category),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? _EmptyState(query: _query)
                  : ListView.separated(
                      padding: const EdgeInsets.all(AyurezeTheme.spaceXl),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AyurezeTheme.spaceSm),
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return ScreenEntrance(
                          index: index,
                          child: _ResultTile(result: result),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final SearchResultCategory? selected;
  final ValueChanged<SearchResultCategory?> onSelected;

  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in SearchResultCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: AyurezeTheme.spaceSm),
              child: GestureDetector(
                onTap: () => onSelected(selected == category ? null : category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AyurezeTheme.spaceLg, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == category
                        ? AyurezeTheme.healingGreen100
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(AyurezeTheme.radiusPill),
                  ),
                  child: Text(
                    _label(category),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected == category
                              ? Colors.white
                              : AyurezeTheme.healingGreen100,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _label(SearchResultCategory category) {
    switch (category) {
      case SearchResultCategory.resources:
        return 'Resources';
      case SearchResultCategory.medication:
        return 'Medication';
      case SearchResultCategory.doctor:
        return 'Doctor';
      case SearchResultCategory.consultation:
        return 'Consultation';
    }
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResult result;

  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
      onTap: result.routeName == null
          ? null
          : () => Navigator.of(context).pushNamed(result.routeName!),
      child: Container(
        padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
        decoration: BoxDecoration(
          color: AyurezeTheme.surface,
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
          border: Border.all(color: AyurezeTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AyurezeTheme.healingGreen10,
                borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
              ),
              child: HugeIcon(
                icon: _iconFor(result.category),
                color: AyurezeTheme.healingGreen100,
                size: 22,
              ),
            ),
            const SizedBox(width: AyurezeTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    result.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AyurezeTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AyurezeTheme.spaceSm),
            OslerTag(
              label: '${result.matchPercent}% Match',
              style: result.matchPercent >= 70
                  ? OslerTagStyle.success
                  : OslerTagStyle.secondary,
            ),
          ],
        ),
      ),
    );
  }

  List<List<dynamic>> _iconFor(SearchResultCategory category) {
    switch (category) {
      case SearchResultCategory.resources:
        return HugeIcons.strokeRoundedFolderLibrary;
      case SearchResultCategory.medication:
        return HugeIcons.strokeRoundedPill;
      case SearchResultCategory.doctor:
        return HugeIcons.strokeRoundedDoctor01;
      case SearchResultCategory.consultation:
        return HugeIcons.strokeRoundedStethoscope02;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return OslerStateView(
      icon: HugeIcons.strokeRoundedSearchRemove,
      tone: OslerStateTone.muted,
      title: query.isEmpty ? 'Start Searching' : 'Woops, Not Found',
      message: query.isEmpty
          ? 'Search your profile, appointments, notifications and settings.'
          : 'Unfortunately, the key you entered cannot be found. '
              'Please try another keyword or check again.',
    );
  }
}
