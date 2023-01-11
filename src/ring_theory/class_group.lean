/-
Copyright (c) 2021 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anne Baanen
-/

import group_theory.quotient_group
import ring_theory.dedekind_domain.ideal

/-!
# The ideal class group

This file defines the ideal class group `class_group R` of fractional ideals of `R`
inside its field of fractions.

## Main definitions
 - `to_principal_ideal` sends an invertible `x : K` to an invertible fractional ideal
 - `class_group` is the quotient of invertible fractional ideals modulo `to_principal_ideal.range`
 - `class_group.mk0` sends a nonzero integral ideal in a Dedekind domain to its class

## Main results
 - `class_group.mk0_eq_mk0_iff` shows the equivalence with the "classical" definition,
   where `I ~ J` iff `x I = y J` for `x y ≠ (0 : R)`

## Implementation details

The definition of `class_group R` involves `fraction_ring R`. However, the API should be completely
identical no matter the choice of field of fractions for `R`.
-/

variables {R K L : Type*} [comm_ring R]
variables [field K] [field L] [decidable_eq L]
variables [algebra R K] [is_fraction_ring R K]
variables [algebra K L] [finite_dimensional K L]
variables [algebra R L] [is_scalar_tower R K L]

open_locale non_zero_divisors

open is_localization is_fraction_ring fractional_ideal units

section

variables (R K)

/-- `to_principal_ideal R K x` sends `x ≠ 0 : K` to the fractional `R`-ideal generated by `x` -/
@[irreducible]
def to_principal_ideal : Kˣ →* (fractional_ideal R⁰ K)ˣ :=
{ to_fun := λ x,
  ⟨span_singleton _ x,
   span_singleton _ x⁻¹,
   by simp only [span_singleton_one, units.mul_inv', span_singleton_mul_span_singleton],
   by simp only [span_singleton_one, units.inv_mul', span_singleton_mul_span_singleton]⟩,
  map_mul' := λ x y, ext
    (by simp only [units.coe_mk, units.coe_mul, span_singleton_mul_span_singleton]),
  map_one' := ext (by simp only [span_singleton_one, units.coe_mk, units.coe_one]) }

local attribute [semireducible] to_principal_ideal

variables {R K}

@[simp] lemma coe_to_principal_ideal (x : Kˣ) :
  (to_principal_ideal R K x : fractional_ideal R⁰ K) = span_singleton _ x :=
rfl

@[simp] lemma to_principal_ideal_eq_iff {I : (fractional_ideal R⁰ K)ˣ} {x : Kˣ} :
  to_principal_ideal R K x = I ↔ span_singleton R⁰ (x : K) = I :=
units.ext_iff

lemma mem_principal_ideals_iff {I : (fractional_ideal R⁰ K)ˣ} :
  I ∈ (to_principal_ideal R K).range ↔ ∃ x : K, span_singleton R⁰ x = I :=
begin
  simp only [monoid_hom.mem_range, to_principal_ideal_eq_iff],
  split; rintros ⟨x, hx⟩,
  { exact ⟨x, hx⟩ },
  { refine ⟨units.mk0 x _, hx⟩,
    rintro rfl,
    simpa [I.ne_zero.symm] using hx }
end

instance principal_ideals.normal : (to_principal_ideal R K).range.normal :=
subgroup.normal_of_comm _

end

variables (R) [is_domain R]

/-- The ideal class group of `R` is the group of invertible fractional ideals
modulo the principal ideals. -/
@[derive comm_group]
def class_group :=
(fractional_ideal R⁰ (fraction_ring R))ˣ ⧸ (to_principal_ideal R (fraction_ring R)).range

noncomputable instance : inhabited (class_group R) := ⟨1⟩

variables {R K}

/-- Send a nonzero fractional ideal to the corresponding class in the class group. -/
noncomputable def class_group.mk : (fractional_ideal R⁰ K)ˣ →* class_group R :=
(quotient_group.mk' (to_principal_ideal R (fraction_ring R)).range).comp
  (units.map (fractional_ideal.canonical_equiv R⁰ K (fraction_ring R)))

lemma class_group.mk_eq_mk {I J : (fractional_ideal R⁰ $ fraction_ring R)ˣ} :
  class_group.mk I = class_group.mk J
    ↔ ∃ x : (fraction_ring R)ˣ, I * to_principal_ideal R (fraction_ring R) x = J :=
by { erw [quotient_group.mk'_eq_mk', canonical_equiv_self, units.map_id, set.exists_range_iff],
     refl }

lemma class_group.mk_eq_mk_of_coe_ideal
  {I J : (fractional_ideal R⁰ $ fraction_ring R)ˣ} {I' J' : ideal R}
  (hI : (I : fractional_ideal R⁰ $ fraction_ring R) = I')
  (hJ : (J : fractional_ideal R⁰ $ fraction_ring R) = J') :
  class_group.mk I = class_group.mk J
    ↔ ∃ x y : R, x ≠ 0 ∧ y ≠ 0 ∧ ideal.span {x} * I' = ideal.span {y} * J' :=
begin
  rw [class_group.mk_eq_mk],
  split,
  { rintro ⟨x, rfl⟩,
    rw [units.coe_mul, hI, coe_to_principal_ideal, mul_comm,
        span_singleton_mul_coe_ideal_eq_coe_ideal] at hJ,
    exact ⟨_, _, sec_fst_ne_zero le_rfl x.ne_zero, sec_snd_ne_zero le_rfl ↑x, hJ⟩ },
  { rintro ⟨x, y, hx, hy, h⟩,
    split, rw [mul_comm, ← units.eq_iff, units.coe_mul, coe_to_principal_ideal],
    convert (mk'_mul_coe_ideal_eq_coe_ideal (fraction_ring R) $
              mem_non_zero_divisors_of_ne_zero hy).2 h,
    apply (ne.is_unit _).unit_spec,
    rwa [ne, mk'_eq_zero_iff_eq_zero] }
end

lemma class_group.mk_eq_one_of_coe_ideal {I : (fractional_ideal R⁰ $ fraction_ring R)ˣ}
  {I' : ideal R} (hI : (I : fractional_ideal R⁰ $ fraction_ring R) = I') :
  class_group.mk I = 1 ↔ ∃ x : R, x ≠ 0 ∧ I' = ideal.span {x} :=
begin
  rw [← map_one class_group.mk, class_group.mk_eq_mk_of_coe_ideal hI (_ : _ = ↑⊤)],
  any_goals { refl },
  split,
  { rintro ⟨x, y, hx, hy, h⟩,
    rw [ideal.mul_top] at h,
    rcases ideal.mem_span_singleton_mul.mp ((ideal.span_singleton_le_iff_mem _).mp h.ge)
      with ⟨i, hi, rfl⟩,
    rw [← ideal.span_singleton_mul_span_singleton, ideal.span_singleton_mul_right_inj hx] at h,
    exact ⟨i, right_ne_zero_of_mul hy, h⟩ },
  { rintro ⟨x, hx, rfl⟩,
    exact ⟨1, x, one_ne_zero, hx, by rw [ideal.span_singleton_one, ideal.top_mul, ideal.mul_top]⟩ }
end

variables (K)

/-- Induction principle for the class group: to show something holds for all `x : class_group R`,
we can choose a fraction field `K` and show it holds for the equivalence class of each
`I : fractional_ideal R⁰ K`. -/
@[elab_as_eliminator] lemma class_group.induction {P : class_group R → Prop}
  (h : ∀ (I : (fractional_ideal R⁰ K)ˣ), P (class_group.mk I)) (x : class_group R) : P x :=
quotient_group.induction_on x (λ I, begin
  convert h (units.map_equiv ↑(canonical_equiv R⁰ (fraction_ring R) K) I),
  ext : 1,
  rw [units.coe_map, units.coe_map_equiv],
  exact (canonical_equiv_flip R⁰ K (fraction_ring R) I).symm
end)

/-- The definition of the class group does not depend on the choice of field of fractions. -/
noncomputable def class_group.equiv :
  class_group R ≃* (fractional_ideal R⁰ K)ˣ ⧸ (to_principal_ideal R K).range :=
quotient_group.congr _ _
  (units.map_equiv (fractional_ideal.canonical_equiv R⁰ (fraction_ring R) K :
    fractional_ideal R⁰ (fraction_ring R) ≃* fractional_ideal R⁰ K)) $
begin
  ext I,
  simp only [subgroup.mem_map, mem_principal_ideals_iff, monoid_hom.coe_coe],
  split,
  { rintro ⟨I, ⟨x, hx⟩, rfl⟩,
    refine ⟨fraction_ring.alg_equiv R K x, _⟩,
    rw [units.coe_map_equiv, ← hx, ring_equiv.coe_to_mul_equiv, canonical_equiv_span_singleton],
    refl },
  { rintro ⟨x, hx⟩,
    refine ⟨units.map_equiv ↑(canonical_equiv R⁰ K (fraction_ring R)) I,
      ⟨(fraction_ring.alg_equiv R K).symm x, _⟩,
      units.ext _⟩,
    { rw [units.coe_map_equiv, ← hx, ring_equiv.coe_to_mul_equiv, canonical_equiv_span_singleton],
      refl },
    simp only [ring_equiv.coe_to_mul_equiv, canonical_equiv_flip, units.coe_map_equiv] },
end

@[simp] lemma class_group.equiv_mk (K' : Type*) [field K'] [algebra R K'] [is_fraction_ring R K']
  (I : (fractional_ideal R⁰ K)ˣ) :
  class_group.equiv K' (class_group.mk I) =
    quotient_group.mk' _ (units.map_equiv ↑(fractional_ideal.canonical_equiv R⁰ K K') I) :=
begin
  rw [class_group.equiv, class_group.mk, monoid_hom.comp_apply, quotient_group.congr_mk'],
  congr,
  ext : 1,
  rw [units.coe_map_equiv, units.coe_map_equiv, units.coe_map],
  exact fractional_ideal.canonical_equiv_canonical_equiv _ _ _ _ _
end

@[simp] lemma class_group.mk_canonical_equiv (K' : Type*) [field K'] [algebra R K']
  [is_fraction_ring R K'] (I : (fractional_ideal R⁰ K)ˣ) :
  class_group.mk (units.map ↑(canonical_equiv R⁰ K K') I : (fractional_ideal R⁰ K')ˣ) =
    class_group.mk I :=
by rw [class_group.mk, monoid_hom.comp_apply, ← monoid_hom.comp_apply (units.map _),
  ← units.map_comp, ← ring_equiv.coe_monoid_hom_trans,
  fractional_ideal.canonical_equiv_trans_canonical_equiv]; refl

/-- Send a nonzero integral ideal to an invertible fractional ideal. -/
noncomputable def fractional_ideal.mk0 [is_dedekind_domain R] :
  (ideal R)⁰ →* (fractional_ideal R⁰ K)ˣ :=
{ to_fun   := λ I, units.mk0 I (coe_ideal_ne_zero.mpr $ mem_non_zero_divisors_iff_ne_zero.mp I.2),
  map_one' := by simp,
  map_mul' := λ x y, by simp }

@[simp] lemma fractional_ideal.coe_mk0 [is_dedekind_domain R] (I : (ideal R)⁰) :
  (fractional_ideal.mk0 K I : fractional_ideal R⁰ K) = I :=
rfl

lemma fractional_ideal.canonical_equiv_mk0 [is_dedekind_domain R]
  (K' : Type*) [field K'] [algebra R K'] [is_fraction_ring R K'] (I : (ideal R)⁰) :
  fractional_ideal.canonical_equiv R⁰ K K' (fractional_ideal.mk0 K I) = fractional_ideal.mk0 K' I :=
by simp only [fractional_ideal.coe_mk0, coe_coe, fractional_ideal.canonical_equiv_coe_ideal]

@[simp] lemma fractional_ideal.map_canonical_equiv_mk0 [is_dedekind_domain R]
  (K' : Type*) [field K'] [algebra R K'] [is_fraction_ring R K'] (I : (ideal R)⁰) :
  units.map ↑(fractional_ideal.canonical_equiv R⁰ K K') (fractional_ideal.mk0 K I) =
    fractional_ideal.mk0 K' I :=
units.ext (fractional_ideal.canonical_equiv_mk0 K K' I)

/-- Send a nonzero ideal to the corresponding class in the class group. -/
noncomputable def class_group.mk0 [is_dedekind_domain R] : (ideal R)⁰ →* class_group R :=
class_group.mk.comp (fractional_ideal.mk0 (fraction_ring R))

@[simp] lemma class_group.mk_mk0 [is_dedekind_domain R] (I : (ideal R)⁰):
  class_group.mk (fractional_ideal.mk0 K I) = class_group.mk0 I :=
by rw [class_group.mk0, monoid_hom.comp_apply,
      ← class_group.mk_canonical_equiv K (fraction_ring R),
      fractional_ideal.map_canonical_equiv_mk0]

@[simp] lemma class_group.equiv_mk0 [is_dedekind_domain R] (I : (ideal R)⁰):
  class_group.equiv K (class_group.mk0 I) =
    quotient_group.mk' (to_principal_ideal R K).range (fractional_ideal.mk0 K I) :=
begin
  rw [class_group.mk0, monoid_hom.comp_apply, class_group.equiv_mk],
  congr,
  ext,
  simp
end

lemma class_group.mk0_eq_mk0_iff_exists_fraction_ring [is_dedekind_domain R] {I J : (ideal R)⁰} :
  class_group.mk0 I = class_group.mk0 J ↔ ∃ (x ≠ (0 : K)), span_singleton R⁰ x * I = J :=
begin
  refine (class_group.equiv K).injective.eq_iff.symm.trans _,
  simp only [class_group.equiv_mk0, quotient_group.mk'_eq_mk', mem_principal_ideals_iff,
    coe_coe, units.ext_iff, units.coe_mul, fractional_ideal.coe_mk0, exists_prop],
  split,
  { rintros ⟨X, ⟨x, hX⟩, hx⟩,
    refine ⟨x, _, _⟩,
    { rintro rfl, simpa [X.ne_zero.symm] using hX },
    simpa only [hX, mul_comm] using hx },
  { rintros ⟨x, hx, eq_J⟩,
    refine ⟨units.mk0 _ (span_singleton_ne_zero_iff.mpr hx), ⟨x, rfl⟩, _⟩,
    simpa only [mul_comm] using eq_J }
end

variables {K}

lemma class_group.mk0_eq_mk0_iff [is_dedekind_domain R] {I J : (ideal R)⁰} :
  class_group.mk0 I = class_group.mk0 J ↔
    ∃ (x y : R) (hx : x ≠ 0) (hy : y ≠ 0), ideal.span {x} * (I : ideal R) = ideal.span {y} * J :=
begin
  refine (class_group.mk0_eq_mk0_iff_exists_fraction_ring (fraction_ring R)).trans ⟨_, _⟩,
  { rintros ⟨z, hz, h⟩,
    obtain ⟨x, ⟨y, hy⟩, rfl⟩ := is_localization.mk'_surjective R⁰ z,
    refine ⟨x, y, _, mem_non_zero_divisors_iff_ne_zero.mp hy, _⟩,
    { rintro hx, apply hz,
      rw [hx, is_fraction_ring.mk'_eq_div, _root_.map_zero, zero_div] },
    { exact (fractional_ideal.mk'_mul_coe_ideal_eq_coe_ideal _ hy).mp h } },
  { rintros ⟨x, y, hx, hy, h⟩,
    have hy' : y ∈ R⁰ := mem_non_zero_divisors_iff_ne_zero.mpr hy,
    refine ⟨is_localization.mk' _ x ⟨y, hy'⟩, _, _⟩,
    { contrapose! hx,
      rwa [mk'_eq_iff_eq_mul, zero_mul, ← (algebra_map R (fraction_ring R)).map_zero,
           (is_fraction_ring.injective R (fraction_ring R)).eq_iff]
        at hx },
    { exact (fractional_ideal.mk'_mul_coe_ideal_eq_coe_ideal _ hy').mpr h } },
end

lemma class_group.mk0_surjective [is_dedekind_domain R] :
  function.surjective (class_group.mk0 : (ideal R)⁰ → class_group R) :=
begin
  rintros ⟨I⟩,
  obtain ⟨a, a_ne_zero', ha⟩ := I.1.2,
  have a_ne_zero := mem_non_zero_divisors_iff_ne_zero.mp a_ne_zero',
  have fa_ne_zero : (algebra_map R (fraction_ring R)) a ≠ 0 :=
    is_fraction_ring.to_map_ne_zero_of_mem_non_zero_divisors a_ne_zero',
  refine ⟨⟨{ carrier := { x | (algebra_map R _ a)⁻¹ * algebra_map R _ x ∈ I.1 }, .. }, _⟩, _⟩,
  { simp only [ring_hom.map_add, set.mem_set_of_eq, mul_zero, ring_hom.map_mul, mul_add],
    exact λ _ _ ha hb, submodule.add_mem I ha hb },
  { simp only [ring_hom.map_zero, set.mem_set_of_eq, mul_zero, ring_hom.map_mul],
    exact submodule.zero_mem I },
  { intros c _ hb,
    simp only [smul_eq_mul, set.mem_set_of_eq, mul_zero, ring_hom.map_mul, mul_add,
               mul_left_comm ((algebra_map R (fraction_ring R)) a)⁻¹],
    rw ← algebra.smul_def c,
    exact submodule.smul_mem I c hb },
  { rw [mem_non_zero_divisors_iff_ne_zero, submodule.zero_eq_bot, submodule.ne_bot_iff],
    obtain ⟨x, x_ne, x_mem⟩ := exists_ne_zero_mem_is_integer I.ne_zero,
    refine ⟨a * x, _, mul_ne_zero a_ne_zero x_ne⟩,
    change ((algebra_map R _) a)⁻¹ * (algebra_map R _) (a * x) ∈ I.1,
    rwa [ring_hom.map_mul, ← mul_assoc, inv_mul_cancel fa_ne_zero, one_mul] },
  { symmetry,
    apply quotient.sound,
    change setoid.r _ _,
    rw quotient_group.left_rel_apply,
    refine ⟨units.mk0 (algebra_map R _ a) fa_ne_zero, _⟩,
    rw [_root_.eq_inv_mul_iff_mul_eq, eq_comm, mul_comm I],
    apply units.ext,
    simp only [fractional_ideal.coe_mk0, fractional_ideal.map_canonical_equiv_mk0, set_like.coe_mk,
        units.coe_mk0, coe_to_principal_ideal, coe_coe, units.coe_mul,
        fractional_ideal.eq_span_singleton_mul],
    split,
    { intros zJ' hzJ',
      obtain ⟨zJ, hzJ : (algebra_map R _ a)⁻¹ * algebra_map R _ zJ ∈ ↑I, rfl⟩ :=
        (mem_coe_ideal R⁰).mp hzJ',
      refine ⟨_, hzJ, _⟩,
      rw [← mul_assoc, mul_inv_cancel fa_ne_zero, one_mul] },
    { intros zI' hzI',
      obtain ⟨y, hy⟩ := ha zI' hzI',
      rw [← algebra.smul_def, mem_coe_ideal],
      refine ⟨y, _, hy⟩,
      show (algebra_map R _ a)⁻¹ * algebra_map R _ y ∈ (I : fractional_ideal R⁰ (fraction_ring R)),
      rwa [hy, algebra.smul_def, ← mul_assoc, inv_mul_cancel fa_ne_zero, one_mul] } }
end

lemma class_group.mk_eq_one_iff {I : (fractional_ideal R⁰ K)ˣ} :
  class_group.mk I = 1 ↔ (I : submodule R K).is_principal :=
begin
  simp only [← (class_group.equiv K).injective.eq_iff, _root_.map_one, class_group.equiv_mk,
      quotient_group.mk'_apply, quotient_group.eq_one_iff, monoid_hom.mem_range, units.ext_iff,
      coe_to_principal_ideal, units.coe_map_equiv, fractional_ideal.canonical_equiv_self, coe_coe,
      ring_equiv.coe_mul_equiv_refl, mul_equiv.refl_apply],
  refine ⟨λ ⟨x, hx⟩, ⟨⟨x, by rw [← hx, coe_span_singleton]⟩⟩, _⟩,
  unfreezingI { intros hI },
  obtain ⟨x, hx⟩ := @submodule.is_principal.principal _ _ _ _ _ _ hI,
  have hx' : (I : fractional_ideal R⁰ K) = span_singleton R⁰ x,
  { apply subtype.coe_injective, rw [hx, coe_span_singleton] },
  refine ⟨units.mk0 x _, _⟩,
  { intro x_eq, apply units.ne_zero I, simp [hx', x_eq] },
  simp [hx']
end

lemma class_group.mk0_eq_one_iff [is_dedekind_domain R] {I : ideal R} (hI : I ∈ (ideal R)⁰) :
  class_group.mk0 ⟨I, hI⟩ = 1 ↔ I.is_principal :=
class_group.mk_eq_one_iff.trans (coe_submodule_is_principal R _)

/-- The class group of principal ideal domain is finite (in fact a singleton).

See `class_group.fintype_of_admissible` for a finiteness proof that works for rings of integers
of global fields.
-/
noncomputable instance [is_principal_ideal_ring R] : fintype (class_group R) :=
{ elems := {1},
  complete :=
  begin
    refine class_group.induction (fraction_ring R) (λ I, _),
    rw finset.mem_singleton,
    exact class_group.mk_eq_one_iff.mpr (I : fractional_ideal R⁰ (fraction_ring R)).is_principal
  end }

/-- The class number of a principal ideal domain is `1`. -/
lemma card_class_group_eq_one [is_principal_ideal_ring R] : fintype.card (class_group R) = 1 :=
begin
  rw fintype.card_eq_one_iff,
  use 1,
  refine class_group.induction (fraction_ring R) (λ I, _),
  exact class_group.mk_eq_one_iff.mpr (I : fractional_ideal R⁰ (fraction_ring R)).is_principal
end

/-- The class number is `1` iff the ring of integers is a principal ideal domain. -/
lemma card_class_group_eq_one_iff [is_dedekind_domain R] [fintype (class_group R)] :
  fintype.card (class_group R) = 1 ↔ is_principal_ideal_ring R :=
begin
  split, swap, { introsI, convert card_class_group_eq_one, assumption, },
  rw fintype.card_eq_one_iff,
  rintros ⟨I, hI⟩,
  have eq_one : ∀ J : class_group R, J = 1 := λ J, trans (hI J) (hI 1).symm,
  refine ⟨λ I, _⟩,
  by_cases hI : I = ⊥,
  { rw hI, exact bot_is_principal },
  exact (class_group.mk0_eq_one_iff (mem_non_zero_divisors_iff_ne_zero.mpr hI)).mp (eq_one _),
end
