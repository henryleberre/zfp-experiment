
import matplotlib.pyplot as plt

import numpy as np
import math

for filename in [ "omp" ]:
    fig = plt.figure(figsize=(10,10))

    ax = fig.add_subplot(1,1,1, projection='3d')
    ax.set_title(f"ZFP Compression Time ({filename})")
    ax.set_xlabel("Buffer size")
    ax.set_ylabel("Tolerance")
    ax.set_zlabel("Compression time")

    plt.rcParams.update({'font.size': 22})

    xs, ys, zs, cs = [], [], [], []

    with open(f"{filename}.dat") as f:
        for line in f.readlines():
            p = [ float(x) for x in line.split(', ') ]
            #p[0] = math.log(p[0], 10)
            #p[1] = math.log(p[1], 10)
            #p[2] = math.log(p[2], 10)
            xs.append(p[0])
            ys.append(p[1])
            zs.append(p[2])
            cs.append(p[3])
    
    scat = ax.scatter(xs=np.log10(xs), ys=np.log10(ys), zs=np.log10(zs), c=cs)

    ax.set_xticks(np.log10(xs))
    ax.set_xticklabels([ f"10e{int(x)}" for x in np.log10(xs)])
    ax.set_yticks(np.log10(ys))
    ax.set_yticklabels([ f"10e{int(y)}" for y in np.log10(ys)])
    ax.set_zticks(np.log10([ math.pow(10, x) for x in range(-6, 0) ]))
    ax.set_zticklabels([ f"10e{x}" for x in range(-6, 0) ])

    cb = plt.colorbar(scat, pad=0.2)

    cb.set_ticks(np.arange(min(cs), max(cs), 0.5))
    cb.ax.set_ylabel("Compression Ratio")

    plt.savefig(f"{filename}.png")
