"""
Bloom Analytics
---------------
Reads bloom_v3.db directly and generates a printed report
+ saves 4 chart images to the same folder.

Usage:
    python bloom_analytics.py                  # looks for bloom_v3.db in same folder
    python bloom_analytics.py path/to/bloom_v3.db
"""

import sqlite3
import sys
import os
from datetime import datetime, timedelta

# ── optional: matplotlib for charts ──────────────────────────────────────────
try:
    import matplotlib
    matplotlib.use('Agg')          # no GUI needed
    import matplotlib.pyplot as plt
    import matplotlib.dates as mdates
    CHARTS = True
except ImportError:
    CHARTS = False
    print("[INFO] matplotlib not installed – skipping charts.")
    print("       Run:  pip install matplotlib\n")

# ─────────────────────────────────────────────────────────────────────────────
# 1. CONNECT
# ─────────────────────────────────────────────────────────────────────────────

DB_PATH = sys.argv[1] if len(sys.argv) > 1 else 'bloom_v3.db'

if not os.path.exists(DB_PATH):
    print(f"ERROR: Could not find '{DB_PATH}'")
    print("  Make sure bloom_v3.db is in the same folder as this script,")
    print("  or pass the path as an argument:  python bloom_analytics.py C:/path/bloom_v3.db")
    sys.exit(1)

conn = sqlite3.connect(DB_PATH)
conn.row_factory = sqlite3.Row   # lets us access columns by name
cur  = conn.cursor()

print("=" * 56)
print("  🌸  BLOOM – ANALYTICS REPORT")
print(f"  Database : {DB_PATH}")
print(f"  Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
print("=" * 56)


# ─────────────────────────────────────────────────────────────────────────────
# 2. HABITS
# ─────────────────────────────────────────────────────────────────────────────

print("\n── HABITS ──────────────────────────────────────────────")

cur.execute("SELECT id, title, streak, lastCompletedDate FROM habits ORDER BY streak DESC")
habits = cur.fetchall()

if not habits:
    print("  No habits found.")
else:
    print(f"  Total habits : {len(habits)}")
    today     = datetime.now().strftime('%Y-%m-%d')
    yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')

    active  = [h for h in habits if h['lastCompletedDate'] in (today, yesterday)]
    broken  = [h for h in habits if h['lastCompletedDate'] not in (today, yesterday, None)]
    longest = habits[0]   # already sorted by streak DESC

    print(f"  Active streaks   : {len(active)}")
    print(f"  Broken streaks   : {len(broken)}")
    print(f"  Longest streak   : '{longest['title']}' – {longest['streak']} days")
    print()
    print(f"  {'#':<4} {'Habit':<28} {'Streak':>7}  {'Last Done'}")
    print(f"  {'-'*4} {'-'*28} {'-'*7}  {'-'*12}")
    for h in habits:
        last = h['lastCompletedDate'] or 'Never'
        print(f"  {h['id']:<4} {h['title']:<28} {h['streak']:>7}  {last}")

    # Chart 1 – Habit Streaks bar chart
    if CHARTS and habits:
        fig, ax = plt.subplots(figsize=(8, max(3, len(habits) * 0.5 + 1)))
        names   = [h['title'] for h in habits]
        streaks = [h['streak'] for h in habits]
        bars = ax.barh(names, streaks, color='#4DB6AC', edgecolor='white')
        ax.bar_label(bars, padding=4, fmt='%d days')
        ax.set_xlabel('Streak (days)')
        ax.set_title('Habit Streaks – Bloom', fontweight='bold')
        ax.invert_yaxis()
        plt.tight_layout()
        plt.savefig('chart_habits.png', dpi=120)
        plt.close()
        print("\n  [Chart saved: chart_habits.png]")


# ─────────────────────────────────────────────────────────────────────────────
# 3. TASKS
# ─────────────────────────────────────────────────────────────────────────────

print("\n── TASKS ───────────────────────────────────────────────")

cur.execute("SELECT id, title, isCompleted, deadline FROM tasks ORDER BY isCompleted, deadline")
tasks = cur.fetchall()

if not tasks:
    print("  No tasks found.")
else:
    done    = [t for t in tasks if t['isCompleted'] == 1]
    pending = [t for t in tasks if t['isCompleted'] == 0]
    pct     = round(len(done) / len(tasks) * 100) if tasks else 0

    print(f"  Total tasks      : {len(tasks)}")
    print(f"  Completed        : {len(done)}  ({pct}%)")
    print(f"  Pending          : {len(pending)}")

    overdue = []
    today_dt = datetime.now().date()
    for t in pending:
        if t['deadline']:
            try:
                dl = datetime.fromisoformat(t['deadline']).date()
                if dl < today_dt:
                    overdue.append(t)
            except ValueError:
                pass

    if overdue:
        print(f"\n  ⚠  Overdue tasks ({len(overdue)}):")
        for t in overdue:
            print(f"     – {t['title']}  (was due {t['deadline'][:10]})")

    # Chart 2 – Completion pie
    if CHARTS:
        fig, ax = plt.subplots(figsize=(5, 5))
        ax.pie(
            [len(done), len(pending)],
            labels=[f'Done ({len(done)})', f'Pending ({len(pending)})'],
            colors=['#4DB6AC', '#B2DFDB'],
            autopct='%1.0f%%',
            startangle=90,
            wedgeprops=dict(edgecolor='white', linewidth=2)
        )
        ax.set_title('Task Completion – Bloom', fontweight='bold')
        plt.tight_layout()
        plt.savefig('chart_tasks.png', dpi=120)
        plt.close()
        print("\n  [Chart saved: chart_tasks.png]")


# ─────────────────────────────────────────────────────────────────────────────
# 4. MOODS
# ─────────────────────────────────────────────────────────────────────────────

print("\n── MOODS ───────────────────────────────────────────────")

cur.execute("SELECT id, mood, content, date FROM moods ORDER BY date")
moods = cur.fetchall()

EMOJI = {1: '😢', 2: '😕', 3: '😐', 4: '🙂', 5: '😄'}

if not moods:
    print("  No mood entries found.")
else:
    scores  = [m['mood'] for m in moods]
    average = sum(scores) / len(scores)
    highest = max(scores)
    lowest  = min(scores)

    print(f"  Total entries    : {len(moods)}")
    print(f"  Average mood     : {average:.1f}  {EMOJI.get(round(average), '')}")
    print(f"  Best day         : {highest}  {EMOJI.get(highest, '')}")
    print(f"  Worst day        : {lowest}  {EMOJI.get(lowest, '')}")

    # Mood distribution
    print()
    print("  Distribution:")
    for score in range(5, 0, -1):
        count = scores.count(score)
        bar   = '█' * count
        print(f"    {EMOJI[score]} {score}  {bar}  ({count})")

    # Chart 3 – Mood over time
    if CHARTS:
        dates  = []
        values = []
        for m in moods:
            try:
                dates.append(datetime.fromisoformat(m['date']))
                values.append(m['mood'])
            except ValueError:
                pass

        if dates:
            fig, ax = plt.subplots(figsize=(10, 4))
            ax.plot(dates, values, color='#00897B', linewidth=2, marker='o',
                    markersize=5, markerfacecolor='white', markeredgewidth=2)
            ax.fill_between(dates, values, alpha=0.1, color='#00897B')
            ax.set_ylim(0.5, 5.5)
            ax.set_yticks([1, 2, 3, 4, 5])
            ax.set_yticklabels(['1 😢', '2 😕', '3 😐', '4 🙂', '5 😄'])
            ax.xaxis.set_major_formatter(mdates.DateFormatter('%b %d'))
            ax.xaxis.set_major_locator(mdates.AutoDateLocator())
            fig.autofmt_xdate()
            ax.set_title('Mood Over Time – Bloom', fontweight='bold')
            ax.grid(axis='y', alpha=0.3)
            plt.tight_layout()
            plt.savefig('chart_moods.png', dpi=120)
            plt.close()
            print("\n  [Chart saved: chart_moods.png]")


# ─────────────────────────────────────────────────────────────────────────────
# 5. JOURNAL
# ─────────────────────────────────────────────────────────────────────────────

print("\n── JOURNAL ─────────────────────────────────────────────")

cur.execute("SELECT id, title, content, date FROM journals ORDER BY date DESC")
entries = cur.fetchall()

if not entries:
    print("  No journal entries found.")
else:
    total_words = sum(len(e['content'].split()) for e in entries if e['content'])
    avg_words   = total_words // len(entries) if entries else 0

    print(f"  Total entries    : {len(entries)}")
    print(f"  Total words      : {total_words:,}")
    print(f"  Avg words/entry  : {avg_words}")
    print()
    print("  Recent entries:")
    for e in entries[:5]:
        date_str = e['date'][:10] if e['date'] else '?'
        words    = len(e['content'].split()) if e['content'] else 0
        print(f"    [{date_str}]  {e['title']}  ({words} words)")

    # Chart 4 – Journal entries per week
    if CHARTS and entries:
        from collections import Counter
        week_counts = Counter()
        for e in entries:
            try:
                dt   = datetime.fromisoformat(e['date'])
                week = dt.strftime('%Y-W%W')
                week_counts[week] += 1
            except ValueError:
                pass

        if week_counts:
            weeks  = sorted(week_counts.keys())
            counts = [week_counts[w] for w in weeks]
            fig, ax = plt.subplots(figsize=(8, 3))
            ax.bar(weeks, counts, color='#80CBC4', edgecolor='white')
            ax.set_xlabel('Week')
            ax.set_ylabel('Entries')
            ax.set_title('Journal Entries per Week – Bloom', fontweight='bold')
            plt.xticks(rotation=45, ha='right')
            plt.tight_layout()
            plt.savefig('chart_journal.png', dpi=120)
            plt.close()
            print("\n  [Chart saved: chart_journal.png]")


# ─────────────────────────────────────────────────────────────────────────────
# 6. SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

print("\n── SUMMARY ─────────────────────────────────────────────")
print(f"  Habits tracked   : {len(habits) if habits else 0}")
print(f"  Tasks created    : {len(tasks) if tasks else 0}")
print(f"  Mood entries     : {len(moods) if moods else 0}")
print(f"  Journal entries  : {len(entries) if entries else 0}")
print("=" * 56)

conn.close()
