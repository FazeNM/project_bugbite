import 'package:flutter/material.dart';

import '../models/bite_guide.dart';
import '../models/community_post.dart';

const guides = <BiteGuide>[
  BiteGuide(
    id: 'mosquito',
    title: 'Mosquito',
    tagline: 'A possible match for an itchy raised bump.',
    summary:
        'Mosquito reactions are often mild, itchy, and appear on exposed skin.',
    pattern:
        'A small raised bump, often itchy and usually appearing as a single mark.',
    recoverySteps: <String>[
      'Cool the area with a clean cloth for about 10 minutes.',
      'Avoid scratching to reduce skin irritation.',
    ],
    watchFor:
        'Seek medical advice if symptoms worsen or you develop fever, body aches, or a spreading rash.',
    filterTags: <String>{'red', 'itchy', 'raised', 'single'},
    category: 'Outdoors',
    visual: BiteVisual.mosquito,
    icon: Icons.pest_control_rounded,
  ),
  BiteGuide(
    id: 'flea',
    title: 'Flea',
    tagline: 'A possible match for small itchy marks in a cluster.',
    summary:
        'Flea bites can appear as several small itchy marks, commonly around the lower legs or ankles.',
    pattern: 'Small itchy marks that may appear in a loose group or cluster.',
    recoverySteps: <String>[
      'Wash the area gently with soap and water.',
      'Use a cool compress and resist scratching where possible.',
    ],
    watchFor:
        'Get medical advice if the area becomes very painful, hot, increasingly red, or you feel unwell.',
    filterTags: <String>{'red', 'itchy', 'cluster'},
    category: 'At home',
    visual: BiteVisual.flea,
    icon: Icons.bug_report_rounded,
  ),
  BiteGuide(
    id: 'bedbug',
    title: 'Bed bug',
    tagline: 'A possible match for itchy marks in a line or cluster.',
    summary:
        'Bed bug bites can resemble many other skin conditions, so look at patterns and your surroundings too.',
    pattern: 'Itchy red marks that may appear in a line or cluster.',
    recoverySteps: <String>[
      'Use a cool compress for itching and swelling.',
      'Avoid scratching and consider checking bedding if new marks continue.',
    ],
    watchFor:
        'Get medical advice for possible infection, many bites, or symptoms that concern you.',
    filterTags: <String>{'red', 'itchy', 'cluster', 'line'},
    category: 'At home',
    visual: BiteVisual.bedbug,
    icon: Icons.bed_rounded,
  ),
  BiteGuide(
    id: 'spider',
    title: 'Spider or another skin issue',
    tagline: 'A photo alone cannot reliably confirm a spider bite.',
    summary:
        'A single painful mark has many possible causes, including non-bite skin conditions.',
    pattern:
        'A single painful mark, sometimes with a small puncture or blister.',
    recoverySteps: <String>[
      'Clean gently and do not squeeze or cut the area.',
      'Note changes in pain, redness, swelling, and skin colour.',
    ],
    watchFor:
        'Seek urgent advice for worsening pain, blistering, spreading redness, fever, or feeling unwell.',
    filterTags: <String>{'red', 'painful', 'single', 'puncture', 'blister'},
    category: 'Outdoors',
    visual: BiteVisual.spider,
    icon: Icons.pest_control_rounded,
  ),
  BiteGuide(
    id: 'tick',
    title: 'Tick attachment',
    tagline: 'Ticks need prompt, careful removal and symptom monitoring.',
    summary:
        'If a tick is attached, careful removal and watching for later symptoms is important.',
    pattern:
        'A tick may stay attached; afterward there can be a small irritated spot.',
    recoverySteps: <String>[
      'Use fine-tipped tweezers to remove an attached tick as soon as possible.',
      'Clean the area and monitor for a rash, fever, or feeling unwell.',
    ],
    watchFor:
        'Contact a clinician promptly if you develop fever, body aches, or a rash after a tick bite.',
    filterTags: <String>{'red', 'single', 'tick'},
    category: 'Outdoors',
    visual: BiteVisual.tick,
    icon: Icons.location_on_rounded,
  ),
];

final seedPosts = <CommunityPost>[
  CommunityPost(
    id: 'post-flea',
    author: 'Maya R.',
    location: 'Southern California',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    possibleMatch: 'Possible flea bites',
    body:
        'Small itchy bumps around my ankle after looking after a friend’s cat. A cool compress was a relief while I checked in with a clinician.',
    visual: BiteVisual.flea,
    tags: const <String>['Itchy', 'Cluster'],
    likes: 24,
  ),
  CommunityPost(
    id: 'post-mosquito',
    author: 'Jordan P.',
    location: 'Oregon',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    possibleMatch: 'Possible mosquito bite',
    body:
        'I noticed one itchy bump after gardening. Keeping it cool and not scratching helped me stay comfortable.',
    visual: BiteVisual.mosquito,
    tags: const <String>['Outdoors', 'Improving'],
    likes: 18,
  ),
];
