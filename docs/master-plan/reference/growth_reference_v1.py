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
    """history: presence of finalized days, most recent LAST (rest days already = 1.0).

    Comeback forgiveness (rev 5): once a comeback completes (3 days with presence > 0
    after >= 3 absent days), the absence before it is forgiven: days before the comeback
    start C are excluded from the window and the weights renormalize over the included days.
    """
    seq = history + ([today] if today > 0 else [])
    # locate the most recent comeback start C in seq (index), if any
    start = None
    i = len(seq) - 1
    while i >= 0:
        if seq[i] > 0:
            j = i
            while j - 1 >= 0 and seq[j - 1] > 0:
                j -= 1
            k = j - 1
            absence = 0
            while k >= 0 and seq[k] == 0:
                absence += 1
                k -= 1
            if absence >= ABSENCE_FOR_COMEBACK:
                start = j
            break
        i -= 1
    n = (len(seq) - start) if start is not None else 0     # trailing run length since C
    forgiven = start is not None and n >= 3
    # window over finalized history (index 0 = yesterday)
    idx = list(range(len(history) - 1, -1, -1))[:WINDOW]
    if forgiven:
        idx = [t for t in idx if t >= start]
    past = [history[t] for t in idx]
    raw_w = [DECAY ** r for r in range(WINDOW)][:len(past)] if forgiven else [DECAY ** r for r in range(WINDOW)]
    past += [0.0] * (len(raw_w) - len(past))
    s = sum(raw_w)
    weights = [w / s for w in raw_w]
    span = min(FREE_DAY_SPAN, len(past))
    recent = past[:span]
    if any(p > 0 for p in recent):
        j = min(range(span), key=lambda q: (recent[q], q))
        past[j] = 1.0
    v_hist = sum(w * p for w, p in zip(weights, past)) if past else 0.0
    v = v_hist + (1.0 - v_hist) * LIVE_BOOST * today
    if start is not None and 1 <= n <= 3:
        v = max(v, RELIGHT[n])
    return max(FLOOR, v)


def completion_multi(contracts, done, F):
    """Rev 5: every issued day contract (offline devices, swaps) is scored; the day takes the max.
    contracts: list of slot lists [(slotId, d)]; done: set of completed slotIds. Never retracts."""
    if not contracts:
        return completion([], [], F)
    return max(completion([d for _, d in c], [d for sid, d in c if sid in done], F) for c in contracts)


def check(name, got, want, tol=1e-9):
    ok = isclose(got, want, abs_tol=tol)
    print(f"{'PASS' if ok else 'FAIL'}  {name}: {got!r} (expected {want!r})")
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
    check("V6c three days off", vitality(full[:-3] + [0.0] * 3), 0.6987509255933241)
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
    check("V7e 365 full days", growth([1.0] * 365), 37.783434332887275)

    # V8 correction voiding a scheduled item lowers completion; voiding surplus does not
    check("V8a void one of two S items", completion([1, 1], [1], 0), 0.5)
    check("V8b void surplus when S full", completion([1, 1], [1, 1], 0.0), 1.0)
    # V9 comeback carries into normal Vitality (Codex r4 blocking #5)
    check("V9a comeback day 4 before acting", vitality(away + [1.0, 1.0, 1.0]), 1.0)
    check("V9b comeback day 4 completed", vitality(away + [1.0, 1.0, 1.0], today=1.0), 1.0)
    check("V9c day 5 after a full day 4", vitality(away + [1.0] * 4, today=1.0), 1.0)
    check("V9d absent again 3 days after comeback", vitality(away + [1.0] * 4 + [0.0] * 3), 0.6355744157043132)
    # V10 competing contracts never retract earned growth (Codex r4 blocking #3)
    a_only = completion_multi([[("a1", 1.0)]], {"a1"}, 0.0)
    both = completion_multi([[("a1", 1.0)], [("b1", 1.0)]], {"a1"}, 0.0)
    check("V10a device A contract, completed", a_only, 1.0)
    check("V10b plus B's competing contract", both, 1.0)
    print("all vectors pass")
