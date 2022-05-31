
import matplotlib.pyplot as plt

import numpy as np
import math

POLICY = 2

fig = plt.figure(figsize=(10,10))

ax = fig.add_subplot(1,1,1, projection='3d')
ax.set_title(f"ZFP Benchmark Time (Cuda)")
ax.set_xlabel("(in) Buffer size (# doubles)")
ax.set_ylabel("(in) Rate")
ax.set_zlabel("Compression time (s)")

plt.rcParams.update({'font.size': 20})

xs, ys, zs, cs = [], [], [], []

with open(f"cpp_results.txt") as f:
    for line in f.readlines():
        p = [ float(x) for x in line.split(', ') ]
        if p[0] == POLICY:
            xs.append(p[1])
            ys.append(p[2])
            zs.append(p[2])
            cs.append(p[6])

scat = ax.scatter(xs=np.log10(xs), ys=np.log10(ys), zs=np.log10(zs), c=cs)

ax.set_xticks(np.log10(xs))
ax.set_xticklabels([ f"10e{int(x)}" for x in np.log10(xs)])
ax.set_yticks(np.log10(ys))
ax.set_yticklabels([ f"{y:.1e}" for y in ys])
ax.set_zticks(np.log10([ math.pow(10, x) for x in range(0, 2) ]))
ax.set_zticklabels([ f"10e{x}" for x in range(0, 2) ])

cb = plt.colorbar(scat, pad=0.2)#

cb.set_ticks([ min(cs), max(cs) ])
cb.ax.set_ylabel("Compression Ratio")

print("here")

plt.savefig(f"pic_{POLICY}.png")

