import os
import glob
import re
from collections import defaultdict

def parse_nmt_file(filepath):
    data = {}
    with open(filepath, 'r') as f:
        for line in f:
            if line.startswith('Total:'):
                m = re.search(r'committed=(\d+)KB', line)
                if m: data['Total'] = int(m.group(1))
            elif line.startswith('- '):
                m = re.search(r'-\s+([A-Za-z \t]+)\(reserved=\d+KB, committed=(\d+)KB', line)
                if m:
                    category = m.group(1).strip()
                    data[category] = int(m.group(2))
    return data

results = defaultdict(lambda: defaultdict(list))

for filepath in glob.glob('logs/*nmt-summary.txt'):
    basename = os.path.basename(filepath)
    m = re.match(r'run_(\d+)_aot(true|false)_coh(true|false)_(\d+)_.*-nmt-summary\.txt', basename)
    if not m: continue
    jdk, aot, coh, run_idx = m.groups()
    config = f"JDK {jdk} (AOT={aot}, COH={coh})"
    nmt_data = parse_nmt_file(filepath)
    for k, v in nmt_data.items():
        results[config][k].append(v)

configs = [
    "JDK 25 (AOT=false, COH=false)",
    "JDK 25 (AOT=false, COH=true)",
    "JDK 25 (AOT=true, COH=false)",
    "JDK 25 (AOT=true, COH=true)",
    "JDK 27 (AOT=false, COH=false)",
    "JDK 27 (AOT=false, COH=true)",
    "JDK 27 (AOT=true, COH=false)",
    "JDK 27 (AOT=true, COH=true)",
]

categories = ['Total', 'Java Heap', 'Class', 'Thread', 'Code', 'GC', 'Compiler', 'Shared class space', 'Metaspace', 'Symbol', 'Arena Chunk', 'Internal']

print(f"{'Configuration':<30} " + " ".join([f"{c[:10]:>10}" for c in categories]))
for config in configs:
    if config not in results: continue
    row = f"{config:<30} "
    for cat in categories:
        vals = results[config][cat]
        if vals:
            avg_mb = sum(vals) / len(vals) / 1024.0
            row += f"{avg_mb:10.1f}"
        else:
            row += f"{'-':>10}"
    print(row)
