class Token {
  final String text;
  final String hanViet;
  final String pinyin;
  final String englishDef;
  final bool isCjk;
  final bool isCompound;
  final bool isKnown;
  final String? wordId;
  final String? charId;

  const Token({
    required this.text,
    this.hanViet = '',
    this.pinyin = '',
    this.englishDef = '',
    required this.isCjk,
    this.isCompound = false,
    this.isKnown = false,
    this.wordId,
    this.charId,
  });
}
