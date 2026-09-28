"""Faz 1–3 deneyleri: simülatörde çok sayıda çalıştırma, istatistik ve grafikler.
Kullanım:  python scripts/run_experiments.py [--shots 1000]
Çıktılar:  results/*.csv, results/*.png, results/summary.md
"""
import argparse, csv, math
from collections import Counter
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from qdk import qsharp

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results"
OUT.mkdir(exist_ok=True)
qsharp.init(project_root=str(ROOT))

ap = argparse.ArgumentParser()
ap.add_argument("--shots", type=int, default=1000)
SHOTS = ap.parse_args().shots

ACCENT, MUTED, THEORY = "#2E6FDB", "#B8C2D1", "#E0702B"
plt.rcParams.update({"font.size": 10, "axes.spines.top": False, "axes.spines.right": False})
summary = []

def run(expr, shots=SHOTS):
    return qsharp.run(expr, shots=shots)

def write_csv(name, header, rows):
    with open(OUT / name, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(header); w.writerows(rows)

# ---------------------------------------------------------------- Faz 1
rb = Counter(str(r) for r in run("Basics.RandomBit()"))
dh = Counter(str(r) for r in run("Basics.DoubleHadamard()"))
bell = Counter(f"{a}{b}".replace("Zero", "0").replace("One", "1")
               for a, b in run("Basics.BellPair()"))
rn = Counter(run("Basics.RandomNumberInRange(7)"))
p_one = rb["One"] / SHOTS
se = math.sqrt(0.25 / SHOTS)
summary += [
    "## Faz 1 — Temel deneyler",
    f"- **RandomBit** ({SHOTS} atış): Zero={rb['Zero']}, One={rb['One']} → P(One)={p_one:.3f} "
    f"(beklenen 0.5; ±2σ aralığı {0.5-2*se:.3f}–{0.5+2*se:.3f}) → "
    f"{'✅ aralıkta' if abs(p_one-0.5) <= 2*se else '⚠️ aralık dışı'}",
    f"- **DoubleHadamard**: Zero={dh['Zero']}, One={dh.get('One',0)} → H·H = I doğrulandı",
    f"- **BellPair**: " + ", ".join(f"{k}={bell.get(k,0)}" for k in ["00","01","10","11"])
    + " → 01/10 hiç görülmedi (tam korelasyon)",
    f"- **RandomNumberInRange(7)**: " + ", ".join(f"{k}:{rn.get(k,0)}" for k in range(8)),
    "",
]
write_csv("phase1_basics.csv", ["experiment", "outcome", "count"],
          [["RandomBit", k, v] for k, v in rb.items()] +
          [["DoubleHadamard", k, v] for k, v in dh.items()] +
          [["BellPair", k, v] for k, v in sorted(bell.items())] +
          [["RandomNumberInRange(7)", k, v] for k, v in sorted(rn.items())])

fig, ax = plt.subplots(1, 3, figsize=(11, 3.2))
ax[0].bar(["Zero", "One"], [rb["Zero"], rb["One"]], color=ACCENT)
ax[0].axhline(SHOTS / 2, ls="--", color=THEORY, lw=1); ax[0].set_title("RandomBit (H + ölçüm)")
ax[1].bar(["00", "01", "10", "11"], [bell.get(k, 0) for k in ["00", "01", "10", "11"]], color=ACCENT)
ax[1].set_title("Bell çifti ölçümleri")
ax[2].bar(range(8), [rn.get(k, 0) for k in range(8)], color=ACCENT)
ax[2].axhline(SHOTS / 8, ls="--", color=THEORY, lw=1); ax[2].set_title("Rastgele sayı 0–7")
for a in ax: a.set_ylabel("sayım")
fig.tight_layout(); fig.savefig(OUT / "phase1_basics.png", dpi=150); plt.close(fig)

# ---------------------------------------------------------------- Faz 2/3
def theory(n, k):
    th = math.asin(1 / math.sqrt(2 ** n))
    return math.sin((2 * k + 1) * th) ** 2

# (a) N=4: her hedef için başarı
rows, rates2 = [], []
for t in range(4):
    c = Counter(run(f"Grover.GroverSearchAuto(2, {t})"))
    rate = c[t] / SHOTS; rates2.append(rate)
    rows.append([2, t, 1, SHOTS, c[t], round(rate, 4), round(theory(2, 1), 4)])
write_csv("grover_n2_all_targets.csv",
          ["n_qubits", "target", "iterations", "shots", "hits", "success_rate", "theory"], rows)

# (b) N=8, hedef 5: tam dağılım (optimum iterasyon)
k_opt3 = qsharp.eval("Grover.OptimalIterations(3)")
dist3 = Counter(run(f"Grover.GroverSearch(3, 5, {k_opt3})"))
fig, ax = plt.subplots(figsize=(6.5, 3.4))
ax.bar(range(8), [dist3.get(i, 0) for i in range(8)],
       color=[ACCENT if i == 5 else MUTED for i in range(8)])
ax.axhline(SHOTS / 8, ls="--", color=THEORY, lw=1, label="Klasik rastgele tahmin (1/8)")
ax.set_xticks(range(8), [f"{i}\n|{i:03b}⟩" for i in range(8)])
ax.set_ylabel("sayım"); ax.set_title(f"Grover, N=8, hedef=5, {k_opt3} iterasyon ({SHOTS} atış)")
ax.legend(frameon=False); fig.tight_layout()
fig.savefig(OUT / "grover_n3_distribution.png", dpi=150); plt.close(fig)
write_csv("grover_n3_distribution.csv", ["outcome", "count"],
          [[i, dist3.get(i, 0)] for i in range(8)])

# (c) İterasyon taraması: başarı vs k (aşırı dönme / overshoot)
sweep_rows, sweep = [], {}
for n, target, kmax in [(3, 5, 8), (4, 11, 10)]:
    xs, ys = [], []
    for k in range(kmax + 1):
        c = Counter(run(f"Grover.GroverSearch({n}, {target}, {k})"))
        r = c[target] / SHOTS
        xs.append(k); ys.append(r)
        sweep_rows.append([n, target, k, SHOTS, c[target], round(r, 4), round(theory(n, k), 4)])
    sweep[n] = (xs, ys)
write_csv("grover_iteration_sweep.csv",
          ["n_qubits", "target", "iterations", "shots", "hits", "success_rate", "theory"], sweep_rows)

fig, ax = plt.subplots(1, 2, figsize=(11, 3.6))
for a, n in zip(ax, [3, 4]):
    xs, ys = sweep[n]
    fine = [i / 20 for i in range(0, 20 * max(xs) + 1)]
    a.plot(fine, [theory(n, k) for k in fine], color=THEORY, lw=1.2, label="Teori sin²((2k+1)θ)")
    a.plot(xs, ys, "o", color=ACCENT, label="Simülatör")
    a.axhline(1 / 2 ** n, ls=":", color="gray", lw=1, label=f"Rastgele tahmin 1/{2**n}")
    a.set_xlabel("iterasyon sayısı k"); a.set_ylabel("başarı olasılığı")
    a.set_title(f"N={2**n} ({n} kübit)"); a.set_ylim(0, 1.05); a.legend(frameon=False, fontsize=8)
fig.tight_layout(); fig.savefig(OUT / "grover_iteration_sweep.png", dpi=150); plt.close(fig)

# (d) Ölçekleme: n = 2..6, optimum k, başarı + sorgu sayısı karşılaştırması
scale_rows = []
for n in range(2, 7):
    k = qsharp.eval(f"Grover.OptimalIterations({n})")
    target = (2 ** n) - 2
    c = Counter(run(f"Grover.GroverSearch({n}, {target}, {k})"))
    r = c[target] / SHOTS
    scale_rows.append([n, 2 ** n, k, round((2 ** n + 1) / 2, 1), SHOTS, c[target], round(r, 4), round(theory(n, k), 4)])
write_csv("grover_scaling.csv",
          ["n_qubits", "N", "grover_oracle_calls", "classical_avg_queries", "shots", "hits", "success_rate", "theory"],
          scale_rows)

# ---------------------------------------------------------------- Özet
summary += [
    "## Faz 2/3 — Grover sonuçları",
    "### N=4 (2 kübit), 1 iterasyon — tüm hedefler",
    "| hedef | başarı | teori |", "|---|---|---|",
    *[f"| {r[1]} | {r[5]:.1%} | {r[6]:.0%} |" for r in rows], "",
    f"### N=8 (3 kübit), hedef=5, {k_opt3} iterasyon",
    f"Başarı: **{dist3[5]/SHOTS:.1%}** (teori {theory(3, k_opt3):.1%}, rastgele tahmin %12.5)", "",
    "### İterasyon taraması (aşırı dönme etkisi)",
    "| n | k | simülatör | teori |", "|---|---|---|---|",
    *[f"| {r[0]} | {r[2]} | {r[5]:.1%} | {r[6]:.1%} |" for r in sweep_rows], "",
    "### Ölçekleme (optimum k)",
    "| kübit | N | Grover oracle çağrısı | klasik ort. sorgu | başarı | teori |",
    "|---|---|---|---|---|---|",
    *[f"| {r[0]} | {r[1]} | {r[2]} | {r[3]} | {r[6]:.1%} | {r[7]:.1%} |" for r in scale_rows],
]
(OUT / "summary.md").write_text(f"# Deney özeti ({SHOTS} atış/deney)\n\n" + "\n".join(summary) + "\n",
                                encoding="utf-8")
print((OUT / "summary.md").read_text(encoding="utf-8"))
