"""src/Tests.qs içindeki tüm @Test() işlemlerini çalıştırır.
Kullanım:  python scripts/run_tests.py
"""
import re, sys, time
from pathlib import Path
from qdk import qsharp

ROOT = Path(__file__).resolve().parents[1]
qsharp.init(project_root=str(ROOT))

src = (ROOT / "src" / "Tests.qs").read_text(encoding="utf-8")
tests = re.findall(r"@Test\(\)\s*operation\s+(\w+)", src)

failed = 0
for name in tests:
    t0 = time.time()
    try:
        qsharp.eval(f"Tests.{name}()")
        print(f"  PASS  {name}  ({time.time()-t0:.2f}s)")
    except Exception as e:
        failed += 1
        print(f"  FAIL  {name}: {e}")

print(f"\n{len(tests)-failed}/{len(tests)} test geçti.")
sys.exit(1 if failed else 0)
