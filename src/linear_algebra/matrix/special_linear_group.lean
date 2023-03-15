/-
Copyright (c) 2020 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anne Baanen
-/
import linear_algebra.general_linear_group
import linear_algebra.matrix.adjugate.det
import linear_algebra.matrix.to_lin

/-!
# The Special Linear group $SL(n, R)$

This file defines the elements of the Special Linear group `special_linear_group n R`, consisting
of all square `R`-matrices with determinant `1` on the fintype `n` by `n`.  In addition, we define
the group structure on `special_linear_group n R` and the embedding into the general linear group
`general_linear_group R (n → R)`.

## Main definitions

 * `matrix.special_linear_group` is the type of matrices with determinant 1
 * `matrix.special_linear_group.group` gives the group structure (under multiplication)
 * `matrix.special_linear_group.to_GL` is the embedding `SLₙ(R) → GLₙ(R)`

## Notation

For `m : ℕ`, we introduce the notation `SL(m,R)` for the special linear group on the fintype
`n = fin m`, in the locale `matrix_groups`.

## Implementation notes
The inverse operation in the `special_linear_group` is defined to be the adjugate
matrix, so that `special_linear_group n R` has a group structure for all `comm_ring R`.

We define the elements of `special_linear_group` to be matrices, since we need to
compute their determinant. This is in contrast with `general_linear_group R M`,
which consists of invertible `R`-linear maps on `M`.

We provide `matrix.special_linear_group.has_coe_to_fun` for convenience, but do not state any
lemmas about it, and use `matrix.special_linear_group.coe_fn_eq_coe` to eliminate it `⇑` in favor
of a regular `↑` coercion.

## References

 * https://en.wikipedia.org/wiki/Special_linear_group

## Tags

matrix group, group, matrix inverse
-/

namespace matrix
universes u v
open_locale matrix
open linear_map


section

variables (n : Type u) [decidable_eq n] [fintype n] (R : Type v) [comm_ring R]

/-- `special_linear_group n R` is the group of `n` by `n` `R`-matrices with determinant equal to 1.
-/
def special_linear_group := { A : matrix n n R // A.det = 1 }

end

localized "notation (name := special_linear_group.fin)
  `SL(`n`, `R`)`:= matrix.special_linear_group (fin n) R" in matrix_groups

namespace special_linear_group

variables {n : Type u} [decidable_eq n] [fintype n] {R : Type v} [comm_ring R]

instance has_coe_to_matrix : has_coe (special_linear_group n R) (matrix n n R) :=
⟨λ A, A.val⟩

/- In this file, Lean often has a hard time working out the values of `n` and `R` for an expression
like `det ↑A`. Rather than writing `(A : matrix n n R)` everywhere in this file which is annoyingly
verbose, or `A.val` which is not the simp-normal form for subtypes, we create a local notation
`↑ₘA`. This notation references the local `n` and `R` variables, so is not valid as a global
notation. -/
local prefix `↑ₘ`:1024 := @coe _ (matrix n n R) _

lemma ext_iff (A B : special_linear_group n R) : A = B ↔ (∀ i j, ↑ₘA i j = ↑ₘB i j) :=
subtype.ext_iff.trans matrix.ext_iff.symm

@[ext] lemma ext (A B : special_linear_group n R) : (∀ i j, ↑ₘA i j = ↑ₘB i j) → A = B :=
(special_linear_group.ext_iff A B).mpr

instance has_inv : has_inv (special_linear_group n R) :=
⟨λ A, ⟨adjugate A, by rw [det_adjugate, A.prop, one_pow]⟩⟩

instance has_mul : has_mul (special_linear_group n R) :=
⟨λ A B, ⟨A.1 ⬝ B.1, by erw [det_mul, A.2, B.2, one_mul]⟩⟩

instance has_one : has_one (special_linear_group n R) :=
⟨⟨1, det_one⟩⟩

instance : has_pow (special_linear_group n R) ℕ :=
{ pow := λ x n, ⟨x ^ n, (det_pow _ _).trans $ x.prop.symm ▸ one_pow _⟩}

instance : inhabited (special_linear_group n R) := ⟨1⟩

section coe_lemmas

variables (A B : special_linear_group n R)

@[simp] lemma coe_mk (A : matrix n n R) (h : det A = 1) :
  ↑(⟨A, h⟩ : special_linear_group n R) = A :=
rfl

@[simp] lemma coe_inv : ↑ₘ(A⁻¹) = adjugate A := rfl

@[simp] lemma coe_mul : ↑ₘ(A * B) = ↑ₘA ⬝ ↑ₘB := rfl

@[simp] lemma coe_one : ↑ₘ(1 : special_linear_group n R) = (1 : matrix n n R) := rfl

@[simp] lemma det_coe : det ↑ₘA = 1 := A.2

@[simp] lemma coe_pow (m : ℕ) : ↑ₘ(A ^ m) = ↑ₘA ^ m := rfl

lemma det_ne_zero [nontrivial R] (g : special_linear_group n R) :
  det ↑ₘg ≠ 0 :=
by { rw g.det_coe, norm_num }

lemma row_ne_zero [nontrivial R] (g : special_linear_group n R) (i : n):
  ↑ₘg i ≠ 0 :=
λ h, g.det_ne_zero $ det_eq_zero_of_row_eq_zero i $ by simp [h]

end coe_lemmas

instance : monoid (special_linear_group n R) :=
function.injective.monoid coe subtype.coe_injective coe_one coe_mul coe_pow

instance : group (special_linear_group n R) :=
{ mul_left_inv := λ A, by { ext1, simp [adjugate_mul] },
  ..special_linear_group.monoid,
  ..special_linear_group.has_inv }

/-- A version of `matrix.to_lin' A` that produces linear equivalences. -/
def to_lin' : special_linear_group n R →* (n → R) ≃ₗ[R] (n → R) :=
{ to_fun := λ A, linear_equiv.of_linear (matrix.to_lin' ↑ₘA) (matrix.to_lin' ↑ₘ(A⁻¹))
    (by rw [←to_lin'_mul, ←coe_mul, mul_right_inv, coe_one, to_lin'_one])
    (by rw [←to_lin'_mul, ←coe_mul, mul_left_inv, coe_one, to_lin'_one]),
  map_one' := linear_equiv.to_linear_map_injective matrix.to_lin'_one,
  map_mul' := λ A B, linear_equiv.to_linear_map_injective $ matrix.to_lin'_mul A B }

lemma to_lin'_apply (A : special_linear_group n R) (v : n → R) :
  special_linear_group.to_lin' A v = matrix.to_lin' ↑ₘA v := rfl

lemma to_lin'_to_linear_map (A : special_linear_group n R) :
  ↑(special_linear_group.to_lin' A) = matrix.to_lin' ↑ₘA := rfl

lemma to_lin'_symm_apply (A : special_linear_group n R) (v : n → R) :
  A.to_lin'.symm v = matrix.to_lin' ↑ₘ(A⁻¹) v := rfl

lemma to_lin'_symm_to_linear_map (A : special_linear_group n R) :
  ↑(A.to_lin'.symm) = matrix.to_lin' ↑ₘ(A⁻¹) := rfl

lemma to_lin'_injective :
  function.injective ⇑(to_lin' : special_linear_group n R →* (n → R) ≃ₗ[R] (n → R)) :=
λ A B h, subtype.coe_injective $ matrix.to_lin'.injective $
  linear_equiv.to_linear_map_injective.eq_iff.mpr h

/-- `to_GL` is the map from the special linear group to the general linear group -/
def to_GL : special_linear_group n R →* general_linear_group R (n → R) :=
(general_linear_group.general_linear_equiv _ _).symm.to_monoid_hom.comp to_lin'

lemma coe_to_GL (A : special_linear_group n R) : ↑A.to_GL = A.to_lin'.to_linear_map := rfl

variables {S : Type*} [comm_ring S]

/-- A ring homomorphism from `R` to `S` induces a group homomorphism from
`special_linear_group n R` to `special_linear_group n S`. -/
@[simps] def map (f : R →+* S) : special_linear_group n R →* special_linear_group n S :=
{ to_fun := λ g, ⟨f.map_matrix ↑g, by { rw ← f.map_det, simp [g.2] }⟩,
  map_one' := subtype.ext $ f.map_matrix.map_one,
  map_mul' := λ x y, subtype.ext $ f.map_matrix.map_mul x y }

section cast

/-- Coercion of SL `n` `ℤ` to SL `n` `R` for a commutative ring `R`. -/
instance : has_coe (special_linear_group n ℤ) (special_linear_group n R) :=
⟨λ x, map (int.cast_ring_hom R) x⟩

@[simp] lemma coe_matrix_coe (g : special_linear_group n ℤ) :
  ↑(g : special_linear_group n R)
  = (↑g : matrix n n ℤ).map (int.cast_ring_hom R) :=
map_apply_coe (int.cast_ring_hom R) g

end cast

section has_neg

variables [fact (even (fintype.card n))]

/-- Formal operation of negation on special linear group on even cardinality `n` given by negating
each element. -/
instance : has_neg (special_linear_group n R) :=
⟨λ g,
  ⟨- g, by simpa [(fact.out $ even $ fintype.card n).neg_one_pow, g.det_coe] using
  det_smul ↑ₘg (-1)⟩⟩

@[simp] lemma coe_neg (g : special_linear_group n R) : ↑(- g) = - (g : matrix n n R) := rfl

instance : has_distrib_neg (special_linear_group n R) :=
function.injective.has_distrib_neg _ subtype.coe_injective coe_neg coe_mul

@[simp] lemma coe_int_neg (g : special_linear_group n ℤ) :
  ↑(-g) = (-↑g : special_linear_group n R) :=
subtype.ext $ (@ring_hom.map_matrix n _ _ _ _ _ _ (int.cast_ring_hom R)).map_neg ↑g

end has_neg

section special_cases

lemma SL2_inv_expl_det (A : SL(2,R)) : det ![![A.1 1 1, -A.1 0 1], ![-A.1 1 0 , A.1 0 0]] = 1 :=
begin
  rw [matrix.det_fin_two, mul_comm],
  simp only [subtype.val_eq_coe, cons_val_zero, cons_val_one, head_cons, mul_neg, neg_mul, neg_neg],
  have := A.2,
  rw matrix.det_fin_two at this,
  convert this,
end

lemma SL2_inv_expl (A : SL(2, R)) : A⁻¹ = ⟨![![A.1 1 1, -A.1 0 1], ![-A.1 1 0 , A.1 0 0]],
    SL2_inv_expl_det A⟩ :=
begin
  ext,
  have := matrix.adjugate_fin_two A.1,
  simp only [subtype.val_eq_coe] at this,
  rw [coe_inv, this],
  refl,
end

lemma fin_two_induction (P : SL(2, R) → Prop)
  (h : ∀ (a b c d : R) (hdet : a * d - b * c = 1), P ⟨!![a, b; c, d], by rwa [det_fin_two_of]⟩)
  (g : SL(2, R)) : P g :=
begin
  obtain ⟨m, hm⟩ := g,
  convert h (m 0 0) (m 0 1) (m 1 0) (m 1 1) (by rwa det_fin_two at hm),
  ext i j, fin_cases i; fin_cases j; refl,
end

lemma fin_two_exists_eq_mk_of_apply_zero_one_eq_zero {R : Type*} [field R]
  (g : SL(2, R)) (hg : (g : matrix (fin 2) (fin 2) R) 1 0 = 0) :
  ∃ (a b : R) (h : a ≠ 0),
    g = (⟨!![a, b; 0, a⁻¹], by simp [h]⟩ : SL(2, R)) :=
begin
  induction g using matrix.special_linear_group.fin_two_induction with a b c d h_det,
  replace hg : c = 0 := by simpa using hg,
  have had : a * d = 1 := by rwa [hg, mul_zero, sub_zero] at h_det,
  refine ⟨a, b, left_ne_zero_of_mul_eq_one had, _⟩,
  simp_rw [eq_inv_of_mul_eq_one_right had, hg],
end

end special_cases

-- this section should be last to ensure we do not use it in lemmas
section coe_fn_instance

/-- This instance is here for convenience, but is not the simp-normal form. -/
instance : has_coe_to_fun (special_linear_group n R) (λ _, n → n → R) :=
{ coe := λ A, A.val }

@[simp]
lemma coe_fn_eq_coe (s : special_linear_group n R) : ⇑s = ↑ₘs := rfl

end coe_fn_instance

end special_linear_group

end matrix

namespace modular_group

open_locale matrix_groups
open matrix matrix.special_linear_group

local prefix `↑ₘ`:1024 := @coe _ (matrix (fin 2) (fin 2) ℤ) _

/-- The matrix `S = [[0, -1], [1, 0]]` as an element of `SL(2, ℤ)`.

This element acts naturally on the Euclidean plane as a rotation about the origin by `π / 2`.

This element also acts naturally on the hyperbolic plane as rotation about `i` by `π`. It
represents the Mobiüs transformation `z ↦ -1/z` and is an involutive elliptic isometry. -/
def S : SL(2, ℤ) := ⟨!![0, -1; 1, 0], by norm_num [matrix.det_fin_two_of]⟩

/-- The matrix `T = [[1, 1], [0, 1]]` as an element of `SL(2, ℤ)` -/
def T : SL(2, ℤ) := ⟨!![1, 1; 0, 1], by norm_num [matrix.det_fin_two_of]⟩

lemma coe_S : ↑ₘS = !![0, -1; 1, 0] := rfl

lemma coe_T : ↑ₘT = !![1, 1; 0, 1] := rfl

lemma coe_T_inv : ↑ₘ(T⁻¹) = !![1, -1; 0, 1] := by simp [coe_inv, coe_T, adjugate_fin_two]

lemma coe_T_zpow (n : ℤ) : ↑ₘ(T ^ n) = !![1, n; 0, 1] :=
begin
  induction n using int.induction_on with n h n h,
  { rw [zpow_zero, coe_one, matrix.one_fin_two] },
  { simp_rw [zpow_add, zpow_one, coe_mul, h, coe_T, matrix.mul_fin_two],
    congrm !![_, _; _, _],
    rw [mul_one, mul_one, add_comm] },
  { simp_rw [zpow_sub, zpow_one, coe_mul, h, coe_T_inv, matrix.mul_fin_two],
    congrm !![_, _; _, _]; ring },
end

@[simp] lemma T_pow_mul_apply_one (n : ℤ) (g : SL(2, ℤ)) : ↑ₘ(T ^ n * g) 1 = ↑ₘg 1 :=
by simp [coe_T_zpow, matrix.mul, matrix.dot_product, fin.sum_univ_succ]

@[simp] lemma T_mul_apply_one (g : SL(2, ℤ)) : ↑ₘ(T * g) 1 = ↑ₘg 1 :=
by simpa using T_pow_mul_apply_one 1 g

@[simp] lemma T_inv_mul_apply_one (g : SL(2, ℤ)) : ↑ₘ(T⁻¹ * g) 1 = ↑ₘg 1 :=
by simpa using T_pow_mul_apply_one (-1) g

end modular_group
