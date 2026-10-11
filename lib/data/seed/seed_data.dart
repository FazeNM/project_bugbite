import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import '../models/bite_guide.dart';
import '../models/community_post.dart';
import 'context_media.dart';
import 'additional_bite_photos.dart';

const guides = <BiteGuide>[
  BiteGuide(
    id: 'mosquito',
    title: 'Mosquito',
    tagline: 'May resemble an itchy, raised bump on exposed skin.',
    summary:
        'Mosquito reactions are often mild and itchy, but appearance alone cannot confirm the cause.',
    pattern:
        'A small raised bump that often itches and may appear as one mark or several nearby marks.',
    recoverySteps: <String>[
      'Wash the area gently and use a wrapped cool pack for about 10 minutes.',
      'Avoid scratching to reduce irritation and the chance of infection.',
    ],
    watchFor:
        'Seek medical advice if symptoms worsen or you develop fever, body aches, or a spreading rash.',
    filterTags: <String>{'red', 'itchy', 'raised', 'single'},
    category: 'Outdoors',
    kind: GuideKind.bite,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.mosquito,
        caption: 'Mosquito example',
        semanticLabel: 'Close-up photograph of a mosquito',
      ),
      GuideMedia(
        asset: AppAssets.mosquitoBite,
        kind: GuideMediaKind.skin,
        caption: 'Bite example · Mosquito reaction on a forearm (CDC)',
        semanticLabel:
            'Reddening and swelling around a documented mosquito bite on a forearm',
        fit: BoxFit.contain,
      ),
      ...AdditionalBitePhotos.mosquito,
      GuideMedia(
        asset: AppAssets.asianTigerMosquito,
        caption: 'Asian tiger mosquito feeding on skin',
        semanticLabel:
            'A female Aedes albopictus mosquito feeding on a human host',
      ),
      ContextMedia.mosquitoWater,
      ContextMedia.cleanHands,
    ],
    icon: Icons.pest_control_rounded,
    isFeatured: true,
  ),
  BiteGuide(
    id: 'flea',
    title: 'Flea',
    tagline: 'May resemble small, itchy marks around ankles or legs.',
    summary:
        'Flea bites can appear as several small itchy marks, often around lower legs or ankles.',
    pattern: 'Small itchy marks that may appear in a loose group or cluster.',
    recoverySteps: <String>[
      'Wash the area gently with soap and water.',
      'Use a cool compress and resist scratching where possible.',
    ],
    watchFor:
        'Get medical advice if the area becomes very painful, hot, increasingly swollen, or you feel unwell.',
    filterTags: <String>{'red', 'itchy', 'cluster', 'lower-leg'},
    category: 'At home',
    kind: GuideKind.bite,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.flea,
        caption: 'Flea example',
        semanticLabel: 'Magnified photograph of a flea',
      ),
      GuideMedia(
        asset: AppAssets.fleaBites,
        kind: GuideMediaKind.skin,
        caption: 'Bite example · Flea-associated marks on lower legs (CDC)',
        semanticLabel:
            'Clinical photograph of lower legs with marks attributed to cat flea bites',
        fit: BoxFit.contain,
      ),
      ContextMedia.petCheck,
      ContextMedia.cleanHands,
    ],
    icon: Icons.bug_report_rounded,
    isFeatured: true,
  ),
  BiteGuide(
    id: 'bedbug',
    title: 'Bed bug',
    tagline: 'May resemble itchy marks in a line or cluster.',
    summary:
        'Bed bug marks can resemble many other skin conditions, so surroundings and evidence of insects matter too.',
    pattern: 'Itchy marks that may appear in a line, loose group, or cluster.',
    recoverySteps: <String>[
      'Use a cool compress for itching and swelling.',
      'Avoid scratching and check bedding if new marks continue.',
    ],
    watchFor:
        'Get medical advice for possible infection, many marks, or symptoms that concern you.',
    filterTags: <String>{'red', 'itchy', 'cluster', 'line'},
    category: 'At home',
    kind: GuideKind.bite,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.bedBug,
        caption: 'Bed bug example',
        semanticLabel: 'Close-up photograph of an adult bed bug',
      ),
      GuideMedia(
        asset: AppAssets.bedBugBites,
        kind: GuideMediaKind.skin,
        caption: 'Bite example · Reported bed bug bites on a hand',
        semanticLabel:
            'Photographer-reported bed bug bites with red raised marks near the thumb',
        fit: BoxFit.contain,
      ),
      ...AdditionalBitePhotos.bedBug,
      ContextMedia.bedBugEvidence,
      ContextMedia.cleanHands,
    ],
    icon: Icons.bed_rounded,
    isFeatured: true,
  ),
  BiteGuide(
    id: 'spider',
    title: 'Spider or another skin issue',
    tagline: 'A photo alone cannot reliably confirm a spider bite.',
    summary:
        'A single painful mark has many possible causes, including non-bite skin conditions.',
    pattern:
        'A single painful mark, sometimes with a puncture-like center or blister.',
    recoverySteps: <String>[
      'Clean gently and do not squeeze or cut the area.',
      'Note changes in pain, swelling, color, and the surrounding skin.',
    ],
    watchFor:
        'Seek urgent advice for worsening pain, blistering, spreading color change, fever, or feeling unwell.',
    filterTags: <String>{'red', 'painful', 'single', 'puncture', 'blister'},
    category: 'Outdoors',
    kind: GuideKind.bite,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.spider,
        caption: 'Spider example',
        semanticLabel: 'Close-up photograph of a spider',
      ),
      ContextMedia.cleanHands,
    ],
    icon: Icons.pest_control_rounded,
  ),
  BiteGuide(
    id: 'tick',
    title: 'Tick attachment',
    tagline: 'An attached tick needs prompt, careful removal.',
    summary:
        'If a tick is attached, careful removal and watching for later symptoms are important.',
    pattern:
        'A tick may remain attached; afterward there can be a small irritated spot.',
    recoverySteps: <String>[
      'Use fine-tipped tweezers to remove an attached tick as soon as possible.',
      'Clean the area and note when and where the exposure happened.',
    ],
    watchFor:
        'Contact a clinician promptly if you develop fever, body aches, or a rash after a tick bite.',
    filterTags: <String>{'red', 'single', 'tick'},
    category: 'Outdoors',
    kind: GuideKind.bite,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.tick,
        caption: 'Tick example',
        semanticLabel: 'Close-up photograph of a blacklegged tick',
      ),
      ...AdditionalBitePhotos.tick,
      ContextMedia.tickOnVegetation,
      ContextMedia.tickRemoval,
    ],
    icon: Icons.location_on_rounded,
    isFeatured: true,
  ),
  BiteGuide(
    id: 'biting-midge',
    title: 'Biting midge or no-see-um',
    tagline: 'Tiny outdoor flies can leave intensely itchy grouped marks.',
    summary:
        'Biting midges are very small flies found especially near water and around dawn or dusk.',
    pattern:
        'Tiny itchy raised marks that may sting or burn and often appear in a group.',
    recoverySteps: <String>[
      'Keep the skin clean and use a wrapped cool pack.',
      'Avoid scratching; a pharmacist can suggest a suitable anti-itch option.',
    ],
    watchFor:
        'Seek care if marks become increasingly painful, warm, draining, or a widespread allergic reaction develops.',
    filterTags: <String>{'red', 'itchy', 'raised', 'cluster'},
    category: 'Outdoors',
    kind: GuideKind.bite,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.bitingMidge,
        caption: 'Biting midge example',
        semanticLabel: 'Magnified photograph of a biting midge',
      ),
      ContextMedia.cleanHands,
    ],
    icon: Icons.air_rounded,
    isFeatured: true,
  ),
  BiteGuide(
    id: 'black-fly',
    title: 'Black fly',
    tagline: 'A small fly bite may later feel sore, itchy, or swollen.',
    summary:
        'Black flies are often active by day near moving water. A mark alone cannot identify the fly.',
    pattern:
        'A sore or itchy spot that may bleed slightly at first and become raised or swollen.',
    recoverySteps: <String>[
      'Wash gently with soap and water.',
      'Use a wrapped cool pack and avoid scratching.',
    ],
    watchFor:
        'Get medical advice if swelling or pain keeps increasing, or fever, nausea, or dizziness develops.',
    filterTags: <String>{'red', 'itchy', 'painful', 'swollen'},
    category: 'Outdoors',
    kind: GuideKind.bite,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.blackFly,
        caption: 'Black fly example',
        semanticLabel: 'Magnified image of a black fly',
      ),
      ContextMedia.cleanHands,
    ],
    icon: Icons.air_rounded,
  ),
  BiteGuide(
    id: 'horse-deer-fly',
    title: 'Horse or deer fly',
    tagline: 'These larger flies can cause an immediately painful mark.',
    summary:
        'Horse and deer flies are often encountered near wooded water, ponds, farms, or livestock.',
    pattern:
        'An immediately painful, cut-like mark followed by a raised or swollen area.',
    recoverySteps: <String>[
      'Wash the area with soap and water.',
      'Apply a wrapped cool pack and avoid scratching.',
    ],
    watchFor:
        'Seek care for increasing pain or swelling. Fever with a skin ulcer or swollen lymph nodes needs prompt evaluation.',
    filterTags: <String>{'red', 'painful', 'swollen', 'single', 'puncture'},
    category: 'Outdoors',
    kind: GuideKind.bite,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.horseFly,
        caption: 'Horse fly example',
        semanticLabel: 'Close-up photograph of a horse fly',
      ),
      ContextMedia.cleanHands,
    ],
    icon: Icons.air_rounded,
  ),
  BiteGuide(
    id: 'stable-fly',
    title: 'Stable fly',
    tagline: 'A painful fly bite often affects exposed lower legs.',
    summary:
        'Stable flies are common around animals and outdoor areas, and can also be found near homes.',
    pattern:
        'A sharp, painful mark, sometimes followed by itching and several marks around the lower legs.',
    recoverySteps: <String>[
      'Wash the area and use a wrapped cool pack.',
      'Cover irritated skin if needed to reduce scratching.',
    ],
    watchFor:
        'Seek medical advice if pain, warmth, swelling, or drainage keeps increasing.',
    filterTags: <String>{'red', 'painful', 'itchy', 'cluster', 'lower-leg'},
    category: 'Outdoors',
    kind: GuideKind.bite,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.stableFly,
        caption: 'Stable fly example',
        semanticLabel: 'Close-up photograph of a stable fly',
      ),
      ContextMedia.cleanHands,
    ],
    icon: Icons.air_rounded,
  ),
  BiteGuide(
    id: 'chigger',
    title: 'Chigger or harvest mite',
    tagline: 'May resemble very itchy groups near tight clothing.',
    summary:
        'Chigger larvae do not burrow into human skin. Marks often appear after grass or brush exposure.',
    pattern:
        'Groups of intensely itchy raised marks near sock lines, the waist, groin, or behind the knees.',
    recoverySteps: <String>[
      'Shower and wash clothing after possible outdoor exposure.',
      'Use a cool compress and ask a pharmacist about itch relief if needed.',
    ],
    watchFor:
        'Contact a clinician if itching is severe, symptoms worsen, or fever, body aches, rash, or a dark scab-like spot develops after travel.',
    filterTags: <String>{
      'red',
      'itchy',
      'raised',
      'cluster',
      'lower-leg',
      'waistline',
    },
    category: 'Outdoors',
    kind: GuideKind.bite,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.chigger,
        caption: 'Chigger larva · Magnified photograph',
        semanticLabel:
            'Magnified photograph of a six-legged chigger mite larva',
        fit: BoxFit.contain,
      ),
      GuideMedia(
        asset: AppAssets.chiggerAnkle,
        kind: GuideMediaKind.skin,
        caption: 'Bite example · Chigger reactions on an ankle',
        semanticLabel:
            'Clinical photograph showing chigger bite reactions on an ankle',
        fit: BoxFit.contain,
      ),
      GuideMedia(
        asset: AppAssets.chiggerBite,
        kind: GuideMediaKind.skin,
        caption: 'Bite example · A blister 24 hours after a chigger bite (CDC)',
        semanticLabel:
            'Documented chigger bite with a blister beside a measuring ruler',
        fit: BoxFit.contain,
      ),
      ...AdditionalBitePhotos.chigger,
      ContextMedia.cleanHands,
    ],
    icon: Icons.grass_rounded,
    isFeatured: true,
  ),
  BiteGuide(
    id: 'fire-ant',
    title: 'Fire ant sting',
    tagline: 'Burning stings may occur in groups outdoors.',
    summary:
        'Fire ant venom can cause small white-tipped bumps later; these are not automatically an infection.',
    pattern:
        'Immediate burning with grouped swollen marks that may become white-tipped within one or two days.',
    recoverySteps: <String>[
      'Brush attached ants off, then wash the skin gently.',
      'Use a wrapped cool pack and do not scratch or pop white-tipped bumps.',
    ],
    watchFor:
        'Get emergency help for trouble breathing, faintness, chest pain, major swelling, or widespread symptoms.',
    filterTags: <String>{
      'red',
      'painful',
      'cluster',
      'swollen',
      'blister',
      'pustule',
    },
    category: 'Outdoors',
    kind: GuideKind.sting,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.fireAnt,
        caption: 'Fire ant example',
        semanticLabel: 'Close-up photograph of a red imported fire ant',
      ),
      ContextMedia.cleanHands,
    ],
    icon: Icons.whatshot_rounded,
    isFeatured: true,
  ),
  BiteGuide(
    id: 'stinging-insect',
    title: 'Bee, wasp, or hornet sting',
    tagline: 'A sudden sharp sting can leave local pain and swelling.',
    summary:
        'Skin appearance alone usually cannot distinguish a bee, wasp, or hornet. Wasps can sting more than once.',
    pattern:
        'Immediate sharp pain followed by a raised, swollen, itchy area; a honeybee stinger may remain.',
    recoverySteps: <String>[
      'Move away from the insects and remove a visible stinger promptly.',
      'Wash with soap and water, then apply a wrapped cool pack.',
    ],
    watchFor:
        'Use prescribed epinephrine and call emergency services for anaphylaxis. Mouth or throat stings and numerous stings need urgent advice.',
    filterTags: <String>{
      'red',
      'painful',
      'raised',
      'swollen',
      'single',
      'stinger',
    },
    category: 'Outdoors',
    kind: GuideKind.sting,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.honeyBee,
        caption: 'Honey bee example',
        semanticLabel: 'Close-up photograph of a honey bee on a flower',
      ),
      GuideMedia(
        asset: AppAssets.yellowjacket,
        caption: 'Yellowjacket example',
        semanticLabel: 'Close-up photograph of a yellowjacket wasp',
      ),
      GuideMedia(
        asset: AppAssets.paperWasp,
        caption: 'Red paper wasp · Polistes carolina',
        semanticLabel: 'Photograph of a red paper wasp specimen',
        fit: BoxFit.contain,
      ),
      ...AdditionalBitePhotos.stings,
      ContextMedia.cleanHands,
    ],
    icon: Icons.crisis_alert_rounded,
    isFeatured: true,
  ),
  BiteGuide(
    id: 'head-lice',
    title: 'Head lice irritation',
    tagline:
        'An infestation is confirmed by finding live lice, not marks alone.',
    summary:
        'Head lice are not caused by poor cleanliness. Scalp itching is more useful when paired with live lice or firmly attached nits.',
    pattern:
        'Scalp itching or tickling, scratch marks, and possible nits near the scalp, especially behind ears and at the neck.',
    recoverySteps: <String>[
      'Check carefully for a live louse or firmly attached nits close to the scalp.',
      'Use an approved treatment exactly as directed and check close household contacts.',
    ],
    watchFor:
        'Ask a clinician if identification is uncertain, sores appear infected, or correct treatment does not work.',
    filterTags: <String>{'itchy', 'cluster', 'scalp'},
    category: 'At home',
    kind: GuideKind.infestation,
    gallery: <GuideMedia>[
      GuideMedia(
        asset: AppAssets.headLouse,
        caption: 'Head louse example',
        semanticLabel: 'Magnified photograph of a head louse',
      ),
    ],
    icon: Icons.person_search_rounded,
  ),
];

final featuredGuides = List<BiteGuide>.unmodifiable(
  guides.where((guide) => guide.isFeatured),
);

BiteGuide? guideById(String id) {
  for (final guide in guides) {
    if (guide.id == id) return guide;
  }
  return null;
}

final seedPosts = <CommunityPost>[
  CommunityPost(
    id: 'post-flea',
    authorId: 'seed-maya',
    author: 'Maya R.',
    location: 'Southern California',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    possibleMatch: 'Possible flea bites',
    body:
        'Small itchy bumps around my ankle after looking after a friend’s cat. A cool compress was a relief while I checked in with a clinician.',
    guideId: 'flea',
    tags: const <String>['Itchy', 'Cluster'],
    likes: 24,
  ),
  CommunityPost(
    id: 'post-mosquito',
    authorId: 'seed-jordan',
    author: 'Jordan P.',
    location: 'Oregon',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    possibleMatch: 'Possible mosquito bite',
    body:
        'I noticed one itchy bump after gardening. Keeping it cool and not scratching helped me stay comfortable.',
    guideId: 'mosquito',
    tags: const <String>['Outdoors', 'Improving'],
    likes: 18,
  ),
];
