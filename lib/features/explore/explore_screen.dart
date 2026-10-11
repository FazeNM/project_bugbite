import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'widgets/explore_collection.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'VISUAL LIBRARY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.rose,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Explore bite photos',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 7),
            const Text(
              'Real bites and stings, with more photos to scroll through.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
      TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.muted,
        indicator: BoxDecoration(
          color: AppColors.rose,
          borderRadius: BorderRadius.circular(18),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 15),
        tabs: const <Widget>[
          Tab(text: 'For you'),
          Tab(text: 'Flies'),
          Tab(text: 'Stings'),
          Tab(text: 'Outdoors'),
          Tab(text: 'At home'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: const <Widget>[
            ExploreCollection(
              title: 'Bite photo gallery',
              subtitle:
                  'Compare real skin examples, then open a guide for context.',
              categories: <String>{'Outdoors', 'At home'},
            ),
            ExploreCollection(
              title: 'Biting flies',
              subtitle:
                  'Skin reactions associated with mosquitoes and other biting flies.',
              categories: <String>{'Outdoors'},
              guideIds: <String>{
                'mosquito',
                'biting-midge',
                'black-fly',
                'horse-deer-fly',
                'stable-fly',
              },
            ),
            ExploreCollection(
              title: 'Stinging insects',
              subtitle: 'Reported sting reactions, not pictures of the insect.',
              categories: <String>{'Outdoors'},
              guideIds: <String>{'fire-ant', 'stinging-insect'},
            ),
            ExploreCollection(
              title: 'Outdoor guides',
              subtitle:
                  'Bites, stings, and attachments associated with time outdoors.',
              categories: <String>{'Outdoors'},
            ),
            ExploreCollection(
              title: 'At-home guides',
              subtitle:
                  'Skin examples associated with bedroom, pet, and indoor concerns.',
              categories: <String>{'At home'},
            ),
          ],
        ),
      ),
    ],
  );
}
