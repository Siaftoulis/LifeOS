#!/usr/bin/env python3
"""
LifeOS Orthodox Typikon & Euchologion Sync Engine
=================================================
Automated liturgical compiler, validator, and web scraper for:
- Paschal movable cycle & Octoechos 8-tone calculations
- Seasonal Katavasies selection & rubrics
- Daily Scripture readings (Epistle & Gospel pericopes)
- Synaxarion & Menaion feast validation
- Yearly Typikon JSON generation for LifeOS Go Daemon

Usage:
  python sync_typikon.py --year 2026 --validate
  python sync_typikon.py --generate-all
  python sync_typikon.py --test-date 2026-08-30
"""

import argparse
import datetime
import json
import os
import re
import sys
import urllib.request
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple

DATA_DIR = Path(__file__).parent
OUTPUT_TYPIKON = DATA_DIR / "typikon_yearly_raw.json"
LECTIONARY_FILE = DATA_DIR / "lectionary_raw.json"
SYNAXARION_FILE = DATA_DIR / "synaxarion_raw.json"
TRIODION_FILE = DATA_DIR / "triodion_raw.json"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) LifeOS/1.0",
    "Accept": "application/json,text/html,*/*",
    "Accept-Language": "el,en-US;q=0.9",
}

TONES = [
    "Ήχος Α'",
    "Ήχος Β'",
    "Ήχος Γ'",
    "Ήχος Δ'",
    "Ήχος Πλ. Α'",
    "Ήχος Πλ. Β'",
    "Ήχος Βαρύς",
    "Ήχος Πλ. Δ'",
]


def calculate_orthodox_easter(year: int) -> datetime.date:
    """Computes Gregorian date of Orthodox Pascha using Meeus Julian Easter algorithm."""
    a = year % 4
    b = year % 7
    c = year % 19
    d = (19 * c + 15) % 30
    e = (2 * a + 4 * b - d + 34) % 7
    month = (d + e + 114) // 31
    day = ((d + e + 114) % 31) + 1
    julian_easter = datetime.date(year, month, day)
    gregorian_easter = julian_easter + datetime.timedelta(days=13)
    return gregorian_easter


def get_movable_dates(year: int) -> Dict[str, datetime.date]:
    """Calculates all key movable liturgical cycle dates for a year."""
    pascha = calculate_orthodox_easter(year)
    triodion_start = pascha - datetime.timedelta(days=70)  # Publican & Pharisee
    meatfare = pascha - datetime.timedelta(days=56)
    cheesefare = pascha - datetime.timedelta(days=49)
    clean_monday = pascha - datetime.timedelta(days=48)
    palm_sunday = pascha - datetime.timedelta(days=7)
    holy_thursday = pascha - datetime.timedelta(days=3)
    holy_friday = pascha - datetime.timedelta(days=2)
    holy_saturday = pascha - datetime.timedelta(days=1)
    bright_monday = pascha + datetime.timedelta(days=1)
    thomas_sunday = pascha + datetime.timedelta(days=7)
    ascension = pascha + datetime.timedelta(days=39)
    pentecost = pascha + datetime.timedelta(days=49)
    all_saints = pascha + datetime.timedelta(days=56)
    
    # Apostles' fast starts on Monday after All Saints
    apostles_start = all_saints + datetime.timedelta(days=1)
    while apostles_start.weekday() != 0:  # Monday
        apostles_start += datetime.timedelta(days=1)
    apostles_end = datetime.date(year, 6, 28)

    return {
        "triodion_start": triodion_start,
        "meatfare": meatfare,
        "cheesefare": cheesefare,
        "clean_monday": clean_monday,
        "palm_sunday": palm_sunday,
        "holy_thursday": holy_thursday,
        "holy_friday": holy_friday,
        "holy_saturday": holy_saturday,
        "pascha": pascha,
        "bright_monday": bright_monday,
        "thomas_sunday": thomas_sunday,
        "ascension": ascension,
        "pentecost": pentecost,
        "all_saints": all_saints,
        "apostles_start": apostles_start,
        "apostles_end": apostles_end,
    }


def get_octoechos_tone(target_date: datetime.date) -> Tuple[str, int]:
    """Calculates the Ήχος (Tone 1-8) of the week for any date."""
    year = target_date.year
    pascha = calculate_orthodox_easter(year)
    thomas_sunday = pascha + datetime.timedelta(days=7)

    if pascha <= target_date < thomas_sunday:
        return "Ήχος Α' (Διακαινήσιμος)", 1

    if target_date >= thomas_sunday:
        diff_days = (target_date - thomas_sunday).days
        weeks = diff_days // 7
        tone_idx = (weeks % 8) + 1
        return TONES[tone_idx - 1], tone_idx

    # Before Pascha: compute from previous year's Thomas Sunday
    pascha_prev = calculate_orthodox_easter(year - 1)
    thomas_prev = pascha_prev + datetime.timedelta(days=7)
    diff_days = (target_date - thomas_prev).days
    weeks = diff_days // 7
    tone_idx = (weeks % 8) + 1
    return TONES[tone_idx - 1], tone_idx


def get_seasonal_katavasies(target_date: datetime.date) -> Dict[str, str]:
    """Determines the appropriate Katavasies for a date based on Typikon rules."""
    m, d = target_date.month, target_date.day
    movable = get_movable_dates(target_date.year)
    pascha = movable["pascha"]
    ascension = movable["ascension"]
    pentecost = movable["pentecost"]
    all_saints = movable["all_saints"]

    # 1. Pascha to Ascension
    if pascha <= target_date < ascension:
        return {
            "id": "pascha",
            "name": "Καταβασίαι του Πάσχα («Αναστάσεως ημέρα»)",
            "tone": "Ήχος Α'",
            "period": "Διακαινήσιμος & Πασχάλιος Περίοδος",
        }

    # 2. Ascension to Pentecost
    if ascension <= target_date < pentecost:
        return {
            "id": "ascension_pentecost",
            "name": "Καταβασίαι της Αναλήψεως («Θείω καλυφθείς»)",
            "tone": "Ήχος Δ'",
            "period": "Ανάληψις & Πεντηκοστή",
        }

    # 3. Pentecost to All Saints
    if target_date == pentecost or (pentecost < target_date <= all_saints):
        return {
            "id": "pentecost",
            "name": "Καταβασίαι της Πεντηκοστής («Πόντω εκάλυψε»)",
            "tone": "Ήχος Δ'",
            "period": "Εβδομάς Αγίου Πνεύματος",
        }

    # 4. Nativity (21 Nov - 31 Dec)
    if (m == 11 and d >= 21) or (m == 12):
        return {
            "id": "nativity",
            "name": "Καταβασίαι των Χριστουγέννων («Χριστός γεννάται»)",
            "tone": "Ήχος Α'",
            "period": "Χριστούγεννα & Προεόρτια",
        }

    # 5. Theophany (1 Jan - 14 Jan)
    if m == 1 and d <= 14:
        return {
            "id": "theophany",
            "name": "Καταβασίαι των Θεοφανείων («Βυθού ανεκάλυψε»)",
            "tone": "Ήχος Β'",
            "period": "Θεοφάνεια",
        }

    # 6. Meeting of the Lord (15 Jan - 9 Feb)
    if (m == 1 and d >= 15) or (m == 2 and d <= 9):
        return {
            "id": "hypapante",
            "name": "Καταβασίαι της Υπαπαντής («Χέρσον αβυσσοτόκον»)",
            "tone": "Ήχος Γ'",
            "period": "Υπαπαντή",
        }

    # 7. Holy Cross (1-6 Aug & 24 Aug - 21 Sep)
    if (m == 8 and (d <= 6 or d >= 24)) or (m == 9 and d <= 21):
        return {
            "id": "holy_cross",
            "name": "Καταβασίαι του Τιμίου Σταυρού («Σταυρόν χαράξας»)",
            "tone": "Ήχος Πλ. Δ'",
            "period": "Ύψωσις Τιμίου Σταυρού",
        }

    # 8. Standard Theotokos Katavasies
    return {
        "id": "theotokos_standard",
        "name": "Καταβασίαι της Θεοτόκου («Ανοίξω το στόμα μου»)",
        "tone": "Ήχος Δ'",
        "period": "Κοινός Κανών",
    }


def calculate_fasting_rule(target_date: datetime.date) -> str:
    """Computes the Orthodox fasting rule for any day."""
    m, d = target_date.month, target_date.day
    weekday = target_date.weekday()  # Monday=0, Sunday=6
    movable = get_movable_dates(target_date.year)
    pascha = movable["pascha"]
    clean_monday = movable["clean_monday"]
    cheesefare = movable["cheesefare"]
    meatfare = movable["meatfare"]

    # 1. Great Feasts with Fish/Wine exemption
    if (m == 3 and d == 25) or (m == 8 and d == 6):
        return "Κατάλυσις Ιχθύος"

    # 2. Strict fast days regardless of weekday
    if (m == 1 and d == 5) or (m == 8 and d == 29) or (m == 9 and d == 14):
        return "Νηστεία (Άνευ Ελαίου & Οίνου)"

    # 3. Bright Week & After Nativity fast-free
    if pascha <= target_date < pascha + datetime.timedelta(days=7):
        return "Ανηστεία"
    if m == 12 and d >= 25:
        return "Ανηστεία"
    if m == 1 and d <= 4:
        return "Ανηστεία"

    # 4. Cheesefare Week (Dairy allowed)
    if meatfare < target_date <= cheesefare:
        return "Κατάλυσις Τυρού και Ωών"

    # 5. Great Lent
    if clean_monday <= target_date < pascha:
        if weekday in (5, 6):  # Sat, Sun
            return "Κατάλυσις Οίνου και Ελαίου"
        return "Νηστεία (Άνευ Ελαίου & Οίνου)"

    # 6. Dormition Fast (1-14 Aug)
    if m == 8 and 1 <= d <= 14:
        if weekday in (5, 6):
            return "Κατάλυσις Οίνου και Ελαίου"
        return "Νηστεία (Άνευ Ελαίου & Οίνου)"

    # 7. Standard Wednesday / Friday fast
    if weekday in (2, 4):  # Wed, Fri
        return "Νηστεία (Άνευ Ελαίου & Οίνου)"

    return "Ανηστεία"


def generate_yearly_typikon(year: int) -> Dict[str, Any]:
    """Compiles the full 365/366 days Typikon map for a given year."""
    start_date = datetime.date(year, 1, 1)
    end_date = datetime.date(year, 12, 31)
    cur = start_date

    movable = get_movable_dates(year)
    days_data = {}

    while cur <= end_date:
        date_str = cur.strftime("%Y-%m-%d")
        mm_dd = cur.strftime("%m-%d")
        tone_str, tone_num = get_octoechos_tone(cur)
        katavasies = get_seasonal_katavasies(cur)
        fasting = calculate_fasting_rule(cur)

        days_data[date_str] = {
            "date": date_str,
            "mm_dd": mm_dd,
            "weekday": cur.strftime("%A"),
            "weekday_num": cur.weekday(),
            "tone": tone_str,
            "tone_num": tone_num,
            "katavasies": katavasies,
            "fasting": fasting,
            "is_sunday": cur.weekday() == 6,
        }
        cur += datetime.timedelta(days=1)

    return {
        "year": year,
        "generated_at": datetime.datetime.now().isoformat(),
        "pascha": movable["pascha"].strftime("%Y-%m-%d"),
        "clean_monday": movable["clean_monday"].strftime("%Y-%m-%d"),
        "pentecost": movable["pentecost"].strftime("%Y-%m-%d"),
        "days": days_data,
    }


def validate_existing_datasets() -> Dict[str, Any]:
    """Validates Lectionary, Synaxarion, and Liturgical books for completeness."""
    report = {"errors": [], "warnings": [], "summary": {}}

    # Check Lectionary
    if LECTIONARY_FILE.exists():
        with open(LECTIONARY_FILE, "r", encoding="utf-8") as f:
            lec = json.load(f)
        readings = lec.get("readings", {})
        report["summary"]["lectionary_days"] = len(readings)
        if len(readings) < 365:
            report["warnings"].append(f"Lectionary has {len(readings)} days (expected 365+)")
    else:
        report["errors"].append("lectionary_raw.json missing")

    # Check Synaxarion
    if SYNAXARION_FILE.exists():
        with open(SYNAXARION_FILE, "r", encoding="utf-8") as f:
            syn = json.load(f)
        days = syn.get("days", {})
        report["summary"]["synaxarion_days"] = len(days)
    else:
        report["errors"].append("synaxarion_raw.json missing")

    return report


def main():
    parser = argparse.ArgumentParser(description="LifeOS Typikon & Euchologion Sync Engine")
    parser.add_argument("--year", type=int, default=datetime.date.today().year, help="Liturgical year to generate")
    parser.add_argument("--validate", action="store_true", help="Validate existing data files")
    parser.add_argument("--generate-all", action="store_true", help="Generate typikon_yearly_raw.json")
    parser.add_argument("--test-date", type=str, help="Test resolution for specific date (YYYY-MM-DD)")

    args = parser.parse_args()

    if args.validate:
        print("Validating liturgical datasets...")
        rep = validate_existing_datasets()
        print(json.dumps(rep, ensure_ascii=False, indent=2))
        return

    if args.test_date:
        d = datetime.datetime.strptime(args.test_date, "%Y-%m-%d").date()
        tone_str, tone_num = get_octoechos_tone(d)
        kat = get_seasonal_katavasies(d)
        fast = calculate_fasting_rule(d)
        res = {
            "date": args.test_date,
            "tone": tone_str,
            "katavasies": kat,
            "fasting": fast,
        }
        print(json.dumps(res, ensure_ascii=False, indent=2))
        return

    # Default / generate-all: generate yearly Typikon JSON
    print(f"Generating Typikon for year {args.year}...")
    data = generate_yearly_typikon(args.year)
    with open(OUTPUT_TYPIKON, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Saved yearly Typikon to {OUTPUT_TYPIKON} ({len(data['days'])} days)")


if __name__ == "__main__":
    main()
