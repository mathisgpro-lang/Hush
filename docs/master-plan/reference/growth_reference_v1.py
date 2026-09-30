"""
Reference calculator for chapter 04 Part B (RuleSet v1).

A planning artifact, not product code: it exists so every golden-vector
number in chapter 04 is computed, not hand-written. The Swift GrowthEngine
must reproduce these outputs exactly (within 1e-9). Run: python3 growth_reference_v1.py
"""
from math import isclose

# ---- constants (RuleSet v1) ----
EDGE = 1.2
EDGE_D = 1.2
FILL_CAP = 0.5
EMPTY_S_FULL = 2.0
WINDOW = 14
DECAY = 0.8
FREE_DAY_SPAN = 7
LIVE_BOOST = 0.3
FLOOR = 0.15
EMBERS = 0.25
RELIGHT = {1: 0.60, 2: 0.80, 3: 1.00}
ABSENCE_FOR_COMEBACK = 3


def f(x):
    """Concave, non-decreasing daily effort curve: adding effort never lowers Depth."""
    return min(x, 2.0) + 0.5 * min(max(x - 2.0, 0.0), 1.0) + 0.25 * max(x - 3.0, 0.0)


def effort(actions, pillar):
    """actions: list of dicts {w:{pillar:weight}, d, spark(bool)}"""
    e = 0.0
    for a in actions:
        w = a["w"].get(pillar, 0.0)
        edge = EDGE if (a.get("spark") or a["d"] >= EDGE_D) else 1.0
        e += w * a["d"] * edge
    return e


def depth(days, pillar):
    """days: list (oldest first) of lists of actions. Returns total Depth for pillar."""
    total = 0.0
    for i, acts in enumerate(days):
        prior = days[max(0, i - 27):i]
        active = sum(1 for d in prior if effort(d, pillar) > 0)
        consistency = 1.0 + 0.5 * active / 27
        total += f(effort(acts, pillar)) * consistency
    return total


def completion(S, done_S, F):
    """S: list of slot difficulties; done_S: difficulties of completed S slots; F: sum d of non-S completions."""
    if not S:
        return min(1.0, F / EMPTY_S_FULL)
    T = sum(S)
    return min(1.0, (sum(done_S) + min(F, FILL_CAP * T)) / T)


def growth(completions):
    g = 1.0
    for c in completions:
        g *= 1.0 + 0.01 * c
    return g


def vitality(history, today=0.0):
    """history: presence of finalized days, most recent LAST (rest days already = 1.0)."""
    past = list(reversed(history[-WINDOW:]))            # index 0 = yesterday
    past += [0.0] * (WINDOW - len(past))
    weights = [DECAY ** i for i in range(WINDOW)]
    s = sum(weights)
    weights = [w / s for w in weights]
    recent = past[:FREE_DAY_SPAN]
    if any(p > 0 for p in recent):                       # free day only if not wholly absent
        j = min(range(FREE_DAY_SPAN), key=lambda i: (recent[i], i))
        past[j] = 1.0
    v_hist = sum(w * p for w, p in zip(weights, past))
    # comeback: scan backward over finalized days + today
    seq = history + ([today] if today > 0 else [])
    n = 0
    k = len(seq) - 1
    while k >= 0 and seq[k] > 0:
        n += 1
        k -= 1
    absence = 0
    while k >= 0 and seq[k] == 0:
        absence += 1
        k -= 1
    v = v_hist + (1.0 - v_hist) * LIVE_BOOST * today
    if absence >= ABSENCE_FOR_COMEBACK and 1 <= n <= 3:
        v = max(v, RELIGHT[n])
    return max(FLOOR, v)


def check(name, got, want, tol=1e-6):
    ok = isclose(got, want, abs_tol=tol)
    print(f"{'PASS' if ok else 'FAIL'}  {name}: {got:.6f} (expected {want:.6f})")
    assert ok


if __name__ == "__main__":
    one = lambda d=1.0, spark=False, w=None: {"w": w or {"body": 1.0}, "d": d, "spark": spark}

    # V1 consistency ramps to 1.5 on day 28 (27 prior active days)
    days = [[one()] for _ in range(28)]
    check("V1 day-28 contribution", depth(days, "body") - depth(days[:-1], "body"), 1.5)

    # V2 six actions in one day, no history
    check("V2 six same-day actions", depth([[one()] * 6], "body"), 3.25)

    # V3 monotonic insertion (Codex round-3 counterexample)
    a = depth([[one(2.0), one(2.0)]], "body")
    b = depth([[one(0.5), one(2.0), one(2.0)]], "body")
    check("V3a two hard actions", a, 2.95)
    check("V3b plus an easy one (must be higher)", b, 3.075)
    assert b > a

    # V4 multi-pillar action
    check("V4 half to body", depth([[one(w={"body": .5, "heart": .5})]], "body"), 0.5)

    # V5 edge bonus: Spark d=1 vs path d=1.25
    check("V5a spark d=1", depth([[one(1.0, spark=True)]], "body"), 1.2)
    check("V5b path d=1.25", depth([[one(1.25)]], "body"), 1.5)

    # V6 vitality
    full = [1.0] * 30
    check("V6a all full", vitality(full), 1.0)
    check("V6b yesterday off (free day)", vitality(full[:-1] + [0.0]), 1.0)
    check("V6c three days off", vitality(full[:-3] + [0.0] * 3), 0.698751, 1e-5)
    check("V6d fourteen days off", vitality(full[:-14] + [0.0] * 14), FLOOR)
    check("V6e thirty days off", vitality([0.0] * 30), FLOOR)
    away = full[:-14] + [0.0] * 14
    check("V6f comeback day 1 (today)", vitality(away, today=1.0), 0.60)
    check("V6g comeback day 2", vitality(away + [1.0], today=1.0), 0.80)
    check("V6h comeback day 3", vitality(away + [1.0, 1.0], today=1.0), 1.00)

    # V7 growth number
    check("V7a full day", growth([completion([1, 1], [1, 1], 0)]), 1.01)
    check("V7b half day", growth([completion([1, 1], [1], 0)]), 1.005)
    check("V7c fill capped: none of S, four extras", completion([1, 1], [], 4.0), 0.5)
    check("V7d empty S, one action", completion([], [], 1.0), 0.5)
    check("V7e 365 full days", growth([1.0] * 365), 37.783434, 1e-5)

    # V8 correction voiding a scheduled item lowers completion; voiding surplus does not
    check("V8a void one of two S items", completion([1, 1], [1], 0), 0.5)
    check("V8b void surplus when S full", completion([1, 1], [1, 1], 0.0), 1.0)
    print("all vectors pass")
