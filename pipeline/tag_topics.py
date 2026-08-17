#!/usr/bin/env python3
"""
tag_topics.py — assign topic_tag to compound_words using word-boundary regex matching.

Usage:
    python3 pipeline/tag_topics.py
    python3 pipeline/tag_topics.py --db path/to/sinosphere.db
    python3 pipeline/tag_topics.py --dry-run   # print counts without writing

Unlike the old LIKE '%keyword%' approach, this uses \b word boundaries so
'body' matches 'body' but not 'somebody', 'everybody', etc.
"""

import argparse
import re
import sqlite3
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Topic keyword sets — whole-word match (re.search with \b boundaries)
# ---------------------------------------------------------------------------
TOPIC_RULES: dict[str, list[str]] = {
    'nature':   [
        'mountain', 'forest', 'ocean', 'river', 'lake', 'wind', 'rain',
        'snow', 'fire', 'earth', 'sky', 'cloud', 'flower', 'tree', 'grass',
        'stone', 'sun', 'moon', 'star', 'season', 'spring', 'summer',
        'autumn', 'winter', 'nature', 'weather', 'animal', 'plant', 'bird',
        'fish', 'insect', 'soil', 'sand', 'wave', 'storm', 'frost', 'dew',
        'fog', 'thunder', 'lightning', 'rainbow', 'tide', 'cliff', 'valley',
        'desert', 'jungle', 'wilderness',
    ],
    'body':     [
        'body', 'head', 'face', 'eye', 'ear', 'nose', 'mouth', 'hand',
        'arm', 'leg', 'foot', 'heart', 'lung', 'bone', 'skin', 'blood',
        'brain', 'nerve', 'muscle', 'organ', 'limb', 'chest', 'back',
        'neck', 'tooth', 'tongue', 'hair', 'finger', 'thumb', 'shoulder',
        'knee', 'elbow', 'wrist', 'ankle', 'heel', 'forehead', 'cheek',
        'chin', 'lip', 'throat', 'stomach', 'liver', 'kidney', 'spine',
        'joint', 'vein', 'artery', 'breath', 'pulse',
    ],
    'city':     [
        'city', 'town', 'village', 'street', 'road', 'bridge', 'building',
        'house', 'room', 'door', 'window', 'wall', 'floor', 'park',
        'square', 'temple', 'tower', 'gate', 'court', 'district',
        'neighbourhood', 'capital', 'suburb', 'port', 'harbour', 'alley',
        'avenue', 'boulevard', 'intersection', 'crossroads', 'sidewalk',
        'pavement', 'lamp', 'sign', 'statue', 'fountain', 'monument',
        'palace', 'fortress', 'castle', 'embassy', 'library', 'museum',
        'stadium', 'arena', 'mall', 'market', 'neighbourhood',
    ],
    'emotions': [
        'happy', 'sad', 'angry', 'fear', 'love', 'hate', 'joy', 'grief',
        'anxious', 'worry', 'excited', 'bored', 'lonely', 'proud', 'shame',
        'hope', 'despair', 'envy', 'jealous', 'emotion', 'feeling', 'mood',
        'sentiment', 'passion', 'affection', 'sorrow', 'delight', 'regret',
        'guilt', 'relief', 'disgust', 'surprise', 'nostalgia', 'melancholy',
        'enthusiasm', 'courage', 'confidence', 'hesitation', 'frustration',
        'disappointment', 'satisfaction', 'comfort', 'distress', 'panic',
    ],
    'time':     [
        'time', 'year', 'month', 'week', 'hour', 'minute', 'second',
        'morning', 'evening', 'night', 'noon', 'dawn', 'dusk', 'today',
        'yesterday', 'tomorrow', 'century', 'era', 'epoch', 'ancient',
        'history', 'future', 'past', 'present', 'deadline', 'schedule',
        'calendar', 'clock', 'moment', 'instant', 'period', 'duration',
        'interval', 'season', 'decade', 'millennium', 'anniversary',
        'birthday', 'holiday', 'festival', 'age', 'generation', 'dynasty',
    ],
    'family':   [
        'family', 'father', 'mother', 'son', 'daughter', 'brother', 'sister',
        'husband', 'wife', 'child', 'parent', 'grandparent', 'grandfather',
        'grandmother', 'uncle', 'aunt', 'nephew', 'niece', 'cousin',
        'relative', 'ancestor', 'descendant', 'household', 'marriage',
        'divorce', 'widow', 'orphan', 'sibling', 'spouse', 'fiance',
        'in-law', 'stepmother', 'stepfather', 'adopted', 'twins',
        'newborn', 'infant', 'toddler', 'teenager', 'elder', 'clan',
    ],
    'learning': [
        'learn', 'study', 'school', 'university', 'college', 'class',
        'lesson', 'teacher', 'student', 'pupil', 'book', 'read', 'write',
        'knowledge', 'education', 'exam', 'test', 'grade', 'research',
        'science', 'theory', 'practice', 'skill', 'language', 'literature',
        'library', 'lecture', 'tutor', 'homework', 'curriculum', 'degree',
        'diploma', 'scholarship', 'academic', 'classroom', 'blackboard',
        'pencil', 'notebook', 'dictionary', 'grammar', 'vocabulary',
        'pronunciation', 'comprehension', 'analysis', 'experiment',
    ],
    'travel':   [
        'travel', 'journey', 'trip', 'tour', 'visit', 'arrive', 'depart',
        'airport', 'station', 'hotel', 'ticket', 'passport', 'visa', 'border',
        'foreign', 'abroad', 'destination', 'luggage', 'suitcase', 'guide',
        'tourist', 'map', 'route', 'flight', 'boarding', 'customs',
        'immigration', 'reservation', 'accommodation', 'hostel', 'motel',
        'itinerary', 'excursion', 'expedition', 'backpacker', 'adventure',
        'cruise', 'ferry', 'transit',
    ],
    'food':     [
        'food', 'eat', 'drink', 'cook', 'meal', 'dish', 'rice', 'noodle',
        'bread', 'meat', 'fish', 'vegetable', 'fruit', 'soup', 'sauce',
        'spice', 'sweet', 'bitter', 'sour', 'salty', 'restaurant', 'kitchen',
        'chef', 'recipe', 'hunger', 'thirst', 'breakfast', 'lunch', 'dinner',
        'snack', 'dessert', 'beverage', 'tea', 'coffee', 'wine', 'beer',
        'juice', 'broth', 'stew', 'roast', 'fry', 'boil', 'steam', 'bake',
        'grill', 'seasoning', 'ingredient', 'portion', 'appetite', 'diet',
        'nutrition', 'calorie', 'flavour', 'texture', 'aroma',
    ],
    'business': [
        'business', 'company', 'trade', 'commerce', 'economy', 'money',
        'price', 'cost', 'profit', 'loss', 'tax', 'contract', 'bank',
        'invest', 'capital', 'salary', 'wage', 'employee', 'employer',
        'manage', 'industry', 'product', 'service', 'customer', 'client',
        'supply', 'demand', 'export', 'import', 'enterprise', 'corporation',
        'shareholder', 'dividend', 'revenue', 'budget', 'accounting',
        'audit', 'merger', 'acquisition', 'startup', 'entrepreneur',
        'brand', 'marketing', 'advertising', 'retail', 'wholesale',
        'negotiation', 'partnership', 'franchise', 'commission',
    ],
}

# Patterns compiled once — \b word boundaries prevent substring false positives
_PATTERNS: dict[str, list[re.Pattern]] = {
    topic: [re.compile(r'\b' + kw + r'\b', re.IGNORECASE) for kw in keywords]
    for topic, keywords in TOPIC_RULES.items()
}


def assign_tags(english_def: str, is_cognate: int) -> str:
    """Return comma-separated topic IDs for a word."""
    tags: list[str] = []
    for topic, patterns in _PATTERNS.items():
        if any(p.search(english_def) for p in patterns):
            tags.append(topic)
    if is_cognate:
        tags.append('cognates')
    return ','.join(tags)


def main():
    parser = argparse.ArgumentParser(description='Tag compound_words with topic_tag')
    parser.add_argument('--db', default='data/db/sinosphere.db')
    parser.add_argument('--dry-run', action='store_true',
                        help='Print counts without writing to DB')
    args = parser.parse_args()

    db_path = Path(args.db)
    if not db_path.exists():
        print(f'DB not found: {db_path}', file=sys.stderr)
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Add column if not present
    existing = {row[1] for row in cur.execute('PRAGMA table_info(compound_words)')}
    if 'topic_tag' not in existing:
        print('Adding topic_tag column…')
        cur.execute('ALTER TABLE compound_words ADD COLUMN topic_tag TEXT')

    print('Loading words…')
    rows = cur.execute(
        'SELECT id, english_def, is_cognate_anchor FROM compound_words'
    ).fetchall()
    print(f'{len(rows):,} words to process')

    updates: list[tuple[str, str]] = []
    topic_counts: dict[str, int] = {t: 0 for t in list(TOPIC_RULES) + ['cognates']}

    for word_id, english_def, is_cognate in rows:
        tag = assign_tags(english_def or '', is_cognate or 0)
        updates.append((tag if tag else None, word_id))
        for t in (tag.split(',') if tag else []):
            if t in topic_counts:
                topic_counts[t] += 1

    print('\nTopic word counts:')
    for topic, count in topic_counts.items():
        print(f'  {topic:<12} {count:>6,}')

    if not args.dry_run:
        print('\nWriting tags…')
        cur.executemany(
            'UPDATE compound_words SET topic_tag = ? WHERE id = ?', updates
        )
        conn.commit()
        tagged = sum(1 for tag, _ in updates if tag)
        print(f'Done. {tagged:,} / {len(rows):,} words tagged.')
    else:
        print('\nDry run — no changes written.')

    conn.close()


if __name__ == '__main__':
    main()
