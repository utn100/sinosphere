"""
Sinosphere Rosetta — Phase 0 Data Pipeline
Builds sinosphere.db from raw datasets:
  - CC-CEDICT        → compound_words (pinyin, english)
  - MakeMeHanzi      → characters + character_components (decomposition)
  - Unihan kVietnamese → per-character Hán-Việt readings
  - Hanja table      → Korean readings per character
  - Frequency list   → frequency_rank on compound_words
  - CJKVI-IDS        → fallback decomposition
"""

import json
import re
import sqlite3
import sys
import unicodedata
import uuid
from pathlib import Path

# ── Paths ────────────────────────────────────────────────────────────────────
ROOT       = Path(__file__).parent.parent
RAW        = ROOT / "data" / "raw"
DB_PATH    = ROOT / "data" / "db" / "sinosphere.db"

CEDICT     = RAW / "cedict.txt"
MMH        = RAW / "makemehanzi_dictionary.txt"
UNIHAN     = RAW / "unihan" / "Unihan_Readings.txt"
HANJA_YML  = RAW / "hanja_table.yml"
FREQ_LIST  = RAW / "zh_cn_50k.txt"
HSK30_CSV  = RAW / "hsk30.csv"
CJKVI      = RAW / "cjkvi_ids.txt"

# ── HSK 3.0 (2021) canonical word list ───────────────────────────────────────
# Source: Official HSK Standard Course — public knowledge
# Levels 1-6 are the pre-2021 standard; 7-9 are the 2021 expansion
# We embed the most-common HSK words per level as a seed;
# remaining words are tagged via frequency ranking against CC-CEDICT entries.
HSK_WORDS = {}  # populated from hsk30.csv at runtime

# ── Helpers ───────────────────────────────────────────────────────────────────
def is_cjk(ch):
    return '一' <= ch <= '鿿' or '㐀' <= ch <= '䶿'

def char_id(ch):
    return f"chr_{ord(ch):05x}"

def word_id(simplified):
    return f"wrd_{abs(hash(simplified)) % 10**10:010d}"

def comp_id(ch):
    return f"cmp_{ord(ch):05x}"

# ── Step 1: Parse Unihan kVietnamese ─────────────────────────────────────────
def parse_unihan_hanviet():
    print("Parsing Unihan kVietnamese...")
    hv_map = {}  # char → hán-việt reading
    with open(UNIHAN, encoding="utf-8") as f:
        for line in f:
            if not line.startswith("U+") or "kVietnamese" not in line:
                continue
            parts = line.strip().split("\t")
            if len(parts) < 3:
                continue
            codepoint, field, value = parts[0], parts[1], parts[2]
            if field != "kVietnamese":
                continue
            try:
                ch = chr(int(codepoint[2:], 16))
                # Take first reading if multiple; uppercase for display
                reading = value.split()[0].upper()
                hv_map[ch] = reading
            except Exception:
                continue
    print(f"  kVietnamese entries: {len(hv_map)}")
    # Sample
    for ch in ["城", "地", "日", "心", "水", "學", "明", "晨"]:
        print(f"  {ch} → {hv_map.get(ch, '?')}")

    # ── Supplement: simplified chars missing from Unihan kVietnamese ──────────
    # Many simplified characters (学,时,间,图,书,乐,声,号...) are not in Unihan
    # kVietnamese because Unihan traditionally covers Traditional Chinese.
    # These are hand-curated mappings from their traditional equivalents.
    SIMPLIFIED_SUPPLEMENT = {
        # Learning & knowledge
        "学": "HỌC",  # 學
        "书": "THƯ",  # 書
        "图": "ĐỒ",   # 圖
        "馆": "QUÁN", # 館
        "习": "TẬP",  # 習
        "语": "NGỮ",  # 語
        "词": "TỪ",   # 詞
        "读": "ĐỌC",  # 讀
        "写": "TẢ",   # 寫
        "话": "THOẠI",# 話
        "说": "THUYẾT",# 說
        "论": "LUẬN", # 論
        "识": "THỨC", # 識
        "记": "KÝ",   # 記
        # Time
        "时": "THỜI", # 時
        "间": "GIAN", # 間
        "历": "LỊCH", # 曆/歷
        "岁": "TUẾ",  # 歲
        "现": "HIỆN", # 現
        "来": "LAI",  # 來
        "过": "QUÁ",  # 過
        "进": "TIẾN", # 進
        "还": "HOÀN", # 還
        # People & society
        "们": "MÔN",  # 們
        "这": "GIÁ",  # 這 (archaic — often skipped)
        "个": "CÁ",   # 個
        "样": "DẠNG", # 樣
        "对": "ĐỐI",  # 對
        "从": "TÙNG", # 從
        "给": "CẤP",  # 給
        "让": "NHƯỢNG",# 讓
        "问": "VẤN",  # 問
        "关": "QUAN", # 關
        "爱": "ÁI",   # 愛
        "态": "THÁI", # 態
        "际": "TẾ",   # 際
        "际": "TẾ",   # 際
        "际": "TẾ",
        "联": "LIÊN", # 聯
        "统": "THỐNG",# 統
        "级": "CẤP",  # 級
        "员": "VIÊN", # 員
        "师": "SƯ",   # 師
        "导": "ĐẠO",  # 導
        # Nature & place
        "乐": "NHẠC", # 樂
        "东": "ĐÔNG", # 東
        "风": "PHONG",# 風
        "万": "VẠN",  # 萬
        "长": "TRƯỜNG",# 長
        "场": "TRƯỜNG",# 場
        "务": "VỤ",   # 務
        "号": "HIỆU", # 號
        "声": "THANH",# 聲
        "义": "NGHĨA",# 義
        "见": "KIẾN", # 見
        "发": "PHÁT", # 發
        "为": "VI",   # 為
        "节": "TIẾT", # 節
        "华": "HOA",  # 華
        "汉": "HÁN",  # 漢
        "语": "NGỮ",  # 語
        "际": "TẾ",   # 際
        "际": "TẾ",
        "办": "BÀN",  # 辦
        "边": "BIÊN", # 邊
        "运": "VẬN",  # 運
        "动": "ĐỘNG", # 動
        "电": "ĐIỆN", # 電
        "话": "THOẠI",# 話
        "视": "THỊ",  # 視
        "报": "BÁO",  # 報
        "纸": "CHỈ",  # 紙
        "经": "KINH", # 經
        "济": "TẾ",   # 濟
        "贸": "MẬU",  # 貿
        "议": "NGHỊ", # 議
        "论": "LUẬN", # 論
        "战": "CHIẾN",# 戰
        "军": "QUÂN", # 軍
        "权": "QUYỀN",# 權
        "则": "TẮC",  # 則
        "约": "ƯỚC",  # 約
        "续": "TỤC",  # 續
        "结": "KẾT",  # 結
        "际": "TẾ",
        "图": "ĐỒ",
        "专": "CHUYÊN",# 專
        "业": "NGHIỆP",# 業
        "产": "SẢN",  # 產
        "质": "CHẤT", # 質
        "纪": "KỶ",   # 紀
        "础": "SỞ",   # 礎
        "值": "TRỊ",  # (same in simplified)
        "验": "NGHIỆM",# 驗
        "难": "NAN",  # 難
        "获": "HOẠCH",# 獲
        "确": "XÁC",  # 確
        "载": "TẢI",  # 載
        "转": "CHUYỂN",# 轉
        "换": "HOÁN", # 換
        "择": "TRẠCH",# 擇
        "实": "THỰC", # 實
        "术": "THUẬT",# 術
        "历": "LỊCH", # 曆/歷
        # Actions & verbs (simplified forms missing from Unihan kVietnamese)
        "笑": "TIẾU",  # 笑 to laugh
        "买": "MÃI",   # 買 to buy
        "卖": "MẠI",   # 賣 to sell
        "跑": "BÃO",   # 跑 to run
        "带": "ĐỚI",   # 帶 to bring/wear
        "帮": "BANG",  # 幫 to help
        "开": "KHAI",  # 開 to open
        "坐": "TỌA",   # 坐 to sit
        "睡": "THỤY",  # 睡 to sleep
        "认": "NHẬN",  # 認 to recognise
        "怕": "BÁ",    # 怕 to fear
        "贵": "QUÝ",   # 貴 expensive/precious
        "旧": "CỰU",   # 舊 old/former
        "热": "NHIỆT", # 熱 hot
        "凉": "LƯƠNG", # 涼 cool
        "湿": "THẤP",  # 濕 wet/damp
        # Additional high-frequency characters still missing
        "饭": "PHẠN",  # 飯 cooked rice/meal
        "欢": "HOAN",  # 歡 joyful/welcome
        "钱": "TIỀN",  # 錢 money
        "银": "NGÂN",  # 銀 silver/bank
        "超": "SIÊU",  # 超 to exceed/super
        "级": "CẤP",   # 級 level/grade
        "试": "THỬ",   # 試 to try/test
        "练": "LUYỆN", # 練 to practise
        "课": "KHÓA",  # 課 lesson/course
        "题": "ĐỀ",    # 題 topic/question
        "答": "ĐÁP",   # 答 to answer
        "错": "THÁC",  # 錯 wrong/mistake
        "对": "ĐỐI",   # 對 correct/opposite
        "难": "NAN",   # 難 difficult
        "易": "DỊ",    # 易 easy/change
        "快": "KHOÁI", # 快 fast/happy
        "慢": "MẠN",   # 慢 slow
        "新": "TÂN",   # 新 new
        "旧": "CỰU",   # 舊 old
        "贵": "QUÝ",   # 貴 expensive
        "便": "TIỆN",  # 便 convenient
        "站": "TRẠM",  # 站 station/to stand
        "路": "LỘ",    # 路 road/route
        "桥": "KIỀU",  # 橋 bridge
        "楼": "LÂU",   # 樓 floor/building
        "园": "VIÊN",  # 園 garden/park
        "院": "VIỆN",  # 院 courtyard/institution
        "馆": "QUÁN",  # 館 hall/establishment
        "厅": "SẢNH",  # 廳 hall/reception
        "层": "TẦNG",  # 層 layer/floor
        "块": "KHỐI",  # 塊 lump/piece
        "张": "TRƯƠNG",# 張 sheet/measure word
        "条": "ĐIỀU",  # 條 strip/item
        "件": "KIỆN",  # 件 item/matter
        "双": "SONG",  # 雙 pair/double
        "种": "CHỦNG", # 種 type/seed
        "次": "THỨ",   # 次 time/sequence
        "遍": "BIẾN",  # 遍 time(s)/everywhere
        "页": "TRANG", # 頁 page
        "篇": "THIÊN", # 篇 piece/article
    }
    before = len(hv_map)
    for ch, hv in SIMPLIFIED_SUPPLEMENT.items():
        if ch not in hv_map:
            hv_map[ch] = hv
    print(f"  Supplemented {len(hv_map) - before} simplified chars → total {len(hv_map)}")

    # ── Corrections: override wrong Unihan kVietnamese readings ───────────────
    # Unihan kVietnamese sometimes carries archaic, dialectal, or incorrect
    # readings for common characters. These are verified corrections.
    HV_CORRECTIONS = {
        "森": "SÂM",    # Unihan: chùm (wrong) — 森林 = sâm lâm
        "每": "MỖI",    # Unihan: hỏi (wrong) — 每天 = mỗi ngày
        "冷": "LÃNH",   # Unihan: lạnh (colloquial VN) — Sino-VN: lãnh
        "哭": "KHỐC",   # Unihan: khóc (colloquial VN) — Sino-VN: khốc
        "跳": "KHIÊU",  # Unihan: khêu (wrong) — 跳舞 = khiêu vũ
        "找": "TÌM",    # Unihan: quơ (wrong) — 找 = tìm kiếm
        "吃": "THỰC",   # Unihan: khật (wrong) — 吃飯 = thực phạn
        "喝": "HÁP",    # Unihan: hát (wrong) — 喝水 = háp thủy
        "喜": "HỶ",     # Unihan: hỉ (variant) — standard: hỷ (喜事 = hỷ sự)
        "年": "NIÊN",   # Unihan: nên (wrong) — 新年 = tân niên, 年 = niên
        "好": "HẢO",    # Unihan: háo (wrong for hǎo/good) — standard: hảo
        "把": "BẢ",     # Unihan: bã (wrong) — standard: bả
        "看": "KHÁN",   # Unihan: khan (secondary/colloquial) — standard: khán
        "吧": "BA",     # Unihan: và (wrong) — standard: ba
        "呢": "NI",     # Unihan: nài (wrong) — standard: ni
        "跟": "CÂN",    # Unihan: ngấn (wrong) — standard: cân
        "着": "TRƯỚC",  # CC-CEDICT picks zhao1/zhuo2 first — aspect particle reading is zhe5=TRƯỚC
    }
    corrected = 0
    for ch, hv in HV_CORRECTIONS.items():
        if hv_map.get(ch) != hv:
            hv_map[ch] = hv
            corrected += 1
    print(f"  Corrected {corrected} wrong Unihan readings")

    # Verify key words are now covered
    for ch in ["学", "时", "间", "图", "书", "乐", "声", "号", "爱", "东"]:
        print(f"  {ch} → {hv_map.get(ch, '?')}")

    return hv_map

# ── Step 2: Build compound Hán-Việt by concatenation ─────────────────────────
def build_compound_hanviet(simplified, hv_map):
    """Reconstruct Hán-Việt for a compound by concatenating per-char readings.
    Allows partial reconstruction — missing chars get a '?' placeholder.
    Returns (hanviet_string, is_complete) tuple.
    """
    parts = []
    complete = True
    for ch in simplified:
        if is_cjk(ch):
            hv = hv_map.get(ch)
            if hv:
                parts.append(hv)
            else:
                parts.append("?")
                complete = False
        # skip non-CJK (numbers, letters, punctuation)
    if not parts:
        return "", False
    return " ".join(parts), complete

# ── Step 3: Parse MakeMeHanzi ────────────────────────────────────────────────
def parse_makemehanzi():
    print("Parsing MakeMeHanzi...")
    chars = {}   # ch → {pinyin, definition, decomposition, radical, etymology}
    with open(MMH, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except Exception:
                continue
            ch = d.get("character", "")
            if not ch or not is_cjk(ch):
                continue
            chars[ch] = {
                "pinyin":        d.get("pinyin", []),
                "definition":    d.get("definition", ""),
                "decomposition": d.get("decomposition", ""),
                "radical":       d.get("radical", ""),
                "etymology":     d.get("etymology", {}),
                "matches":       d.get("matches", []),
            }
    print(f"  MakeMeHanzi characters: {len(chars)}")
    return chars

# ── Step 4: Parse CJKVI-IDS for fallback decomposition ───────────────────────
def parse_cjkvi():
    print("Parsing CJKVI-IDS...")
    ids_map = {}
    with open(CJKVI, encoding="utf-8") as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            parts = line.strip().split("\t")
            if len(parts) < 3:
                continue
            try:
                ch = chr(int(parts[0][2:], 16))
                ids_map[ch] = parts[2]  # IDS string
            except Exception:
                continue
    print(f"  CJKVI entries: {len(ids_map)}")
    return ids_map

# ── Step 5: Parse Hanja table ─────────────────────────────────────────────────
def parse_hanja():
    print("Parsing Hanja table...")
    import yaml
    with open(HANJA_YML, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    print(f"  Hanja entries: {len(data)}")
    return data  # {char: hangul_reading}

# ── Step 6: Parse CC-CEDICT ───────────────────────────────────────────────────
def parse_cedict():
    print("Parsing CC-CEDICT...")
    entries = []
    # Format: Traditional Simplified [pin1 yin1] /def1/def2/
    pattern = re.compile(r'^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+)/$')
    with open(CEDICT, encoding="utf-8") as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            m = pattern.match(line.strip())
            if not m:
                continue
            traditional, simplified, pinyin_raw, defs_raw = m.groups()
            # Skip entries with no CJK simplified
            if not any(is_cjk(c) for c in simplified):
                continue
            # Clean pinyin: "pin1 yin1" → "pīn yīn"
            pinyin = convert_pinyin_numbers(pinyin_raw)
            # Take first few non-classifier definitions to preserve complete semantic scope
            defs = [d for d in defs_raw.split("/")
                    if d and not d.startswith("CL:") and not d.startswith("variant")]
            if not defs:
                continue
            english = "; ".join(defs[:3])
            entries.append({
                "traditional": traditional,
                "simplified":  simplified,
                "pinyin":      pinyin,
                "pinyin_raw":  pinyin_raw,
                "english":     english,
            })
    print(f"  CC-CEDICT entries: {len(entries)}")
    return entries

# ── Step 7: Parse frequency list ─────────────────────────────────────────────
def parse_frequency():
    print("Parsing frequency list...")
    freq = {}
    if not FREQ_LIST.exists():
        print("  Frequency list not found — skipping")
        return freq
    with open(FREQ_LIST, encoding="utf-8") as f:
        for rank, line in enumerate(f, 1):
            parts = line.strip().split()
            if parts:
                freq[parts[0]] = rank
    print(f"  Frequency entries: {len(freq)}")
    return freq

# ── Pinyin tone number → diacritic conversion ─────────────────────────────────
TONE_MAP = {
    "a": ["ā","á","ǎ","à","a"], "e": ["ē","é","ě","è","e"],
    "i": ["ī","í","ǐ","ì","i"], "o": ["ō","ó","ǒ","ò","o"],
    "u": ["ū","ú","ǔ","ù","u"], "ü": ["ǖ","ǘ","ǚ","ǜ","ü"],
    "v": ["ǖ","ǘ","ǚ","ǜ","ü"],
}
TONE_ORDER = ["a","e","i","ou","o","u","v","ü"]

def convert_syllable(syl):
    """Convert a single pinyin syllable with number tone to diacritic."""
    if not syl:
        return syl
    tone = 5
    if syl[-1].isdigit():
        tone = int(syl[-1])
        syl = syl[:-1]
    if tone == 5:
        return syl
    syl_lower = syl.lower()
    for key in TONE_ORDER:
        idx = syl_lower.find(key)
        if idx == -1:
            continue
        # For 'ou', tone goes on the 'o'
        vowel = key[0] if key == "ou" else key
        if vowel not in TONE_MAP:
            continue
        replacement = TONE_MAP[vowel][tone - 1]
        return syl[:idx] + replacement + syl[idx + 1:]
    return syl

def convert_pinyin_numbers(raw):
    """Convert "pin1 yin1" → "pīn yīn"."""
    return " ".join(convert_syllable(s) for s in raw.split())

# ── hanviet_resonance scoring ─────────────────────────────────────────────────
# Vietnamese words still commonly used (high resonance cognates)
HV_HIGH_STEMS = {
    # Body & mind
    "TÂM","TRÍ","TÀI","ĐỨC","NHÂN","NGHĨA","LỄ","TÍN","TÌNH","CẢM",
    # Time
    "THỜI","NHẬT","NGUYỆT","NIÊN","KỲ","ĐẠI","THẾ","KỶ","GIAN","ĐẠI",
    # Nature
    "SƠN","HẢI","GIANG","HÀ","LÂM","THIÊN","ĐỊA","THỦY","HỎA","MỘC","KIM","THỔ",
    # Society
    "QUỐC","DÂN","XÃ","HỘI","GIA","ĐÌNH","PHỤ","MẪU","TỬ","NỮ",
    # Learning & knowledge
    "HỌC","VĂN","KHOA","NGHIÊN","CỨU","GIÁO","SƯ","SINH","THƯ","ĐỒ","QUÁN",
    "NGỮ","TỪ","LUẬN","THỨC","KÝ","THOẠI","THUYẾT",
    # Places & movement
    "THÀNH","THỊ","PHƯƠNG","TRUNG","ĐỊA","QUẢNG","TRƯỜNG","CƠ","QUỐC","BẮC","KINH",
    # Common high-value stems from supplement
    "ÂM","NHẠC","GIAN","TÌNH","LÝ","TƯỞNG","LÍ",
    "TỰ","DO","GIỚI","ỨC","SỰ","BẰNG","HỮU",
    "CÔNG","TÁC","DƯƠNG","MINH","THANH","THIÊN",
    # Additional common Hán-Việt stems alive in modern Vietnamese
    "ÁI","LAI","HOÀ","ĐỐI","TÙNG","CẤP","NHƯỢNG","VẤN","QUAN",
    "LIÊN","THỐNG","CẤP","VIÊN","ĐẠO","NGHIỆP","SẢN","CHẤT","KỶ",
    "THỰC","THUẬT","LỊCH","KINH","TẾ","MẬU","NGHỊ","CHIẾN","QUÂN",
    "QUYỀN","TẮC","ƯỚC","KẾT","CHUYÊN","PHÁT","VI","TIẾT","HOA","HÁN",
    "BÀN","BIÊN","VẬN","ĐỘNG","ĐIỆN","BÁO","CHỈ","TẢI","CHUYỂN","HOÁN",
    "NHẠC","THANH","HIỆU","PHONG","VẠN","TRƯỜNG","VỤ","ĐÔNG",
}

def score_resonance(simplified, han_viet, is_complete, hv_map):
    """
    Score hanviet_resonance based on:
    1. Full coverage (no '?' placeholders) → can be high
    2. Partial coverage → medium at best
    3. Stems in known high-resonance set
    """
    if not han_viet or han_viet == "?":
        return "none"

    cjk_chars = [c for c in simplified if is_cjk(c)]
    if not cjk_chars:
        return "none"

    covered = sum(1 for c in cjk_chars if c in hv_map)
    coverage = covered / len(cjk_chars)

    if covered == 0:
        return "none"

    # Filter out placeholder parts for stem matching
    real_parts = [p for p in han_viet.upper().split() if p != "?"]
    if not real_parts:
        return "none"

    high_hits = sum(1 for p in real_parts if p in HV_HIGH_STEMS)
    high_ratio = high_hits / len(real_parts)

    if is_complete and (high_ratio >= 0.5 or len(simplified) == 1):
        return "high"
    elif coverage >= 0.5:
        return "medium"
    else:
        return "low"

# ── HSK level lookup ──────────────────────────────────────────────────────────
def build_hsk_lookup():
    """Parse HSK 3.0 CSV from andycburke/HSK-3.0-Word-List.
    Columns: HSK_3_0_Level, HSK_3_0_No, OCR, Hanzi, Hanzi_Alternate, HSK_Level_Usage
    Returns: {simplified: level}
    """
    import csv
    lookup = {}
    if not HSK30_CSV.exists():
        print("  WARNING: hsk30.csv not found — HSK levels will be missing")
        return lookup
    with open(HSK30_CSV, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            level_raw = row.get("HSK_3_0_Level", "").strip()
            hanzi = row.get("Hanzi", "").strip()
            primary = hanzi.split("｜")[0].strip()
            # Map '7-9' band to level 7
            if level_raw == "7-9":
                level = 7
            elif level_raw.isdigit():
                level = int(level_raw)
            else:
                continue
            if primary:
                lookup[primary] = level
            alt = row.get("Hanzi_Alternate", "").strip()
            if alt:
                lookup[alt] = level
    print(f"  HSK 3.0 words loaded: {len(lookup)}")
    # Level breakdown
    from collections import Counter
    counts = Counter(lookup.values())
    for lvl in sorted(counts):
        print(f"    HSK {lvl}: {counts[lvl]:,}")
    return lookup

# ── Infer component type from MakeMeHanzi etymology ──────────────────────────
def infer_component_type(etymology, component_char, parent_char):
    """
    Determine semantic/phonetic/iconic from MakeMeHanzi etymology data.
    """
    if not etymology:
        return "semantic"
    etype = etymology.get("type", "")
    if etype == "pictographic":
        return "iconic"
    if etype == "ideographic":
        return "semantic"
    if etype == "pictophonetic":
        phonetic = etymology.get("phonetic", "")
        semantic = etymology.get("semantic", "")
        if component_char == phonetic:
            return "phonetic"
        if component_char == semantic:
            return "semantic"
    return "semantic"

# ── Extract components from MakeMeHanzi decomposition ────────────────────────
IDS_OPS = "⿰⿱⿲⿳⿴⿵⿶⿷⿸⿹⿺⿻"

def extract_components(decomposition, mmh_data, etymology):
    """Extract direct child components from IDS decomposition string."""
    if not decomposition or decomposition == "？":
        return []
    components = []
    for ch in decomposition:
        if ch in IDS_OPS or ch == "？":
            continue
        if is_cjk(ch) and ch in mmh_data:
            components.append(ch)
    return components[:4]  # cap at 4 components

# ── Select best CC-CEDICT candidate entry ────────────────────────────────────
def select_best_cedict_entry(simp, group, mmh_data):
    """
    Selects the most common/standard CC-CEDICT entry among duplicate simplified CJK words.
    Uses first-syllable capitalization checks to avoid obscure proper nouns/surnames,
    and matches with MakeMeHanzi preferred pinyin for single-character words.
    """
    if len(group) == 1:
        return group[0]

    # Check if there are any candidates that do NOT start with an uppercase letter in Pinyin.
    # We check the raw pinyin of the first syllable.
    has_lowercase = False
    for entry in group:
        pinyin_raw = entry["pinyin_raw"]
        if pinyin_raw:
            first_syl = pinyin_raw.split()[0]
            if first_syl and first_syl[0].islower():
                has_lowercase = True
                break

    best_entry = None
    best_score = -999999

    for entry in group:
        score = 0
        pinyin_raw = entry["pinyin_raw"]
        first_syl = pinyin_raw.split()[0] if pinyin_raw else ""
        english = entry["english"]
        pinyin_converted = entry["pinyin"]

        # Penalty for capitalized proper nouns / surnames if lowercase alternatives exist
        if has_lowercase and first_syl and first_syl[0].isupper():
            score -= 1000

        # Penalty if definition is just a surname
        if "surname " in english.lower() or english.lower().startswith("surname"):
            score -= 500

        # Match with MakeMeHanzi preferred pinyin for single-character words
        if len(simp) == 1 and simp in mmh_data:
            mmh_pinyins = mmh_data[simp].get("pinyin", [])
            if mmh_pinyins:
                pref_py = mmh_pinyins[0].lower()
                if pinyin_converted.lower() == pref_py:
                    score += 200
                elif pinyin_converted.lower() in [py.lower() for py in mmh_pinyins]:
                    score += 100
                else:
                    score -= 50

        if score > best_score:
            best_score = score
            best_entry = entry

    return best_entry

# ── Main pipeline ─────────────────────────────────────────────────────────────
def build_database():
    print("\n=== Sinosphere Rosetta — Phase 0 Data Pipeline ===\n")

    # Load all raw data
    hv_map   = parse_unihan_hanviet()
    mmh_data = parse_makemehanzi()
    ids_map  = parse_cjkvi()
    hanja    = parse_hanja()
    cedict   = parse_cedict()
    freq     = parse_frequency()
    hsk_lu   = build_hsk_lookup()

    # ── Create database ───────────────────────────────────────────────────────
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()
    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()

    print("\nCreating schema...")
    cur.executescript("""
    CREATE TABLE components (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL,
        pinyin TEXT NOT NULL,
        han_viet TEXT NOT NULL,
        english_def TEXT NOT NULL,
        stroke_count INTEGER DEFAULT 0
    );

    CREATE TABLE characters (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL UNIQUE,
        pinyin TEXT NOT NULL,
        hangul TEXT,
        han_viet TEXT NOT NULL,
        english_def TEXT NOT NULL,
        etymology_story TEXT,
        decomposition TEXT,
        radical TEXT,
        hsk_level INTEGER,
        jp_onyomi TEXT,
        stroke_count INTEGER DEFAULT 0
    );

    CREATE TABLE character_components (
        character_id TEXT NOT NULL,
        component_id TEXT NOT NULL,
        component_type TEXT CHECK(component_type IN ('semantic','phonetic','iconic')),
        position INTEGER DEFAULT 0,
        PRIMARY KEY (character_id, component_id),
        FOREIGN KEY (character_id) REFERENCES characters(id),
        FOREIGN KEY (component_id) REFERENCES components(id)
    );

    CREATE TABLE compound_words (
        id TEXT PRIMARY KEY,
        simplified TEXT NOT NULL UNIQUE,
        traditional TEXT,
        pinyin TEXT NOT NULL,
        hangul TEXT,
        han_viet TEXT NOT NULL,
        han_viet_resonance TEXT DEFAULT 'medium'
            CHECK(han_viet_resonance IN ('high','medium','low','none')),
        vietnamese_note TEXT,
        english_def TEXT NOT NULL,
        hsk_level INTEGER,
        frequency_rank INTEGER,
        origin_type TEXT DEFAULT 'sino_chinese',
        is_cognate_anchor INTEGER DEFAULT 0,
        ai_generated INTEGER DEFAULT 0
    );

    CREATE TABLE word_characters (
        word_id TEXT NOT NULL,
        character_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (word_id, character_id, position),
        FOREIGN KEY (word_id) REFERENCES compound_words(id),
        FOREIGN KEY (character_id) REFERENCES characters(id)
    );

    CREATE TABLE user_collections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        created_at INTEGER NOT NULL
    );

    CREATE TABLE user_collection_words (
        collection_id TEXT NOT NULL,
        word_id TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (collection_id, word_id)
    );

    CREATE TABLE reading_history (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        raw_text TEXT NOT NULL,
        token_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
    );

    CREATE TABLE ai_cache (
        query TEXT PRIMARY KEY,
        response_json TEXT NOT NULL,
        cached_at INTEGER NOT NULL
    );
    """)
    con.commit()
    print("  Schema created.")

    # ── Insert characters from MakeMeHanzi ────────────────────────────────────
    print("\nInserting characters...")
    char_rows = 0
    comp_rows = 0
    char_comp_rows = 0
    inserted_components = set()

    for ch, data in mmh_data.items():
        if not is_cjk(ch):
            continue

        han_viet = hv_map.get(ch, "")
        hangul   = hanja.get(ch, "")
        pinyin_list = data["pinyin"]
        pinyin   = pinyin_list[0] if pinyin_list else ""
        english  = data.get("definition", "") or ""
        decomp   = data.get("decomposition", "")
        radical  = data.get("radical", "")
        etym     = data.get("etymology", {})

        # Convert pinyin number format if needed
        if pinyin and pinyin[-1].isdigit():
            pinyin = convert_syllable(pinyin)

        cur.execute("""
            INSERT OR IGNORE INTO characters
            (id, symbol, pinyin, hangul, han_viet, english_def, decomposition, radical)
            VALUES (?,?,?,?,?,?,?,?)
        """, (char_id(ch), ch, pinyin, hangul or None, han_viet, english, decomp, radical))
        char_rows += 1

        # Extract and insert components
        components = extract_components(decomp, mmh_data, etym)
        for pos, comp_ch in enumerate(components):
            cid = comp_id(comp_ch)
            if cid not in inserted_components:
                comp_hv  = hv_map.get(comp_ch, "")
                comp_py  = ""
                comp_def = ""
                if comp_ch in mmh_data:
                    comp_py_list = mmh_data[comp_ch]["pinyin"]
                    comp_py  = comp_py_list[0] if comp_py_list else ""
                    comp_def = mmh_data[comp_ch].get("definition", "") or ""
                    if comp_py and comp_py[-1].isdigit():
                        comp_py = convert_syllable(comp_py)
                cur.execute("""
                    INSERT OR IGNORE INTO components (id, symbol, pinyin, han_viet, english_def)
                    VALUES (?,?,?,?,?)
                """, (cid, comp_ch, comp_py, comp_hv, comp_def))
                inserted_components.add(cid)
                comp_rows += 1

            ctype = infer_component_type(etym, comp_ch, ch)
            cur.execute("""
                INSERT OR IGNORE INTO character_components
                (character_id, component_id, component_type, position)
                VALUES (?,?,?,?)
            """, (char_id(ch), cid, ctype, pos))
            char_comp_rows += 1

    con.commit()
    print(f"  Characters: {char_rows}")
    print(f"  Components: {comp_rows}")
    print(f"  Character-component links: {char_comp_rows}")

    # ── Group and select best CC-CEDICT entries ───────────────────────────────
    print("\nGrouping and selecting best CC-CEDICT entries...")
    cedict_groups = {}
    for entry in cedict:
        cedict_groups.setdefault(entry["simplified"], []).append(entry)

    selected_cedict = []
    for simp, group in cedict_groups.items():
        best_entry = select_best_cedict_entry(simp, group, mmh_data)
        if best_entry:
            selected_cedict.append(best_entry)
    print(f"  Selected {len(selected_cedict)} unique compound words from {len(cedict)} raw entries.")

    # ── Insert compound words from CC-CEDICT ──────────────────────────────────
    print("\nInserting compound words...")
    word_rows = 0
    wc_rows   = 0

    for entry in selected_cedict:
        simp = entry["simplified"]

        # Build Hán-Việt — partial reconstruction allowed, '?' for missing chars
        han_viet, hv_complete = build_compound_hanviet(simp, hv_map)

        resonance = score_resonance(simp, han_viet, hv_complete, hv_map)
        hsk_level = hsk_lu.get(simp)
        freq_rank = freq.get(simp)
        hangul    = "".join(hanja.get(c, "") for c in simp if is_cjk(c)) or None
        wid       = word_id(simp)

        cur.execute("""
            INSERT OR IGNORE INTO compound_words
            (id, simplified, traditional, pinyin, hangul, han_viet,
             han_viet_resonance, english_def, hsk_level, frequency_rank, origin_type)
            VALUES (?,?,?,?,?,?,?,?,?,?,?)
        """, (wid, simp, entry["traditional"], entry["pinyin"], hangul,
              han_viet, resonance, entry["english"],
              hsk_level, freq_rank, "sino_chinese"))
        word_rows += 1

        # word_characters links
        for pos, ch in enumerate(simp):
            if is_cjk(ch) and char_id(ch) in {r[0] for r in cur.execute(
                    "SELECT id FROM characters WHERE id=?", (char_id(ch),)).fetchall()}:
                cur.execute("""
                    INSERT OR IGNORE INTO word_characters (word_id, character_id, position)
                    VALUES (?,?,?)
                """, (wid, char_id(ch), pos))
                wc_rows += 1

        if word_rows % 10000 == 0:
            print(f"  ... {word_rows} words inserted")
            con.commit()

    con.commit()
    print(f"  Compound words: {word_rows}")
    print(f"  Word-character links: {wc_rows}")

    # ── Update HSK levels for known words ─────────────────────────────────────
    print("\nApplying HSK level tags...")
    hsk_updated = 0
    for simp, level in hsk_lu.items():
        cur.execute(
            "UPDATE compound_words SET hsk_level=? WHERE simplified=?",
            (level, simp))
        if cur.rowcount:
            hsk_updated += 1
    con.commit()
    print(f"  HSK-tagged words: {hsk_updated}")

    # ── Insert HSK words missing from CC-CEDICT ───────────────────────────────
    # These are contextual phrases, grammatical patterns, and formal compounds
    # that CC-CEDICT doesn't carry as standalone entries.
    # Curated manually with pinyin, Hán-Việt, English, and resonance.
    print("\nInserting missing HSK words...")
    MISSING_HSK = [
        # fmt: (simplified, traditional, pinyin, han_viet, resonance, english, hsk_level)
        # HSK 1
        ("车上",   "車上",   "chē shàng",   "XA THƯỢNG",   "medium", "on the vehicle; aboard",            1),
        # HSK 2
        ("不一会儿","不一會兒","bù yī huì r", "BẤT NHẤT HỒI","medium", "in a moment; shortly; soon",        2),
        ("不太",   "不太",   "bù tài",       "BẤT THÁI",    "medium", "not very; not too",                 2),
        ("见过",   "見過",   "jiàn guo",     "KIẾN QUÁ",    "medium", "to have met; have seen before",     2),
        ("这时候", "這時候", "zhè shí hou",  "? THỜI HẬU",  "medium", "at this time; at this moment",      2),
        ("送到",   "送到",   "sòng dào",     "TỐNG ĐÁO",    "medium", "to deliver to; to send to",         2),
        # HSK 3
        ("干吗",   "幹嗎",   "gàn ma",       "CAN MA",      "low",    "why; what for; whatever for",       3),
        ("放到",   "放到",   "fàng dào",     "PHÓNG ĐÁO",   "medium", "to put into; to place at",         3),
        ("纪录",   "紀錄",   "jì lù",        "KỶ LỤC",      "high",   "record; (sports) record",           3),
        ("能不能", "能不能", "néng bù néng", "NĂNG BẤT NĂNG","medium","can or cannot; whether one can",    3),
        # HSK 4
        ("有劲儿", "有勁兒", "yǒu jìn r",    "HỮU KÌNH",    "medium", "energetic; forceful; strong",       4),
        ("眼里",   "眼裡",   "yǎn lǐ",       "NHÃN LỊA",    "medium", "in one's eyes; in one's view",      4),
        # HSK 5
        ("城里",   "城裡",   "chéng lǐ",     "THÀNH LỊA",   "medium", "in the city; inside the city",      5),
        ("辞典",   "辭典",   "cí diǎn",      "TỪ ĐIỂN",     "high",   "dictionary; lexicon",               5),
        # HSK 6
        ("一番",   "一番",   "yī fān",       "NHẤT PHIÊN",  "high",   "a time; once; a measure word for actions",6),
        ("很难说", "很難說", "hěn nán shuō", "? NAN THUYẾT","medium", "hard to say; difficult to tell",    6),
        ("指着",   "指著",   "zhǐ zhe",      "CHỈ TRƯỚC",   "medium", "pointing at; indicating",           6),
        # HSK 7-9
        ("下功夫", "下功夫", "xià gōng fu",  "HẠ CÔNG PHU", "high",   "to put in effort; to work hard at", 7),
        ("不予",   "不予",   "bù yǔ",        "BẤT DỰ",      "high",   "to not give; to withhold; to deny", 7),
        ("不利于", "不利於", "bù lì yú",     "BẤT LỢI VÀO", "medium", "unfavorable to; disadvantageous for",7),
        ("不如说", "不如說", "bù rú shuō",   "BẤT NHƯ THUYẾT","medium","it would be better to say; rather", 7),
        ("不肯",   "不肯",   "bù kěn",       "BẤT KHẲNG",   "medium", "unwilling to; refusing to",         7),
        ("不难",   "不難",   "bù nán",       "BẤT NAN",     "high",   "not difficult; easy",               7),
        ("做证",   "做證",   "zuò zhèng",    "TÁC CHỨNG",   "high",   "to testify; to give evidence",      7),
        ("公益性", "公益性", "gōng yì xìng", "CÔNG ÍCH TÍNH","high",  "public welfare nature; non-profit", 7),
        ("定为",   "定為",   "dìng wéi",     "ĐỊNH VI",     "high",   "to designate as; to set as",        7),
        ("得意扬扬","得意揚揚","dé yì yáng yáng","ĐẮC Ý DƯƠNG DƯƠNG","high","complacent; self-satisfied; triumphant",7),
        ("怀着",   "懷著",   "huái zhe",     "HOÀI TRƯỚC",  "medium", "to hold in the heart; cherishing",  7),
        ("火暴",   "火暴",   "huǒ bào",      "HỎA BẠO",     "high",   "fiery; violent; explosive (temper)", 7),
        ("着眼于", "著眼於", "zhuó yǎn yú",  "TRƯỚC NHÃN VÀO","medium","to focus on; to keep in view",     7),
        ("纯朴",   "純樸",   "chún pǔ",      "THUẦN PHÁC",  "high",   "simple and honest; unsophisticated", 7),
        ("致力于", "致力於", "zhì lì yú",    "TRÍ LỰC VÀO", "medium", "to devote oneself to; to work for", 7),
        ("说起来", "說起來", "shuō qǐ lai",  "THUYẾT KHỞI LAI","medium","speaking of; come to think of it", 7),
        ("趁着",   "趁著",   "chèn zhe",     "THỪA TRƯỚC",  "medium", "to take advantage of; while",       7),
        ("难以想象","難以想象","nán yǐ xiǎng xiàng","NAN DĨ TƯỞNG TƯỢNG","high","hard to imagine; unimaginable",7),
        ("飞往",   "飛往",   "fēi wǎng",     "PHI VÃNG",    "high",   "to fly to; to travel by air to",    7),
    ]

    missing_inserted = 0
    for row in MISSING_HSK:
        simp, trad, pinyin, han_viet, resonance, english, hsk = row
        wid = word_id(simp)
        # Skip if somehow already exists
        if cur.execute("SELECT 1 FROM compound_words WHERE simplified=?", (simp,)).fetchone():
            continue
        hangul = "".join(hanja.get(c, "") for c in simp if is_cjk(c)) or None
        freq_rank = freq.get(simp)
        cur.execute("""
            INSERT OR IGNORE INTO compound_words
            (id, simplified, traditional, pinyin, hangul, han_viet,
             han_viet_resonance, english_def, hsk_level, frequency_rank, origin_type)
            VALUES (?,?,?,?,?,?,?,?,?,?,?)
        """, (wid, simp, trad, pinyin, hangul, han_viet,
              resonance, english, hsk, freq_rank, "sino_chinese"))
        # word_characters links
        for pos, ch in enumerate(simp):
            if is_cjk(ch):
                cid = char_id(ch)
                if cur.execute("SELECT 1 FROM characters WHERE id=?", (cid,)).fetchone():
                    cur.execute("""
                        INSERT OR IGNORE INTO word_characters (word_id, character_id, position)
                        VALUES (?,?,?)
                    """, (wid, cid, pos))
        missing_inserted += 1

    con.commit()
    print(f"  Missing HSK words inserted: {missing_inserted}")

    # ── Curated compound overrides ────────────────────────────────────────────
    # Fix compounds where per-character concatenation gives the wrong Hán-Việt
    # due to polysemous characters or unusual compound readings.
    print("\nApplying curated compound overrides...")
    COMPOUND_OVERRIDES = {
        # 乐 = NHẠC (music) but LẠC (happiness) — must fix compounds using LẠC sense
        "快乐":  ("KHOÁI LẠC",  "high"),
        "乐趣":  ("LẠC THÚ",   "high"),
        "乐观":  ("LẠC QUAN",   "high"),
        "娱乐":  ("NGU LẠC",    "high"),
        "享乐":  ("HƯỞNG LẠC",  "high"),
        "安乐":  ("AN LẠC",     "high"),
        "乐园":  ("LẠC VIÊN",   "high"),
        # 长 = TRƯỜNG (long) but TRƯỞNG (elder/chief) in some compounds
        "长辈":  ("TRƯỞNG BỐI", "high"),
        "长官":  ("TRƯỞNG QUAN","high"),
        "成长":  ("THÀNH TRƯỞNG","high"),
        "部长":  ("BỘ TRƯỞNG",  "high"),
        "市长":  ("THỊ TRƯỞNG", "high"),
        "校长":  ("HIỆU TRƯỞNG","high"),
        "队长":  ("ĐỘI TRƯỞNG", "high"),
        # 好 = HẢO (good) but HÁO (fond of) in some compounds
        "好奇":  ("HÁO KỲ",    "high"),
        "好学":  ("HÁO HỌC",   "high"),
        # 大 = ĐẠI but compounds where it reads as TẠI should be corrected
        # (none needed currently)
    }
    overridden = 0
    for simp, (new_hv, new_res) in COMPOUND_OVERRIDES.items():
        cur.execute("""
            UPDATE compound_words
            SET han_viet=?, han_viet_resonance=?
            WHERE simplified=?
        """, (new_hv, new_res, simp))
        if cur.rowcount:
            overridden += 1

    # Fix pinyin for entries where CC-CEDICT dedup picked the wrong reading
    PINYIN_OVERRIDES = {
        # simplified: (correct_pinyin, correct_english)
        "长":  ("cháng", "long; length; strong point; to be good at"),
        "着":  ("zhe",   "aspect particle indicating action in progress or ongoing state"),
    }
    for simp, (py, eng) in PINYIN_OVERRIDES.items():
        cur.execute("""
            UPDATE compound_words SET pinyin=?, english_def=?
            WHERE simplified=?
        """, (py, eng, simp))
    con.commit()
    print(f"  Compound overrides applied: {overridden}, pinyin fixes: {len(PINYIN_OVERRIDES)}")
    con.commit()
    print(f"  Compound overrides applied: {overridden}")

    # ── Mark cognate anchors (high resonance + hsk <= 4 + freq rank <= 5000) ─
    print("\nMarking cognate anchors...")
    cur.execute("""
        UPDATE compound_words SET is_cognate_anchor=1
        WHERE han_viet_resonance='high'
          AND (hsk_level <= 4 OR frequency_rank <= 5000)
          AND han_viet != ''
    """)
    anchor_count = cur.execute(
        "SELECT COUNT(*) FROM compound_words WHERE is_cognate_anchor=1").fetchone()[0]
    con.commit()
    print(f"  Cognate anchors: {anchor_count}")

    # ── Create indexes for sub-50ms search ────────────────────────────────────
    print("\nCreating search indexes...")
    cur.executescript("""
        CREATE INDEX IF NOT EXISTS idx_words_simplified   ON compound_words(simplified);
        CREATE INDEX IF NOT EXISTS idx_words_hanviet      ON compound_words(han_viet);
        CREATE INDEX IF NOT EXISTS idx_words_hsk          ON compound_words(hsk_level);
        CREATE INDEX IF NOT EXISTS idx_words_resonance    ON compound_words(han_viet_resonance);
        CREATE INDEX IF NOT EXISTS idx_words_freq         ON compound_words(frequency_rank);
        CREATE INDEX IF NOT EXISTS idx_words_anchor       ON compound_words(is_cognate_anchor);
        CREATE INDEX IF NOT EXISTS idx_chars_symbol       ON characters(symbol);
        CREATE INDEX IF NOT EXISTS idx_chars_hanviet      ON characters(han_viet);
        CREATE INDEX IF NOT EXISTS idx_comps_symbol       ON components(symbol);
        CREATE INDEX IF NOT EXISTS idx_char_comp_char     ON character_components(character_id);
        CREATE INDEX IF NOT EXISTS idx_wc_word            ON word_characters(word_id);
        CREATE INDEX IF NOT EXISTS idx_wc_char            ON word_characters(character_id);
    """)
    con.commit()
    print("  Indexes created.")

    # ── Full-text search virtual table ────────────────────────────────────────
    # Include pinyin so users can search by romanization too.
    # rank() weighted: simplified=10, han_viet=5, pinyin=3, english=1
    cur.executescript("""
        CREATE VIRTUAL TABLE IF NOT EXISTS words_fts USING fts5(
            simplified, han_viet, pinyin, english_def,
            content='compound_words', content_rowid='rowid',
            tokenize='unicode61'
        );
        INSERT INTO words_fts(words_fts) VALUES('rebuild');

        -- Frequency-boosted search view: wraps FTS with frequency ordering
        CREATE VIEW IF NOT EXISTS v_search AS
            SELECT cw.rowid, cw.simplified, cw.pinyin, cw.han_viet,
                   cw.english_def, cw.han_viet_resonance,
                   cw.hsk_level, cw.frequency_rank, cw.is_cognate_anchor
            FROM compound_words cw
            ORDER BY
                CASE WHEN cw.hsk_level IS NOT NULL THEN cw.hsk_level ELSE 99 END,
                CASE WHEN cw.frequency_rank IS NOT NULL THEN cw.frequency_rank ELSE 999999 END;
    """)
    con.commit()
    print("  FTS index built.")

    # ── Final stats ───────────────────────────────────────────────────────────
    print("\n=== Database Summary ===")
    for table in ["characters","components","character_components",
                  "compound_words","word_characters"]:
        count = cur.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"  {table:30s}: {count:,}")

    # Resonance breakdown
    print("\n  hanviet_resonance breakdown:")
    for row in cur.execute("""
        SELECT han_viet_resonance, COUNT(*) as n
        FROM compound_words GROUP BY han_viet_resonance ORDER BY n DESC
    """):
        print(f"    {row[0]:8s}: {row[1]:,}")

    # HSK breakdown
    print("\n  HSK level breakdown:")
    for row in cur.execute("""
        SELECT hsk_level, COUNT(*) as n FROM compound_words
        WHERE hsk_level IS NOT NULL
        GROUP BY hsk_level ORDER BY hsk_level
    """):
        print(f"    HSK {row[0]}: {row[1]:,}")

    db_size = DB_PATH.stat().st_size / 1024 / 1024
    print(f"\n  Database size: {db_size:.1f} MB")
    print(f"  Path: {DB_PATH}")
    print("\n=== Phase 0 Complete ===\n")

    con.close()

if __name__ == "__main__":
    build_database()
