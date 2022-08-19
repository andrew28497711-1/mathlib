import measure_theory.integral.interval_integral
import measure_theory.measure.haar_lebesgue
import analysis.special_functions.exp
import analysis.transcendental.small_lemmas
import data.polynomial.derivative

noncomputable theory
open_locale big_operators
open_locale classical
open_locale polynomial

namespace e_transcendental_lemmas

/-Theorem
If forall $x\in(a,b), 0 \le f(x)\le c$ then
$$
\int_a^b f\le (b-a)c
$$
-/
theorem integral_le_max_times_length (f : ℝ -> ℝ) {h1 : measurable f} (a b : ℝ) (h : a ≤ b) (c : ℝ)
    (f_nonneg : ∀ x ∈ set.Icc a b, 0 ≤ f x) (c_max : ∀ x ∈ set.Icc a b, f x ≤ c) :
    (∫ x in a..b, f x) ≤ (b - a) * c :=
begin
    rw [mul_comm, ←abs_of_nonneg (sub_nonneg_of_le h)],
    have triv1 : (∫ x in a..b, f x) = ∥(∫ x in a..b, f x)∥,
    {
        rw real.norm_eq_abs,
        rw abs_of_nonneg,
        rw interval_integral.integral_of_le h,
        apply measure_theory.integral_nonneg_of_ae,
        apply (@measure_theory.ae_restrict_iff ℝ _ _ (set.Ioc a b) _ _).2,
        { apply measure_theory.ae_of_all,
          intros x hx,
          simp only [and_imp, set.mem_Ioc, pi.zero_apply, ge_iff_le, set.mem_Icc] at *,
          refine f_nonneg x hx.1.le hx.2 },
        { simp only [pi.zero_apply],
          refine measurable_set_le measurable_zero h1 },
    },
    rw triv1,
    apply interval_integral.norm_integral_le_of_norm_le_const _,
    rw set.interval_oc_of_le h,
    intros x hx,
    rw real.norm_eq_abs,
    rw abs_of_nonneg,
    { exact c_max _ (set.Ioc_subset_Icc_self hx) },
    refine f_nonneg x _,
    exact set.Ioc_subset_Icc_self hx,
end

/-Theorem
$$
\frac{\mathrm{d}-\exp(t-x)}{\mathrm{d}x}=\exp(t-x)
$$
-/
theorem deriv_exp_t_x' (t : ℝ) : (deriv (λ x, - (real.exp (t-x)))) = (λ x, real.exp (t-x)) :=
begin
    simp only [deriv_exp, differentiable_at_const, mul_one, zero_sub, deriv_sub, differentiable_at_id', deriv_id'', deriv.neg', deriv_const', mul_neg, differentiable_at.sub, neg_neg],
end

/--
# about I
-/

/-Definition
Suppose $f$ is an integer polynomial with degree $n$ and $t\ge0$ then define
    \[I(f,t):=\int_0^t \exp(t-x)f(z)\mathrm{d}x\]
We use integration by parts to prove
    \[I(f,t)=\exp(t)\left(\sum_{i=0}^n f^{(i)}(0)\right)-\sum_{i=0}^n f^{(i)}(t)\]

The two different ways of representing $I(f,t)$ we give us upper bound and lower bound when we are using this on transcendence of $e$.
-/
def I (f : ℤ[X]) (t : ℝ) : ℝ :=
    t.exp * (∑ i in finset.range f.nat_degree.succ, (polynomial.aeval (0 : ℝ) (polynomial.derivative^[i] f))) -
    (∑ i in finset.range f.nat_degree.succ, (polynomial.aeval t (polynomial.derivative^[i] f)))

/--
I equivalent definition
\[I(f,t):=\int_0^t \exp(t-x)f(z)\mathrm{d}x\]
-/
def II (f : ℤ[X]) (t : ℝ) : ℝ := ∫ x in 0..t, real.exp(t - x) * (polynomial.aeval x f)

/-Theorem
$I(0,t)$ is 0.
-/
theorem II_0 (t : ℝ) : II 0 t = 0 :=
begin
    -- We are integrating $\exp(t-x)\times 0$
    rw II,
    simp only [mul_zero, polynomial.aeval_zero, polynomial.map_zero,
        interval_integral.integral_const, smul_zero],
end

lemma differentiable_aeval (f : ℤ[X]) :
    differentiable ℝ (λ (x : ℝ), (polynomial.aeval x) (f)) :=
begin
      simp only [polynomial.aeval_def, polynomial.eval₂_eq_eval_map],
      apply polynomial.differentiable,

end


/-Theorem
By integration by part we have:
\[I(f, t) = e^tf(0)-f(t)+I(f',t)\]
-/
lemma II_integrate_by_part (f : ℤ[X]) (t : ℝ) :
    (II f t) = (real.exp t) * (polynomial.aeval (0 : ℝ) f) - (polynomial.aeval t f) + (II f.derivative t) :=
begin
  simp only [II],
  have hd := real.differentiable_exp.comp (differentiable_id'.const_sub t),
  convert @interval_integral.integral_mul_deriv_eq_deriv_mul
    0 t (λ x : ℝ, polynomial.aeval x f) (λ (x : ℝ), -(t - x).exp)
    (λ x : ℝ, polynomial.aeval x f.derivative) (λ (x : ℝ), (t - x).exp) _ _ _ _ using 1,
  { apply interval_integral.integral_congr,
    intros x hx,
    dsimp only, rw mul_comm },
  { simp only [sub_eq_add_neg],
    apply congr_arg2,
    { rw [add_neg_self, neg_zero, add_zero, real.exp_zero], ring },
    { simp_rw [←interval_integral.integral_neg, neg_mul_eq_neg_mul, neg_neg] } },
  { intros x hx,
    dsimp only,
    rw [←polynomial.aeval_deriv, has_deriv_at_deriv_iff],
    apply differentiable_aeval },
  { intros x hx,
    rw [←deriv_exp_t_x', has_deriv_at_deriv_iff],
    exact hd.neg.differentiable_at },
  { exact (differentiable_aeval f.derivative).continuous.continuous_on.interval_integrable },
  { exact hd.continuous.continuous_on.interval_integrable },
end

/-Theorem
Combine the theorem above with induction we get for all $m\in\mathbb N$
\[
I(f,t)=e^t\sum_{i=0}^m f^{(i)}(0)-\sum_{i=0}^m f^{(i)}(t)
\]
-/
lemma II_integrate_by_part_m (f : ℤ[X]) (t : ℝ) (m : ℕ) :
  II f t =
  t.exp * (∑ i in finset.range (m+1), (polynomial.aeval (0 : ℝ) (polynomial.derivative^[i] f))) -
  (∑ i in finset.range (m+1), polynomial.aeval t (polynomial.derivative^[i] f)) +
  (II (polynomial.derivative^[m + 1] f) t) :=
begin
    induction m with m ih,
    {   rw [II_integrate_by_part],
        simp only [function.iterate_one, finset.sum_singleton, finset.range_one,
            function.iterate_zero_apply] },

    rw [ih, II_integrate_by_part, finset.sum_range_succ _ (m + 1),
        finset.sum_range_succ _ (m + 1), ←function.iterate_succ_apply' polynomial.derivative],
    ring,
end

/-Theorem
So the using if $f$ has degree $n$, then $f^{(n+1)}$ is zero we have the two definition of $I(f,t)$ agrees.
-/
theorem II_eq_I (f : ℤ[X]) (t : ℝ) : II f t = I f t :=
begin
  have II_integrate_by_part_m := II_integrate_by_part_m f t f.nat_degree,
  rwa [polynomial.iterate_derivative_eq_zero (nat.lt_succ_self _), II_0, add_zero] at
    II_integrate_by_part_m,
end

/-- # $\bar{f}$
- Say $f(T)=a_0+a_1T+a_2T^2+\cdots+a_nT^n$. Then $\bar{f}=|a_0|+|a_1|T+|a_2|T^2+\cdots+|a_n|T^n$
- We proved some theorems about $\bar{f}$
-/

def f_bar (f : ℤ[X]) : ℤ[X] :=
⟨{ support := f.support,
  to_fun  := λ n, abs (f.coeff n),
  mem_support_to_fun := λ n, by rw [ne.def, abs_eq_zero, polynomial.mem_support_iff]}⟩

/-Theorem
By our construction the $n$-th coefficient of $\bar{f}$ is the absolute value of $n$-th coefficient of $f$
-/
theorem bar_coeff (f : ℤ[X]) (n : ℕ) : (f_bar f).coeff n = abs (f.coeff n) :=
begin
    -- true by definition
    dsimp [f_bar], refl,
end

/-Theorem
By our construction, $\bar{f}$ and $f$ has the same support
-/
theorem bar_supp (f : ℤ[X]) : (f_bar f).support = f.support :=
begin
    -- true by definition
    dsimp [f_bar], refl,
end

/-Theorem
Since $\bar{f}$ and $f$ has the same support, they have the same degree.
-/
theorem bar_same_deg (f : ℤ[X]) : (f_bar f).nat_degree = f.nat_degree :=
begin
    apply polynomial.nat_degree_eq_of_degree_eq,
    -- degree is defined to be $\sup$ of support. Since support of $\bar{f}$ and $f$ are the same, their degree is the same.
    rw polynomial.degree, rw polynomial.degree, rw bar_supp,
end

/-Theorem
$\bar{0}=0$
-/
theorem f_bar_0 : f_bar 0 = 0 :=
begin
    ext, rw bar_coeff, simp only [abs_zero, polynomial.coeff_zero],
end

/-Theorem
for any $f\in\mathbb Z$, if $\bar{f}=0$ then $f=0$
-/
theorem f_bar_eq_0 (f : ℤ[X]) : f_bar f = 0 -> f = 0 :=
begin
    intro h, rw polynomial.ext_iff at h, ext,
    have hn := h n, simp only [polynomial.coeff_zero] at hn, rw bar_coeff at hn, simp only [abs_eq_zero, polynomial.coeff_zero] at hn ⊢, assumption,
end

theorem coeff_f_bar_mul (f g : ℤ[X]) (n : ℕ) : (f_bar (f*g)).coeff n = abs(∑ p in finset.nat.antidiagonal n, (f.coeff p.1)*(g.coeff p.2)) :=
begin
    rw bar_coeff (f*g) n, rw polynomial.coeff_mul,
end

theorem f_bar_eq (f : ℤ[X]) : f_bar f = ∑ i in finset.range f.nat_degree.succ, polynomial.C (abs (f.coeff i)) * polynomial.X^i :=
begin
    ext, rw bar_coeff, rw polynomial.finset_sum_coeff, simp_rw [polynomial.coeff_C_mul_X_pow],
    simp only [finset.mem_range, finset.sum_ite_eq], split_ifs, refl, simp only [not_lt] at h,
    rw polynomial.coeff_eq_zero_of_nat_degree_lt h, exact rfl,
end

lemma polynomial.aeval_eq_sum_support {R A : Type*} [comm_semiring R] [comm_semiring A] [algebra R A]
    (x : A) (f : R[X]) :
    polynomial.aeval x f = ∑ i in f.support, (f.coeff i) • x ^ i:=
begin
  simp_rw [polynomial.aeval_def, polynomial.eval₂_eq_sum, polynomial.sum, algebra.smul_def],
end

/-Theorem
For any $x\in(0,t)$
$|f(x)|\le \bar{f}(t)$
-/
lemma f_bar_ineq (f : ℤ[X]) (t : ℝ) (x) (hx : x ∈ set.Icc 0 t) :
  abs (polynomial.aeval x f) ≤ polynomial.aeval t (f_bar f) :=
begin
  rw set.mem_Icc at hx,
  calc |polynomial.aeval x f| = |∑ i in f.support, (f.coeff i : ℝ) * x ^ i| : _
  ... ≤ ∑ i in f.support, |(f.coeff i : ℝ) * x ^ i| : finset.abs_sum_le_sum_abs _ _
  ... = ∑ i in f.support, |(f.coeff i : ℝ)| * x ^ i : finset.sum_congr rfl (λ i hi, _)
  ... ≤ ∑ i in (f_bar f).support, abs (f.coeff i : ℝ) * t ^ i : _
  ... = _ : _,
  { rw [polynomial.aeval_eq_sum_support x f], simp only [zsmul_eq_mul] },
  { have := pow_nonneg hx.1 i,
    rw [abs_mul, abs_of_nonneg this], },
  { rw bar_supp,
    refine finset.sum_le_sum (λ n hn, mul_le_mul_of_nonneg_left _ (abs_nonneg _)),
    exact pow_le_pow_of_le_left hx.1 hx.2 _ },
  { rw [polynomial.aeval_eq_sum_support],
    simp only [e_transcendental_lemmas.bar_coeff, finset.sum_congr, zsmul_eq_mul, int.cast_abs] }
end

theorem eval_f_bar_mul (f g : ℤ[X]) (k : ℕ) : polynomial.eval (k:ℤ) (f_bar (f * g)) ≤ (polynomial.eval (k:ℤ) (f_bar f)) * (polynomial.eval (k:ℤ) (f_bar g)) :=
begin
  by_cases (f=0 ∨ g=0),
  { cases h, rw h, simp only [f_bar_0, zero_mul, polynomial.eval_zero], rw h, simp only [f_bar_0, mul_zero, polynomial.eval_zero] },
  replace h := not_or_distrib.1 h,
  rw [polynomial.as_sum_range (f_bar (f*g)), polynomial.eval_finset_sum, bar_same_deg,
    ←polynomial.eval_mul, polynomial.as_sum_range ((f_bar f)*(f_bar g))],
  have deg_eq : (f_bar f * f_bar g).nat_degree = f.nat_degree + g.nat_degree,
  { rw polynomial.nat_degree_mul, rw bar_same_deg, rw bar_same_deg, intro rid, exact h.1 (f_bar_eq_0 f rid), intro rid, exact h.2 (f_bar_eq_0 g rid) },
  rw deg_eq,
  replace deg_eq : (f * g).nat_degree = f.nat_degree + g.nat_degree,
  { rw polynomial.nat_degree_mul h.1 h.2 },
  rw [deg_eq, polynomial.eval_finset_sum], apply finset.sum_le_sum,
  intros x hx, simp only [polynomial.eval_X, polynomial.eval_C, polynomial.eval_pow, polynomial.eval_mul], rw coeff_f_bar_mul, rw polynomial.coeff_mul,
  cases k,
  { cases x,
    { simp only [mul_one, finset.nat.antidiagonal_zero, finset.sum_singleton, pow_zero],
      rw bar_coeff, rw bar_coeff, rw abs_mul },
    { simp only [int.coe_nat_zero, polynomial.eval_monomial, linear_map.map_sum, mul_zero,
        zero_pow (nat.succ_pos x), polynomial.eval_finset_sum],
      exact finset.sum_nonneg (λ i hi, le_rfl), } },

  { simp only [polynomial.eval_monomial, bar_coeff, ←abs_mul],
    refine mul_le_mul_of_nonneg_right (finset.abs_sum_le_sum_abs _ _) _,
    { apply pow_nonneg, norm_cast, exact bot_le } }
end

lemma f_bar_1 : f_bar 1 = 1 :=
begin
  ext, simp only [bar_coeff, polynomial.coeff_one, apply_ite abs, abs_zero, abs_one],
end


lemma eval_f_bar_nonneg (f : ℤ[X]) (i:ℕ) : 0 ≤ polynomial.eval (i:ℤ) (f_bar f) :=
begin
  rw [f_bar_eq, polynomial.eval_finset_sum],
  apply finset.sum_nonneg,
  intros x hx,
  simp only [polynomial.eval_X, polynomial.eval_C, polynomial.eval_pow, polynomial.eval_mul],
  exact mul_nonneg (abs_nonneg (polynomial.coeff f x)) (pow_nonneg (int.coe_nat_nonneg _) _),
end

theorem eval_f_bar_pow (f : ℤ[X]) (k n : ℕ) : polynomial.eval (k:ℤ) (f_bar (f^n)) ≤ (polynomial.eval (k:ℤ) (f_bar f))^n :=
begin
  induction n with n H,
  {simp only [f_bar_1, polynomial.eval_one, pow_zero]},
  rw pow_succ, have ineq := eval_f_bar_mul f (f^n) k,
  have ineq2 : polynomial.eval ↑k (f_bar f) * polynomial.eval ↑k (f_bar (f ^ n)) ≤  polynomial.eval ↑k (f_bar f) * polynomial.eval ↑k (f_bar f) ^ n,
  {apply mul_le_mul, exact le_refl (polynomial.eval ↑k (f_bar f)), exact H, exact eval_f_bar_nonneg (f ^ n) k, exact eval_f_bar_nonneg f k},
  exact le_trans ineq ineq2,
end

theorem eval_f_bar_prod (f : ℕ -> (ℤ[X])) (k : ℕ) (s:finset ℕ): polynomial.eval (k:ℤ) (f_bar (∏ i in s, (f i))) ≤ (∏ i in s, polynomial.eval (k:ℤ) (f_bar (f i))) :=
begin
  apply finset.induction_on s,
  {simp only [f_bar_1, polynomial.eval_one, finset.prod_empty]},
  intros a s ha H, rw finset.prod_insert, rw finset.prod_insert,
  have ineq := eval_f_bar_mul (f a) (∏ (x : ℕ) in s, f x) k,
  have ineq2 : polynomial.eval ↑k (f_bar (f a)) * polynomial.eval ↑k (f_bar (∏ (x : ℕ) in s, f x)) ≤
    polynomial.eval ↑k (f_bar (f a)) * ∏ (i : ℕ) in s, polynomial.eval ↑k (f_bar (f i)),
  { apply mul_le_mul, exact le_refl _, exact H, exact eval_f_bar_nonneg (∏ (x : ℕ) in s, f x) k, exact eval_f_bar_nonneg (f a) k },
  exact le_trans ineq ineq2, exact ha, exact ha,
end


/-Theorem
$$|I(f,t)|\le te^t\bar{f}(t)$$
-/
theorem abs_II_le2 (f : ℤ[X]) (t : ℝ) (ht : 0 ≤ t) :
  abs (II f t) ≤ t * t.exp * (polynomial.aeval t (f_bar f)) :=
begin
  refine (interval_integral.abs_integral_le_integral_abs ht).trans _,
  convert integral_le_max_times_length ((λ x, abs ((t - x).exp * polynomial.aeval x f))) 0 t ht
    (t.exp * polynomial.aeval t (f_bar f)) (λ x _, abs_nonneg _) _ using 1,
  { rw [sub_zero, mul_assoc], },
  { refine continuous.measurable _,
    refine continuous_abs.comp _,
    exact continuous.mul (real.continuous_exp.comp (continuous_sub_left _))
      (differentiable_aeval _).continuous},
  { intros x hx,
    rw [abs_mul, real.abs_exp],
    refine mul_le_mul _ (f_bar_ineq f t x hx) (abs_nonneg _) (real.exp_pos t).le,
    rw set.mem_Icc at hx,
    rw [real.exp_le_exp, sub_le, sub_self], exact hx.1 },
end

end e_transcendental_lemmas
