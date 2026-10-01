"""Pacing from simulated lives (Plan 2.0 Part 9 §4.7). Runs the chapter 04 reference engine (RuleSet v1) on typical
histories and reports the day each Heart restoration level and each Flame stage is reached. Planning artifact."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "master-plan", "reference"))
from growth_reference_v1 import effort, f

PILLARS = ["body", "mind", "heart", "spirit", "craft", "world"]
LEVELS = [3, 15, 50, 150, 400]
DAYS = 730

def act(p, d=1.0):
    return {"w": {p: 1.0}, "d": d}

def life(kind):
    days = []
    for i in range(DAYS):
        wk = i % 7
        if kind == "Heart focus (1 a day)":
            days.append([act("heart")])
        elif kind == "Heart focus (2 a day)":
            days.append([act("heart"), act("heart")])
        elif kind == "Balanced (1 a day, rotating)":
            days.append([act(PILLARS[i % 6])])
        elif kind == "Balanced (3 a day)":
            days.append([act(PILLARS[i % 6]), act(PILLARS[(i + 2) % 6]), act(PILLARS[(i + 4) % 6])])
        elif kind == "Low frequency (Heart 3 days a week)":
            days.append([act("heart")] if wk in (0, 2, 4) else [])
        elif kind == "Planned rest (Heart 6 days a week)":
            days.append([act("heart")] if wk != 6 else [])
        elif kind == "Pause (3 weeks on, 3 off)":
            days.append([act("heart")] if (i // 21) % 2 == 0 else [])
        elif kind == "Comeback (10 days, 30 away, then daily)":
            days.append([act("heart")] if (i < 10 or i >= 40) else [])
    return days

def run(kind):
    days = life(kind)
    heart = 0.0; total = 0.0; active = 0
    hit = {}; stage = {}
    for i, acts in enumerate(days):
        for p in PILLARS:
            prior = days[max(0, i - 27):i]
            a = sum(1 for d in prior if effort(d, p) > 0)
            gain = f(effort(acts, p)) * (1.0 + 0.5 * a / 27)
            total += gain
            if p == "heart": heart += gain
        if acts: active += 1
        for lv in LEVELS:
            if heart >= lv and lv not in hit: hit[lv] = i + 1
        if active >= 7 and "Flame" not in stage: stage["Flame"] = i + 1
        if active >= 60 and total >= 120 and "Blaze" not in stage: stage["Blaze"] = i + 1
        if active >= 300 and total >= 800 and "Kindled" not in stage: stage["Kindled"] = i + 1
    return hit, stage

kinds = ["Heart focus (1 a day)", "Heart focus (2 a day)", "Balanced (1 a day, rotating)", "Balanced (3 a day)",
         "Low frequency (Heart 3 days a week)", "Planned rest (Heart 6 days a week)", "Pause (3 weeks on, 3 off)",
         "Comeback (10 days, 30 away, then daily)"]
fmt = lambda d: f"day {d}" if d else "—"
print("| Life | Grove L1 (3) | L2 (15) | L3 (50) | L4 (150) | L5 (400) | Flame stage | Blaze | Kindled |")
print("|---|---|---|---|---|---|---|---|---|")
for k in kinds:
    hit, st = run(k)
    print(f"| {k} | " + " | ".join(fmt(hit.get(l)) for l in LEVELS) + " | " +
          " | ".join(fmt(st.get(s)) for s in ("Flame", "Blaze", "Kindled")) + " |")
