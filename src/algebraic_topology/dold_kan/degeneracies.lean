/-
Copyright (c) 2022 Joël Riou. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joël Riou
-/

import algebraic_topology.dold_kan.decomposition
import tactic.fin_cases

/-!

# Behaviour of P_infty with respect to degeneracies

> THIS FILE IS SYNCHRONIZED WITH MATHLIB4.
> Any changes to this file require a corresponding PR to mathlib4.

For any `X : simplicial_object C` where `C` is an abelian category,
the projector `P_infty : K[X] ⟶ K[X]` is supposed to be the projection
on the normalized subcomplex, parallel to the degenerate subcomplex, i.e.
the subcomplex generated by the images of all `X.σ i`.

In this file, we obtain `degeneracy_comp_P_infty` which states that
if `X : simplicial_object C` with `C` a preadditive category,
`θ : [n] ⟶ Δ'` is a non injective map in `simplex_category`, then
`X.map θ.op ≫ P_infty.f n = 0`. It follows from the more precise
statement vanishing statement `σ_comp_P_eq_zero` for the `P q`.

-/

open category_theory category_theory.category category_theory.limits
  category_theory.preadditive opposite
open_locale simplicial dold_kan

namespace algebraic_topology

namespace dold_kan

variables {C : Type*} [category C] [preadditive C]

lemma higher_faces_vanish.comp_σ {Y : C} {X : simplicial_object C} {n b q : ℕ} {φ : Y ⟶ X _[n+1]}
  (v : higher_faces_vanish q φ) (hnbq : n + 1 = b + q) :
    higher_faces_vanish q (φ ≫ X.σ ⟨b,
    by simpa only [hnbq, nat.lt_succ_iff, le_add_iff_nonneg_right] using zero_le q⟩) :=
λ j hj, begin
  rw [assoc, simplicial_object.δ_comp_σ_of_gt', fin.pred_succ,
    v.comp_δ_eq_zero_assoc _ _ hj, zero_comp],
  { intro hj',
    simpa only [hj', hnbq, fin.coe_zero, zero_add, add_comm b, add_assoc, false_and,
      add_le_iff_nonpos_right, le_zero_iff, add_eq_zero_iff, nat.one_ne_zero] using hj, },
  { simp only [fin.lt_iff_coe_lt_coe, nat.lt_iff_add_one_le,
      fin.succ_mk, fin.coe_mk, fin.coe_succ, add_le_add_iff_right],
    linarith, },
end

lemma σ_comp_P_eq_zero (X : simplicial_object C)
  {n q : ℕ} (i : fin (n + 1)) (hi : n + 1 ≤ i + q) : (X.σ i) ≫ (P q).f (n + 1) = 0 :=
begin
  induction q with q hq generalizing i hi,
  { exfalso,
    have h := fin.is_lt i,
    linarith, },
  { by_cases n+1 ≤ (i : ℕ) + q,
    { unfold P,
      simp only [homological_complex.comp_f, ← assoc],
      rw [hq i h, zero_comp], },
    { have hi' : n = (i : ℕ) + q,
      { cases le_iff_exists_add.mp hi with j hj,
        rw [← nat.lt_succ_iff, nat.succ_eq_add_one, add_assoc, hj, not_lt,
          add_le_iff_nonpos_right, nonpos_iff_eq_zero] at h,
        rw [← add_left_inj 1, add_assoc, hj, self_eq_add_right, h], },
      cases n,
      { fin_cases i,
        rw [show q = 0, by linarith],
        unfold P,
        simp only [id_comp, homological_complex.add_f_apply, comp_add, homological_complex.id_f,
          Hσ, homotopy.null_homotopic_map'_f (c_mk 2 1 rfl) (c_mk 1 0 rfl),
          alternating_face_map_complex.obj_d_eq],
        erw [hσ'_eq' (zero_add 0).symm, hσ'_eq' (add_zero 1).symm, comp_id,
          fin.sum_univ_two, fin.sum_univ_succ, fin.sum_univ_two],
        simp only [pow_zero, pow_one, pow_two, fin.coe_zero, fin.coe_one, fin.coe_two,
          one_zsmul, neg_zsmul, fin.mk_zero, fin.mk_one, fin.coe_succ, pow_add, one_mul,
          neg_mul, neg_neg, fin.succ_zero_eq_one, fin.succ_one_eq_two, comp_neg, neg_comp,
          add_comp, comp_add],
        erw [simplicial_object.δ_comp_σ_self, simplicial_object.δ_comp_σ_self_assoc,
          simplicial_object.δ_comp_σ_succ, comp_id, simplicial_object.δ_comp_σ_of_le X
            (show (0 : fin(2)) ≤ fin.cast_succ 0, by rw fin.cast_succ_zero),
          simplicial_object.δ_comp_σ_self_assoc, simplicial_object.δ_comp_σ_succ_assoc],
        abel, },
      { rw [← id_comp (X.σ i), ← (P_add_Q_f q n.succ : _ = 𝟙 (X.obj _)), add_comp, add_comp],
        have v : higher_faces_vanish q ((P q).f n.succ ≫ X.σ i) :=
          (higher_faces_vanish.of_P q n).comp_σ hi',
        unfold P,
        erw [← assoc, v.comp_P_eq_self, homological_complex.add_f_apply,
          preadditive.comp_add, comp_id, v.comp_Hσ_eq hi', assoc,
          simplicial_object.δ_comp_σ_succ'_assoc, fin.eta,
          decomposition_Q n q, sum_comp, sum_comp, finset.sum_eq_zero, add_zero,
          add_neg_eq_zero], swap,
        { ext, simp only [fin.coe_mk, fin.coe_succ], },
        { intros j hj,
          simp only [true_and, finset.mem_univ, finset.mem_filter] at hj,
          simp only [nat.succ_eq_add_one] at hi',
          obtain ⟨k, hk⟩ := nat.le.dest (nat.lt_succ_iff.mp (fin.is_lt j)),
          rw add_comm at hk,
          have hi'' : i = fin.cast_succ ⟨i, by linarith⟩ :=
            by { ext, simp only [fin.cast_succ_mk, fin.eta], },
          have eq := hq j.rev.succ begin
            simp only [← hk, fin.rev_eq j hk.symm, nat.succ_eq_add_one, fin.succ_mk, fin.coe_mk],
            linarith,
          end,
          rw [homological_complex.comp_f, assoc, assoc, assoc, hi'',
            simplicial_object.σ_comp_σ_assoc, reassoc_of eq, zero_comp, comp_zero,
            comp_zero, comp_zero],
          simp only [fin.rev_eq j hk.symm, fin.le_iff_coe_le_coe, fin.coe_mk],
          linarith, }, }, }, }
end

@[simp, reassoc]
lemma σ_comp_P_infty (X : simplicial_object C) {n : ℕ} (i : fin (n+1)) :
  (X.σ i) ≫ P_infty.f (n+1) = 0 :=
begin
  rw [P_infty_f, σ_comp_P_eq_zero X i],
  simp only [le_add_iff_nonneg_left, zero_le],
end

@[reassoc]
lemma degeneracy_comp_P_infty (X : simplicial_object C)
  (n : ℕ) {Δ' : simplex_category} (θ : [n] ⟶ Δ') (hθ : ¬mono θ) :
  X.map θ.op ≫ P_infty.f n = 0 :=
begin
  rw simplex_category.mono_iff_injective at hθ,
  cases n,
  { exfalso,
    apply hθ,
    intros x y h,
    fin_cases x,
    fin_cases y, },
  { obtain ⟨i, α, h⟩ := simplex_category.eq_σ_comp_of_not_injective θ hθ,
    rw [h, op_comp, X.map_comp, assoc, (show X.map (simplex_category.σ i).op = X.σ i, by refl),
      σ_comp_P_infty, comp_zero], },
end

end dold_kan

end algebraic_topology
