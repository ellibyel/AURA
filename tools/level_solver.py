"""Level solver and generator for AURA.

The board is a 16x9 grid. The beam leaves the sun downwards and moves cell by
cell. A mirror at 45 deg ("\\") turns down->right, a mirror at 135 deg ("/")
turns down->left. Walls stop the beam, stars let it pass. A level is solved
when one beam passes through every star.

Usage:
  python3 tools/level_solver.py check levels/level_3.json   # min mirrors + solutions
  python3 tools/level_solver.py check-all                   # every levels/level_*.json
  python3 tools/level_solver.py generate --stars 3 --walls 10 --min 3 --seed 7
"""
import argparse, glob, json, os, random, sys

W, H = 16, 9
MAX_BOUNCES = 64


def reflect(d, angle):
    dx, dy = d
    return (dy, dx) if angle == 45 else (-dy, -dx)


def trace(level, mirrors):
    """Returns (path cells in order, lit stars)."""
    walls = {tuple(c) for c in level.get("walls", [])}
    fixed = {(c[0], c[1]): c[2] for c in level.get("fixed", [])}
    stars = {tuple(c) for c in level["stars"]}
    pos, d = tuple(level["source"]), (0, 1)
    path, lit, bounces, seen = [], set(), 0, set()
    while True:
        pos = (pos[0] + d[0], pos[1] + d[1])
        if not (0 <= pos[0] < W and 0 <= pos[1] < H) or pos in walls:
            break
        if (pos, d) in seen:
            break
        seen.add((pos, d))
        path.append(pos)
        if pos in stars:
            lit.add(pos)
        angle = mirrors.get(pos, fixed.get(pos))
        if angle is not None:
            bounces += 1
            if bounces > MAX_BOUNCES:
                break
            d = reflect(d, angle)
    return path, lit


def solve(level, max_depth=6, limit=200):
    """Minimum number of player mirrors and up to `limit` solutions with that count."""
    stars = {tuple(c) for c in level["stars"]}
    blocked = stars | {tuple(level["source"])} | {tuple(c) for c in level.get("blocked", [])}
    blocked |= {(c[0], c[1]) for c in level.get("fixed", [])}
    for depth in range(0, max_depth + 1):
        found = []

        def dfs(mirrors, after):
            if len(found) >= limit:
                return
            path, lit = trace(level, mirrors)
            if lit == stars:
                if len(mirrors) == depth:
                    found.append(dict(mirrors))
                return
            if len(mirrors) == depth:
                return
            for i, cell in enumerate(path):
                if i <= after or cell in blocked or cell in mirrors:
                    continue
                for angle in (45, 135):
                    mirrors[cell] = angle
                    dfs(mirrors, i)
                    del mirrors[cell]

        dfs({}, -1)
        if found:
            return depth, found
    return None, []


def check(path):
    level = json.load(open(path))
    depth, sols = solve(level)
    par = level.get("par")
    status = "OK" if depth == par else "MISMATCH"
    print(f"{os.path.basename(path):16} min={depth} par={par} solutions={len(sols)} max_mirrors={level.get('max_mirrors')} {status}")
    if sols:
        sol = sorted(sols[0].items(), key=lambda kv: kv[0])
        print("   e.g.", [[c[0], c[1], a] for c, a in sol])
    return depth == par


def generate(n_stars, n_walls, want_min, seed, tries=4000):
    rng = random.Random(seed)
    for _ in range(tries):
        src = (rng.randrange(1, W - 1), rng.randrange(0, 2))
        cells = [(x, y) for x in range(W) for y in range(H) if (x, y) != src and abs(x - src[0]) + abs(y - src[1]) > 1]
        rng.shuffle(cells)
        stars = cells[:n_stars]
        walls = cells[n_stars:n_stars + n_walls]
        level = {"source": list(src), "stars": [list(s) for s in stars], "walls": [list(w) for w in walls]}
        # the bare beam must not light everything
        if trace(level, {})[1] == set(stars):
            continue
        depth, sols = solve(level, max_depth=want_min, limit=30)
        if depth == want_min and len(sols) <= 6:
            sol = sorted(sols[0].items())
            level.update({"par": depth, "solutions_found": len(sols), "solution": [[c[0], c[1], a] for c, a in sol]})
            return level
    return None


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["check", "check-all", "generate"])
    ap.add_argument("file", nargs="?")
    ap.add_argument("--stars", type=int, default=3)
    ap.add_argument("--walls", type=int, default=10)
    ap.add_argument("--min", type=int, default=3)
    ap.add_argument("--seed", type=int, default=1)
    a = ap.parse_args()
    if a.cmd == "check":
        sys.exit(0 if check(a.file) else 1)
    if a.cmd == "check-all":
        root = os.path.join(os.path.dirname(__file__), "..", "levels")
        ok = all([check(p) for p in sorted(glob.glob(os.path.join(root, "level_*.json")), key=lambda p: int(p.split("_")[-1].split(".")[0]))])
        sys.exit(0 if ok else 1)
    print(json.dumps(generate(a.stars, a.walls, a.min, a.seed)))
