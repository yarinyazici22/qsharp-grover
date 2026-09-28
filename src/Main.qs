// Giriş noktası: VS Code'da "Run" veya `python scripts/run_experiments.py`
// 4 elemanlı (2 kübit) ve 8 elemanlı (3 kübit) aramayı çalıştırır.

import Grover.*;
import Std.Diagnostics.*;

@EntryPoint()
operation Main() : Int[] {
    // --- 2 kübit, hedef = 3 (|11⟩) : tek iterasyonda %100 başarı
    let r2 = GroverSearchAuto(2, 3);
    Message($"N=4,  hedef=3 → ölçülen {r2}");

    // --- 3 kübit, hedef = 5 (|101⟩) : 2 iterasyonda ~%94.5
    let k3 = OptimalIterations(3);
    let r3 = GroverSearch(3, 5, k3);
    Message($"N=8,  hedef=5, {k3} iterasyon → ölçülen {r3}");

    // --- Öğrenme amaçlı: 3 kübitte 1 iterasyon sonrası durum vektörü
    use qs = Qubit[3];
    PrepareGroverState(5, 1, qs);
    Message("1 iterasyon sonrası durum (hedef |101⟩ genliği büyüyor):");
    DumpMachine();
    ResetAll(qs);

    return [r2, r3];
}
