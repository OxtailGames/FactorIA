#!/usr/bin/env python3
"""Fits the subsurface scattering kernel of engine/render/src/subsurface.cpp (kSssGauss): our own fit, no table copied from anywhere.

What it fits. The diffuse profile R(r) of a surface is the share of light that leaves at distance r from where it entered. We take the
normalized diffusion profile of Burley (Disney, 2015) as the target shape,

    R(r) = (exp(-r/d) + exp(-r/(3 d))) / (8 pi d r)        (integral of 2 pi r R dr over the plane = 1)

and build a separable kernel for it: a sum of four 1D Gaussians K(x) = sum_i w_i N(x; sigma_i), applied along x and then along y. The
1D kernel is fitted to the 1D marginal of R (the line integral M(x) = integral R(sqrt(x^2 + y^2)) dy), through its cumulative
distribution (the marginal has an integrable log singularity at 0, its cumulative does not): the weights are non-negative and sum to 1,
the four sigmas are searched by a deterministic random search. The unit is the scatter radius: r90, the distance inside which 90% of the
light of the 2D profile lands (C(r) = ((1 - e^(-r/d)) + 3 (1 - e^(-r/(3 d)))) / 4 = 0.9), so a MeshRenderer.subsurfaceRadius of 1 metre
puts 90% of the energy within 1 metre.

Run:  python3 tools/shaders/fit_subsurface_profile.py   (pure Python, a minute; prints the table to paste into subsurface.cpp)
"""
import math
import random

D = 1.0


def radial_cdf(r):
    return 0.25 * ((1 - math.exp(-r / D)) + 3 * (1 - math.exp(-r / (3 * D))))


def r90():
    lo, hi = 0.0, 100.0
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        if radial_cdf(mid) < 0.9:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)


def profile(r):
    return (math.exp(-r / D) + math.exp(-r / (3 * D))) / (8 * math.pi * D * r)


def marginal(x, steps=600, ymax=60.0):
    # integral over y in (-inf, inf) = 2 * integral over (0, ymax); y = ymax * t^3 densifies near 0 where R is largest.
    total = 0.0
    for k in range(steps):
        t0, t1 = k / steps, (k + 1) / steps
        tm = 0.5 * (t0 + t1)
        y = ymax * tm ** 3
        dy = ymax * 3 * tm ** 2 * (t1 - t0)
        total += profile(math.hypot(x, y)) * dy
    return 2 * total


def build_cdf(xs):
    """Cumulative distribution of the marginal at the positions xs."""
    X = 40.0
    n = 1600
    h = 2 * X / n
    grid = [-X + (k + 0.5) * h for k in range(n)]
    half = [marginal(abs(x)) for x in grid[: n // 2]]
    vals = half + half[::-1]
    cum = []
    acc = 0.0
    for v in vals:
        acc += v * h
        cum.append(acc)
    total = cum[-1]
    out = []
    for x in xs:
        idx = min(n - 1, max(0, int((x + X) / h)))
        out.append(cum[idx] / total)
    return out


def phi(z):
    return 0.5 * (1 + math.erf(z / math.sqrt(2)))


def nnls_sum1(rows, target, iters):
    """Non-negative weights summing to 1 that fit rows . w to target (projected coordinate descent, renormalized)."""
    m = len(rows[0])
    w = [1.0 / m] * m
    for _ in range(iters):
        for j in range(m):
            num = 0.0
            den = 0.0
            for r, t in zip(rows, target):
                resid = t - sum(r[k] * w[k] for k in range(m)) + r[j] * w[j]
                num += r[j] * resid
                den += r[j] * r[j]
            w[j] = max(0.0, num / den) if den > 0 else 0.0
        s = sum(w)
        w = [v / s for v in w] if s > 0 else [1.0 / m] * m
    return w


def error(rows, target, w):
    return sum((t - sum(a * b for a, b in zip(r, w))) ** 2 for r, t in zip(rows, target))


def main():
    scale = r90()
    xs = sorted(set([(-6.0 + 12.0 * k / 60) for k in range(61)] + [0.05 * k for k in range(-10, 11)]))
    target = build_cdf(xs)
    rng = random.Random(73)
    best = None
    for _ in range(150):
        sig = sorted(math.exp(rng.uniform(math.log(0.05), math.log(8.0))) for _ in range(4))
        rows = [[phi(x / s) for s in sig] for x in xs]
        w = nnls_sum1(rows, target, 20)
        e = error(rows, target, w)
        if best is None or e < best[0]:
            best = (e, sig, w)
    e, sig, w = best
    step = 0.15
    for _ in range(40):
        improved = False
        for i in range(4):
            for f in (1 + step, 1 / (1 + step)):
                trial = sorted(sig[:i] + [sig[i] * f] + sig[i + 1:])
                rows = [[phi(x / s) for s in trial] for x in xs]
                tw = nnls_sum1(rows, target, 30)
                te = error(rows, target, tw)
                if te < e:
                    e, sig, w, improved = te, trial, tw, True
        if not improved:
            step *= 0.6
    print("r90 = %.6f d" % scale)
    print("cdf squared error = %.3e" % e)
    print("// weight, sigma (in units of the scatter radius: the distance that holds 90% of the light)")
    for wi, si in zip(w, sig):
        print("    {%.6ff, %.6ff}," % (wi, si / scale))


if __name__ == "__main__":
    main()
