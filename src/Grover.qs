// =============================================================
// Faz 2 — Ana proje: Grover arama algoritması
//
// Problem: N = 2^n elemanlı sırasız bir "veritabanında" tek bir
// işaretli elemanı (target) bul. Klasik olarak ortalama N/2 sorgu
// gerekir; Grover ~ (π/4)·√N sorguda yüksek olasılıkla bulur.
//
// Kübit sıralaması little-endian: qs[0] en düşük anlamlı bit.
// =============================================================

import Std.Math.*;
import Std.Convert.*;
import Std.Arrays.*;
import Std.Diagnostics.Fact;

/// ORACLE: |target⟩ durumunun fazını çevirir (|x⟩ → -|x⟩ eğer x == target),
/// diğer tüm baz durumlarına dokunmaz.
///
/// Yöntem: target'ta 0 olan bitlere X uygula → target durumu |11…1⟩ olur,
/// çok kontrollü Z uygula (yalnız |11…1⟩'in fazını çevirir), X'leri geri al.
operation MarkTarget(target : Int, qs : Qubit[]) : Unit is Adj + Ctl {
    let bits = IntAsBoolArray(target, Length(qs));
    within {
        for i in IndexRange(qs) {
            if not bits[i] { X(qs[i]); }
        }
    } apply {
        Controlled Z(Most(qs), Tail(qs));
    }
}

/// DIFFUSION (ortalama etrafında yansıma): 2|s⟩⟨s| − I
/// |s⟩ düzgün süperpozisyon. H·X ile |s⟩'yi |11…1⟩'e taşıyıp orada faz
/// çevirir, sonra geri döneriz. (Global faz −1 fark eder, ölçümü etkilemez.)
operation Diffuse(qs : Qubit[]) : Unit is Adj + Ctl {
    within {
        ApplyToEachCA(H, qs);
        ApplyToEachCA(X, qs);
    } apply {
        Controlled Z(Most(qs), Tail(qs));
    }
}

/// Tek Grover iterasyonu = Oracle + Diffusion
operation GroverIteration(target : Int, qs : Qubit[]) : Unit is Adj + Ctl {
    MarkTarget(target, qs);
    Diffuse(qs);
}

/// Tek işaretli eleman için optimum iterasyon sayısı.
/// θ = arcsin(1/√N);  başarı olasılığı P(k) = sin²((2k+1)θ)
/// En iyi k ≈ π/(4θ) − 1/2  (en yakın tam sayıya yuvarlanır).
function OptimalIterations(nQubits : Int) : Int {
    let N = IntAsDouble(1 <<< nQubits);
    let theta = ArcSin(1.0 / Sqrt(N));
    return Round(PI() / (4.0 * theta) - 0.5);
}

/// Grover durumunu hazırlar (ölçüm yapmadan) — testler ve analiz için.
operation PrepareGroverState(target : Int, iterations : Int, qs : Qubit[]) : Unit {
    ApplyToEach(H, qs);                  // düzgün süperpozisyon |s⟩
    for _ in 1..iterations {
        GroverIteration(target, qs);
    }
}

/// Tam algoritma: n kübit, verilen hedef ve iterasyon sayısı ile arar,
/// ölçülen indeksi döndürür.
operation GroverSearch(nQubits : Int, target : Int, iterations : Int) : Int {
    Fact(nQubits >= 2, "En az 2 kübit gerekli.");
    Fact(target >= 0 and target < (1 <<< nQubits), "Hedef aralık dışında.");
    use qs = Qubit[nQubits];
    PrepareGroverState(target, iterations, qs);
    return MeasureInteger(qs);           // ölç + kübitleri sıfırla
}

/// Optimum iterasyon sayısını otomatik seçen kısa yol.
operation GroverSearchAuto(nQubits : Int, target : Int) : Int {
    return GroverSearch(nQubits, target, OptimalIterations(nQubits));
}

