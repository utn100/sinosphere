// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinyinMeta = const VerificationMeta('pinyin');
  @override
  late final GeneratedColumn<String> pinyin = GeneratedColumn<String>(
    'pinyin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hangulMeta = const VerificationMeta('hangul');
  @override
  late final GeneratedColumn<String> hangul = GeneratedColumn<String>(
    'hangul',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hanVietMeta = const VerificationMeta(
    'hanViet',
  );
  @override
  late final GeneratedColumn<String> hanViet = GeneratedColumn<String>(
    'han_viet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _englishDefMeta = const VerificationMeta(
    'englishDef',
  );
  @override
  late final GeneratedColumn<String> englishDef = GeneratedColumn<String>(
    'english_def',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _etymologyStoryMeta = const VerificationMeta(
    'etymologyStory',
  );
  @override
  late final GeneratedColumn<String> etymologyStory = GeneratedColumn<String>(
    'etymology_story',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decompositionMeta = const VerificationMeta(
    'decomposition',
  );
  @override
  late final GeneratedColumn<String> decomposition = GeneratedColumn<String>(
    'decomposition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _radicalMeta = const VerificationMeta(
    'radical',
  );
  @override
  late final GeneratedColumn<String> radical = GeneratedColumn<String>(
    'radical',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hskLevelMeta = const VerificationMeta(
    'hskLevel',
  );
  @override
  late final GeneratedColumn<int> hskLevel = GeneratedColumn<int>(
    'hsk_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jpOnyomiMeta = const VerificationMeta(
    'jpOnyomi',
  );
  @override
  late final GeneratedColumn<String> jpOnyomi = GeneratedColumn<String>(
    'jp_onyomi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strokeCountMeta = const VerificationMeta(
    'strokeCount',
  );
  @override
  late final GeneratedColumn<int> strokeCount = GeneratedColumn<int>(
    'stroke_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    symbol,
    pinyin,
    hangul,
    hanViet,
    englishDef,
    etymologyStory,
    decomposition,
    radical,
    hskLevel,
    jpOnyomi,
    strokeCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Character> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('pinyin')) {
      context.handle(
        _pinyinMeta,
        pinyin.isAcceptableOrUnknown(data['pinyin']!, _pinyinMeta),
      );
    } else if (isInserting) {
      context.missing(_pinyinMeta);
    }
    if (data.containsKey('hangul')) {
      context.handle(
        _hangulMeta,
        hangul.isAcceptableOrUnknown(data['hangul']!, _hangulMeta),
      );
    }
    if (data.containsKey('han_viet')) {
      context.handle(
        _hanVietMeta,
        hanViet.isAcceptableOrUnknown(data['han_viet']!, _hanVietMeta),
      );
    }
    if (data.containsKey('english_def')) {
      context.handle(
        _englishDefMeta,
        englishDef.isAcceptableOrUnknown(data['english_def']!, _englishDefMeta),
      );
    }
    if (data.containsKey('etymology_story')) {
      context.handle(
        _etymologyStoryMeta,
        etymologyStory.isAcceptableOrUnknown(
          data['etymology_story']!,
          _etymologyStoryMeta,
        ),
      );
    }
    if (data.containsKey('decomposition')) {
      context.handle(
        _decompositionMeta,
        decomposition.isAcceptableOrUnknown(
          data['decomposition']!,
          _decompositionMeta,
        ),
      );
    }
    if (data.containsKey('radical')) {
      context.handle(
        _radicalMeta,
        radical.isAcceptableOrUnknown(data['radical']!, _radicalMeta),
      );
    }
    if (data.containsKey('hsk_level')) {
      context.handle(
        _hskLevelMeta,
        hskLevel.isAcceptableOrUnknown(data['hsk_level']!, _hskLevelMeta),
      );
    }
    if (data.containsKey('jp_onyomi')) {
      context.handle(
        _jpOnyomiMeta,
        jpOnyomi.isAcceptableOrUnknown(data['jp_onyomi']!, _jpOnyomiMeta),
      );
    }
    if (data.containsKey('stroke_count')) {
      context.handle(
        _strokeCountMeta,
        strokeCount.isAcceptableOrUnknown(
          data['stroke_count']!,
          _strokeCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      pinyin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinyin'],
      )!,
      hangul: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hangul'],
      ),
      hanViet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}han_viet'],
      )!,
      englishDef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_def'],
      )!,
      etymologyStory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etymology_story'],
      ),
      decomposition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decomposition'],
      ),
      radical: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}radical'],
      ),
      hskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hsk_level'],
      ),
      jpOnyomi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jp_onyomi'],
      ),
      strokeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stroke_count'],
      )!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  final String id;
  final String symbol;
  final String pinyin;
  final String? hangul;
  final String hanViet;
  final String englishDef;
  final String? etymologyStory;
  final String? decomposition;
  final String? radical;
  final int? hskLevel;
  final String? jpOnyomi;
  final int strokeCount;
  const Character({
    required this.id,
    required this.symbol,
    required this.pinyin,
    this.hangul,
    required this.hanViet,
    required this.englishDef,
    this.etymologyStory,
    this.decomposition,
    this.radical,
    this.hskLevel,
    this.jpOnyomi,
    required this.strokeCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['symbol'] = Variable<String>(symbol);
    map['pinyin'] = Variable<String>(pinyin);
    if (!nullToAbsent || hangul != null) {
      map['hangul'] = Variable<String>(hangul);
    }
    map['han_viet'] = Variable<String>(hanViet);
    map['english_def'] = Variable<String>(englishDef);
    if (!nullToAbsent || etymologyStory != null) {
      map['etymology_story'] = Variable<String>(etymologyStory);
    }
    if (!nullToAbsent || decomposition != null) {
      map['decomposition'] = Variable<String>(decomposition);
    }
    if (!nullToAbsent || radical != null) {
      map['radical'] = Variable<String>(radical);
    }
    if (!nullToAbsent || hskLevel != null) {
      map['hsk_level'] = Variable<int>(hskLevel);
    }
    if (!nullToAbsent || jpOnyomi != null) {
      map['jp_onyomi'] = Variable<String>(jpOnyomi);
    }
    map['stroke_count'] = Variable<int>(strokeCount);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      symbol: Value(symbol),
      pinyin: Value(pinyin),
      hangul: hangul == null && nullToAbsent
          ? const Value.absent()
          : Value(hangul),
      hanViet: Value(hanViet),
      englishDef: Value(englishDef),
      etymologyStory: etymologyStory == null && nullToAbsent
          ? const Value.absent()
          : Value(etymologyStory),
      decomposition: decomposition == null && nullToAbsent
          ? const Value.absent()
          : Value(decomposition),
      radical: radical == null && nullToAbsent
          ? const Value.absent()
          : Value(radical),
      hskLevel: hskLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(hskLevel),
      jpOnyomi: jpOnyomi == null && nullToAbsent
          ? const Value.absent()
          : Value(jpOnyomi),
      strokeCount: Value(strokeCount),
    );
  }

  factory Character.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      id: serializer.fromJson<String>(json['id']),
      symbol: serializer.fromJson<String>(json['symbol']),
      pinyin: serializer.fromJson<String>(json['pinyin']),
      hangul: serializer.fromJson<String?>(json['hangul']),
      hanViet: serializer.fromJson<String>(json['hanViet']),
      englishDef: serializer.fromJson<String>(json['englishDef']),
      etymologyStory: serializer.fromJson<String?>(json['etymologyStory']),
      decomposition: serializer.fromJson<String?>(json['decomposition']),
      radical: serializer.fromJson<String?>(json['radical']),
      hskLevel: serializer.fromJson<int?>(json['hskLevel']),
      jpOnyomi: serializer.fromJson<String?>(json['jpOnyomi']),
      strokeCount: serializer.fromJson<int>(json['strokeCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'symbol': serializer.toJson<String>(symbol),
      'pinyin': serializer.toJson<String>(pinyin),
      'hangul': serializer.toJson<String?>(hangul),
      'hanViet': serializer.toJson<String>(hanViet),
      'englishDef': serializer.toJson<String>(englishDef),
      'etymologyStory': serializer.toJson<String?>(etymologyStory),
      'decomposition': serializer.toJson<String?>(decomposition),
      'radical': serializer.toJson<String?>(radical),
      'hskLevel': serializer.toJson<int?>(hskLevel),
      'jpOnyomi': serializer.toJson<String?>(jpOnyomi),
      'strokeCount': serializer.toJson<int>(strokeCount),
    };
  }

  Character copyWith({
    String? id,
    String? symbol,
    String? pinyin,
    Value<String?> hangul = const Value.absent(),
    String? hanViet,
    String? englishDef,
    Value<String?> etymologyStory = const Value.absent(),
    Value<String?> decomposition = const Value.absent(),
    Value<String?> radical = const Value.absent(),
    Value<int?> hskLevel = const Value.absent(),
    Value<String?> jpOnyomi = const Value.absent(),
    int? strokeCount,
  }) => Character(
    id: id ?? this.id,
    symbol: symbol ?? this.symbol,
    pinyin: pinyin ?? this.pinyin,
    hangul: hangul.present ? hangul.value : this.hangul,
    hanViet: hanViet ?? this.hanViet,
    englishDef: englishDef ?? this.englishDef,
    etymologyStory: etymologyStory.present
        ? etymologyStory.value
        : this.etymologyStory,
    decomposition: decomposition.present
        ? decomposition.value
        : this.decomposition,
    radical: radical.present ? radical.value : this.radical,
    hskLevel: hskLevel.present ? hskLevel.value : this.hskLevel,
    jpOnyomi: jpOnyomi.present ? jpOnyomi.value : this.jpOnyomi,
    strokeCount: strokeCount ?? this.strokeCount,
  );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      id: data.id.present ? data.id.value : this.id,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      pinyin: data.pinyin.present ? data.pinyin.value : this.pinyin,
      hangul: data.hangul.present ? data.hangul.value : this.hangul,
      hanViet: data.hanViet.present ? data.hanViet.value : this.hanViet,
      englishDef: data.englishDef.present
          ? data.englishDef.value
          : this.englishDef,
      etymologyStory: data.etymologyStory.present
          ? data.etymologyStory.value
          : this.etymologyStory,
      decomposition: data.decomposition.present
          ? data.decomposition.value
          : this.decomposition,
      radical: data.radical.present ? data.radical.value : this.radical,
      hskLevel: data.hskLevel.present ? data.hskLevel.value : this.hskLevel,
      jpOnyomi: data.jpOnyomi.present ? data.jpOnyomi.value : this.jpOnyomi,
      strokeCount: data.strokeCount.present
          ? data.strokeCount.value
          : this.strokeCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('id: $id, ')
          ..write('symbol: $symbol, ')
          ..write('pinyin: $pinyin, ')
          ..write('hangul: $hangul, ')
          ..write('hanViet: $hanViet, ')
          ..write('englishDef: $englishDef, ')
          ..write('etymologyStory: $etymologyStory, ')
          ..write('decomposition: $decomposition, ')
          ..write('radical: $radical, ')
          ..write('hskLevel: $hskLevel, ')
          ..write('jpOnyomi: $jpOnyomi, ')
          ..write('strokeCount: $strokeCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    symbol,
    pinyin,
    hangul,
    hanViet,
    englishDef,
    etymologyStory,
    decomposition,
    radical,
    hskLevel,
    jpOnyomi,
    strokeCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.id == this.id &&
          other.symbol == this.symbol &&
          other.pinyin == this.pinyin &&
          other.hangul == this.hangul &&
          other.hanViet == this.hanViet &&
          other.englishDef == this.englishDef &&
          other.etymologyStory == this.etymologyStory &&
          other.decomposition == this.decomposition &&
          other.radical == this.radical &&
          other.hskLevel == this.hskLevel &&
          other.jpOnyomi == this.jpOnyomi &&
          other.strokeCount == this.strokeCount);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  final Value<String> id;
  final Value<String> symbol;
  final Value<String> pinyin;
  final Value<String?> hangul;
  final Value<String> hanViet;
  final Value<String> englishDef;
  final Value<String?> etymologyStory;
  final Value<String?> decomposition;
  final Value<String?> radical;
  final Value<int?> hskLevel;
  final Value<String?> jpOnyomi;
  final Value<int> strokeCount;
  final Value<int> rowid;
  const CharactersCompanion({
    this.id = const Value.absent(),
    this.symbol = const Value.absent(),
    this.pinyin = const Value.absent(),
    this.hangul = const Value.absent(),
    this.hanViet = const Value.absent(),
    this.englishDef = const Value.absent(),
    this.etymologyStory = const Value.absent(),
    this.decomposition = const Value.absent(),
    this.radical = const Value.absent(),
    this.hskLevel = const Value.absent(),
    this.jpOnyomi = const Value.absent(),
    this.strokeCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharactersCompanion.insert({
    required String id,
    required String symbol,
    required String pinyin,
    this.hangul = const Value.absent(),
    this.hanViet = const Value.absent(),
    this.englishDef = const Value.absent(),
    this.etymologyStory = const Value.absent(),
    this.decomposition = const Value.absent(),
    this.radical = const Value.absent(),
    this.hskLevel = const Value.absent(),
    this.jpOnyomi = const Value.absent(),
    this.strokeCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       symbol = Value(symbol),
       pinyin = Value(pinyin);
  static Insertable<Character> custom({
    Expression<String>? id,
    Expression<String>? symbol,
    Expression<String>? pinyin,
    Expression<String>? hangul,
    Expression<String>? hanViet,
    Expression<String>? englishDef,
    Expression<String>? etymologyStory,
    Expression<String>? decomposition,
    Expression<String>? radical,
    Expression<int>? hskLevel,
    Expression<String>? jpOnyomi,
    Expression<int>? strokeCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (symbol != null) 'symbol': symbol,
      if (pinyin != null) 'pinyin': pinyin,
      if (hangul != null) 'hangul': hangul,
      if (hanViet != null) 'han_viet': hanViet,
      if (englishDef != null) 'english_def': englishDef,
      if (etymologyStory != null) 'etymology_story': etymologyStory,
      if (decomposition != null) 'decomposition': decomposition,
      if (radical != null) 'radical': radical,
      if (hskLevel != null) 'hsk_level': hskLevel,
      if (jpOnyomi != null) 'jp_onyomi': jpOnyomi,
      if (strokeCount != null) 'stroke_count': strokeCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharactersCompanion copyWith({
    Value<String>? id,
    Value<String>? symbol,
    Value<String>? pinyin,
    Value<String?>? hangul,
    Value<String>? hanViet,
    Value<String>? englishDef,
    Value<String?>? etymologyStory,
    Value<String?>? decomposition,
    Value<String?>? radical,
    Value<int?>? hskLevel,
    Value<String?>? jpOnyomi,
    Value<int>? strokeCount,
    Value<int>? rowid,
  }) {
    return CharactersCompanion(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      pinyin: pinyin ?? this.pinyin,
      hangul: hangul ?? this.hangul,
      hanViet: hanViet ?? this.hanViet,
      englishDef: englishDef ?? this.englishDef,
      etymologyStory: etymologyStory ?? this.etymologyStory,
      decomposition: decomposition ?? this.decomposition,
      radical: radical ?? this.radical,
      hskLevel: hskLevel ?? this.hskLevel,
      jpOnyomi: jpOnyomi ?? this.jpOnyomi,
      strokeCount: strokeCount ?? this.strokeCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (pinyin.present) {
      map['pinyin'] = Variable<String>(pinyin.value);
    }
    if (hangul.present) {
      map['hangul'] = Variable<String>(hangul.value);
    }
    if (hanViet.present) {
      map['han_viet'] = Variable<String>(hanViet.value);
    }
    if (englishDef.present) {
      map['english_def'] = Variable<String>(englishDef.value);
    }
    if (etymologyStory.present) {
      map['etymology_story'] = Variable<String>(etymologyStory.value);
    }
    if (decomposition.present) {
      map['decomposition'] = Variable<String>(decomposition.value);
    }
    if (radical.present) {
      map['radical'] = Variable<String>(radical.value);
    }
    if (hskLevel.present) {
      map['hsk_level'] = Variable<int>(hskLevel.value);
    }
    if (jpOnyomi.present) {
      map['jp_onyomi'] = Variable<String>(jpOnyomi.value);
    }
    if (strokeCount.present) {
      map['stroke_count'] = Variable<int>(strokeCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('symbol: $symbol, ')
          ..write('pinyin: $pinyin, ')
          ..write('hangul: $hangul, ')
          ..write('hanViet: $hanViet, ')
          ..write('englishDef: $englishDef, ')
          ..write('etymologyStory: $etymologyStory, ')
          ..write('decomposition: $decomposition, ')
          ..write('radical: $radical, ')
          ..write('hskLevel: $hskLevel, ')
          ..write('jpOnyomi: $jpOnyomi, ')
          ..write('strokeCount: $strokeCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ComponentsTable extends Components
    with TableInfo<$ComponentsTable, Component> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComponentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinyinMeta = const VerificationMeta('pinyin');
  @override
  late final GeneratedColumn<String> pinyin = GeneratedColumn<String>(
    'pinyin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hanVietMeta = const VerificationMeta(
    'hanViet',
  );
  @override
  late final GeneratedColumn<String> hanViet = GeneratedColumn<String>(
    'han_viet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _englishDefMeta = const VerificationMeta(
    'englishDef',
  );
  @override
  late final GeneratedColumn<String> englishDef = GeneratedColumn<String>(
    'english_def',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _strokeCountMeta = const VerificationMeta(
    'strokeCount',
  );
  @override
  late final GeneratedColumn<int> strokeCount = GeneratedColumn<int>(
    'stroke_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    symbol,
    pinyin,
    hanViet,
    englishDef,
    strokeCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'components';
  @override
  VerificationContext validateIntegrity(
    Insertable<Component> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('pinyin')) {
      context.handle(
        _pinyinMeta,
        pinyin.isAcceptableOrUnknown(data['pinyin']!, _pinyinMeta),
      );
    } else if (isInserting) {
      context.missing(_pinyinMeta);
    }
    if (data.containsKey('han_viet')) {
      context.handle(
        _hanVietMeta,
        hanViet.isAcceptableOrUnknown(data['han_viet']!, _hanVietMeta),
      );
    }
    if (data.containsKey('english_def')) {
      context.handle(
        _englishDefMeta,
        englishDef.isAcceptableOrUnknown(data['english_def']!, _englishDefMeta),
      );
    }
    if (data.containsKey('stroke_count')) {
      context.handle(
        _strokeCountMeta,
        strokeCount.isAcceptableOrUnknown(
          data['stroke_count']!,
          _strokeCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Component map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Component(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      pinyin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinyin'],
      )!,
      hanViet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}han_viet'],
      )!,
      englishDef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_def'],
      )!,
      strokeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stroke_count'],
      )!,
    );
  }

  @override
  $ComponentsTable createAlias(String alias) {
    return $ComponentsTable(attachedDatabase, alias);
  }
}

class Component extends DataClass implements Insertable<Component> {
  final String id;
  final String symbol;
  final String pinyin;
  final String hanViet;
  final String englishDef;
  final int strokeCount;
  const Component({
    required this.id,
    required this.symbol,
    required this.pinyin,
    required this.hanViet,
    required this.englishDef,
    required this.strokeCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['symbol'] = Variable<String>(symbol);
    map['pinyin'] = Variable<String>(pinyin);
    map['han_viet'] = Variable<String>(hanViet);
    map['english_def'] = Variable<String>(englishDef);
    map['stroke_count'] = Variable<int>(strokeCount);
    return map;
  }

  ComponentsCompanion toCompanion(bool nullToAbsent) {
    return ComponentsCompanion(
      id: Value(id),
      symbol: Value(symbol),
      pinyin: Value(pinyin),
      hanViet: Value(hanViet),
      englishDef: Value(englishDef),
      strokeCount: Value(strokeCount),
    );
  }

  factory Component.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Component(
      id: serializer.fromJson<String>(json['id']),
      symbol: serializer.fromJson<String>(json['symbol']),
      pinyin: serializer.fromJson<String>(json['pinyin']),
      hanViet: serializer.fromJson<String>(json['hanViet']),
      englishDef: serializer.fromJson<String>(json['englishDef']),
      strokeCount: serializer.fromJson<int>(json['strokeCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'symbol': serializer.toJson<String>(symbol),
      'pinyin': serializer.toJson<String>(pinyin),
      'hanViet': serializer.toJson<String>(hanViet),
      'englishDef': serializer.toJson<String>(englishDef),
      'strokeCount': serializer.toJson<int>(strokeCount),
    };
  }

  Component copyWith({
    String? id,
    String? symbol,
    String? pinyin,
    String? hanViet,
    String? englishDef,
    int? strokeCount,
  }) => Component(
    id: id ?? this.id,
    symbol: symbol ?? this.symbol,
    pinyin: pinyin ?? this.pinyin,
    hanViet: hanViet ?? this.hanViet,
    englishDef: englishDef ?? this.englishDef,
    strokeCount: strokeCount ?? this.strokeCount,
  );
  Component copyWithCompanion(ComponentsCompanion data) {
    return Component(
      id: data.id.present ? data.id.value : this.id,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      pinyin: data.pinyin.present ? data.pinyin.value : this.pinyin,
      hanViet: data.hanViet.present ? data.hanViet.value : this.hanViet,
      englishDef: data.englishDef.present
          ? data.englishDef.value
          : this.englishDef,
      strokeCount: data.strokeCount.present
          ? data.strokeCount.value
          : this.strokeCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Component(')
          ..write('id: $id, ')
          ..write('symbol: $symbol, ')
          ..write('pinyin: $pinyin, ')
          ..write('hanViet: $hanViet, ')
          ..write('englishDef: $englishDef, ')
          ..write('strokeCount: $strokeCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, symbol, pinyin, hanViet, englishDef, strokeCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Component &&
          other.id == this.id &&
          other.symbol == this.symbol &&
          other.pinyin == this.pinyin &&
          other.hanViet == this.hanViet &&
          other.englishDef == this.englishDef &&
          other.strokeCount == this.strokeCount);
}

class ComponentsCompanion extends UpdateCompanion<Component> {
  final Value<String> id;
  final Value<String> symbol;
  final Value<String> pinyin;
  final Value<String> hanViet;
  final Value<String> englishDef;
  final Value<int> strokeCount;
  final Value<int> rowid;
  const ComponentsCompanion({
    this.id = const Value.absent(),
    this.symbol = const Value.absent(),
    this.pinyin = const Value.absent(),
    this.hanViet = const Value.absent(),
    this.englishDef = const Value.absent(),
    this.strokeCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComponentsCompanion.insert({
    required String id,
    required String symbol,
    required String pinyin,
    this.hanViet = const Value.absent(),
    this.englishDef = const Value.absent(),
    this.strokeCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       symbol = Value(symbol),
       pinyin = Value(pinyin);
  static Insertable<Component> custom({
    Expression<String>? id,
    Expression<String>? symbol,
    Expression<String>? pinyin,
    Expression<String>? hanViet,
    Expression<String>? englishDef,
    Expression<int>? strokeCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (symbol != null) 'symbol': symbol,
      if (pinyin != null) 'pinyin': pinyin,
      if (hanViet != null) 'han_viet': hanViet,
      if (englishDef != null) 'english_def': englishDef,
      if (strokeCount != null) 'stroke_count': strokeCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComponentsCompanion copyWith({
    Value<String>? id,
    Value<String>? symbol,
    Value<String>? pinyin,
    Value<String>? hanViet,
    Value<String>? englishDef,
    Value<int>? strokeCount,
    Value<int>? rowid,
  }) {
    return ComponentsCompanion(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      pinyin: pinyin ?? this.pinyin,
      hanViet: hanViet ?? this.hanViet,
      englishDef: englishDef ?? this.englishDef,
      strokeCount: strokeCount ?? this.strokeCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (pinyin.present) {
      map['pinyin'] = Variable<String>(pinyin.value);
    }
    if (hanViet.present) {
      map['han_viet'] = Variable<String>(hanViet.value);
    }
    if (englishDef.present) {
      map['english_def'] = Variable<String>(englishDef.value);
    }
    if (strokeCount.present) {
      map['stroke_count'] = Variable<int>(strokeCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComponentsCompanion(')
          ..write('id: $id, ')
          ..write('symbol: $symbol, ')
          ..write('pinyin: $pinyin, ')
          ..write('hanViet: $hanViet, ')
          ..write('englishDef: $englishDef, ')
          ..write('strokeCount: $strokeCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterComponentsTable extends CharacterComponents
    with TableInfo<$CharacterComponentsTable, CharacterComponent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterComponentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _componentIdMeta = const VerificationMeta(
    'componentId',
  );
  @override
  late final GeneratedColumn<String> componentId = GeneratedColumn<String>(
    'component_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES components (id)',
    ),
  );
  static const VerificationMeta _componentTypeMeta = const VerificationMeta(
    'componentType',
  );
  @override
  late final GeneratedColumn<String> componentType = GeneratedColumn<String>(
    'component_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    characterId,
    componentId,
    componentType,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_components';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterComponent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('component_id')) {
      context.handle(
        _componentIdMeta,
        componentId.isAcceptableOrUnknown(
          data['component_id']!,
          _componentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_componentIdMeta);
    }
    if (data.containsKey('component_type')) {
      context.handle(
        _componentTypeMeta,
        componentType.isAcceptableOrUnknown(
          data['component_type']!,
          _componentTypeMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {characterId, componentId};
  @override
  CharacterComponent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterComponent(
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      componentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_id'],
      )!,
      componentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_type'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CharacterComponentsTable createAlias(String alias) {
    return $CharacterComponentsTable(attachedDatabase, alias);
  }
}

class CharacterComponent extends DataClass
    implements Insertable<CharacterComponent> {
  final String characterId;
  final String componentId;
  final String? componentType;
  final int position;
  const CharacterComponent({
    required this.characterId,
    required this.componentId,
    this.componentType,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character_id'] = Variable<String>(characterId);
    map['component_id'] = Variable<String>(componentId);
    if (!nullToAbsent || componentType != null) {
      map['component_type'] = Variable<String>(componentType);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  CharacterComponentsCompanion toCompanion(bool nullToAbsent) {
    return CharacterComponentsCompanion(
      characterId: Value(characterId),
      componentId: Value(componentId),
      componentType: componentType == null && nullToAbsent
          ? const Value.absent()
          : Value(componentType),
      position: Value(position),
    );
  }

  factory CharacterComponent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterComponent(
      characterId: serializer.fromJson<String>(json['characterId']),
      componentId: serializer.fromJson<String>(json['componentId']),
      componentType: serializer.fromJson<String?>(json['componentType']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'characterId': serializer.toJson<String>(characterId),
      'componentId': serializer.toJson<String>(componentId),
      'componentType': serializer.toJson<String?>(componentType),
      'position': serializer.toJson<int>(position),
    };
  }

  CharacterComponent copyWith({
    String? characterId,
    String? componentId,
    Value<String?> componentType = const Value.absent(),
    int? position,
  }) => CharacterComponent(
    characterId: characterId ?? this.characterId,
    componentId: componentId ?? this.componentId,
    componentType: componentType.present
        ? componentType.value
        : this.componentType,
    position: position ?? this.position,
  );
  CharacterComponent copyWithCompanion(CharacterComponentsCompanion data) {
    return CharacterComponent(
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      componentId: data.componentId.present
          ? data.componentId.value
          : this.componentId,
      componentType: data.componentType.present
          ? data.componentType.value
          : this.componentType,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterComponent(')
          ..write('characterId: $characterId, ')
          ..write('componentId: $componentId, ')
          ..write('componentType: $componentType, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(characterId, componentId, componentType, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterComponent &&
          other.characterId == this.characterId &&
          other.componentId == this.componentId &&
          other.componentType == this.componentType &&
          other.position == this.position);
}

class CharacterComponentsCompanion extends UpdateCompanion<CharacterComponent> {
  final Value<String> characterId;
  final Value<String> componentId;
  final Value<String?> componentType;
  final Value<int> position;
  final Value<int> rowid;
  const CharacterComponentsCompanion({
    this.characterId = const Value.absent(),
    this.componentId = const Value.absent(),
    this.componentType = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterComponentsCompanion.insert({
    required String characterId,
    required String componentId,
    this.componentType = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : characterId = Value(characterId),
       componentId = Value(componentId);
  static Insertable<CharacterComponent> custom({
    Expression<String>? characterId,
    Expression<String>? componentId,
    Expression<String>? componentType,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (characterId != null) 'character_id': characterId,
      if (componentId != null) 'component_id': componentId,
      if (componentType != null) 'component_type': componentType,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterComponentsCompanion copyWith({
    Value<String>? characterId,
    Value<String>? componentId,
    Value<String?>? componentType,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CharacterComponentsCompanion(
      characterId: characterId ?? this.characterId,
      componentId: componentId ?? this.componentId,
      componentType: componentType ?? this.componentType,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (componentId.present) {
      map['component_id'] = Variable<String>(componentId.value);
    }
    if (componentType.present) {
      map['component_type'] = Variable<String>(componentType.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterComponentsCompanion(')
          ..write('characterId: $characterId, ')
          ..write('componentId: $componentId, ')
          ..write('componentType: $componentType, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompoundWordsTable extends CompoundWords
    with TableInfo<$CompoundWordsTable, CompoundWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompoundWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _simplifiedMeta = const VerificationMeta(
    'simplified',
  );
  @override
  late final GeneratedColumn<String> simplified = GeneratedColumn<String>(
    'simplified',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _traditionalMeta = const VerificationMeta(
    'traditional',
  );
  @override
  late final GeneratedColumn<String> traditional = GeneratedColumn<String>(
    'traditional',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinyinMeta = const VerificationMeta('pinyin');
  @override
  late final GeneratedColumn<String> pinyin = GeneratedColumn<String>(
    'pinyin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hangulMeta = const VerificationMeta('hangul');
  @override
  late final GeneratedColumn<String> hangul = GeneratedColumn<String>(
    'hangul',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hanVietMeta = const VerificationMeta(
    'hanViet',
  );
  @override
  late final GeneratedColumn<String> hanViet = GeneratedColumn<String>(
    'han_viet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hanVietResonanceMeta = const VerificationMeta(
    'hanVietResonance',
  );
  @override
  late final GeneratedColumn<String> hanVietResonance = GeneratedColumn<String>(
    'han_viet_resonance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _vietnameseNoteMeta = const VerificationMeta(
    'vietnameseNote',
  );
  @override
  late final GeneratedColumn<String> vietnameseNote = GeneratedColumn<String>(
    'vietnamese_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _englishDefMeta = const VerificationMeta(
    'englishDef',
  );
  @override
  late final GeneratedColumn<String> englishDef = GeneratedColumn<String>(
    'english_def',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hskLevelMeta = const VerificationMeta(
    'hskLevel',
  );
  @override
  late final GeneratedColumn<int> hskLevel = GeneratedColumn<int>(
    'hsk_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyRankMeta = const VerificationMeta(
    'frequencyRank',
  );
  @override
  late final GeneratedColumn<int> frequencyRank = GeneratedColumn<int>(
    'frequency_rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originTypeMeta = const VerificationMeta(
    'originType',
  );
  @override
  late final GeneratedColumn<String> originType = GeneratedColumn<String>(
    'origin_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sino_chinese'),
  );
  static const VerificationMeta _isCognateAnchorMeta = const VerificationMeta(
    'isCognateAnchor',
  );
  @override
  late final GeneratedColumn<int> isCognateAnchor = GeneratedColumn<int>(
    'is_cognate_anchor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _aiGeneratedMeta = const VerificationMeta(
    'aiGenerated',
  );
  @override
  late final GeneratedColumn<int> aiGenerated = GeneratedColumn<int>(
    'ai_generated',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    simplified,
    traditional,
    pinyin,
    hangul,
    hanViet,
    hanVietResonance,
    vietnameseNote,
    englishDef,
    hskLevel,
    frequencyRank,
    originType,
    isCognateAnchor,
    aiGenerated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'compound_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompoundWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('simplified')) {
      context.handle(
        _simplifiedMeta,
        simplified.isAcceptableOrUnknown(data['simplified']!, _simplifiedMeta),
      );
    } else if (isInserting) {
      context.missing(_simplifiedMeta);
    }
    if (data.containsKey('traditional')) {
      context.handle(
        _traditionalMeta,
        traditional.isAcceptableOrUnknown(
          data['traditional']!,
          _traditionalMeta,
        ),
      );
    }
    if (data.containsKey('pinyin')) {
      context.handle(
        _pinyinMeta,
        pinyin.isAcceptableOrUnknown(data['pinyin']!, _pinyinMeta),
      );
    } else if (isInserting) {
      context.missing(_pinyinMeta);
    }
    if (data.containsKey('hangul')) {
      context.handle(
        _hangulMeta,
        hangul.isAcceptableOrUnknown(data['hangul']!, _hangulMeta),
      );
    }
    if (data.containsKey('han_viet')) {
      context.handle(
        _hanVietMeta,
        hanViet.isAcceptableOrUnknown(data['han_viet']!, _hanVietMeta),
      );
    }
    if (data.containsKey('han_viet_resonance')) {
      context.handle(
        _hanVietResonanceMeta,
        hanVietResonance.isAcceptableOrUnknown(
          data['han_viet_resonance']!,
          _hanVietResonanceMeta,
        ),
      );
    }
    if (data.containsKey('vietnamese_note')) {
      context.handle(
        _vietnameseNoteMeta,
        vietnameseNote.isAcceptableOrUnknown(
          data['vietnamese_note']!,
          _vietnameseNoteMeta,
        ),
      );
    }
    if (data.containsKey('english_def')) {
      context.handle(
        _englishDefMeta,
        englishDef.isAcceptableOrUnknown(data['english_def']!, _englishDefMeta),
      );
    }
    if (data.containsKey('hsk_level')) {
      context.handle(
        _hskLevelMeta,
        hskLevel.isAcceptableOrUnknown(data['hsk_level']!, _hskLevelMeta),
      );
    }
    if (data.containsKey('frequency_rank')) {
      context.handle(
        _frequencyRankMeta,
        frequencyRank.isAcceptableOrUnknown(
          data['frequency_rank']!,
          _frequencyRankMeta,
        ),
      );
    }
    if (data.containsKey('origin_type')) {
      context.handle(
        _originTypeMeta,
        originType.isAcceptableOrUnknown(data['origin_type']!, _originTypeMeta),
      );
    }
    if (data.containsKey('is_cognate_anchor')) {
      context.handle(
        _isCognateAnchorMeta,
        isCognateAnchor.isAcceptableOrUnknown(
          data['is_cognate_anchor']!,
          _isCognateAnchorMeta,
        ),
      );
    }
    if (data.containsKey('ai_generated')) {
      context.handle(
        _aiGeneratedMeta,
        aiGenerated.isAcceptableOrUnknown(
          data['ai_generated']!,
          _aiGeneratedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompoundWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompoundWord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      simplified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}simplified'],
      )!,
      traditional: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}traditional'],
      ),
      pinyin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinyin'],
      )!,
      hangul: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hangul'],
      ),
      hanViet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}han_viet'],
      )!,
      hanVietResonance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}han_viet_resonance'],
      )!,
      vietnameseNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vietnamese_note'],
      ),
      englishDef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_def'],
      )!,
      hskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hsk_level'],
      ),
      frequencyRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frequency_rank'],
      ),
      originType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_type'],
      )!,
      isCognateAnchor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_cognate_anchor'],
      )!,
      aiGenerated: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ai_generated'],
      )!,
    );
  }

  @override
  $CompoundWordsTable createAlias(String alias) {
    return $CompoundWordsTable(attachedDatabase, alias);
  }
}

class CompoundWord extends DataClass implements Insertable<CompoundWord> {
  final String id;
  final String simplified;
  final String? traditional;
  final String pinyin;
  final String? hangul;
  final String hanViet;
  final String hanVietResonance;
  final String? vietnameseNote;
  final String englishDef;
  final int? hskLevel;
  final int? frequencyRank;
  final String originType;
  final int isCognateAnchor;
  final int aiGenerated;
  const CompoundWord({
    required this.id,
    required this.simplified,
    this.traditional,
    required this.pinyin,
    this.hangul,
    required this.hanViet,
    required this.hanVietResonance,
    this.vietnameseNote,
    required this.englishDef,
    this.hskLevel,
    this.frequencyRank,
    required this.originType,
    required this.isCognateAnchor,
    required this.aiGenerated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['simplified'] = Variable<String>(simplified);
    if (!nullToAbsent || traditional != null) {
      map['traditional'] = Variable<String>(traditional);
    }
    map['pinyin'] = Variable<String>(pinyin);
    if (!nullToAbsent || hangul != null) {
      map['hangul'] = Variable<String>(hangul);
    }
    map['han_viet'] = Variable<String>(hanViet);
    map['han_viet_resonance'] = Variable<String>(hanVietResonance);
    if (!nullToAbsent || vietnameseNote != null) {
      map['vietnamese_note'] = Variable<String>(vietnameseNote);
    }
    map['english_def'] = Variable<String>(englishDef);
    if (!nullToAbsent || hskLevel != null) {
      map['hsk_level'] = Variable<int>(hskLevel);
    }
    if (!nullToAbsent || frequencyRank != null) {
      map['frequency_rank'] = Variable<int>(frequencyRank);
    }
    map['origin_type'] = Variable<String>(originType);
    map['is_cognate_anchor'] = Variable<int>(isCognateAnchor);
    map['ai_generated'] = Variable<int>(aiGenerated);
    return map;
  }

  CompoundWordsCompanion toCompanion(bool nullToAbsent) {
    return CompoundWordsCompanion(
      id: Value(id),
      simplified: Value(simplified),
      traditional: traditional == null && nullToAbsent
          ? const Value.absent()
          : Value(traditional),
      pinyin: Value(pinyin),
      hangul: hangul == null && nullToAbsent
          ? const Value.absent()
          : Value(hangul),
      hanViet: Value(hanViet),
      hanVietResonance: Value(hanVietResonance),
      vietnameseNote: vietnameseNote == null && nullToAbsent
          ? const Value.absent()
          : Value(vietnameseNote),
      englishDef: Value(englishDef),
      hskLevel: hskLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(hskLevel),
      frequencyRank: frequencyRank == null && nullToAbsent
          ? const Value.absent()
          : Value(frequencyRank),
      originType: Value(originType),
      isCognateAnchor: Value(isCognateAnchor),
      aiGenerated: Value(aiGenerated),
    );
  }

  factory CompoundWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompoundWord(
      id: serializer.fromJson<String>(json['id']),
      simplified: serializer.fromJson<String>(json['simplified']),
      traditional: serializer.fromJson<String?>(json['traditional']),
      pinyin: serializer.fromJson<String>(json['pinyin']),
      hangul: serializer.fromJson<String?>(json['hangul']),
      hanViet: serializer.fromJson<String>(json['hanViet']),
      hanVietResonance: serializer.fromJson<String>(json['hanVietResonance']),
      vietnameseNote: serializer.fromJson<String?>(json['vietnameseNote']),
      englishDef: serializer.fromJson<String>(json['englishDef']),
      hskLevel: serializer.fromJson<int?>(json['hskLevel']),
      frequencyRank: serializer.fromJson<int?>(json['frequencyRank']),
      originType: serializer.fromJson<String>(json['originType']),
      isCognateAnchor: serializer.fromJson<int>(json['isCognateAnchor']),
      aiGenerated: serializer.fromJson<int>(json['aiGenerated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'simplified': serializer.toJson<String>(simplified),
      'traditional': serializer.toJson<String?>(traditional),
      'pinyin': serializer.toJson<String>(pinyin),
      'hangul': serializer.toJson<String?>(hangul),
      'hanViet': serializer.toJson<String>(hanViet),
      'hanVietResonance': serializer.toJson<String>(hanVietResonance),
      'vietnameseNote': serializer.toJson<String?>(vietnameseNote),
      'englishDef': serializer.toJson<String>(englishDef),
      'hskLevel': serializer.toJson<int?>(hskLevel),
      'frequencyRank': serializer.toJson<int?>(frequencyRank),
      'originType': serializer.toJson<String>(originType),
      'isCognateAnchor': serializer.toJson<int>(isCognateAnchor),
      'aiGenerated': serializer.toJson<int>(aiGenerated),
    };
  }

  CompoundWord copyWith({
    String? id,
    String? simplified,
    Value<String?> traditional = const Value.absent(),
    String? pinyin,
    Value<String?> hangul = const Value.absent(),
    String? hanViet,
    String? hanVietResonance,
    Value<String?> vietnameseNote = const Value.absent(),
    String? englishDef,
    Value<int?> hskLevel = const Value.absent(),
    Value<int?> frequencyRank = const Value.absent(),
    String? originType,
    int? isCognateAnchor,
    int? aiGenerated,
  }) => CompoundWord(
    id: id ?? this.id,
    simplified: simplified ?? this.simplified,
    traditional: traditional.present ? traditional.value : this.traditional,
    pinyin: pinyin ?? this.pinyin,
    hangul: hangul.present ? hangul.value : this.hangul,
    hanViet: hanViet ?? this.hanViet,
    hanVietResonance: hanVietResonance ?? this.hanVietResonance,
    vietnameseNote: vietnameseNote.present
        ? vietnameseNote.value
        : this.vietnameseNote,
    englishDef: englishDef ?? this.englishDef,
    hskLevel: hskLevel.present ? hskLevel.value : this.hskLevel,
    frequencyRank: frequencyRank.present
        ? frequencyRank.value
        : this.frequencyRank,
    originType: originType ?? this.originType,
    isCognateAnchor: isCognateAnchor ?? this.isCognateAnchor,
    aiGenerated: aiGenerated ?? this.aiGenerated,
  );
  CompoundWord copyWithCompanion(CompoundWordsCompanion data) {
    return CompoundWord(
      id: data.id.present ? data.id.value : this.id,
      simplified: data.simplified.present
          ? data.simplified.value
          : this.simplified,
      traditional: data.traditional.present
          ? data.traditional.value
          : this.traditional,
      pinyin: data.pinyin.present ? data.pinyin.value : this.pinyin,
      hangul: data.hangul.present ? data.hangul.value : this.hangul,
      hanViet: data.hanViet.present ? data.hanViet.value : this.hanViet,
      hanVietResonance: data.hanVietResonance.present
          ? data.hanVietResonance.value
          : this.hanVietResonance,
      vietnameseNote: data.vietnameseNote.present
          ? data.vietnameseNote.value
          : this.vietnameseNote,
      englishDef: data.englishDef.present
          ? data.englishDef.value
          : this.englishDef,
      hskLevel: data.hskLevel.present ? data.hskLevel.value : this.hskLevel,
      frequencyRank: data.frequencyRank.present
          ? data.frequencyRank.value
          : this.frequencyRank,
      originType: data.originType.present
          ? data.originType.value
          : this.originType,
      isCognateAnchor: data.isCognateAnchor.present
          ? data.isCognateAnchor.value
          : this.isCognateAnchor,
      aiGenerated: data.aiGenerated.present
          ? data.aiGenerated.value
          : this.aiGenerated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompoundWord(')
          ..write('id: $id, ')
          ..write('simplified: $simplified, ')
          ..write('traditional: $traditional, ')
          ..write('pinyin: $pinyin, ')
          ..write('hangul: $hangul, ')
          ..write('hanViet: $hanViet, ')
          ..write('hanVietResonance: $hanVietResonance, ')
          ..write('vietnameseNote: $vietnameseNote, ')
          ..write('englishDef: $englishDef, ')
          ..write('hskLevel: $hskLevel, ')
          ..write('frequencyRank: $frequencyRank, ')
          ..write('originType: $originType, ')
          ..write('isCognateAnchor: $isCognateAnchor, ')
          ..write('aiGenerated: $aiGenerated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    simplified,
    traditional,
    pinyin,
    hangul,
    hanViet,
    hanVietResonance,
    vietnameseNote,
    englishDef,
    hskLevel,
    frequencyRank,
    originType,
    isCognateAnchor,
    aiGenerated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompoundWord &&
          other.id == this.id &&
          other.simplified == this.simplified &&
          other.traditional == this.traditional &&
          other.pinyin == this.pinyin &&
          other.hangul == this.hangul &&
          other.hanViet == this.hanViet &&
          other.hanVietResonance == this.hanVietResonance &&
          other.vietnameseNote == this.vietnameseNote &&
          other.englishDef == this.englishDef &&
          other.hskLevel == this.hskLevel &&
          other.frequencyRank == this.frequencyRank &&
          other.originType == this.originType &&
          other.isCognateAnchor == this.isCognateAnchor &&
          other.aiGenerated == this.aiGenerated);
}

class CompoundWordsCompanion extends UpdateCompanion<CompoundWord> {
  final Value<String> id;
  final Value<String> simplified;
  final Value<String?> traditional;
  final Value<String> pinyin;
  final Value<String?> hangul;
  final Value<String> hanViet;
  final Value<String> hanVietResonance;
  final Value<String?> vietnameseNote;
  final Value<String> englishDef;
  final Value<int?> hskLevel;
  final Value<int?> frequencyRank;
  final Value<String> originType;
  final Value<int> isCognateAnchor;
  final Value<int> aiGenerated;
  final Value<int> rowid;
  const CompoundWordsCompanion({
    this.id = const Value.absent(),
    this.simplified = const Value.absent(),
    this.traditional = const Value.absent(),
    this.pinyin = const Value.absent(),
    this.hangul = const Value.absent(),
    this.hanViet = const Value.absent(),
    this.hanVietResonance = const Value.absent(),
    this.vietnameseNote = const Value.absent(),
    this.englishDef = const Value.absent(),
    this.hskLevel = const Value.absent(),
    this.frequencyRank = const Value.absent(),
    this.originType = const Value.absent(),
    this.isCognateAnchor = const Value.absent(),
    this.aiGenerated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompoundWordsCompanion.insert({
    required String id,
    required String simplified,
    this.traditional = const Value.absent(),
    required String pinyin,
    this.hangul = const Value.absent(),
    this.hanViet = const Value.absent(),
    this.hanVietResonance = const Value.absent(),
    this.vietnameseNote = const Value.absent(),
    this.englishDef = const Value.absent(),
    this.hskLevel = const Value.absent(),
    this.frequencyRank = const Value.absent(),
    this.originType = const Value.absent(),
    this.isCognateAnchor = const Value.absent(),
    this.aiGenerated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       simplified = Value(simplified),
       pinyin = Value(pinyin);
  static Insertable<CompoundWord> custom({
    Expression<String>? id,
    Expression<String>? simplified,
    Expression<String>? traditional,
    Expression<String>? pinyin,
    Expression<String>? hangul,
    Expression<String>? hanViet,
    Expression<String>? hanVietResonance,
    Expression<String>? vietnameseNote,
    Expression<String>? englishDef,
    Expression<int>? hskLevel,
    Expression<int>? frequencyRank,
    Expression<String>? originType,
    Expression<int>? isCognateAnchor,
    Expression<int>? aiGenerated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (simplified != null) 'simplified': simplified,
      if (traditional != null) 'traditional': traditional,
      if (pinyin != null) 'pinyin': pinyin,
      if (hangul != null) 'hangul': hangul,
      if (hanViet != null) 'han_viet': hanViet,
      if (hanVietResonance != null) 'han_viet_resonance': hanVietResonance,
      if (vietnameseNote != null) 'vietnamese_note': vietnameseNote,
      if (englishDef != null) 'english_def': englishDef,
      if (hskLevel != null) 'hsk_level': hskLevel,
      if (frequencyRank != null) 'frequency_rank': frequencyRank,
      if (originType != null) 'origin_type': originType,
      if (isCognateAnchor != null) 'is_cognate_anchor': isCognateAnchor,
      if (aiGenerated != null) 'ai_generated': aiGenerated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompoundWordsCompanion copyWith({
    Value<String>? id,
    Value<String>? simplified,
    Value<String?>? traditional,
    Value<String>? pinyin,
    Value<String?>? hangul,
    Value<String>? hanViet,
    Value<String>? hanVietResonance,
    Value<String?>? vietnameseNote,
    Value<String>? englishDef,
    Value<int?>? hskLevel,
    Value<int?>? frequencyRank,
    Value<String>? originType,
    Value<int>? isCognateAnchor,
    Value<int>? aiGenerated,
    Value<int>? rowid,
  }) {
    return CompoundWordsCompanion(
      id: id ?? this.id,
      simplified: simplified ?? this.simplified,
      traditional: traditional ?? this.traditional,
      pinyin: pinyin ?? this.pinyin,
      hangul: hangul ?? this.hangul,
      hanViet: hanViet ?? this.hanViet,
      hanVietResonance: hanVietResonance ?? this.hanVietResonance,
      vietnameseNote: vietnameseNote ?? this.vietnameseNote,
      englishDef: englishDef ?? this.englishDef,
      hskLevel: hskLevel ?? this.hskLevel,
      frequencyRank: frequencyRank ?? this.frequencyRank,
      originType: originType ?? this.originType,
      isCognateAnchor: isCognateAnchor ?? this.isCognateAnchor,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (simplified.present) {
      map['simplified'] = Variable<String>(simplified.value);
    }
    if (traditional.present) {
      map['traditional'] = Variable<String>(traditional.value);
    }
    if (pinyin.present) {
      map['pinyin'] = Variable<String>(pinyin.value);
    }
    if (hangul.present) {
      map['hangul'] = Variable<String>(hangul.value);
    }
    if (hanViet.present) {
      map['han_viet'] = Variable<String>(hanViet.value);
    }
    if (hanVietResonance.present) {
      map['han_viet_resonance'] = Variable<String>(hanVietResonance.value);
    }
    if (vietnameseNote.present) {
      map['vietnamese_note'] = Variable<String>(vietnameseNote.value);
    }
    if (englishDef.present) {
      map['english_def'] = Variable<String>(englishDef.value);
    }
    if (hskLevel.present) {
      map['hsk_level'] = Variable<int>(hskLevel.value);
    }
    if (frequencyRank.present) {
      map['frequency_rank'] = Variable<int>(frequencyRank.value);
    }
    if (originType.present) {
      map['origin_type'] = Variable<String>(originType.value);
    }
    if (isCognateAnchor.present) {
      map['is_cognate_anchor'] = Variable<int>(isCognateAnchor.value);
    }
    if (aiGenerated.present) {
      map['ai_generated'] = Variable<int>(aiGenerated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompoundWordsCompanion(')
          ..write('id: $id, ')
          ..write('simplified: $simplified, ')
          ..write('traditional: $traditional, ')
          ..write('pinyin: $pinyin, ')
          ..write('hangul: $hangul, ')
          ..write('hanViet: $hanViet, ')
          ..write('hanVietResonance: $hanVietResonance, ')
          ..write('vietnameseNote: $vietnameseNote, ')
          ..write('englishDef: $englishDef, ')
          ..write('hskLevel: $hskLevel, ')
          ..write('frequencyRank: $frequencyRank, ')
          ..write('originType: $originType, ')
          ..write('isCognateAnchor: $isCognateAnchor, ')
          ..write('aiGenerated: $aiGenerated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordCharactersTable extends WordCharacters
    with TableInfo<$WordCharactersTable, WordCharacter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordCharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES compound_words (id)',
    ),
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [wordId, characterId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordCharacter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId, characterId, position};
  @override
  WordCharacter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordCharacter(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $WordCharactersTable createAlias(String alias) {
    return $WordCharactersTable(attachedDatabase, alias);
  }
}

class WordCharacter extends DataClass implements Insertable<WordCharacter> {
  final String wordId;
  final String characterId;
  final int position;
  const WordCharacter({
    required this.wordId,
    required this.characterId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<String>(wordId);
    map['character_id'] = Variable<String>(characterId);
    map['position'] = Variable<int>(position);
    return map;
  }

  WordCharactersCompanion toCompanion(bool nullToAbsent) {
    return WordCharactersCompanion(
      wordId: Value(wordId),
      characterId: Value(characterId),
      position: Value(position),
    );
  }

  factory WordCharacter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordCharacter(
      wordId: serializer.fromJson<String>(json['wordId']),
      characterId: serializer.fromJson<String>(json['characterId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<String>(wordId),
      'characterId': serializer.toJson<String>(characterId),
      'position': serializer.toJson<int>(position),
    };
  }

  WordCharacter copyWith({
    String? wordId,
    String? characterId,
    int? position,
  }) => WordCharacter(
    wordId: wordId ?? this.wordId,
    characterId: characterId ?? this.characterId,
    position: position ?? this.position,
  );
  WordCharacter copyWithCompanion(WordCharactersCompanion data) {
    return WordCharacter(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordCharacter(')
          ..write('wordId: $wordId, ')
          ..write('characterId: $characterId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, characterId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordCharacter &&
          other.wordId == this.wordId &&
          other.characterId == this.characterId &&
          other.position == this.position);
}

class WordCharactersCompanion extends UpdateCompanion<WordCharacter> {
  final Value<String> wordId;
  final Value<String> characterId;
  final Value<int> position;
  final Value<int> rowid;
  const WordCharactersCompanion({
    this.wordId = const Value.absent(),
    this.characterId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordCharactersCompanion.insert({
    required String wordId,
    required String characterId,
    required int position,
    this.rowid = const Value.absent(),
  }) : wordId = Value(wordId),
       characterId = Value(characterId),
       position = Value(position);
  static Insertable<WordCharacter> custom({
    Expression<String>? wordId,
    Expression<String>? characterId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (characterId != null) 'character_id': characterId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordCharactersCompanion copyWith({
    Value<String>? wordId,
    Value<String>? characterId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return WordCharactersCompanion(
      wordId: wordId ?? this.wordId,
      characterId: characterId ?? this.characterId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordCharactersCompanion(')
          ..write('wordId: $wordId, ')
          ..write('characterId: $characterId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserCollectionsTable extends UserCollections
    with TableInfo<$UserCollectionsTable, UserCollection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, icon, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserCollection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserCollection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserCollection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserCollectionsTable createAlias(String alias) {
    return $UserCollectionsTable(attachedDatabase, alias);
  }
}

class UserCollection extends DataClass implements Insertable<UserCollection> {
  final String id;
  final String name;
  final String? icon;
  final int createdAt;
  const UserCollection({
    required this.id,
    required this.name,
    this.icon,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  UserCollectionsCompanion toCompanion(bool nullToAbsent) {
    return UserCollectionsCompanion(
      id: Value(id),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      createdAt: Value(createdAt),
    );
  }

  factory UserCollection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserCollection(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  UserCollection copyWith({
    String? id,
    String? name,
    Value<String?> icon = const Value.absent(),
    int? createdAt,
  }) => UserCollection(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    createdAt: createdAt ?? this.createdAt,
  );
  UserCollection copyWithCompanion(UserCollectionsCompanion data) {
    return UserCollection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserCollection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserCollection &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.createdAt == this.createdAt);
}

class UserCollectionsCompanion extends UpdateCompanion<UserCollection> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> icon;
  final Value<int> createdAt;
  final Value<int> rowid;
  const UserCollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserCollectionsCompanion.insert({
    required String id,
    required String name,
    this.icon = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<UserCollection> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserCollectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? icon,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return UserCollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserCollectionWordsTable extends UserCollectionWords
    with TableInfo<$UserCollectionWordsTable, UserCollectionWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCollectionWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES user_collections (id)',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [collectionId, wordId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_collection_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserCollectionWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionId, wordId};
  @override
  UserCollectionWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserCollectionWord(
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $UserCollectionWordsTable createAlias(String alias) {
    return $UserCollectionWordsTable(attachedDatabase, alias);
  }
}

class UserCollectionWord extends DataClass
    implements Insertable<UserCollectionWord> {
  final String collectionId;
  final String wordId;
  final int addedAt;
  const UserCollectionWord({
    required this.collectionId,
    required this.wordId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<String>(collectionId);
    map['word_id'] = Variable<String>(wordId);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  UserCollectionWordsCompanion toCompanion(bool nullToAbsent) {
    return UserCollectionWordsCompanion(
      collectionId: Value(collectionId),
      wordId: Value(wordId),
      addedAt: Value(addedAt),
    );
  }

  factory UserCollectionWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserCollectionWord(
      collectionId: serializer.fromJson<String>(json['collectionId']),
      wordId: serializer.fromJson<String>(json['wordId']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<String>(collectionId),
      'wordId': serializer.toJson<String>(wordId),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  UserCollectionWord copyWith({
    String? collectionId,
    String? wordId,
    int? addedAt,
  }) => UserCollectionWord(
    collectionId: collectionId ?? this.collectionId,
    wordId: wordId ?? this.wordId,
    addedAt: addedAt ?? this.addedAt,
  );
  UserCollectionWord copyWithCompanion(UserCollectionWordsCompanion data) {
    return UserCollectionWord(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserCollectionWord(')
          ..write('collectionId: $collectionId, ')
          ..write('wordId: $wordId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collectionId, wordId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserCollectionWord &&
          other.collectionId == this.collectionId &&
          other.wordId == this.wordId &&
          other.addedAt == this.addedAt);
}

class UserCollectionWordsCompanion extends UpdateCompanion<UserCollectionWord> {
  final Value<String> collectionId;
  final Value<String> wordId;
  final Value<int> addedAt;
  final Value<int> rowid;
  const UserCollectionWordsCompanion({
    this.collectionId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserCollectionWordsCompanion.insert({
    required String collectionId,
    required String wordId,
    required int addedAt,
    this.rowid = const Value.absent(),
  }) : collectionId = Value(collectionId),
       wordId = Value(wordId),
       addedAt = Value(addedAt);
  static Insertable<UserCollectionWord> custom({
    Expression<String>? collectionId,
    Expression<String>? wordId,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (wordId != null) 'word_id': wordId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserCollectionWordsCompanion copyWith({
    Value<String>? collectionId,
    Value<String>? wordId,
    Value<int>? addedAt,
    Value<int>? rowid,
  }) {
    return UserCollectionWordsCompanion(
      collectionId: collectionId ?? this.collectionId,
      wordId: wordId ?? this.wordId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCollectionWordsCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('wordId: $wordId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingHistoryTable extends ReadingHistory
    with TableInfo<$ReadingHistoryTable, ReadingHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokenJsonMeta = const VerificationMeta(
    'tokenJson',
  );
  @override
  late final GeneratedColumn<String> tokenJson = GeneratedColumn<String>(
    'token_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    rawText,
    tokenJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('token_json')) {
      context.handle(
        _tokenJsonMeta,
        tokenJson.isAcceptableOrUnknown(data['token_json']!, _tokenJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      tokenJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReadingHistoryTable createAlias(String alias) {
    return $ReadingHistoryTable(attachedDatabase, alias);
  }
}

class ReadingHistoryData extends DataClass
    implements Insertable<ReadingHistoryData> {
  final String id;
  final String title;
  final String rawText;
  final String tokenJson;
  final int createdAt;
  const ReadingHistoryData({
    required this.id,
    required this.title,
    required this.rawText,
    required this.tokenJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['raw_text'] = Variable<String>(rawText);
    map['token_json'] = Variable<String>(tokenJson);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ReadingHistoryCompanion toCompanion(bool nullToAbsent) {
    return ReadingHistoryCompanion(
      id: Value(id),
      title: Value(title),
      rawText: Value(rawText),
      tokenJson: Value(tokenJson),
      createdAt: Value(createdAt),
    );
  }

  factory ReadingHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingHistoryData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      rawText: serializer.fromJson<String>(json['rawText']),
      tokenJson: serializer.fromJson<String>(json['tokenJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'rawText': serializer.toJson<String>(rawText),
      'tokenJson': serializer.toJson<String>(tokenJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ReadingHistoryData copyWith({
    String? id,
    String? title,
    String? rawText,
    String? tokenJson,
    int? createdAt,
  }) => ReadingHistoryData(
    id: id ?? this.id,
    title: title ?? this.title,
    rawText: rawText ?? this.rawText,
    tokenJson: tokenJson ?? this.tokenJson,
    createdAt: createdAt ?? this.createdAt,
  );
  ReadingHistoryData copyWithCompanion(ReadingHistoryCompanion data) {
    return ReadingHistoryData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      tokenJson: data.tokenJson.present ? data.tokenJson.value : this.tokenJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingHistoryData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('rawText: $rawText, ')
          ..write('tokenJson: $tokenJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, rawText, tokenJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingHistoryData &&
          other.id == this.id &&
          other.title == this.title &&
          other.rawText == this.rawText &&
          other.tokenJson == this.tokenJson &&
          other.createdAt == this.createdAt);
}

class ReadingHistoryCompanion extends UpdateCompanion<ReadingHistoryData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> rawText;
  final Value<String> tokenJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ReadingHistoryCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.rawText = const Value.absent(),
    this.tokenJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingHistoryCompanion.insert({
    required String id,
    required String title,
    required String rawText,
    required String tokenJson,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       rawText = Value(rawText),
       tokenJson = Value(tokenJson),
       createdAt = Value(createdAt);
  static Insertable<ReadingHistoryData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? rawText,
    Expression<String>? tokenJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (rawText != null) 'raw_text': rawText,
      if (tokenJson != null) 'token_json': tokenJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? rawText,
    Value<String>? tokenJson,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return ReadingHistoryCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      rawText: rawText ?? this.rawText,
      tokenJson: tokenJson ?? this.tokenJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (tokenJson.present) {
      map['token_json'] = Variable<String>(tokenJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingHistoryCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('rawText: $rawText, ')
          ..write('tokenJson: $tokenJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiCacheTable extends AiCache with TableInfo<$AiCacheTable, AiCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseJsonMeta = const VerificationMeta(
    'responseJson',
  );
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
    'response_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [query, responseJson, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('response_json')) {
      context.handle(
        _responseJsonMeta,
        responseJson.isAcceptableOrUnknown(
          data['response_json']!,
          _responseJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query};
  @override
  AiCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiCacheData(
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      responseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $AiCacheTable createAlias(String alias) {
    return $AiCacheTable(attachedDatabase, alias);
  }
}

class AiCacheData extends DataClass implements Insertable<AiCacheData> {
  final String query;
  final String responseJson;
  final int cachedAt;
  const AiCacheData({
    required this.query,
    required this.responseJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['response_json'] = Variable<String>(responseJson);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  AiCacheCompanion toCompanion(bool nullToAbsent) {
    return AiCacheCompanion(
      query: Value(query),
      responseJson: Value(responseJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory AiCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiCacheData(
      query: serializer.fromJson<String>(json['query']),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'responseJson': serializer.toJson<String>(responseJson),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  AiCacheData copyWith({String? query, String? responseJson, int? cachedAt}) =>
      AiCacheData(
        query: query ?? this.query,
        responseJson: responseJson ?? this.responseJson,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  AiCacheData copyWithCompanion(AiCacheCompanion data) {
    return AiCacheData(
      query: data.query.present ? data.query.value : this.query,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiCacheData(')
          ..write('query: $query, ')
          ..write('responseJson: $responseJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, responseJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiCacheData &&
          other.query == this.query &&
          other.responseJson == this.responseJson &&
          other.cachedAt == this.cachedAt);
}

class AiCacheCompanion extends UpdateCompanion<AiCacheData> {
  final Value<String> query;
  final Value<String> responseJson;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const AiCacheCompanion({
    this.query = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiCacheCompanion.insert({
    required String query,
    required String responseJson,
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : query = Value(query),
       responseJson = Value(responseJson),
       cachedAt = Value(cachedAt);
  static Insertable<AiCacheData> custom({
    Expression<String>? query,
    Expression<String>? responseJson,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (responseJson != null) 'response_json': responseJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiCacheCompanion copyWith({
    Value<String>? query,
    Value<String>? responseJson,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return AiCacheCompanion(
      query: query ?? this.query,
      responseJson: responseJson ?? this.responseJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiCacheCompanion(')
          ..write('query: $query, ')
          ..write('responseJson: $responseJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $ComponentsTable components = $ComponentsTable(this);
  late final $CharacterComponentsTable characterComponents =
      $CharacterComponentsTable(this);
  late final $CompoundWordsTable compoundWords = $CompoundWordsTable(this);
  late final $WordCharactersTable wordCharacters = $WordCharactersTable(this);
  late final $UserCollectionsTable userCollections = $UserCollectionsTable(
    this,
  );
  late final $UserCollectionWordsTable userCollectionWords =
      $UserCollectionWordsTable(this);
  late final $ReadingHistoryTable readingHistory = $ReadingHistoryTable(this);
  late final $AiCacheTable aiCache = $AiCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    characters,
    components,
    characterComponents,
    compoundWords,
    wordCharacters,
    userCollections,
    userCollectionWords,
    readingHistory,
    aiCache,
  ];
}

typedef $$CharactersTableCreateCompanionBuilder = CharactersCompanion Function({
  required String id,
  required String symbol,
  required String pinyin,
  Value<String?> hangul,
  Value<String> hanViet,
  Value<String> englishDef,
  Value<String?> etymologyStory,
  Value<String?> decomposition,
  Value<String?> radical,
  Value<int?> hskLevel,
  Value<String?> jpOnyomi,
  Value<int> strokeCount,
  Value<int> rowid,
});
typedef $$CharactersTableUpdateCompanionBuilder = CharactersCompanion Function({
  Value<String> id,
  Value<String> symbol,
  Value<String> pinyin,
  Value<String?> hangul,
  Value<String> hanViet,
  Value<String> englishDef,
  Value<String?> etymologyStory,
  Value<String?> decomposition,
  Value<String?> radical,
  Value<int?> hskLevel,
  Value<String?> jpOnyomi,
  Value<int> strokeCount,
  Value<int> rowid,
});

final class $$CharactersTableReferences
    extends BaseReferences<_$AppDatabase, $CharactersTable, Character> {
  $$CharactersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $CharacterComponentsTable,
    List<CharacterComponent>
  >
  _characterComponentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.characterComponents,
        aliasName: 'characters__id__character_components__character_id',
      );

  $$CharacterComponentsTableProcessedTableManager get characterComponentsRefs {
    final manager = $$CharacterComponentsTableTableManager(
      $_db,
      $_db.characterComponents,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _characterComponentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WordCharactersTable, List<WordCharacter>>
  _wordCharactersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wordCharacters,
    aliasName: 'characters__id__word_characters__character_id',
  );

  $$WordCharactersTableProcessedTableManager get wordCharactersRefs {
    final manager = $$WordCharactersTableTableManager(
      $_db,
      $_db.wordCharacters,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordCharactersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CharactersTableFilterComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hangul => $composableBuilder(
    column: $table.hangul,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hanViet => $composableBuilder(
    column: $table.hanViet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishDef => $composableBuilder(
    column: $table.englishDef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etymologyStory => $composableBuilder(
    column: $table.etymologyStory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decomposition => $composableBuilder(
    column: $table.decomposition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get radical => $composableBuilder(
    column: $table.radical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hskLevel => $composableBuilder(
    column: $table.hskLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jpOnyomi => $composableBuilder(
    column: $table.jpOnyomi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> characterComponentsRefs(
    Expression<bool> Function($$CharacterComponentsTableFilterComposer f) f,
  ) {
    final $$CharacterComponentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterComponents,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterComponentsTableFilterComposer(
            $db: $db,
            $table: $db.characterComponents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> wordCharactersRefs(
    Expression<bool> Function($$WordCharactersTableFilterComposer f) f,
  ) {
    final $$WordCharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordCharacters,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordCharactersTableFilterComposer(
            $db: $db,
            $table: $db.wordCharacters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hangul => $composableBuilder(
    column: $table.hangul,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hanViet => $composableBuilder(
    column: $table.hanViet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishDef => $composableBuilder(
    column: $table.englishDef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etymologyStory => $composableBuilder(
    column: $table.etymologyStory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decomposition => $composableBuilder(
    column: $table.decomposition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get radical => $composableBuilder(
    column: $table.radical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hskLevel => $composableBuilder(
    column: $table.hskLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jpOnyomi => $composableBuilder(
    column: $table.jpOnyomi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get pinyin =>
      $composableBuilder(column: $table.pinyin, builder: (column) => column);

  GeneratedColumn<String> get hangul =>
      $composableBuilder(column: $table.hangul, builder: (column) => column);

  GeneratedColumn<String> get hanViet =>
      $composableBuilder(column: $table.hanViet, builder: (column) => column);

  GeneratedColumn<String> get englishDef => $composableBuilder(
    column: $table.englishDef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etymologyStory => $composableBuilder(
    column: $table.etymologyStory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get decomposition => $composableBuilder(
    column: $table.decomposition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get radical =>
      $composableBuilder(column: $table.radical, builder: (column) => column);

  GeneratedColumn<int> get hskLevel =>
      $composableBuilder(column: $table.hskLevel, builder: (column) => column);

  GeneratedColumn<String> get jpOnyomi =>
      $composableBuilder(column: $table.jpOnyomi, builder: (column) => column);

  GeneratedColumn<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => column,
  );

  Expression<T> characterComponentsRefs<T extends Object>(
    Expression<T> Function($$CharacterComponentsTableAnnotationComposer a) f,
  ) {
    final $$CharacterComponentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.characterComponents,
          getReferencedColumn: (t) => t.characterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CharacterComponentsTableAnnotationComposer(
                $db: $db,
                $table: $db.characterComponents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> wordCharactersRefs<T extends Object>(
    Expression<T> Function($$WordCharactersTableAnnotationComposer a) f,
  ) {
    final $$WordCharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordCharacters,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordCharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.wordCharacters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharactersTable,
          Character,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (Character, $$CharactersTableReferences),
          Character,
          PrefetchHooks Function({
            bool characterComponentsRefs,
            bool wordCharactersRefs,
          })
        > {
  $$CharactersTableTableManager(_$AppDatabase db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<String> pinyin = const Value.absent(),
                Value<String?> hangul = const Value.absent(),
                Value<String> hanViet = const Value.absent(),
                Value<String> englishDef = const Value.absent(),
                Value<String?> etymologyStory = const Value.absent(),
                Value<String?> decomposition = const Value.absent(),
                Value<String?> radical = const Value.absent(),
                Value<int?> hskLevel = const Value.absent(),
                Value<String?> jpOnyomi = const Value.absent(),
                Value<int> strokeCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion(
                id: id,
                symbol: symbol,
                pinyin: pinyin,
                hangul: hangul,
                hanViet: hanViet,
                englishDef: englishDef,
                etymologyStory: etymologyStory,
                decomposition: decomposition,
                radical: radical,
                hskLevel: hskLevel,
                jpOnyomi: jpOnyomi,
                strokeCount: strokeCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String symbol,
                required String pinyin,
                Value<String?> hangul = const Value.absent(),
                Value<String> hanViet = const Value.absent(),
                Value<String> englishDef = const Value.absent(),
                Value<String?> etymologyStory = const Value.absent(),
                Value<String?> decomposition = const Value.absent(),
                Value<String?> radical = const Value.absent(),
                Value<int?> hskLevel = const Value.absent(),
                Value<String?> jpOnyomi = const Value.absent(),
                Value<int> strokeCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion.insert(
                id: id,
                symbol: symbol,
                pinyin: pinyin,
                hangul: hangul,
                hanViet: hanViet,
                englishDef: englishDef,
                etymologyStory: etymologyStory,
                decomposition: decomposition,
                radical: radical,
                hskLevel: hskLevel,
                jpOnyomi: jpOnyomi,
                strokeCount: strokeCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharactersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({characterComponentsRefs = false, wordCharactersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (characterComponentsRefs) db.characterComponents,
                    if (wordCharactersRefs) db.wordCharacters,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (characterComponentsRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          CharacterComponent
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._characterComponentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).characterComponentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (wordCharactersRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          WordCharacter
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._wordCharactersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).wordCharactersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharactersTable,
      Character,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (Character, $$CharactersTableReferences),
      Character,
      PrefetchHooks Function({
        bool characterComponentsRefs,
        bool wordCharactersRefs,
      })
    >;
typedef $$ComponentsTableCreateCompanionBuilder = ComponentsCompanion Function({
  required String id,
  required String symbol,
  required String pinyin,
  Value<String> hanViet,
  Value<String> englishDef,
  Value<int> strokeCount,
  Value<int> rowid,
});
typedef $$ComponentsTableUpdateCompanionBuilder = ComponentsCompanion Function({
  Value<String> id,
  Value<String> symbol,
  Value<String> pinyin,
  Value<String> hanViet,
  Value<String> englishDef,
  Value<int> strokeCount,
  Value<int> rowid,
});

final class $$ComponentsTableReferences
    extends BaseReferences<_$AppDatabase, $ComponentsTable, Component> {
  $$ComponentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $CharacterComponentsTable,
    List<CharacterComponent>
  >
  _characterComponentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.characterComponents,
        aliasName: 'components__id__character_components__component_id',
      );

  $$CharacterComponentsTableProcessedTableManager get characterComponentsRefs {
    final manager = $$CharacterComponentsTableTableManager(
      $_db,
      $_db.characterComponents,
    ).filter((f) => f.componentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _characterComponentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ComponentsTableFilterComposer
    extends Composer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hanViet => $composableBuilder(
    column: $table.hanViet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishDef => $composableBuilder(
    column: $table.englishDef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> characterComponentsRefs(
    Expression<bool> Function($$CharacterComponentsTableFilterComposer f) f,
  ) {
    final $$CharacterComponentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterComponents,
      getReferencedColumn: (t) => t.componentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterComponentsTableFilterComposer(
            $db: $db,
            $table: $db.characterComponents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComponentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hanViet => $composableBuilder(
    column: $table.hanViet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishDef => $composableBuilder(
    column: $table.englishDef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComponentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get pinyin =>
      $composableBuilder(column: $table.pinyin, builder: (column) => column);

  GeneratedColumn<String> get hanViet =>
      $composableBuilder(column: $table.hanViet, builder: (column) => column);

  GeneratedColumn<String> get englishDef => $composableBuilder(
    column: $table.englishDef,
    builder: (column) => column,
  );

  GeneratedColumn<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => column,
  );

  Expression<T> characterComponentsRefs<T extends Object>(
    Expression<T> Function($$CharacterComponentsTableAnnotationComposer a) f,
  ) {
    final $$CharacterComponentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.characterComponents,
          getReferencedColumn: (t) => t.componentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CharacterComponentsTableAnnotationComposer(
                $db: $db,
                $table: $db.characterComponents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ComponentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ComponentsTable,
          Component,
          $$ComponentsTableFilterComposer,
          $$ComponentsTableOrderingComposer,
          $$ComponentsTableAnnotationComposer,
          $$ComponentsTableCreateCompanionBuilder,
          $$ComponentsTableUpdateCompanionBuilder,
          (Component, $$ComponentsTableReferences),
          Component,
          PrefetchHooks Function({bool characterComponentsRefs})
        > {
  $$ComponentsTableTableManager(_$AppDatabase db, $ComponentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComponentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComponentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComponentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<String> pinyin = const Value.absent(),
                Value<String> hanViet = const Value.absent(),
                Value<String> englishDef = const Value.absent(),
                Value<int> strokeCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComponentsCompanion(
                id: id,
                symbol: symbol,
                pinyin: pinyin,
                hanViet: hanViet,
                englishDef: englishDef,
                strokeCount: strokeCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String symbol,
                required String pinyin,
                Value<String> hanViet = const Value.absent(),
                Value<String> englishDef = const Value.absent(),
                Value<int> strokeCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComponentsCompanion.insert(
                id: id,
                symbol: symbol,
                pinyin: pinyin,
                hanViet: hanViet,
                englishDef: englishDef,
                strokeCount: strokeCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ComponentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterComponentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (characterComponentsRefs) db.characterComponents,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (characterComponentsRefs)
                    await $_getPrefetchedData<
                      Component,
                      $ComponentsTable,
                      CharacterComponent
                    >(
                      currentTable: table,
                      referencedTable: $$ComponentsTableReferences
                          ._characterComponentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ComponentsTableReferences(
                            db,
                            table,
                            p0,
                          ).characterComponentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.componentId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ComponentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ComponentsTable,
      Component,
      $$ComponentsTableFilterComposer,
      $$ComponentsTableOrderingComposer,
      $$ComponentsTableAnnotationComposer,
      $$ComponentsTableCreateCompanionBuilder,
      $$ComponentsTableUpdateCompanionBuilder,
      (Component, $$ComponentsTableReferences),
      Component,
      PrefetchHooks Function({bool characterComponentsRefs})
    >;
typedef $$CharacterComponentsTableCreateCompanionBuilder =
    CharacterComponentsCompanion Function({
      required String characterId,
      required String componentId,
      Value<String?> componentType,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$CharacterComponentsTableUpdateCompanionBuilder =
    CharacterComponentsCompanion Function({
      Value<String> characterId,
      Value<String> componentId,
      Value<String?> componentType,
      Value<int> position,
      Value<int> rowid,
    });

final class $$CharacterComponentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CharacterComponentsTable,
          CharacterComponent
        > {
  $$CharacterComponentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CharactersTable _characterIdTable(_$AppDatabase db) => db.characters
      .createAlias('character_components__character_id__characters__id');

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<String>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ComponentsTable _componentIdTable(_$AppDatabase db) => db.components
      .createAlias('character_components__component_id__components__id');

  $$ComponentsTableProcessedTableManager get componentId {
    final $_column = $_itemColumn<String>('component_id')!;

    final manager = $$ComponentsTableTableManager(
      $_db,
      $_db.components,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_componentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CharacterComponentsTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterComponentsTable> {
  $$CharacterComponentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComponentsTableFilterComposer get componentId {
    final $$ComponentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableFilterComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterComponentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterComponentsTable> {
  $$CharacterComponentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComponentsTableOrderingComposer get componentId {
    final $$ComponentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableOrderingComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterComponentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterComponentsTable> {
  $$CharacterComponentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComponentsTableAnnotationComposer get componentId {
    final $$ComponentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableAnnotationComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterComponentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterComponentsTable,
          CharacterComponent,
          $$CharacterComponentsTableFilterComposer,
          $$CharacterComponentsTableOrderingComposer,
          $$CharacterComponentsTableAnnotationComposer,
          $$CharacterComponentsTableCreateCompanionBuilder,
          $$CharacterComponentsTableUpdateCompanionBuilder,
          (CharacterComponent, $$CharacterComponentsTableReferences),
          CharacterComponent,
          PrefetchHooks Function({bool characterId, bool componentId})
        > {
  $$CharacterComponentsTableTableManager(
    _$AppDatabase db,
    $CharacterComponentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterComponentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterComponentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CharacterComponentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> characterId = const Value.absent(),
                Value<String> componentId = const Value.absent(),
                Value<String?> componentType = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterComponentsCompanion(
                characterId: characterId,
                componentId: componentId,
                componentType: componentType,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String characterId,
                required String componentId,
                Value<String?> componentType = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterComponentsCompanion.insert(
                characterId: characterId,
                componentId: componentId,
                componentType: componentType,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharacterComponentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterId = false, componentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (characterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.characterId,
                        referencedTable: $$CharacterComponentsTableReferences
                            ._characterIdTable(db),
                        referencedColumn: $$CharacterComponentsTableReferences
                            ._characterIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (componentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.componentId,
                        referencedTable: $$CharacterComponentsTableReferences
                            ._componentIdTable(db),
                        referencedColumn: $$CharacterComponentsTableReferences
                            ._componentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CharacterComponentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterComponentsTable,
      CharacterComponent,
      $$CharacterComponentsTableFilterComposer,
      $$CharacterComponentsTableOrderingComposer,
      $$CharacterComponentsTableAnnotationComposer,
      $$CharacterComponentsTableCreateCompanionBuilder,
      $$CharacterComponentsTableUpdateCompanionBuilder,
      (CharacterComponent, $$CharacterComponentsTableReferences),
      CharacterComponent,
      PrefetchHooks Function({bool characterId, bool componentId})
    >;
typedef $$CompoundWordsTableCreateCompanionBuilder =
    CompoundWordsCompanion Function({
      required String id,
      required String simplified,
      Value<String?> traditional,
      required String pinyin,
      Value<String?> hangul,
      Value<String> hanViet,
      Value<String> hanVietResonance,
      Value<String?> vietnameseNote,
      Value<String> englishDef,
      Value<int?> hskLevel,
      Value<int?> frequencyRank,
      Value<String> originType,
      Value<int> isCognateAnchor,
      Value<int> aiGenerated,
      Value<int> rowid,
    });
typedef $$CompoundWordsTableUpdateCompanionBuilder =
    CompoundWordsCompanion Function({
      Value<String> id,
      Value<String> simplified,
      Value<String?> traditional,
      Value<String> pinyin,
      Value<String?> hangul,
      Value<String> hanViet,
      Value<String> hanVietResonance,
      Value<String?> vietnameseNote,
      Value<String> englishDef,
      Value<int?> hskLevel,
      Value<int?> frequencyRank,
      Value<String> originType,
      Value<int> isCognateAnchor,
      Value<int> aiGenerated,
      Value<int> rowid,
    });

final class $$CompoundWordsTableReferences
    extends BaseReferences<_$AppDatabase, $CompoundWordsTable, CompoundWord> {
  $$CompoundWordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$WordCharactersTable, List<WordCharacter>>
  _wordCharactersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wordCharacters,
    aliasName: 'compound_words__id__word_characters__word_id',
  );

  $$WordCharactersTableProcessedTableManager get wordCharactersRefs {
    final manager = $$WordCharactersTableTableManager(
      $_db,
      $_db.wordCharacters,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordCharactersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CompoundWordsTableFilterComposer
    extends Composer<_$AppDatabase, $CompoundWordsTable> {
  $$CompoundWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get simplified => $composableBuilder(
    column: $table.simplified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get traditional => $composableBuilder(
    column: $table.traditional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hangul => $composableBuilder(
    column: $table.hangul,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hanViet => $composableBuilder(
    column: $table.hanViet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hanVietResonance => $composableBuilder(
    column: $table.hanVietResonance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vietnameseNote => $composableBuilder(
    column: $table.vietnameseNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishDef => $composableBuilder(
    column: $table.englishDef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hskLevel => $composableBuilder(
    column: $table.hskLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frequencyRank => $composableBuilder(
    column: $table.frequencyRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originType => $composableBuilder(
    column: $table.originType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isCognateAnchor => $composableBuilder(
    column: $table.isCognateAnchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aiGenerated => $composableBuilder(
    column: $table.aiGenerated,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> wordCharactersRefs(
    Expression<bool> Function($$WordCharactersTableFilterComposer f) f,
  ) {
    final $$WordCharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordCharacters,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordCharactersTableFilterComposer(
            $db: $db,
            $table: $db.wordCharacters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompoundWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompoundWordsTable> {
  $$CompoundWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get simplified => $composableBuilder(
    column: $table.simplified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get traditional => $composableBuilder(
    column: $table.traditional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hangul => $composableBuilder(
    column: $table.hangul,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hanViet => $composableBuilder(
    column: $table.hanViet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hanVietResonance => $composableBuilder(
    column: $table.hanVietResonance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vietnameseNote => $composableBuilder(
    column: $table.vietnameseNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishDef => $composableBuilder(
    column: $table.englishDef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hskLevel => $composableBuilder(
    column: $table.hskLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frequencyRank => $composableBuilder(
    column: $table.frequencyRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originType => $composableBuilder(
    column: $table.originType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isCognateAnchor => $composableBuilder(
    column: $table.isCognateAnchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aiGenerated => $composableBuilder(
    column: $table.aiGenerated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompoundWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompoundWordsTable> {
  $$CompoundWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get simplified => $composableBuilder(
    column: $table.simplified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get traditional => $composableBuilder(
    column: $table.traditional,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinyin =>
      $composableBuilder(column: $table.pinyin, builder: (column) => column);

  GeneratedColumn<String> get hangul =>
      $composableBuilder(column: $table.hangul, builder: (column) => column);

  GeneratedColumn<String> get hanViet =>
      $composableBuilder(column: $table.hanViet, builder: (column) => column);

  GeneratedColumn<String> get hanVietResonance => $composableBuilder(
    column: $table.hanVietResonance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vietnameseNote => $composableBuilder(
    column: $table.vietnameseNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get englishDef => $composableBuilder(
    column: $table.englishDef,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hskLevel =>
      $composableBuilder(column: $table.hskLevel, builder: (column) => column);

  GeneratedColumn<int> get frequencyRank => $composableBuilder(
    column: $table.frequencyRank,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originType => $composableBuilder(
    column: $table.originType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isCognateAnchor => $composableBuilder(
    column: $table.isCognateAnchor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get aiGenerated => $composableBuilder(
    column: $table.aiGenerated,
    builder: (column) => column,
  );

  Expression<T> wordCharactersRefs<T extends Object>(
    Expression<T> Function($$WordCharactersTableAnnotationComposer a) f,
  ) {
    final $$WordCharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordCharacters,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordCharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.wordCharacters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompoundWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompoundWordsTable,
          CompoundWord,
          $$CompoundWordsTableFilterComposer,
          $$CompoundWordsTableOrderingComposer,
          $$CompoundWordsTableAnnotationComposer,
          $$CompoundWordsTableCreateCompanionBuilder,
          $$CompoundWordsTableUpdateCompanionBuilder,
          (CompoundWord, $$CompoundWordsTableReferences),
          CompoundWord,
          PrefetchHooks Function({bool wordCharactersRefs})
        > {
  $$CompoundWordsTableTableManager(_$AppDatabase db, $CompoundWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompoundWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompoundWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompoundWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> simplified = const Value.absent(),
                Value<String?> traditional = const Value.absent(),
                Value<String> pinyin = const Value.absent(),
                Value<String?> hangul = const Value.absent(),
                Value<String> hanViet = const Value.absent(),
                Value<String> hanVietResonance = const Value.absent(),
                Value<String?> vietnameseNote = const Value.absent(),
                Value<String> englishDef = const Value.absent(),
                Value<int?> hskLevel = const Value.absent(),
                Value<int?> frequencyRank = const Value.absent(),
                Value<String> originType = const Value.absent(),
                Value<int> isCognateAnchor = const Value.absent(),
                Value<int> aiGenerated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompoundWordsCompanion(
                id: id,
                simplified: simplified,
                traditional: traditional,
                pinyin: pinyin,
                hangul: hangul,
                hanViet: hanViet,
                hanVietResonance: hanVietResonance,
                vietnameseNote: vietnameseNote,
                englishDef: englishDef,
                hskLevel: hskLevel,
                frequencyRank: frequencyRank,
                originType: originType,
                isCognateAnchor: isCognateAnchor,
                aiGenerated: aiGenerated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String simplified,
                Value<String?> traditional = const Value.absent(),
                required String pinyin,
                Value<String?> hangul = const Value.absent(),
                Value<String> hanViet = const Value.absent(),
                Value<String> hanVietResonance = const Value.absent(),
                Value<String?> vietnameseNote = const Value.absent(),
                Value<String> englishDef = const Value.absent(),
                Value<int?> hskLevel = const Value.absent(),
                Value<int?> frequencyRank = const Value.absent(),
                Value<String> originType = const Value.absent(),
                Value<int> isCognateAnchor = const Value.absent(),
                Value<int> aiGenerated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompoundWordsCompanion.insert(
                id: id,
                simplified: simplified,
                traditional: traditional,
                pinyin: pinyin,
                hangul: hangul,
                hanViet: hanViet,
                hanVietResonance: hanVietResonance,
                vietnameseNote: vietnameseNote,
                englishDef: englishDef,
                hskLevel: hskLevel,
                frequencyRank: frequencyRank,
                originType: originType,
                isCognateAnchor: isCognateAnchor,
                aiGenerated: aiGenerated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompoundWordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordCharactersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (wordCharactersRefs) db.wordCharacters,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wordCharactersRefs)
                    await $_getPrefetchedData<
                      CompoundWord,
                      $CompoundWordsTable,
                      WordCharacter
                    >(
                      currentTable: table,
                      referencedTable: $$CompoundWordsTableReferences
                          ._wordCharactersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CompoundWordsTableReferences(
                            db,
                            table,
                            p0,
                          ).wordCharactersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.wordId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CompoundWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompoundWordsTable,
      CompoundWord,
      $$CompoundWordsTableFilterComposer,
      $$CompoundWordsTableOrderingComposer,
      $$CompoundWordsTableAnnotationComposer,
      $$CompoundWordsTableCreateCompanionBuilder,
      $$CompoundWordsTableUpdateCompanionBuilder,
      (CompoundWord, $$CompoundWordsTableReferences),
      CompoundWord,
      PrefetchHooks Function({bool wordCharactersRefs})
    >;
typedef $$WordCharactersTableCreateCompanionBuilder =
    WordCharactersCompanion Function({
      required String wordId,
      required String characterId,
      required int position,
      Value<int> rowid,
    });
typedef $$WordCharactersTableUpdateCompanionBuilder =
    WordCharactersCompanion Function({
      Value<String> wordId,
      Value<String> characterId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$WordCharactersTableReferences
    extends BaseReferences<_$AppDatabase, $WordCharactersTable, WordCharacter> {
  $$WordCharactersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CompoundWordsTable _wordIdTable(_$AppDatabase db) => db.compoundWords
      .createAlias('word_characters__word_id__compound_words__id');

  $$CompoundWordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<String>('word_id')!;

    final manager = $$CompoundWordsTableTableManager(
      $_db,
      $_db.compoundWords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CharactersTable _characterIdTable(_$AppDatabase db) => db.characters
      .createAlias('word_characters__character_id__characters__id');

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<String>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordCharactersTableFilterComposer
    extends Composer<_$AppDatabase, $WordCharactersTable> {
  $$WordCharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$CompoundWordsTableFilterComposer get wordId {
    final $$CompoundWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.compoundWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompoundWordsTableFilterComposer(
            $db: $db,
            $table: $db.compoundWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordCharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $WordCharactersTable> {
  $$WordCharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompoundWordsTableOrderingComposer get wordId {
    final $$CompoundWordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.compoundWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompoundWordsTableOrderingComposer(
            $db: $db,
            $table: $db.compoundWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordCharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordCharactersTable> {
  $$WordCharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$CompoundWordsTableAnnotationComposer get wordId {
    final $$CompoundWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.compoundWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompoundWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.compoundWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordCharactersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordCharactersTable,
          WordCharacter,
          $$WordCharactersTableFilterComposer,
          $$WordCharactersTableOrderingComposer,
          $$WordCharactersTableAnnotationComposer,
          $$WordCharactersTableCreateCompanionBuilder,
          $$WordCharactersTableUpdateCompanionBuilder,
          (WordCharacter, $$WordCharactersTableReferences),
          WordCharacter,
          PrefetchHooks Function({bool wordId, bool characterId})
        > {
  $$WordCharactersTableTableManager(
    _$AppDatabase db,
    $WordCharactersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordCharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordCharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordCharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> wordId = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordCharactersCompanion(
                wordId: wordId,
                characterId: characterId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String wordId,
                required String characterId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => WordCharactersCompanion.insert(
                wordId: wordId,
                characterId: characterId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WordCharactersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false, characterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wordId,
                        referencedTable: $$WordCharactersTableReferences
                            ._wordIdTable(db),
                        referencedColumn: $$WordCharactersTableReferences
                            ._wordIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (characterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.characterId,
                        referencedTable: $$WordCharactersTableReferences
                            ._characterIdTable(db),
                        referencedColumn: $$WordCharactersTableReferences
                            ._characterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WordCharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordCharactersTable,
      WordCharacter,
      $$WordCharactersTableFilterComposer,
      $$WordCharactersTableOrderingComposer,
      $$WordCharactersTableAnnotationComposer,
      $$WordCharactersTableCreateCompanionBuilder,
      $$WordCharactersTableUpdateCompanionBuilder,
      (WordCharacter, $$WordCharactersTableReferences),
      WordCharacter,
      PrefetchHooks Function({bool wordId, bool characterId})
    >;
typedef $$UserCollectionsTableCreateCompanionBuilder =
    UserCollectionsCompanion Function({
      required String id,
      required String name,
      Value<String?> icon,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$UserCollectionsTableUpdateCompanionBuilder =
    UserCollectionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> icon,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$UserCollectionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $UserCollectionsTable, UserCollection> {
  $$UserCollectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $UserCollectionWordsTable,
    List<UserCollectionWord>
  >
  _userCollectionWordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userCollectionWords,
        aliasName: 'user_collections__id__user_collection_words__collection_id',
      );

  $$UserCollectionWordsTableProcessedTableManager get userCollectionWordsRefs {
    final manager = $$UserCollectionWordsTableTableManager(
      $_db,
      $_db.userCollectionWords,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _userCollectionWordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $UserCollectionsTable> {
  $$UserCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userCollectionWordsRefs(
    Expression<bool> Function($$UserCollectionWordsTableFilterComposer f) f,
  ) {
    final $$UserCollectionWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userCollectionWords,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCollectionWordsTableFilterComposer(
            $db: $db,
            $table: $db.userCollectionWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserCollectionsTable> {
  $$UserCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserCollectionsTable> {
  $$UserCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> userCollectionWordsRefs<T extends Object>(
    Expression<T> Function($$UserCollectionWordsTableAnnotationComposer a) f,
  ) {
    final $$UserCollectionWordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userCollectionWords,
          getReferencedColumn: (t) => t.collectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserCollectionWordsTableAnnotationComposer(
                $db: $db,
                $table: $db.userCollectionWords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UserCollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserCollectionsTable,
          UserCollection,
          $$UserCollectionsTableFilterComposer,
          $$UserCollectionsTableOrderingComposer,
          $$UserCollectionsTableAnnotationComposer,
          $$UserCollectionsTableCreateCompanionBuilder,
          $$UserCollectionsTableUpdateCompanionBuilder,
          (UserCollection, $$UserCollectionsTableReferences),
          UserCollection,
          PrefetchHooks Function({bool userCollectionWordsRefs})
        > {
  $$UserCollectionsTableTableManager(
    _$AppDatabase db,
    $UserCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserCollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserCollectionsCompanion(
                id: id,
                name: name,
                icon: icon,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> icon = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => UserCollectionsCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserCollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userCollectionWordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userCollectionWordsRefs) db.userCollectionWords,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userCollectionWordsRefs)
                    await $_getPrefetchedData<
                      UserCollection,
                      $UserCollectionsTable,
                      UserCollectionWord
                    >(
                      currentTable: table,
                      referencedTable: $$UserCollectionsTableReferences
                          ._userCollectionWordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UserCollectionsTableReferences(
                            db,
                            table,
                            p0,
                          ).userCollectionWordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.collectionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UserCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserCollectionsTable,
      UserCollection,
      $$UserCollectionsTableFilterComposer,
      $$UserCollectionsTableOrderingComposer,
      $$UserCollectionsTableAnnotationComposer,
      $$UserCollectionsTableCreateCompanionBuilder,
      $$UserCollectionsTableUpdateCompanionBuilder,
      (UserCollection, $$UserCollectionsTableReferences),
      UserCollection,
      PrefetchHooks Function({bool userCollectionWordsRefs})
    >;
typedef $$UserCollectionWordsTableCreateCompanionBuilder =
    UserCollectionWordsCompanion Function({
      required String collectionId,
      required String wordId,
      required int addedAt,
      Value<int> rowid,
    });
typedef $$UserCollectionWordsTableUpdateCompanionBuilder =
    UserCollectionWordsCompanion Function({
      Value<String> collectionId,
      Value<String> wordId,
      Value<int> addedAt,
      Value<int> rowid,
    });

final class $$UserCollectionWordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $UserCollectionWordsTable,
          UserCollectionWord
        > {
  $$UserCollectionWordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UserCollectionsTable _collectionIdTable(_$AppDatabase db) =>
      db.userCollections.createAlias(
        'user_collection_words__collection_id__user_collections__id',
      );

  $$UserCollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<String>('collection_id')!;

    final manager = $$UserCollectionsTableTableManager(
      $_db,
      $_db.userCollections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserCollectionWordsTableFilterComposer
    extends Composer<_$AppDatabase, $UserCollectionWordsTable> {
  $$UserCollectionWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UserCollectionsTableFilterComposer get collectionId {
    final $$UserCollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.userCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCollectionsTableFilterComposer(
            $db: $db,
            $table: $db.userCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserCollectionWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserCollectionWordsTable> {
  $$UserCollectionWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UserCollectionsTableOrderingComposer get collectionId {
    final $$UserCollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.userCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.userCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserCollectionWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserCollectionWordsTable> {
  $$UserCollectionWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$UserCollectionsTableAnnotationComposer get collectionId {
    final $$UserCollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.userCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.userCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserCollectionWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserCollectionWordsTable,
          UserCollectionWord,
          $$UserCollectionWordsTableFilterComposer,
          $$UserCollectionWordsTableOrderingComposer,
          $$UserCollectionWordsTableAnnotationComposer,
          $$UserCollectionWordsTableCreateCompanionBuilder,
          $$UserCollectionWordsTableUpdateCompanionBuilder,
          (UserCollectionWord, $$UserCollectionWordsTableReferences),
          UserCollectionWord,
          PrefetchHooks Function({bool collectionId})
        > {
  $$UserCollectionWordsTableTableManager(
    _$AppDatabase db,
    $UserCollectionWordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserCollectionWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserCollectionWordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserCollectionWordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> collectionId = const Value.absent(),
                Value<String> wordId = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserCollectionWordsCompanion(
                collectionId: collectionId,
                wordId: wordId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionId,
                required String wordId,
                required int addedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserCollectionWordsCompanion.insert(
                collectionId: collectionId,
                wordId: wordId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserCollectionWordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (collectionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.collectionId,
                        referencedTable: $$UserCollectionWordsTableReferences
                            ._collectionIdTable(db),
                        referencedColumn: $$UserCollectionWordsTableReferences
                            ._collectionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserCollectionWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserCollectionWordsTable,
      UserCollectionWord,
      $$UserCollectionWordsTableFilterComposer,
      $$UserCollectionWordsTableOrderingComposer,
      $$UserCollectionWordsTableAnnotationComposer,
      $$UserCollectionWordsTableCreateCompanionBuilder,
      $$UserCollectionWordsTableUpdateCompanionBuilder,
      (UserCollectionWord, $$UserCollectionWordsTableReferences),
      UserCollectionWord,
      PrefetchHooks Function({bool collectionId})
    >;
typedef $$ReadingHistoryTableCreateCompanionBuilder =
    ReadingHistoryCompanion Function({
      required String id,
      required String title,
      required String rawText,
      required String tokenJson,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$ReadingHistoryTableUpdateCompanionBuilder =
    ReadingHistoryCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> rawText,
      Value<String> tokenJson,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$ReadingHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tokenJson => $composableBuilder(
    column: $table.tokenJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tokenJson => $composableBuilder(
    column: $table.tokenJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get tokenJson =>
      $composableBuilder(column: $table.tokenJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReadingHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingHistoryTable,
          ReadingHistoryData,
          $$ReadingHistoryTableFilterComposer,
          $$ReadingHistoryTableOrderingComposer,
          $$ReadingHistoryTableAnnotationComposer,
          $$ReadingHistoryTableCreateCompanionBuilder,
          $$ReadingHistoryTableUpdateCompanionBuilder,
          (
            ReadingHistoryData,
            BaseReferences<
              _$AppDatabase,
              $ReadingHistoryTable,
              ReadingHistoryData
            >,
          ),
          ReadingHistoryData,
          PrefetchHooks Function()
        > {
  $$ReadingHistoryTableTableManager(
    _$AppDatabase db,
    $ReadingHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String> tokenJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingHistoryCompanion(
                id: id,
                title: title,
                rawText: rawText,
                tokenJson: tokenJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String rawText,
                required String tokenJson,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingHistoryCompanion.insert(
                id: id,
                title: title,
                rawText: rawText,
                tokenJson: tokenJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingHistoryTable,
      ReadingHistoryData,
      $$ReadingHistoryTableFilterComposer,
      $$ReadingHistoryTableOrderingComposer,
      $$ReadingHistoryTableAnnotationComposer,
      $$ReadingHistoryTableCreateCompanionBuilder,
      $$ReadingHistoryTableUpdateCompanionBuilder,
      (
        ReadingHistoryData,
        BaseReferences<_$AppDatabase, $ReadingHistoryTable, ReadingHistoryData>,
      ),
      ReadingHistoryData,
      PrefetchHooks Function()
    >;
typedef $$AiCacheTableCreateCompanionBuilder = AiCacheCompanion Function({
  required String query,
  required String responseJson,
  required int cachedAt,
  Value<int> rowid,
});
typedef $$AiCacheTableUpdateCompanionBuilder = AiCacheCompanion Function({
  Value<String> query,
  Value<String> responseJson,
  Value<int> cachedAt,
  Value<int> rowid,
});

class $$AiCacheTableFilterComposer
    extends Composer<_$AppDatabase, $AiCacheTable> {
  $$AiCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $AiCacheTable> {
  $$AiCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiCacheTable> {
  $$AiCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$AiCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiCacheTable,
          AiCacheData,
          $$AiCacheTableFilterComposer,
          $$AiCacheTableOrderingComposer,
          $$AiCacheTableAnnotationComposer,
          $$AiCacheTableCreateCompanionBuilder,
          $$AiCacheTableUpdateCompanionBuilder,
          (
            AiCacheData,
            BaseReferences<_$AppDatabase, $AiCacheTable, AiCacheData>,
          ),
          AiCacheData,
          PrefetchHooks Function()
        > {
  $$AiCacheTableTableManager(_$AppDatabase db, $AiCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> query = const Value.absent(),
                Value<String> responseJson = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiCacheCompanion(
                query: query,
                responseJson: responseJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String query,
                required String responseJson,
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => AiCacheCompanion.insert(
                query: query,
                responseJson: responseJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiCacheTable,
      AiCacheData,
      $$AiCacheTableFilterComposer,
      $$AiCacheTableOrderingComposer,
      $$AiCacheTableAnnotationComposer,
      $$AiCacheTableCreateCompanionBuilder,
      $$AiCacheTableUpdateCompanionBuilder,
      (AiCacheData, BaseReferences<_$AppDatabase, $AiCacheTable, AiCacheData>),
      AiCacheData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db, _db.components);
  $$CharacterComponentsTableTableManager get characterComponents =>
      $$CharacterComponentsTableTableManager(_db, _db.characterComponents);
  $$CompoundWordsTableTableManager get compoundWords =>
      $$CompoundWordsTableTableManager(_db, _db.compoundWords);
  $$WordCharactersTableTableManager get wordCharacters =>
      $$WordCharactersTableTableManager(_db, _db.wordCharacters);
  $$UserCollectionsTableTableManager get userCollections =>
      $$UserCollectionsTableTableManager(_db, _db.userCollections);
  $$UserCollectionWordsTableTableManager get userCollectionWords =>
      $$UserCollectionWordsTableTableManager(_db, _db.userCollectionWords);
  $$ReadingHistoryTableTableManager get readingHistory =>
      $$ReadingHistoryTableTableManager(_db, _db.readingHistory);
  $$AiCacheTableTableManager get aiCache =>
      $$AiCacheTableTableManager(_db, _db.aiCache);
}
