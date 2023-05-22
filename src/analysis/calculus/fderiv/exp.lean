/-
Copyright (c) 2023 Eric Wieser. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Eric Wieser, Anatole Dedecker
-/
import measure_theory.integral.fund_thm_calculus
import analysis.normed_space.exponential
import analysis.quaternion
import algebra.lie.of_associative
import analysis.special_functions.exponential
import analysis.calculus.fderiv_symmetric
import analysis.calculus.mean_value

/-! More lemmas aboutderiviatives of `exp`.

This follows https://physics.stackexchange.com/a/41671/185147. -/

variables {𝕂 𝔸 𝔹 : Type*}

open_locale topology
open asymptotics filter

section mem_ball
variables [nontrivially_normed_field 𝕂] [char_zero 𝕂]
variables [normed_comm_ring 𝔸] [normed_ring 𝔹]
variables [normed_algebra 𝕂 𝔸] [normed_algebra 𝕂 𝔹] [algebra 𝔸 𝔹] [has_continuous_smul 𝔸 𝔹]
variables [is_scalar_tower 𝕂 𝔸 𝔹]
variables [complete_space 𝔹]

lemma has_fderiv_at_exp_smul_const_of_mem_ball
  (x : 𝔹) (t : 𝔸) (htx : t • x ∈ emetric.ball (0 : 𝔹) (exp_series 𝕂 𝔹).radius) :
  has_fderiv_at (λ u : 𝔸, exp 𝕂 (u • x))
    (exp 𝕂 (t • x) • ((1 : 𝔸 →L[𝕂] 𝔸).smul_right x)) t :=
begin
  have hpos : 0 < (exp_series 𝕂 𝔹).radius := (zero_le _).trans_lt htx,
  rw has_fderiv_at_iff_is_o_nhds_zero,
  suffices :
    (λ h, exp 𝕂 (t • x) * (exp 𝕂 ((0 + h) • x) - exp 𝕂 ((0 : 𝔸) • x)
      - ((1 : 𝔸 →L[𝕂] 𝔸).smul_right x) h))
    =ᶠ[𝓝 0] (λ h, exp 𝕂 ((t + h) • x) - exp 𝕂 (t • x)
      - (exp 𝕂 (t • x) • ((1 : 𝔸 →L[𝕂] 𝔸).smul_right x)) h),
  { refine (is_o.const_mul_left _ _).congr' this (eventually_eq.refl _ _),
    rw ← @has_fderiv_at_iff_is_o_nhds_zero _ _ _ _ _ _ _ _
      (λ u, exp 𝕂 (u • x)) ((1 : 𝔸 →L[𝕂] 𝔸).smul_right x) 0,
    have : has_fderiv_at (exp 𝕂) (1 : 𝔹 →L[𝕂] 𝔹) (((1 : 𝔸 →L[𝕂] 𝔸).smul_right x) 0),
    { rw [continuous_linear_map.smul_right_apply, continuous_linear_map.one_apply, zero_smul],
      exact has_fderiv_at_exp_zero_of_radius_pos hpos },
    exact this.comp 0 ((1 : 𝔸 →L[𝕂] 𝔸).smul_right x).has_fderiv_at },
  have : tendsto (λ h : 𝔸, h • x) (𝓝 0) (𝓝 0),
  { rw ← zero_smul 𝔸 x,
    exact tendsto_id.smul_const x },
  have : ∀ᶠ h in 𝓝 (0 : 𝔸), h • x ∈ emetric.ball (0 : 𝔹) (exp_series 𝕂 𝔹).radius :=
    this.eventually (emetric.ball_mem_nhds _ hpos),
  filter_upwards [this],
  intros h hh,
  have : commute (t • x) (h • x) := ((commute.refl x).smul_left t).smul_right h,
  rw [add_smul t h, exp_add_of_commute_of_mem_ball this htx hh, zero_add, zero_smul, exp_zero,
      continuous_linear_map.smul_right_apply, continuous_linear_map.one_apply,
      continuous_linear_map.smul_apply, continuous_linear_map.smul_right_apply,
      continuous_linear_map.one_apply, smul_eq_mul, mul_sub_left_distrib, mul_sub_left_distrib,
      mul_one],
end

lemma has_fderiv_at_exp_smul_const_of_mem_ball'
  (x : 𝔹) (t : 𝔸) (htx : t • x ∈ emetric.ball (0 : 𝔹) (exp_series 𝕂 𝔹).radius) :
  has_fderiv_at (λ u : 𝔸, exp 𝕂 (u • x))
    (((1 : 𝔸 →L[𝕂] 𝔸).smul_right x).smul_right (exp 𝕂 (t • x))) t :=
begin
  convert has_fderiv_at_exp_smul_const_of_mem_ball _ _ htx using 1,
  ext t',
  show commute (t' • x) (exp 𝕂 (t • x)),
  exact (((commute.refl x).smul_left t').smul_right t).exp_right 𝕂,
end

lemma has_strict_fderiv_at_exp_smul_const_of_mem_ball (t : 𝔸) (x : 𝔹)
  (htx : t • x ∈ emetric.ball (0 : 𝔹) (exp_series 𝕂 𝔹).radius) :
  has_strict_fderiv_at (λ u : 𝔸, exp 𝕂 (u • x))
    (exp 𝕂 (t • x) • ((1 : 𝔸 →L[𝕂] 𝔸).smul_right x)) t :=
let ⟨p, hp⟩ := analytic_at_exp_of_mem_ball (t • x) htx in
have deriv₁ : has_strict_fderiv_at (λ u : 𝔸, exp 𝕂 (u • x)) _ t,
  from hp.has_strict_fderiv_at.comp t
    ((continuous_linear_map.id 𝕂 𝔸).smul_right x).has_strict_fderiv_at,
have deriv₂ : has_fderiv_at (λ u : 𝔸, exp 𝕂 (u • x)) _ t,
  from has_fderiv_at_exp_smul_const_of_mem_ball x t htx,
(deriv₁.has_fderiv_at.unique deriv₂) ▸ deriv₁

lemma has_strict_fderiv_at_exp_smul_const_of_mem_ball' (t : 𝔸) (x : 𝔹)
  (htx : t • x ∈ emetric.ball (0 : 𝔹) (exp_series 𝕂 𝔹).radius) :
  has_strict_fderiv_at (λ u : 𝔸, exp 𝕂 (u • x))
    (((1 : 𝔸 →L[𝕂] 𝔸).smul_right x).smul_right (exp 𝕂 (t • x))) t :=
let ⟨p, hp⟩ := analytic_at_exp_of_mem_ball (t • x) htx in
begin
  convert has_strict_fderiv_at_exp_smul_const_of_mem_ball _ _ htx using 1,
  ext t',
  show commute (t' • x) (exp 𝕂 (t • x)),
  exact (((commute.refl x).smul_left t').smul_right t).exp_right 𝕂,
end

lemma has_strict_deriv_at_exp_smul_const_of_mem_ball (t : 𝕂) (x : 𝔹)
  (htx : t • x ∈ emetric.ball (0 : 𝔹) (exp_series 𝕂 𝔹).radius) :
  has_strict_deriv_at (λ u : 𝕂, exp 𝕂 (u • x)) (exp 𝕂 (t • x) * x) t :=
by simpa using (has_strict_fderiv_at_exp_smul_const_of_mem_ball t x htx).has_strict_deriv_at


lemma has_strict_deriv_at_exp_smul_const_of_mem_ball' (t : 𝕂) (x : 𝔹)
  (htx : t • x ∈ emetric.ball (0 : 𝔹) (exp_series 𝕂 𝔹).radius) :
  has_strict_deriv_at (λ u : 𝕂, exp 𝕂 (u • x)) (x * exp 𝕂 (t • x)) t :=
by simpa using (has_strict_fderiv_at_exp_smul_const_of_mem_ball' t x htx).has_strict_deriv_at

lemma has_deriv_at_exp_smul_const_of_mem_ball (t : 𝕂) (x : 𝔹)
  (htx : t • x ∈ emetric.ball (0 : 𝔹) (exp_series 𝕂 𝔹).radius) :
  has_deriv_at (λ u : 𝕂, exp 𝕂 (u • x)) (exp 𝕂 (t • x) * x) t :=
(has_strict_deriv_at_exp_smul_const_of_mem_ball t x htx).has_deriv_at

lemma has_deriv_at_exp_smul_const_of_mem_ball' (t : 𝕂) (x : 𝔹)
  (htx : t • x ∈ emetric.ball (0 : 𝔹) (exp_series 𝕂 𝔹).radius) :
  has_deriv_at (λ u : 𝕂, exp 𝕂 (u • x)) (x * exp 𝕂 (t • x)) t :=
(has_strict_deriv_at_exp_smul_const_of_mem_ball' t x htx).has_deriv_at

end mem_ball

section is_R_or_C
variables [is_R_or_C 𝕂]
variables [normed_comm_ring 𝔸] [normed_ring 𝔹]
variables [normed_algebra 𝕂 𝔸] [normed_algebra 𝕂 𝔹] [algebra 𝔸 𝔹] [has_continuous_smul 𝔸 𝔹]
variables [is_scalar_tower 𝕂 𝔸 𝔹]
variables [complete_space 𝔹]

lemma has_fderiv_at_exp_smul_const (x : 𝔹) (t : 𝔸) :
  has_fderiv_at (λ u : 𝔸, exp 𝕂 (u • x))
    (exp 𝕂 (t • x) • ((1 : 𝔸 →L[𝕂] 𝔸).smul_right x)) t :=
has_fderiv_at_exp_smul_const_of_mem_ball _ _ $
  (exp_series_radius_eq_top 𝕂 𝔹).symm ▸ edist_lt_top _ _

lemma has_fderiv_at_exp_smul_const' (x : 𝔹) (t : 𝔸) :
  has_fderiv_at (λ u : 𝔸, exp 𝕂 (u • x))
    (((1 : 𝔸 →L[𝕂] 𝔸).smul_right x).smul_right (exp 𝕂 (t • x))) t :=
has_fderiv_at_exp_smul_const_of_mem_ball' _ _ $
  (exp_series_radius_eq_top 𝕂 𝔹).symm ▸ edist_lt_top _ _

lemma has_strict_fderiv_at_exp_smul_const (t : 𝔸) (x : 𝔹) :
  has_strict_fderiv_at (λ u : 𝔸, exp 𝕂 (u • x))
    (exp 𝕂 (t • x) • ((1 : 𝔸 →L[𝕂] 𝔸).smul_right x)) t :=
has_strict_fderiv_at_exp_smul_const_of_mem_ball _ _ $
  (exp_series_radius_eq_top 𝕂 𝔹).symm ▸ edist_lt_top _ _

lemma has_strict_fderiv_at_exp_smul_const' (t : 𝔸) (x : 𝔹) :
  has_strict_fderiv_at (λ u : 𝔸, exp 𝕂 (u • x))
    (((1 : 𝔸 →L[𝕂] 𝔸).smul_right x).smul_right (exp 𝕂 (t • x))) t :=
has_strict_fderiv_at_exp_smul_const_of_mem_ball' _ _ $
  (exp_series_radius_eq_top 𝕂 𝔹).symm ▸ edist_lt_top _ _

lemma has_strict_deriv_at_exp_smul_const (t : 𝕂) (x : 𝔹) :
  has_strict_deriv_at (λ u : 𝕂, exp 𝕂 (u • x)) (exp 𝕂 (t • x) * x) t :=
has_strict_deriv_at_exp_smul_const_of_mem_ball _ _ $
  (exp_series_radius_eq_top 𝕂 𝔹).symm ▸ edist_lt_top _ _

lemma has_strict_deriv_at_exp_smul_const' (t : 𝕂) (x : 𝔹) :
  has_strict_deriv_at (λ u : 𝕂, exp 𝕂 (u • x)) (x * exp 𝕂 (t • x)) t :=
has_strict_deriv_at_exp_smul_const_of_mem_ball' _ _ $
  (exp_series_radius_eq_top 𝕂 𝔹).symm ▸ edist_lt_top _ _

lemma has_deriv_at_exp_smul_const (t : 𝕂) (x : 𝔹) :
  has_deriv_at (λ u : 𝕂, exp 𝕂 (u • x)) (exp 𝕂 (t • x) * x) t :=
has_deriv_at_exp_smul_const_of_mem_ball _ _ $
  (exp_series_radius_eq_top 𝕂 𝔹).symm ▸ edist_lt_top _ _

lemma has_deriv_at_exp_smul_const' (t : 𝕂) (x : 𝔹) :
  has_deriv_at (λ u : 𝕂, exp 𝕂 (u • x)) (x * exp 𝕂 (t • x)) t :=
has_deriv_at_exp_smul_const_of_mem_ball' _ _ $
  (exp_series_radius_eq_top 𝕂 𝔹).symm ▸ edist_lt_top _ _

end is_R_or_C

variables [normed_ring 𝔸] [normed_algebra ℝ 𝔸] [complete_space 𝔸]

-- to make the goal view readable
notation (name := deriv) `∂` binders `, ` r:(scoped:67 f, deriv f) := r
local notation `e` := exp ℝ

lemma has_deriv_at_exp_smul_const2 (A : 𝔸) (t : ℝ) :
  has_deriv_at (λ t : ℝ, exp ℝ (t • A)) (A * exp ℝ (t • A)) t :=
has_deriv_at_exp_smul_const' _ _

lemma has_deriv_at_exp_smul_const2' (A : 𝔸) (t : ℝ) :
  has_deriv_at (λ t : ℝ, exp ℝ (t • A)) (exp ℝ (t • A) * A) t :=
begin
  convert has_deriv_at_exp_smul_const2 A t using 1,
  refine commute.exp_left _ _,
  refine (commute.refl _).smul_left _,
end

lemma deriv_exp_aux (A : ℝ → 𝔸) (r t : ℝ)
  (hA : differentiable_at ℝ A r) :
  exp ℝ (-t • A r) * deriv (λ x, exp ℝ (t • A x)) r =
    (∫ s : ℝ in 0..t, exp ℝ (-s • A r) * deriv A r * exp ℝ (s • A r)) :=
begin
  revert t,
  rw ←function.funext_iff,
  refine eq_of_fderiv_eq (_ : differentiable ℝ _) _ _ (0 : ℝ) _,
  { refine differentiable.mul _ _,
    sorry,
    sorry, },
  { sorry },
  swap,
  { simp },
  { intro t,
    ext1,
    rw [←deriv,←deriv],
    rw interval_integral.deriv_integral_right,
    { rw deriv_mul,
      have deriv_comm : deriv (λ (y : ℝ), deriv (λ (x : ℝ), exp ℝ (y • A x)) r) t =
        deriv (λ (x : ℝ), deriv (λ (y : ℝ), exp ℝ (y • A x)) t) r,
      { -- this one is probably really annoying
        have := @second_derivative_symmetric,
        sorry },
      { rw deriv_comm,
        simp_rw [(has_deriv_at_exp_smul_const' t (_ : 𝔸)).deriv],
        rw deriv_mul,
        simp_rw [mul_add, ←add_assoc, ←mul_assoc],
        rw [add_right_comm],
        convert zero_add _,
        rw [←add_mul],
        convert zero_mul _,
        rw [←(has_deriv_at_exp_smul_const _ (_ : 𝔸)).deriv, ←eq_neg_iff_add_eq_zero],
        change deriv ((λ t : ℝ, exp ℝ (t • A r)) ∘ has_neg.neg) t = _,
        rw [deriv.scomp t, deriv_neg, neg_one_smul],
        { exact (has_deriv_at_exp_smul_const _ _).differentiable_at },
        { exact differentiable_at_id.neg },
        { apply_instance },
        { exact hA },
        { change differentiable_at ℝ (exp ℝ ∘ _) _,
          refine differentiable_at.comp _ _ (hA.const_smul _),
          -- uh oh, this looks circular
          sorry }, },
      { exact has_deriv_at.differentiable_at
          ((has_deriv_at_exp_smul_const' (-t) (A r)).scomp _ (has_deriv_at_neg _)) },
      { sorry } },
    { sorry },
    { sorry },
    { have h : continuous_at (λ t : ℝ, exp ℝ (t • A r)) t,
      { sorry },
      have hn : continuous_at (λ t : ℝ, exp ℝ (-t • A r)) t,
      { sorry },
      refine (hn.mul continuous_at_const).mul h,}, },
end

/-- Non-commutative version of `deriv_exp`. -/
lemma deriv_exp' (A : ℝ → 𝔸) (r : ℝ) (h : differentiable_at ℝ A r) :
  deriv (λ x, exp ℝ (A x)) r = (∫ s : ℝ in 0..1, exp ℝ ((1 - s) • A r) * deriv A r * exp ℝ (s • A r)) :=
begin
  apply (is_unit_exp ℝ (-A r)).mul_left_cancel,
  have := deriv_exp_aux A r 1 h,
  simp_rw [neg_one_smul, one_smul] at this,
  -- have hA : ∀ r s : ℝ, commute (A r) (-s • A r) := λ r s, commute.refl,
  simp_rw [sub_eq_add_neg, add_smul, one_smul,
    @exp_add_of_commute ℝ _ _ _ _ _ _ _ ((commute.refl (A _)).smul_right _)],
  rw this,
  -- `integral_const_mul` is not general enough!
  sorry,
end

/-- Non-commutative version of `has_deriv_at_exp`. -/
lemma has_deriv_at_exp' (A : ℝ → 𝔸) (A' : 𝔸) (r : ℝ) (h : has_deriv_at A A' r) :
  has_deriv_at (λ x, exp ℝ (A x)) (∫ (s : ℝ) in 0..1, exp ℝ ((1 - s) • A r) * A' * exp ℝ (s • A r)) r :=
begin
  sorry,
end
