// =============================================================
// Faz 1 — Temel kavramlar: süperpozisyon, ölçüm, dolanıklık,
// ışınlama (teleportation). Küçük, tek başına çalışabilen işlemler.
// =============================================================

import Std.Math.*;
import Std.Convert.*;

/// Tek bir rastgele bit üretir: |0⟩ → H → ölç. %50 Zero, %50 One.
operation RandomBit() : Result {
    use q = Qubit();
    H(q);                // |0⟩ → (|0⟩ + |1⟩)/√2
    return MResetZ(q);   // ölç ve kübiti |0⟩'a geri döndür
}

/// 0 ile max (dahil) arasında kuantum rastgele sayı üretir.
/// Gereken sayıda rastgele bit üretip sayıya çevirir; aralık dışıysa tekrar dener.
operation RandomNumberInRange(max : Int) : Int {
    let nBits = BitSizeI(max);
    mutable value = max + 1;
    repeat {
        mutable bits = [];
        for _ in 1..nBits {
            set bits += [RandomBit()];
        }
        set value = ResultArrayAsInt(bits);
    } until value <= max;
    return value;
}

/// Arka arkaya iki H: H·H = I, yani sonuç HER ZAMAN Zero olmalı.
/// Girişim (interference) etkisinin en basit örneği.
operation DoubleHadamard() : Result {
    use q = Qubit();
    H(q);
    H(q);
    return MResetZ(q);
}

/// Bell durumu |Φ+⟩ = (|00⟩ + |11⟩)/√2 hazırlar ve iki kübiti ölçer.
/// Sonuçlar ya (Zero, Zero) ya da (One, One) olmalı — asla karışık değil.
operation BellPair() : (Result, Result) {
    use (a, b) = (Qubit(), Qubit());
    H(a);
    CNOT(a, b);
    return (MResetZ(a), MResetZ(b));
}

/// Kuantum ışınlama: `msg` kübitinin durumunu `target` kübitine taşır.
/// Alice: msg + here   |   Bob: target  (here–target önceden dolanık)
operation Teleport(msg : Qubit, target : Qubit) : Unit {
    use here = Qubit();

    // 1) Alice ile Bob arasında dolanık çift oluştur
    H(here);
    CNOT(here, target);

    // 2) Alice, mesajı kendi yarısıyla etkileştirir ve ölçer
    CNOT(msg, here);
    H(msg);

    // 3) Bob, Alice'in iki klasik bitine göre düzeltme yapar
    if M(msg) == One { Z(target); }
    if M(here) == One { X(target); }

    Reset(here);
}

/// Ry(θ) ile rastgele bir durum hazırlayıp ışınlar, sonra Bob tarafında
/// Ry(-θ) uygular. Işınlama doğruysa ölçüm her zaman Zero çıkar.
operation TeleportRoundTrip(theta : Double) : Result {
    use (msg, target) = (Qubit(), Qubit());
    Ry(theta, msg);
    Teleport(msg, target);
    Adjoint Ry(theta, target);
    Reset(msg);
    return MResetZ(target);
}
