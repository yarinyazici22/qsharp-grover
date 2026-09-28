// =============================================================
// Faz 3 — Birim testler. VS Code Test Explorer'da @Test() ile görünür;
// ayrıca scripts/run_tests.py hepsini sırayla çalıştırır.
// Deterministik olanlar burada; istatistiksel testler Python'da.
// =============================================================

import Basics.*;
import Grover.*;
import Std.Diagnostics.*;
import Std.Arrays.*;
import Std.Math.*;

/// İki H kapısı birbirini sıfırlar → sonuç her zaman Zero.
@Test()
operation TestDoubleHadamardIsIdentity() : Unit {
    for _ in 1..50 {
        Fact(DoubleHadamard() == Zero, "H·H ≠ I");
    }
}

/// Bell çifti: iki ölçüm her zaman aynı çıkmalı.
@Test()
operation TestBellPairCorrelated() : Unit {
    for _ in 1..100 {
        let (a, b) = BellPair();
        Fact(a == b, "Bell ölçümleri korele değil");
    }
}

/// Işınlama: farklı açılardaki durumlar kayıpsız aktarılmalı.
@Test()
operation TestTeleportation() : Unit {
    for theta in [0.0, 0.3, PI() / 3.0, PI() / 2.0, 2.0, PI()] {
        for _ in 1..20 {
            Fact(TeleportRoundTrip(theta) == Zero, $"Işınlama başarısız, θ={theta}");
        }
    }
}

/// Oracle baz durumunu DEĞİŞTİRMEMELİ (sadece faz). |k⟩ → oracle → ölç = k
@Test()
operation TestOracleKeepsBasisState() : Unit {
    let n = 3;
    for target in 0..7 {
        for k in 0..7 {
            use qs = Qubit[n];
            ApplyXorInPlace(k, qs);
            MarkTarget(target, qs);
            Fact(MeasureInteger(qs) == k, "Oracle baz durumunu bozdu");
        }
    }
}

/// Oracle fazı SADECE hedefte çevirmeli. Faz geri tepmesi (phase kickback):
/// kontrol kübiti |+⟩ → Controlled oracle → H → ölç.
/// Faz çevrildiyse One, çevrilmediyse Zero.
@Test()
operation TestOraclePhaseKickback() : Unit {
    let n = 3;
    for target in 0..7 {
        for k in 0..7 {
            use ctrl = Qubit();
            use qs = Qubit[n];
            ApplyXorInPlace(k, qs);
            H(ctrl);
            Controlled MarkTarget([ctrl], (target, qs));
            H(ctrl);
            let flipped = MResetZ(ctrl) == One;
            Fact(flipped == (k == target), $"Faz hatası: hedef={target}, k={k}");
            ResetAll(qs);
        }
    }
}

/// Diffusion düzgün süperpozisyonu (|s⟩) değiştirmemeli (global faz hariç):
/// H^n → Diffuse → H^n  ⇒  |0…0⟩
@Test()
operation TestDiffusionFixesUniformState() : Unit {
    use qs = Qubit[3];
    ApplyToEach(H, qs);
    Diffuse(qs);
    ApplyToEach(H, qs);
    Fact(CheckAllZero(qs), "Diffusion |s⟩'yi korumuyor");
}

/// Oracle ve Diffusion'ın adjoint'i kendisine eşit olmalı (yansımalar).
@Test()
operation TestReflectionsAreSelfInverse() : Unit {
    let n = 3;
    Fact(CheckOperationsAreEqual(n,
        qs => { MarkTarget(5, qs); MarkTarget(5, qs); },
        qs => ()), "Oracle² ≠ I");
    Fact(CheckOperationsAreEqual(n,
        qs => { Diffuse(qs); Diffuse(qs); },
        qs => ()), "Diffusion² ≠ I");
}

/// N=4 için tek iterasyon teorik olarak %100 başarı verir → her hedef için deterministik.
@Test()
operation TestGrover2QubitsAlwaysFindsTarget() : Unit {
    for target in 0..3 {
        for _ in 1..25 {
            Fact(GroverSearchAuto(2, target) == target, $"N=4 hedef {target} bulunamadı");
        }
    }
}

/// Optimum iterasyon sayıları teoriyle uyumlu: n=2→1, 3→2, 4→3, 5→4, 6→6
@Test()
operation TestOptimalIterations() : Unit {
    Fact(OptimalIterations(2) == 1, "n=2");
    Fact(OptimalIterations(3) == 2, "n=3");
    Fact(OptimalIterations(4) == 3, "n=4");
    Fact(OptimalIterations(5) == 4, "n=5");
    Fact(OptimalIterations(6) == 6, "n=6");
}
