#!/usr/bin/env python3
"""Generate deterministic synthetic rows for the demo seed CSVs.

The script preserves the small hand-authored seed rows and replaces only rows
inside the generated ID ranges below. That makes reruns idempotent: the same
arguments produce the same CSV files without duplicate appends.
"""

from __future__ import annotations

import argparse
import csv
import random
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Callable, Iterable


GENERATED_ID_STARTS = {
    "article_id": 100_000,
    "reader_id": 200_000,
    "pageview_id": 30_000_000,
    "subscription_id": 40_000_000,
    "campaign_id": 50_000_000,
    "send_id": 60_000_000,
    "paywall_event_id": 70_000_000,
}

SEED_FILES = {
    "articles": "raw_articles.csv",
    "readers": "raw_readers.csv",
    "pageviews": "raw_pageviews.csv",
    "subscriptions": "raw_subscriptions.csv",
    "ad_campaigns": "raw_ad_campaigns.csv",
    "newsletter_sends": "raw_newsletter_sends.csv",
    "paywall_events": "raw_paywall_events.csv",
}

SECTIONS = ["News", "Culture", "Business", "Sports", "Media", "Entertainment"]
PRIMARY_CHANNELS = ["search", "social", "newsletter"]
ACQUISITION_CHANNELS = ["newsletter", "search", "social", "referral"]
COUNTRIES = ["United Kingdom", "United States", "Ireland", "Canada", "Australia"]
AGE_BANDS = ["18-24", "25-34", "35-44", "45-54", "55-64", "65+"]
EMAIL_DOMAINS = ["example.com", "mail.com", "news.test", "reader.net", "demo.org"]
AUTHORS = [
    "Avery Stone",
    "Jamie Lee",
    "Morgan Patel",
    "Riley Brooks",
    "Taylor Morgan",
    "Casey Reed",
    "Jordan Quinn",
    "Sam Rivera",
]
HEADLINE_NOUNS = [
    "housing",
    "transport",
    "football",
    "theatre",
    "streaming",
    "markets",
    "elections",
    "startups",
    "schools",
    "restaurants",
]
HEADLINE_VERBS = [
    "faces fresh scrutiny",
    "draws record interest",
    "sets new agenda",
    "sparks local debate",
    "finds a wider audience",
    "signals cautious optimism",
]
DEVICE_TYPES = ["mobile", "desktop", "tablet"]
TRAFFIC_SOURCES = ["search", "social", "newsletter", "direct", "referral"]
PLAN_NAMES = ["Digital", "Digital Plus", "Print + Digital"]
BILLING_PERIODS = ["monthly", "annual"]
SUBSCRIPTION_STATUSES = ["active", "cancelled", "trial"]
ADVERTISER_CATEGORIES = [
    "Transport",
    "Entertainment",
    "Finance",
    "Retail",
    "Education",
    "Technology",
]
NEWSLETTER_NAMES = [
    "Morning Briefing",
    "Daily Edition",
    "Weekend Reads",
    "Culture Notes",
    "Business Dispatch",
]
SEND_STATUSES = ["sent", "sent", "sent", "sent", "bounced"]
EVENT_TYPES = ["paywall_view", "meter_limit"]
CONVERSION_STATUSES = ["viewed", "dismissed", "trial_started", "converted"]
OFFER_NAMES = ["Digital", "Digital Plus", "Intro Offer", "Annual Saver"]


@dataclass(frozen=True)
class ExistingIds:
    article_ids: list[int]
    reader_ids: list[int]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate deterministic synthetic rows for seed-backed raw sources.",
    )
    parser.add_argument(
        "--rows-per-source",
        type=int,
        default=1_000,
        help="Synthetic rows to generate for each raw source CSV.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for deterministic output.",
    )
    parser.add_argument(
        "--seeds-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "seeds",
        help="Directory containing raw seed CSV files.",
    )
    parser.add_argument(
        "--start-date",
        type=date.fromisoformat,
        default=date(2026, 6, 1),
        help="First date used when spreading generated event timestamps.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print intended row counts without writing CSV files.",
    )
    return parser.parse_args()


def read_rows(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(newline="", encoding="utf-8") as file:
        reader = csv.DictReader(file)
        if reader.fieldnames is None:
            raise ValueError(f"{path} has no header row")
        return reader.fieldnames, list(reader)


def write_rows(path: Path, fieldnames: list[str], rows: Iterable[dict[str, object]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fieldnames})


def base_rows(rows: list[dict[str, str]], id_column: str) -> list[dict[str, str]]:
    generated_start = GENERATED_ID_STARTS[id_column]
    return [
        row
        for row in rows
        if int(row[id_column]) < generated_start
    ]


def csv_bool(value: bool) -> str:
    return "true" if value else "false"


def fmt_date(value: date) -> str:
    return value.isoformat()


def fmt_datetime(value: datetime | None) -> str:
    return "" if value is None else value.strftime("%Y-%m-%d %H:%M:%S")


def choose_id(rng: random.Random, ids: list[int], offset: int) -> int:
    return ids[(offset + rng.randrange(len(ids))) % len(ids)]


def generated_ids(id_column: str, count: int) -> list[int]:
    start = GENERATED_ID_STARTS[id_column]
    return [start + offset for offset in range(1, count + 1)]


def generate_articles(count: int, rng: random.Random, start_date: date) -> list[dict[str, object]]:
    rows = []
    for offset, article_id in enumerate(generated_ids("article_id", count), start=1):
        published_at = datetime.combine(start_date + timedelta(days=offset % 45), datetime.min.time())
        published_at += timedelta(hours=6 + offset % 12, minutes=(offset * 7) % 60)
        section = SECTIONS[offset % len(SECTIONS)]
        rows.append(
            {
                "article_id": article_id,
                "headline": f"{rng.choice(HEADLINE_NOUNS).title()} {rng.choice(HEADLINE_VERBS)}",
                "section": section,
                "author": AUTHORS[offset % len(AUTHORS)],
                "published_at": fmt_datetime(published_at),
                "primary_channel": PRIMARY_CHANNELS[offset % len(PRIMARY_CHANNELS)],
                "word_count": rng.randint(450, 2_400),
                "is_premium": csv_bool(section in {"Business", "Media"} or offset % 5 == 0),
            }
        )
    return rows


def generate_readers(count: int, rng: random.Random, start_date: date) -> list[dict[str, object]]:
    rows = []
    signup_start = start_date - timedelta(days=40)
    for offset, reader_id in enumerate(generated_ids("reader_id", count), start=1):
        rows.append(
            {
                "reader_id": reader_id,
                "email_domain": EMAIL_DOMAINS[offset % len(EMAIL_DOMAINS)],
                "signup_date": fmt_date(signup_start + timedelta(days=offset % 55)),
                "acquisition_channel": ACQUISITION_CHANNELS[offset % len(ACQUISITION_CHANNELS)],
                "country": COUNTRIES[offset % len(COUNTRIES)],
                "age_band": AGE_BANDS[offset % len(AGE_BANDS)],
                "marketing_opt_in": csv_bool(rng.random() < 0.62),
            }
        )
    return rows


def generate_pageviews(
    count: int,
    rng: random.Random,
    start_date: date,
    existing_ids: ExistingIds,
) -> list[dict[str, object]]:
    rows = []
    article_ids = existing_ids.article_ids + generated_ids("article_id", count)
    reader_ids = existing_ids.reader_ids + generated_ids("reader_id", count)
    for offset, pageview_id in enumerate(generated_ids("pageview_id", count), start=1):
        viewed_at = datetime.combine(start_date + timedelta(days=offset % 50), datetime.min.time())
        viewed_at += timedelta(hours=7 + offset % 15, minutes=(offset * 11) % 60)
        rows.append(
            {
                "pageview_id": pageview_id,
                "article_id": choose_id(rng, article_ids, offset),
                "reader_id": choose_id(rng, reader_ids, offset * 3),
                "viewed_at": fmt_datetime(viewed_at),
                "session_id": f"gen_s{offset:06d}",
                "device_type": DEVICE_TYPES[offset % len(DEVICE_TYPES)],
                "traffic_source": TRAFFIC_SOURCES[offset % len(TRAFFIC_SOURCES)],
                "engaged_seconds": rng.randint(8, 240),
                "ad_impressions": rng.randint(0, 8),
            }
        )
    return rows


def generate_subscriptions(
    count: int,
    rng: random.Random,
    start_date: date,
    existing_ids: ExistingIds,
) -> list[dict[str, object]]:
    rows = []
    reader_ids = existing_ids.reader_ids + generated_ids("reader_id", count)
    prices = {"Digital": 899, "Digital Plus": 1299, "Print + Digital": 2499}
    for offset, subscription_id in enumerate(generated_ids("subscription_id", count), start=1):
        status = SUBSCRIPTION_STATUSES[offset % len(SUBSCRIPTION_STATUSES)]
        plan_name = PLAN_NAMES[offset % len(PLAN_NAMES)]
        started_at = start_date + timedelta(days=offset % 60)
        ended_at = "" if status != "cancelled" else fmt_date(started_at + timedelta(days=30 + offset % 45))
        rows.append(
            {
                "subscription_id": subscription_id,
                "reader_id": choose_id(rng, reader_ids, offset * 5),
                "started_at": fmt_date(started_at),
                "ended_at": ended_at,
                "plan_name": plan_name,
                "billing_period": BILLING_PERIODS[offset % len(BILLING_PERIODS)],
                "monthly_price_pence": prices[plan_name],
                "status": status,
            }
        )
    return rows


def generate_ad_campaigns(
    count: int,
    rng: random.Random,
    start_date: date,
    existing_ids: ExistingIds,
) -> list[dict[str, object]]:
    rows = []
    article_ids = existing_ids.article_ids + generated_ids("article_id", count)
    for offset, campaign_id in enumerate(generated_ids("campaign_id", count), start=1):
        flight_start = start_date + timedelta(days=offset % 45)
        category = ADVERTISER_CATEGORIES[offset % len(ADVERTISER_CATEGORIES)]
        rows.append(
            {
                "campaign_id": campaign_id,
                "article_id": choose_id(rng, article_ids, offset * 7),
                "campaign_name": f"{category} Campaign {offset:04d}",
                "advertiser_category": category,
                "flight_start_date": fmt_date(flight_start),
                "flight_end_date": fmt_date(flight_start + timedelta(days=3 + offset % 12)),
                "spend_pence": rng.randint(45_000, 300_000),
                "booked_impressions": rng.randint(20_000, 180_000),
            }
        )
    return rows


def generate_newsletter_sends(
    count: int,
    rng: random.Random,
    start_date: date,
    existing_ids: ExistingIds,
) -> list[dict[str, object]]:
    rows = []
    article_ids = existing_ids.article_ids + generated_ids("article_id", count)
    reader_ids = existing_ids.reader_ids + generated_ids("reader_id", count)
    for offset, send_id in enumerate(generated_ids("send_id", count), start=1):
        sent_at = datetime.combine(start_date + timedelta(days=offset % 50), datetime.min.time())
        sent_at += timedelta(hours=6 + offset % 5, minutes=(offset * 13) % 60)
        send_status = SEND_STATUSES[offset % len(SEND_STATUSES)]
        opened_at = None if send_status == "bounced" or rng.random() < 0.28 else sent_at + timedelta(minutes=rng.randint(5, 180))
        clicked_at = None if opened_at is None or rng.random() < 0.68 else opened_at + timedelta(minutes=rng.randint(1, 45))
        rows.append(
            {
                "send_id": send_id,
                "article_id": choose_id(rng, article_ids, offset * 11),
                "reader_id": choose_id(rng, reader_ids, offset * 13),
                "sent_at": fmt_datetime(sent_at),
                "newsletter_name": NEWSLETTER_NAMES[offset % len(NEWSLETTER_NAMES)],
                "send_status": send_status,
                "opened_at": fmt_datetime(opened_at),
                "clicked_at": fmt_datetime(clicked_at),
            }
        )
    return rows


def generate_paywall_events(
    count: int,
    rng: random.Random,
    start_date: date,
    existing_ids: ExistingIds,
) -> list[dict[str, object]]:
    rows = []
    article_ids = existing_ids.article_ids + generated_ids("article_id", count)
    reader_ids = existing_ids.reader_ids + generated_ids("reader_id", count)
    for offset, paywall_event_id in enumerate(generated_ids("paywall_event_id", count), start=1):
        event_at = datetime.combine(start_date + timedelta(days=offset % 50), datetime.min.time())
        event_at += timedelta(hours=8 + offset % 14, minutes=(offset * 17) % 60)
        conversion_status = CONVERSION_STATUSES[offset % len(CONVERSION_STATUSES)]
        revenue_pence = rng.choice([899, 1299, 2499]) if conversion_status == "converted" else 0
        rows.append(
            {
                "paywall_event_id": paywall_event_id,
                "article_id": choose_id(rng, article_ids, offset * 17),
                "reader_id": choose_id(rng, reader_ids, offset * 19),
                "event_at": fmt_datetime(event_at),
                "event_type": EVENT_TYPES[offset % len(EVENT_TYPES)],
                "offer_name": OFFER_NAMES[offset % len(OFFER_NAMES)],
                "conversion_status": conversion_status,
                "revenue_pence": revenue_pence,
            }
        )
    return rows


def upsert_generated_rows(
    seeds_dir: Path,
    file_key: str,
    id_column: str,
    generated_rows: list[dict[str, object]],
    dry_run: bool,
) -> None:
    path = seeds_dir / SEED_FILES[file_key]
    fieldnames, existing_rows = read_rows(path)
    preserved_rows = base_rows(existing_rows, id_column)
    if dry_run:
        print(
            f"{path}: preserve {len(preserved_rows)} hand-authored rows, "
            f"write {len(generated_rows)} generated rows"
        )
        return
    write_rows(path, fieldnames, [*preserved_rows, *generated_rows])


def get_existing_ids(seeds_dir: Path) -> ExistingIds:
    _, article_rows = read_rows(seeds_dir / SEED_FILES["articles"])
    _, reader_rows = read_rows(seeds_dir / SEED_FILES["readers"])
    return ExistingIds(
        article_ids=[int(row["article_id"]) for row in base_rows(article_rows, "article_id")],
        reader_ids=[int(row["reader_id"]) for row in base_rows(reader_rows, "reader_id")],
    )


def main() -> None:
    args = parse_args()
    if args.rows_per_source < 1:
        raise ValueError("--rows-per-source must be at least 1")

    rng = random.Random(args.seed)
    seeds_dir = args.seeds_dir.resolve()
    existing_ids = get_existing_ids(seeds_dir)

    generators: list[tuple[str, str, Callable[[], list[dict[str, object]]]]] = [
        ("articles", "article_id", lambda: generate_articles(args.rows_per_source, rng, args.start_date)),
        ("readers", "reader_id", lambda: generate_readers(args.rows_per_source, rng, args.start_date)),
        (
            "pageviews",
            "pageview_id",
            lambda: generate_pageviews(args.rows_per_source, rng, args.start_date, existing_ids),
        ),
        (
            "subscriptions",
            "subscription_id",
            lambda: generate_subscriptions(args.rows_per_source, rng, args.start_date, existing_ids),
        ),
        (
            "ad_campaigns",
            "campaign_id",
            lambda: generate_ad_campaigns(args.rows_per_source, rng, args.start_date, existing_ids),
        ),
        (
            "newsletter_sends",
            "send_id",
            lambda: generate_newsletter_sends(args.rows_per_source, rng, args.start_date, existing_ids),
        ),
        (
            "paywall_events",
            "paywall_event_id",
            lambda: generate_paywall_events(args.rows_per_source, rng, args.start_date, existing_ids),
        ),
    ]

    for file_key, id_column, generator in generators:
        upsert_generated_rows(seeds_dir, file_key, id_column, generator(), args.dry_run)

    action = "Would write" if args.dry_run else "Wrote"
    print(f"{action} {args.rows_per_source} generated rows per seed source in {seeds_dir}")


if __name__ == "__main__":
    main()
