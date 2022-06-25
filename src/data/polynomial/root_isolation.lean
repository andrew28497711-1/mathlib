/-
Copyright (c) 2022 Bolton Bailey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Bolton Bailey
-/

import data.polynomial.ring_division
import data.polynomial.degree.definitions
import data.real.basic
import topology.algebra.order.intermediate_value
import topology.metric_space.basic
import topology.continuous_function.polynomial
-- import data.finset.nat_antidiagonal
-- import data.nat.choose.sum

/-!
# Root isolation

Algorithms and theorems for locating the roots of real polynomials.

## TODO

* Descartes' rule of signs
* Sturm's Theorem

-/

-- -- TODO put in erase_lead.lean?
-- lemma rec_on_erase_lead (P : R[X] → Sort*)
--   (P_0 : P 0)
--   (P_C_mul_pow : ∀ n : ℕ, ∀ r : R, r ≠ 0 → P (C r * X ^ n))
--   (P_C_erase_lead : ∀ g : R[X],
--     P g.erase_lead → P g) :
--   ∀ f : R[X], P f :=
-- begin
--   intros f,
--   generalize' hd : card f.support = c,
--   revert f,
--   induction c with c hc,
--   { assume f f0,
--     convert P_0,
--     simpa only [support_eq_empty, card_eq_zero] using f0 },
--   { intros f f0,
--     rw [← erase_lead_add_C_mul_X_pow f],
--     cases c,
--     { convert P_C_mul_pow f.nat_degree f.leading_coeff _,
--       { convert zero_add _,
--         rw [← card_support_eq_zero, erase_lead_card_support f0] },
--       { rw [leading_coeff_ne_zero, ne.def, ← card_support_eq_zero, f0],
--         exact zero_ne_one.symm } },
--     refine P_C_erase_lead _ _,
--     apply hc,
--     { simp only [polynomial.erase_lead_add_C_mul_X_pow],
--       apply erase_lead_card_support',
--       rw f0, }, },
-- end

-- lemma rec_on_erase_lead_with_nat_degree_le (P : R[X] → Sort*) (N : ℕ)
--   (P_0 : P 0)
--   (P_C_mul_pow : ∀ n : ℕ, ∀ r : R, r ≠ 0 → n ≤ N → P (C r * X ^ n))
--   (P_C_erase_lead : ∀ g : R[X],
--     g.nat_degree ≤ N → P g.erase_lead → P g) :
--   ∀ f : R[X], f.nat_degree ≤ N → P f :=
-- begin
--   intros f df,
--   generalize' hd : card f.support = c,
--   revert f,
--   induction c with c hc,
--   { assume f df f0,
--     convert P_0,
--     simpa only [support_eq_empty, card_eq_zero] using f0 },
--   { intros f df f0,
--     rw [← erase_lead_add_C_mul_X_pow f],
--     cases c,
--     { convert P_C_mul_pow f.nat_degree f.leading_coeff _ df,
--       { convert zero_add _,
--         rw [← card_support_eq_zero, erase_lead_card_support f0] },
--       { rw [leading_coeff_ne_zero, ne.def, ← card_support_eq_zero, f0],
--         exact zero_ne_one.symm } },
--     apply P_C_erase_lead,
--     { simp only [polynomial.erase_lead_add_C_mul_X_pow],
--       exact df, },
--     apply hc,
--     { simp only [polynomial.erase_lead_add_C_mul_X_pow],
--       apply le_trans _ df,
--       apply le_trans (erase_lead_nat_degree_le f),
--       simp only [tsub_le_self], },
--     { simp only [polynomial.erase_lead_add_C_mul_X_pow],
--       apply erase_lead_card_support',
--       rw f0, }, },
-- end


-- noncomputable def sign_switches (p : polynomial ℝ) : ℕ :=
-- begin
--   apply @polynomial.rec_on_erase_lead ℝ _ (λ _, ℕ),
--   -- The zero polynomial has zero sign changes
--   { exact 0, },
--   -- A monomial has zero sign changes
--   { intros n r hr, exact 0, },
--   -- A multinomial has as many sign changes as its erasure, potentially plus one for the leading coefficient.
--   { intros p_erased switches_in_erased,
--     exact (switches_in_erased + if p.leading_coeff * p_erased.leading_coeff < 0 then 1 else 0),
--   },
--   exact p,
-- end

lemma multiset.filter_singleton (s : ℝ) (p : ℝ -> Prop) [decidable_pred p] :
  multiset.filter p {s} = if p s then {s} else ∅ :=
begin
  unfold singleton,
  simp_rw multiset.filter_cons,
  simp,
  split_ifs,
  unfold singleton,
  refl,
end


lemma root_parity_in_range_of_evals (a b : ℝ) (hab : a ≤ b) (p : polynomial ℝ)
  (ha : p.eval a ≠ 0) (hb : p.eval b ≠ 0) :
  even ((p.roots.filter ((λ x, a < x ∧ x < b))).card)
    ↔ ((0 < p.eval a ∧ 0 < p.eval b) ∨ (p.eval a < 0 ∧ p.eval b < 0)) :=
begin

  generalize hr : (multiset.filter ((λ x, a < x ∧ x < b)) p.roots) = root_set,
  revert hr hb ha p,
  refine multiset.induction_on root_set _ _,
  {
    intros p ha hb hr,
    have p_nonzero : p ≠ 0,
    { contrapose! ha,
      rw ha,
      simp only [le_refl, and_self, polynomial.eval_zero], },
    simp only [multiset.card_zero, true_iff, even_zero],
    contrapose! hr,
    simp only [ne.def],
    rw multiset.eq_zero_iff_forall_not_mem,
    push_neg,
    replace ha := lt_or_gt_of_ne ha,
    replace hb := lt_or_gt_of_ne hb,
    have p_continuous : continuous_on (λ x, p.eval x) (set.Icc a b),
    {
      exact (polynomial.continuous p).continuous_on,
    },
    rcases ha with ha'|ha'; rcases hb with hb'|hb',
    {
      replace hr := hr.right ha',
      linarith,
    },
    { have ivt := intermediate_value_Ioo hab p_continuous,
      have zero_mem_image := @set.mem_of_mem_of_subset _ 0 _ _ _ ivt,
      { simp at zero_mem_image ⊢,
        rcases zero_mem_image with ⟨x, hx⟩,
        use x,
        rw [polynomial.mem_roots p_nonzero, polynomial.is_root],
        exact and.comm.mp hx, },
      { simp [ha'],
        exact hb', }, },
    { have ivt := intermediate_value_Ioo' hab p_continuous,
      have zero_mem_image := @set.mem_of_mem_of_subset _ 0 _ _ _ ivt,
      { simp at zero_mem_image ⊢,
        rcases zero_mem_image with ⟨x, hx⟩,
        use x,
        rw [polynomial.mem_roots p_nonzero, polynomial.is_root],
        exact and.comm.mp hx, },
      { simp [hb'],
        exact ha', }, },
    {
      replace hr := hr.left ha',
      linarith,
    },
  },
  { -- Inductive case: Polynomial has at least one root `root` in the interval.
    intros root root_set' hf p ha hb hr,
    have p_nonzero : p ≠ 0,
    { contrapose! ha,
      rw ha,
      simp only [le_refl, and_self, polynomial.eval_zero], },
    -- clear_except ha hr,
    have in_roots : root ∈ multiset.filter (λ (x : ℝ), a < x ∧ x < b) p.roots,
    {
      rw hr, simp,
    },
    -- clear hr,
    rw multiset.mem_filter at in_roots,
    rcases in_roots with ⟨in_roots, h_root_range⟩,
    rw polynomial.mem_roots p_nonzero at in_roots,
    -- Divide factor out the root to get a new polynomial to which to apply the inductive hypothesis
    rw <-polynomial.dvd_iff_is_root at in_roots,
    rcases in_roots with ⟨p', hpp'⟩,
    rw hpp' at *,
    have ha' : p'.eval a ≠ 0,
    {
      clear_except ha hpp',
      -- rw hpp' at ha,
      simp at ha,
      push_neg at ha,
      exact ha.right,
    },
    have hb' : p'.eval b ≠ 0,
    {
      clear_except hb hpp',
      -- rw hpp' at hb,
      simp at hb,
      push_neg at hb,
      exact hb.right,    },
    have hr' : multiset.filter (λ (x : ℝ), a < x ∧ x < b) p'.roots = root_set',
    {
      clear_except hr hpp' p_nonzero h_root_range,
      -- rw hpp' at hr,
      rw polynomial.roots_mul at hr,
      rw multiset.filter_add at hr,
      simp only [polynomial.roots_X_sub_C] at hr,
      rw multiset.filter_singleton at hr,
      rw if_pos h_root_range at hr,
      rw multiset.singleton_add at hr,
      simp at hr,
      exact hr,
      -- rw <-hpp',
      assumption,
    },

    replace hf := hf p' ha' hb' hr',
    simp only [multiset.card_cons],
    rw nat.even_succ,
    rw hf,
    clear_except h_root_range ha' hb',
    rcases h_root_range with ⟨hra, hrb⟩,
    have hra' : ¬ root < a, by linarith [hra],
    have hrb' : ¬ b < root, by linarith [hrb],
    simp_rw [ne_iff_lt_or_gt, polynomial.eval_mul] at *,
    simp_rw [polynomial.eval_sub, polynomial.eval_X, polynomial.eval_C] at *,
    unfold gt at *,
    simp_rw [mul_pos_iff, mul_neg_iff] at *,
    simp only [hra, hrb, hra', hrb', sub_pos, sub_neg] at *,
    clear hra hrb hra' hrb',
    simp only [false_and, true_and, false_or, or_false, lt_or_lt_iff_ne, ne.def, not_false_iff] at *,
    push_neg,
    replace ha' := lt_or_gt_of_ne ha',
    replace hb' := lt_or_gt_of_ne hb',
    tauto! {closer := tactic.linarith tt ff []},
  },
end

lemma pos_root_parity_of_leading_trailing_coeff (p : polynomial ℝ) (hp : p.to_finsupp 0 ≠ 0) :
  even ((p.roots.filter (λ x, (0 : ℝ) < x)).card + if p.leading_coeff > 0 then 1 else 0) :=
begin

end
