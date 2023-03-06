import order.partition.finpartition
import topology.instances.complex
import combinatorics.additive.salem_spencer
import data.real.pi.bounds
import data.nat.dist
import analysis.special_functions.log.base
import group_theory.finite_abelian
import data.zmod.quotient
import analysis.inner_product_space.pi_L2
import combinatorics.pigeonhole
import order.partition.finpartition

noncomputable theory

open_locale complex_conjugate big_operators real

open finset
open fintype (card)

section general_fourier

variables {α β G 𝕜 : Type*}  [comm_group G]

@[derive [comm_group, inhabited]]
def character (G : Type*) [comm_group G] := G →* circle

instance : monoid_hom_class (character G) G circle := monoid_hom.monoid_hom_class

instance : has_coe (α → circle) (α → ℂ) := ⟨λ χ i, (χ i : ℂ)⟩ -- should be a local instance

lemma conj_eq_inv (χ : character G) {x : G} : (χ⁻¹ x : ℂ) = conj (χ x : ℂ) :=
by { rw ←coe_inv_circle_eq_conj, simp }

@[simp] lemma coe_coe_eq {χ : character G} {x : G} : (χ : G → ℂ) x = χ x := rfl

def finset.expect {α 𝕜 : Type*} [field 𝕜] (s : finset α) (f : α → 𝕜) : 𝕜 :=
s.sum f / s.card

open finset

lemma sum_mul_sq_le_sq_mul_sq {α 𝕜 : Type*} [linear_ordered_comm_ring 𝕜] (s : finset α) (f g : α → 𝕜) :
  (∑ i in s, f i * g i)^2 ≤ (∑ i in s, (f i)^2) * ∑ i in s, (g i)^2 :=
begin
  have h : 0 ≤ ∑ i in s, (f i * ∑ j in s, (g j)^2 - g i * ∑ j in s, f j * g j)^2 :=
    sum_nonneg (λ i hi, sq_nonneg _),
  simp_rw [sub_sq, sum_add_distrib, finset.sum_sub_distrib, mul_pow, mul_assoc, ←mul_sum, ←sum_mul,
    mul_left_comm, ←mul_assoc, ←sum_mul, mul_right_comm, ←sq, mul_comm, sub_add, two_mul,
    add_sub_cancel, mul_comm (∑ j in s, (g j)^2), sq (∑ j in s, (g j)^2),
    ←mul_assoc, ←mul_sub_right_distrib] at h,
  obtain h' | h' := (sum_nonneg (λ i (hi : i ∈ s), sq_nonneg (g i))).eq_or_lt,
  { have h'' : ∀ i ∈ s, g i = 0 :=
      λ i hi, by simpa using (sum_eq_zero_iff_of_nonneg (λ i _, sq_nonneg (g i))).1 h'.symm i hi,
    rw [←h', sum_congr rfl (show ∀ i ∈ s, f i * g i = 0, from λ i hi, by simp [h'' i hi])],
    simp },
  rw ←sub_nonneg,
  exact nonneg_of_mul_nonneg_left h h',
end

lemma cauchy_schwarz_sqrt {α : Type*} (s : finset α) (f g : α → ℝ) :
  ∑ i in s, f i * g i ≤ (∑ i in s, f i ^ 2).sqrt * (∑ i in s, g i ^ 2).sqrt :=
(real.le_sqrt_of_sq_le (sum_mul_sq_le_sq_mul_sq _ _ _)).trans_eq
  (real.sqrt_mul (sum_nonneg (λ _ _, sq_nonneg _)) _)

localized "notation `𝔼` binders ` in ` s ` with ` p:(scoped:49 p, p) `, ` r:(scoped:67 f, finset.expect (s.filter p) f) := r" in expectations
localized "notation `𝔼` binders ` in ` s `, ` r:(scoped:67 f, finset.expect s f) := r" in expectations
localized "notation `𝔼` binders ` with ` p:(scoped:49 p, p) `, ` r:(scoped:67 f, finset.expect (finset.univ.filter p) f) := r" in expectations
localized "notation `𝔼` binders `, ` r:(scoped:67 f, finset.expect finset.univ f) := r" in expectations

lemma expect_sum [field 𝕜] {s : finset α} {t : finset β} (f : α → β → 𝕜) :
  𝔼 x in s, ∑ y in t, f x y = ∑ y in t, 𝔼 x in s, f x y :=
begin
  rw [expect, sum_comm, sum_div],
  refl
end

lemma expect_comm [field 𝕜] {s : finset α} {t : finset β} (f : α → β → 𝕜) :
  𝔼 x in s, 𝔼 y in t, f x y = 𝔼 y in t, 𝔼 x in s, f x y :=
by rw [expect, expect, ←expect_sum, ←expect_sum, expect, expect,
  div_div, mul_comm, div_div, sum_comm]

lemma expect_mul [field 𝕜] {s : finset α} (f : α → 𝕜) (x : 𝕜) :
  (𝔼 i in s, f i) * x = 𝔼 i in s, f i * x :=
by { rw [expect, div_mul_eq_mul_div, sum_mul], refl }

lemma mul_expect [field 𝕜] {s : finset α} (f : α → 𝕜) (x : 𝕜) :
  x * (𝔼 i in s, f i) = 𝔼 i in s, x * f i :=
by simp_rw [mul_comm x, expect_mul]

lemma expect_true_univ [field 𝕜] [fintype α] {f : α → 𝕜} : 𝔼 x, f x = (∑ x, f x) / card α :=
by rw [expect, card_univ]

lemma expect_indicate_eq [field 𝕜] [char_zero 𝕜] [fintype α] [nonempty α] [decidable_eq α]
  (f : α → 𝕜) (x : α) : 𝔼 i, ite (x = i) (card α : 𝕜) 0 * f i = f x :=
begin
  simp_rw [expect_true_univ, ite_mul, zero_mul, sum_ite_eq, if_pos (mem_univ _)],
  rw mul_div_cancel_left,
  simp [fintype.card_ne_zero]
end

lemma expect_indicate_eq' [field 𝕜] [char_zero 𝕜] [fintype α] [nonempty α] [decidable_eq α]
  (f : α → 𝕜) (x : α) : 𝔼 i, ite (i = x) (card α : 𝕜) 0 * f i = f x :=
by simp_rw [@eq_comm _ _ x, expect_indicate_eq]

lemma expect_congr [field 𝕜] {s : finset α} (f g : α → 𝕜) (p : α → Prop) [decidable_pred p]
  (h : ∀ x ∈ s, p x → f x = g x) :
  𝔼 i in s with p i, f i = 𝔼 i in s with p i, g i :=
begin
  rw [expect, sum_congr rfl],
  { refl },
  simpa using h
end

lemma expect_congr' [field 𝕜] {s : finset α} (f g : α → 𝕜) (p : α → Prop) [decidable_pred p]
  (h : ∀ x, p x → f x = g x) :
  𝔼 i in s with p i, f i = 𝔼 i in s with p i, g i :=
expect_congr _ _ _ (λ x _, h x)

-- a nondependent version of sum_bij
lemma sum_nbij {γ : Type*} [add_comm_monoid β] {s : finset α} {t : finset γ} {f : α → β} {g : γ → β}
  (i : α → γ) (hi : ∀ a ∈ s, i a ∈ t) (h : ∀ a ∈ s, f a = g (i a))
  (i_inj : ∀ a₁ a₂, a₁ ∈ s → a₂ ∈ s → i a₁ = i a₂ → a₁ = a₂) (i_surj : ∀ b ∈ t, ∃ a ∈ s, b = i a) :
  (∑ x in s, f x) = (∑ x in t, g x) :=
sum_bij (λ a _, i a) hi h i_inj i_surj

lemma expect_bij {γ : Type*} [field 𝕜] {s : finset α} {t : finset γ} {f : α → 𝕜} {g : γ → 𝕜}
  (i : Π a ∈ s, γ) (hi : ∀ a ha, i a ha ∈ t) (h : ∀ a ha, f a = g (i a ha))
  (i_inj : ∀ a₁ a₂ ha₁ ha₂, i a₁ ha₁ = i a₂ ha₂ → a₁ = a₂) (i_surj : ∀ b ∈ t, ∃ a ha, b = i a ha) :
  (𝔼 x in s, f x) = (𝔼 x in t, g x) :=
begin
  rw [expect, expect, card_congr i hi i_inj, sum_bij i hi h i_inj i_surj],
  simpa [eq_comm] using i_surj,
end

lemma expect_nbij {γ : Type*} [field 𝕜] {s : finset α} {t : finset γ} {f : α → 𝕜} {g : γ → 𝕜}
  (i : α → γ) (hi : ∀ a ∈ s, i a ∈ t) (h : ∀ a ∈ s, f a = g (i a))
  (i_inj : ∀ a₁ a₂, a₁ ∈ s → a₂ ∈ s → i a₁ = i a₂ → a₁ = a₂) (i_surj : ∀ b ∈ t, ∃ a ∈ s, b = i a) :
  (𝔼 x in s, f x) = (𝔼 x in t, g x) :=
expect_bij (λ a _, i a) hi h i_inj i_surj

lemma expect_bij' {γ : Type*} [field 𝕜] {s : finset α} {t : finset γ} {f : α → 𝕜} {g : γ → 𝕜}
  (i : Π a ∈ s, γ) (hi : ∀ a ha, i a ha ∈ t) (h : ∀ a ha, f a = g (i a ha))
  (j : Π a ∈ t, α) (hj : ∀ a ha, j a ha ∈ s) (left_inv : ∀ a ha, j (i a ha) (hi a ha) = a)
  (right_inv : ∀ a ha, i (j a ha) (hj a ha) = a) :
  (𝔼 x in s, f x) = (𝔼 x in t, g x) :=
begin
  rw [expect, expect, sum_bij' i hi h j hj left_inv right_inv, card_congr i hi],
  { intros a b ha hb z,
    rw [←left_inv a ha, ←left_inv b hb],
    congr' 1 },
  intros b hb,
  exact ⟨j b hb, hj _ _, right_inv _ _⟩,
end

lemma expect_nbij' {γ : Type*} [field 𝕜] {s : finset α} {t : finset γ} {f : α → 𝕜} {g : γ → 𝕜}
  (i : α → γ) (hi : ∀ a ∈ s, i a ∈ t) (h : ∀ a ∈ s, f a = g (i a))
  (j : γ → α) (hj : ∀ a ∈ t, j a ∈ s) (left_inv : ∀ a ∈ s, j (i a) = a)
  (right_inv : ∀ a ∈ t, i (j a) = a) :
  (𝔼 x in s, f x) = (𝔼 x in t, g x) :=
expect_bij' (λ a _, i a) hi h (λ b _, j b) hj left_inv right_inv

lemma expect_product' {γ : Type*} [field 𝕜] {s : finset γ} {t : finset α} {f : γ → α → 𝕜} :
  (𝔼 x in s ×ˢ t, f x.1 x.2) = 𝔼 x in s, 𝔼 y in t, f x y :=
by simp only [expect, expect, card_product, sum_product', ←sum_div, div_div, mul_comm s.card,
    nat.cast_mul]

lemma expect_multiplicative {G : Type*} [fintype G] {f : multiplicative G → ℂ} :
  𝔼 (x : multiplicative G), f x = 𝔼 x : G, f (multiplicative.of_add x) :=
rfl

-- there are versions of this in mathlib, like exp_map_circle and exp_map_circle_hom
-- but fuck you let me be me
def e (r : ℝ) : ℂ := complex.exp (r * (2 * π * complex.I))

-- sometimes useful to write as real * I rather than real * 2πi
lemma e_eq (r : ℝ) : e r = complex.exp ((2 * π * r : ℝ) * complex.I) :=
begin
  rw [e],
  simp only [complex.of_real_mul, complex.of_real_bit0, complex.of_real_one],
  ring_nf,
end

lemma abs_e {r : ℝ} : (e r).abs = 1 := by rw [e_eq, complex.abs_exp_of_real_mul_I _]

lemma e_ne_zero {r : ℝ} : e r ≠ 0 :=
begin
  intro h,
  simpa [h] using @abs_e r,
end

lemma e_mem_circle {r : ℝ} : e r ∈ circle := by rw [mem_circle_iff_abs, abs_e]

lemma e_add {r s : ℝ} : e (r + s) = e r * e s :=
by rw [e, complex.of_real_add, add_mul, complex.exp_add, e, e]

lemma e_sub {r s : ℝ} : e (r - s) = e r / e s :=
by rw [e, complex.of_real_sub, sub_mul, complex.exp_sub, e, e]

lemma e_neg {s : ℝ} : e (- s) = (e s)⁻¹ :=
by rw [e, complex.of_real_neg, neg_mul, complex.exp_neg, e]

lemma e_int (z : ℤ) : e z = 1 :=
by rw [e, complex.of_real_int_cast, complex.exp_int_mul_two_pi_mul_I]

lemma e_zero : e 0 = 1 := by simpa using e_int 0
lemma e_one : e 1 = 1 := by simpa using e_int 1

lemma e_add_int {r : ℝ} {z : ℤ} : e (r + z) = e r :=
by rw [e_add, e_int, mul_one]

lemma e_sub_int {r : ℝ} {z : ℤ} : e (r - z) = e r :=
by rw [e_sub, e_int, div_one]

lemma e_fract (r : ℝ) : e (int.fract r) = e r :=
by rw [int.fract, e_sub_int]

lemma e_mod_div {m : ℤ} {n : ℕ} : e ((m % n : ℤ) / n) = e (m / n) :=
begin
  rcases eq_or_ne (n : ℝ) 0 with hn | hn,
  { rw [hn, div_zero, div_zero] },
  { rw [int.mod_def, int.cast_sub, sub_div, int.cast_mul, int.cast_coe_nat,
      mul_div_cancel_left _ hn, e_sub_int] },
end

lemma e_eq_one_iff {r : ℝ} : e r = 1 ↔ ∃ (z : ℤ), r = z :=
begin
  rw [e, complex.exp_eq_one_iff],
  simp only [mul_eq_mul_right_iff, complex.two_pi_I_ne_zero, or_false],
  split;
  { rintro ⟨n, h⟩,
    refine ⟨n, _⟩,
    exact_mod_cast h },
end

lemma conj_e {r : ℝ} : conj (e r) = e (-r) := by { rw [e, e, ←complex.exp_conj], simp }

lemma conj_expect [fintype α] {f : α → ℂ} : conj (𝔼 i, f i) = 𝔼 i, conj (f i) :=
by simp only [expect_true_univ, map_div₀, map_nat_cast, map_sum]

def inner_prod_expect (α : Type*) [fintype α] (f g : α → ℂ) : ℂ := 𝔼 x, conj (f x) * g x
def inner_prod_sum (α : Type*) [fintype α] (f g : α → ℂ) : ℂ := ∑ x, conj (f x) * g x

lemma inner_prod_expect_eq_inner_sum {α : Type*} [fintype α] (f g : α → ℂ) :
  inner_prod_expect α f g = inner_prod_sum α f g / card α := rfl

lemma character_trivial_iff {χ : character G} : χ = 1 ↔ ∀ u : G, χ u = 1 :=
by { rw fun_like.ext_iff, simp }

lemma character_nontrivial_iff {χ : character G} : χ ≠ 1 ↔ ∃ u : G, χ u ≠ 1 :=
by rw [ne.def, character_trivial_iff, not_forall]

lemma inner_sum_self [fintype α] {f : α → ℂ} (hf : ∀ x, (f x).abs = 1) :
  inner_prod_sum _ f f = card α :=
begin
  rw [inner_prod_sum],
  simp_rw [mul_comm, complex.mul_conj, complex.norm_sq_eq_abs, hf],
  simp [card_univ],
end

lemma inner_prod_expect_self [fintype G] {f : G → ℂ} (hf : ∀ x, (f x).abs = 1) :
  inner_prod_expect _ f f = 1 :=
begin
  rw [inner_prod_expect_eq_inner_sum, inner_sum_self hf, div_self],
  rw nat.cast_ne_zero,
  exact fintype.card_ne_zero,
end

lemma sum_eq_zero_of_nontrivial [fintype G] {χ : character G} {u : G} (hχ : χ u ≠ 1) :
  (∑ x, χ x : ℂ) = 0 :=
begin
  have : (∑ x, χ x : ℂ) = χ u * ∑ x, χ x,
  { rw [finset.mul_sum, ←equiv.sum_comp (equiv.mul_left u)],
    simp_rw [equiv.coe_mul_left, map_mul, coe_mul_unit_sphere] },
  have hχ' : (χ u : ℂ) ≠ 1, { simpa using hχ },
  exact eq_zero_of_mul_eq_self_left hχ' this.symm,
end.

lemma expect_eq_zero_of_nontrivial [fintype G] {χ : character G} {u : G} (hχ : χ u ≠ 1) :
  (𝔼 x, χ x : ℂ) = 0 :=
by rw [expect, sum_eq_zero_of_nontrivial hχ, zero_div]

lemma inner_sum_eq_zero_of_ne [fintype G] {χ₁ χ₂ : character G} (h : χ₁ ≠ χ₂) :
  inner_prod_sum G χ₁ χ₂ = 0 :=
begin
  have : χ₁⁻¹ * χ₂ ≠ 1, { rwa [ne.def, inv_mul_eq_one] },
  rw character_nontrivial_iff at this,
  obtain ⟨u, hu⟩ := this,
  simp_rw [inner_prod_sum, coe_coe_eq, ←conj_eq_inv],
  simpa using sum_eq_zero_of_nontrivial hu,
end

lemma inner_prod_expect_eq_zero_of_ne [fintype G] {χ₁ χ₂ : character G} (h : χ₁ ≠ χ₂) :
  inner_prod_expect G χ₁ χ₂ = 0 :=
by rw [inner_prod_expect_eq_inner_sum, inner_sum_eq_zero_of_ne h, zero_div]

lemma inner_sum_orthogonal [fintype G] {χ₁ χ₂ : character G} :
  inner_prod_sum G χ₁ χ₂ = if χ₁ = χ₂ then card G else 0 :=
begin
  split_ifs,
  { rw [h, inner_sum_self], simp },
  { rw [inner_sum_eq_zero_of_ne h] }
end

lemma inner_prod_expect_orthogonal [fintype G] {χ₁ χ₂ : character G} :
  inner_prod_expect G χ₁ χ₂ = if χ₁ = χ₂ then 1 else 0 :=
begin
  split_ifs,
  { rw [h, inner_prod_expect_self],
    simp only [coe_coe_eq, abs_coe_circle, forall_const] },
  { rw inner_prod_expect_eq_zero_of_ne h },
end

def transform [fintype G] (f : G → ℂ) (χ : character G) : ℂ := inner_prod_expect G χ f

lemma lin_indep_char [finite G] : linear_independent ℂ (λ (i : character G), (i : G → ℂ)) :=
begin
  haveI : fintype G := fintype.of_finite G,
  suffices : linear_independent ℂ (λ (i : character G), ((i : G → ℂ) : euclidean_space ℂ G)),
  { exact this },
  refine @linear_independent_of_ne_zero_of_inner_eq_zero _ (euclidean_space ℂ G) _ _ _ _ _ _,
  { intros χ,
    rw [ne.def, function.funext_iff],
    intro h,
    simpa using h 1 },
  intros χ₁ χ₂,
  simp only [pi_Lp.inner_apply, coe_coe_eq, is_R_or_C.inner_apply],
  intro h,
  exact inner_sum_eq_zero_of_ne h,
end

section

open_locale direct_sum

def my_thing_forward {ι : Type} [decidable_eq ι] (p : ι → ℕ) (n : ι → ℕ) :
  (⨁ (i : {i // n i ≠ 0}), zmod (p i ^ n i)) →+ ⨁ i, zmod (p i ^ n i) :=
direct_sum.to_add_monoid $ λ i, direct_sum.of (λ i, zmod (p i ^ n i)) i

def my_thing_backward {ι : Type} [decidable_eq ι] (p : ι → ℕ) (n : ι → ℕ) :
  (⨁ i, zmod (p i ^ n i)) →+ ⨁ (i : {i // n i ≠ 0}), zmod (p i ^ n i) :=
direct_sum.to_add_monoid $ λ i,
  if h : n i = 0 then 0 else direct_sum.of (λ (j : {i // n i ≠ 0}), zmod (p j ^ n j)) ⟨i, h⟩

lemma subsingleton_zmod_one : ∀ {n : ℕ} (x y : zmod n), n = 1 → x = y
| _ _ _ rfl := subsingleton.elim _ _

def my_thing (ι : Type) [decidable_eq ι] (p : ι → ℕ) (n : ι → ℕ) :
  (⨁ (i : {i // n i ≠ 0}), zmod (p i ^ n i)) ≃+ ⨁ i, zmod (p i ^ n i) :=
{ to_fun := my_thing_forward p n,
  inv_fun := my_thing_backward p n,
  left_inv :=
  begin
    intro x,
    induction x using direct_sum.induction_on with i x x y hx hy,
    { simp
    },
    { rw [my_thing_forward, direct_sum.to_add_monoid_of, my_thing_backward,
        direct_sum.to_add_monoid_of, dif_neg i.prop],
      cases i,
      refl },
    { rw [map_add, map_add, hx, hy] },
  end,
  right_inv :=
  begin
    intro x,
    induction x using direct_sum.induction_on with i x x y hx hy,
    { simp },
    { rw [my_thing_backward, direct_sum.to_add_monoid_of],
      split_ifs,
      { have : x = 0,
        { refine subsingleton_zmod_one _ _ _,
          rw [h, pow_zero] },
        rw [add_monoid_hom.zero_apply, map_zero, this, map_zero] },
      rw [my_thing_forward, direct_sum.to_add_monoid_of],
      refl },
    { rw [map_add, map_add, hx, hy] },
  end,
  map_add' :=
  begin
    intros x y,
    rw [map_add],
  end }

theorem my_classification (G : Type*) [add_comm_group G] [finite G] :
  ∃ (ι : Type) [fintype ι] (n : ι → ℕ) (hn : ∀ i, 1 < n i),
  nonempty $ G ≃+ direct_sum ι (λ (i : ι), zmod (n i)) :=
begin
  classical,
  obtain ⟨ι, hι, p, hp, n, ⟨e⟩⟩ := add_comm_group.equiv_direct_sum_zmod_of_fintype G,
  resetI,
  refine ⟨{i : ι // n i ≠ 0}, infer_instance, λ i, p i ^ n i, _, ⟨e.trans _⟩⟩,
  { rintro ⟨i, hi⟩,
    exact one_lt_pow (hp _).one_lt hi },
  exact (my_thing _ _ _).symm,
end

end

def mk_character_zmod_aux_aux (n : ℕ) : ℤ →+ additive circle :=
{ to_fun := λ x, additive.of_mul (⟨e (x / n), e_mem_circle⟩ : circle),
  map_zero' := by rw [int.cast_zero, zero_div, of_mul_eq_zero, subtype.ext_iff, subtype.coe_mk,
    e_zero, coe_one_unit_sphere],
  map_add' :=
  begin
    intros x y,
    rw [←of_mul_mul, equiv.apply_eq_iff_eq, submonoid.mk_mul_mk, subtype.ext_iff,
      subtype.coe_mk, subtype.coe_mk, int.cast_add, add_div, e_add],
  end }

def mk_character_zmod_aux (n : ℕ) : zmod n →+ additive circle :=
zmod.lift _ ⟨mk_character_zmod_aux_aux n,
begin
  rw [mk_character_zmod_aux_aux],
  simp only [int.cast_coe_nat, add_monoid_hom.coe_mk, set_like.coe_eq_coe, of_mul_eq_zero],
  ext : 1,
  rw [set_like.coe_mk, coe_one_unit_sphere],
  cases eq_or_ne (n : ℝ) 0 with hn hn,
  { rw [hn, zero_div, e_zero] },
  { rw [div_self hn, e_one] },
end⟩

lemma zmod.lift_inj {A : Type*} [add_comm_group A] {n : ℕ} (f : {f : ℤ →+ A // f n = 0})
  (hf : ∀ i : ℤ, f i = 0 → (i : zmod n) = 0) :
  function.injective (zmod.lift n f) :=
begin
  rw [←add_monoid_hom.ker_eq_bot_iff, eq_bot_iff],
  intros i,
  simp only [add_subgroup.mem_bot, add_monoid_hom.mem_ker],
  obtain ⟨i, rfl⟩ := zmod.int_cast_surjective i,
  simp only [zmod.lift_coe],
  exact hf _
end

lemma mk_character_zmod_aux_inj {n : ℕ} (hn : n ≠ 0) :
  function.injective (mk_character_zmod_aux n) :=
begin
  apply zmod.lift_inj,
  intros i hi,
  change additive.of_mul (⟨e _, _⟩ : circle) = _ at hi,
  rw [of_mul_eq_zero, subtype.ext_iff, subtype.coe_mk, coe_one_unit_sphere, e_eq_one_iff] at hi,
  obtain ⟨z, hz⟩ := hi,
  rw zmod.int_coe_zmod_eq_zero_iff_dvd,
  rw [div_eq_iff, mul_comm] at hz,
  { norm_cast at hz,
    exact ⟨z, hz⟩ },
  exact_mod_cast hn
end

def mk_character_zmod (n : ℕ) (f : zmod n) : zmod n →+ additive circle :=
(mk_character_zmod_aux n).comp (add_monoid_hom.mul_left f)

lemma mk_character_zmod_inj {n : ℕ} (hn : n ≠ 0) :
  function.injective (mk_character_zmod n) :=
begin
  intros x y h,
  have := fun_like.congr_fun h (1 : zmod n),
  simpa using mk_character_zmod_aux_inj hn this,
end

def mk_character_zmod_hom (n : ℕ) : zmod n →+ zmod n →+ additive circle :=
{ to_fun := mk_character_zmod n,
  map_zero' :=
  begin
    ext x : 1,
    rw [mk_character_zmod, add_monoid_hom.coe_comp, function.comp_app, add_monoid_hom.coe_mul_left,
      zero_mul, map_zero, add_monoid_hom.zero_apply],
  end,
  map_add' := λ x y,
  begin
    ext z : 1,
    simp only [mk_character_zmod, add_monoid_hom.coe_mul_left, add_monoid_hom.coe_comp,
      add_monoid_hom.add_apply, function.comp_app, add_mul, map_add],
  end }

def mk_character_aux {ι : Type} [decidable_eq ι] (n : ι → ℕ)
  (u : Π i : ι, zmod (n i)) :
  direct_sum ι (λ i, zmod (n i)) →+ additive circle :=
direct_sum.to_add_monoid (λ i, (mk_character_zmod (n i) (u i)))

lemma mk_character_aux_inj {ι : Type} [decidable_eq ι] {n : ι → ℕ} (hn : ∀ i, n i ≠ 0) :
  function.injective (mk_character_aux n) :=
begin
  intros u v h,
  ext i,
  let x : direct_sum ι (λ i, zmod (n i)) := direct_sum.of _ i 1,
  have : mk_character_aux n u x = mk_character_aux n v x,
  { rw h },
  simp only [mk_character_aux, direct_sum.to_add_monoid_of, mk_character_zmod,
    add_monoid_hom.coe_comp, add_monoid_hom.coe_mul_left, function.comp_app] at this,
  simpa using mk_character_zmod_aux_inj (hn _) this,
end

lemma finite_character [finite G] : finite (character G) :=
begin
  letI : fintype G := fintype.of_finite G,
  rw ←cardinal.lt_aleph_0_iff_finite,
  have := @finite_dimensional.cardinal_mk_le_finrank_of_linear_independent ℂ (G → ℂ) _ _ _ _
    (character G) _ lin_indep_char,
  apply this.trans_lt _,
  apply cardinal.nat_lt_aleph_0,
end

instance fintype_character [fintype G] : fintype (character G) :=
@fintype.of_finite (character G) finite_character

lemma comp_symm_eq {β δ : Type*} [add_comm_group β] [add_comm_group δ] (e : δ ≃+ β) :
  (e : δ →+ β).comp (e.symm : β →+ δ) = add_monoid_hom.id β :=
begin
  ext,
  simp only [add_monoid_hom.coe_comp, add_monoid_hom.coe_coe, add_equiv.self_comp_symm, id.def,
    add_monoid_hom.id_apply],
end

-- cf https://discord.com/channels/@me/827209384811561031/1079538520353423380
lemma comp_inj {α β γ δ : Type*} [add_comm_group β] [add_comm_group γ] [add_comm_group δ]
  (f : α → β →+ γ) (e : δ ≃+ β) (hf : function.injective f):
  function.injective (λ x : α, (f x).comp (e : δ →+ β)) :=
begin
  change function.injective ((λ i : β →+ γ, i.comp (e : δ →+ β)) ∘ f),
  refine function.injective.comp _ hf,
  intros x y h,
  dsimp at h,
  have : (x.comp (e : δ →+ β)).comp (e.symm : β →+ δ) =
    (y.comp (e : δ →+ β)).comp (e.symm : β →+ δ),
  { rw h },
  rw [add_monoid_hom.comp_assoc, add_monoid_hom.comp_assoc, comp_symm_eq] at this,
  rw add_monoid_hom.comp_id at this,
  rw add_monoid_hom.comp_id at this,
  exact this
end

variable [fintype G]

lemma card_character_le : card G ≤ card (character G) :=
begin
  obtain ⟨ι, hi, n, hn, ⟨e⟩⟩ := my_classification (additive G),
  resetI,
  classical,
  have hn' : ∀ i, n i ≠ 0, { intro i, linarith only [hn i] },
  let f : G → character G := monoid_hom.to_additive.symm ∘
    (λ x, (mk_character_aux n x).comp (e : additive G →+ direct_sum ι (λ i, zmod (n i)))) ∘
      coe_fn ∘ e ∘ additive.of_mul,
  have : function.injective f,
  { refine monoid_hom.to_additive.symm.injective.comp _,
    refine function.injective.comp _
      (fun_like.coe_injective.comp (e.injective.comp additive.of_mul.injective)),
    apply comp_inj,
    apply mk_character_aux_inj hn' },
  exact fintype.card_le_of_injective _ this,
end

lemma card_character : card (character G) = card G :=
begin
  classical,
  have := @finite_dimensional.fintype_card_le_finrank_of_linear_independent _ (G → ℂ) _ _ _ _ _ _ _
    lin_indep_char,
  simp only [finite_dimensional.finrank_fintype_fun_eq_card] at this,
  exact le_antisymm this card_character_le,
end

def characters_basis (G : Type*) [comm_group G] [fintype G] : basis (character G) ℂ (G → ℂ) :=
basis_of_linear_independent_of_card_eq_finrank lin_indep_char $
  by rw [card_character, finite_dimensional.finrank_fintype_fun_eq_card]

@[simp] lemma characters_basis_apply {i : character G} : characters_basis G i = i :=
by rw [characters_basis, coe_basis_of_linear_independent_of_card_eq_finrank]

@[simps {fully_applied := ff}] def to_double_dual : G →* character (character G) := monoid_hom.eval

lemma exists_character_of_nontrivial {g : G} (hg : g ≠ 1) : ∃ χ : character G, χ g ≠ 1 :=
begin
  classical,
  by_contra' h,
  let x : G → ℂ := λ h, if g = h then 1 else 0,
  have t := (characters_basis G).sum_repr x,
  simp only [characters_basis_apply] at t,
  have t₁ := congr_fun t g,
  have t₂ := congr_fun t 1,
  simp only [fintype.sum_apply, pi.smul_apply, coe_coe_eq, h, coe_one_unit_sphere, smul_eq_mul,
    mul_one, map_one] at t₁ t₂,
  simp only [x, t₁, hg] at t₂,
  simpa using t₂,
end

lemma to_double_dual_nontrivial {g : G} (hg : g ≠ 1) : to_double_dual g ≠ 1 :=
begin
  obtain ⟨χ, hχ⟩ := exists_character_of_nontrivial hg,
  contrapose! hχ,
  simpa using fun_like.congr_fun hχ χ,
end

lemma to_double_dual_injective :
  function.injective (to_double_dual : G → character (character G)) :=
begin
  rw [←to_double_dual.ker_eq_bot_iff, eq_bot_iff],
  intro g,
  simp only [subgroup.mem_bot, monoid_hom.mem_ker],
  intro hg,
  contrapose hg,
  exact to_double_dual_nontrivial hg,
end

lemma sum_apply_of_nontrivial {x : G} (hx : x ≠ 1) : (∑ χ : character G, χ x : ℂ) = 0 :=
begin
  let x' : character (character G) := to_double_dual x,
  have : x' ≠ 1 := to_double_dual_nontrivial hx,
  rw character_nontrivial_iff at this,
  obtain ⟨χ, hχ⟩ := this,
  exact sum_eq_zero_of_nontrivial hχ,
end

lemma sum_apply_character [decidable_eq G] {x : G} :
  (∑ χ : character G, χ x : ℂ) = if x = 1 then card G else 0 :=
begin
  split_ifs,
  { rw [h],
    simp [card_univ, card_character] },
  rw [sum_apply_of_nontrivial h],
end

lemma parseval {f g : G → ℂ} :
  inner_prod_sum _ (transform f) (transform g) = inner_prod_expect _ f g :=
begin
  classical,
  simp_rw [inner_prod_sum, transform, inner_prod_expect, conj_expect, map_mul,
    star_ring_end_self_apply, expect_mul, mul_expect, coe_coe_eq, ←expect_sum],
  conv in (_ * _) { rw mul_mul_mul_comm },
  simp_rw [←sum_mul, ←coe_inv_circle_eq_conj, ←map_inv, ←coe_mul_unit_sphere, ←map_mul,
    sum_apply_character, mul_inv_eq_one, expect_indicate_eq],
end

lemma inversion (f : G → ℂ) (x : G) :
  ∑ (χ : character G), transform f χ * χ x = f x :=
begin
  classical,
  simp_rw [transform, inner_prod_expect, expect_mul, ←expect_sum, mul_right_comm _ (f _),
    ←sum_mul, coe_coe_eq, ←coe_inv_circle_eq_conj, ←map_inv, ←coe_mul_unit_sphere, ←map_mul,
    sum_apply_character, inv_mul_eq_one, expect_indicate_eq'],
end

def convolve (f g : G → ℂ) (x : G) : ℂ := 𝔼 y, f y * g (x * y⁻¹)

lemma convolve_eq [decidable_eq G] {f g : G → ℂ} (x : G) :
  𝔼 yz : G × G with yz.1 * yz.2 = x, f yz.1 * g yz.2 = convolve f g x :=
calc 𝔼 yz : G × G with yz.1 * yz.2 = x, f yz.1 * g yz.2 =
      𝔼 yz : G × G with yz.2 = x * yz.1⁻¹, f yz.1 * g yz.2 :
        by simp_rw [eq_mul_inv_iff_mul_eq, mul_comm]
    ... = convolve f g x :
    begin
      refine expect_nbij prod.fst (by simp) (by simp {contextual := tt}) _ (by simp),
      { rintro ⟨x, y⟩ ⟨z, w⟩,
        simp {contextual := tt} },
    end

lemma convolve_swap {f g : G → ℂ} :
  convolve f g = convolve g f :=
begin
  ext x : 1,
  refine expect_nbij (λ a, x * a⁻¹) (by simp) _ (by simp) (λ a _, ⟨x * a⁻¹, by simp⟩),
  simp [mul_comm],
end

lemma transform_convolve_apply {f g : G → ℂ} (χ : character G) :
  transform (convolve f g) χ = transform f χ * transform g χ :=
begin
  simp_rw [transform, inner_prod_expect, convolve, mul_expect, expect_mul, coe_coe_eq],
  rw [←expect_product', ←expect_product', univ_product_univ],
  refine expect_nbij' (λ x, (x.1 * x.2⁻¹, x.2)) (by simp) (λ x _, _) (λ x, (x.1 * x.2, x.2))
    (by simp) (by simp) (by simp),
  rw [mul_mul_mul_comm, ←map_mul, ←coe_mul_unit_sphere, ←map_mul, mul_left_comm x.2, mul_inv_self,
    mul_one],
end

lemma transform_convolve {f g : G → ℂ} : transform (convolve f g) = transform f * transform g :=
funext transform_convolve_apply

def {u} scale_endo {α : Type u} [comm_monoid α] : ℕ →* monoid.End α :=
{ to_fun := λ z,
  { to_fun := λ g, g ^ z,
    map_one' := one_pow _,
    map_mul' := λ x y, mul_pow _ _ _ },
  map_one' :=
  begin
    ext g,
    simp only [pow_one, monoid_hom.coe_mk, monoid.coe_one, id.def],
  end,
  map_mul' := λ x y, by { ext g, exact pow_mul' _ _ _ } }

lemma scale_endo_apply_apply {α : Type*} [comm_monoid α] (a : ℕ) (g : α) :
  scale_endo a g = g ^ a := rfl

lemma scale_endo_add {α : Type*} [comm_monoid α] (z₁ z₂ : ℕ) (g : α) :
  scale_endo (z₁ + z₂) g = scale_endo z₁ g * scale_endo z₂ g :=
pow_add _ _ _

lemma scale_endo_zero_apply {α : Type*} [comm_monoid α] (g : α) : scale_endo 0 g = 1 := pow_zero _

lemma scale_endo_one_apply {α : Type*} [comm_monoid α] (g : α) : scale_endo 1 g = g := pow_one _

lemma scale_endo_mul_apply {α : Type*} [comm_monoid α] (z₁ z₂ : ℕ) (g : α) :
  scale_endo (z₁ * z₂) g = scale_endo z₁ (scale_endo z₂ g) :=
pow_mul' _ _ _

lemma scale_endo_card (g : G) : scale_endo (card G) g = 1 := pow_card_eq_one

lemma scale_endo_mod (n : ℕ) :
  (scale_endo (n % card G) : monoid.End G) = scale_endo n :=
begin
  ext g,
  conv_rhs {rw [←nat.mod_add_div n (card G), scale_endo_add, scale_endo_mul_apply, scale_endo_card,
    mul_one] },
end

lemma scale_endo_val {m : ℕ} (h : m = card G) (n : ℕ) :
  (scale_endo (n : zmod m).val : monoid.End G) = scale_endo n :=
by rw [zmod.val_nat_cast, h, scale_endo_mod]

lemma zmod.coe_add {n : ℕ} {x y : zmod n} : ((x + y : zmod n) : ℤ) = (x + y) % n :=
by rw [←zmod.coe_int_cast, int.cast_add, zmod.int_cast_zmod_cast, zmod.int_cast_zmod_cast]

lemma zmod.coe_mul {n : ℕ} {x y : zmod n} : ((x * y : zmod n) : ℤ) = (x * y) % n :=
by rw [←zmod.coe_int_cast, int.cast_mul, zmod.int_cast_zmod_cast, zmod.int_cast_zmod_cast]

lemma zmod.coe_sub {n : ℕ} {x y : zmod n} : ((x - y : zmod n) : ℤ) = (x - y) % n :=
by rw [←zmod.coe_int_cast, int.cast_sub, zmod.int_cast_zmod_cast, zmod.int_cast_zmod_cast]

lemma zmod.coe_neg {n : ℕ} {x : zmod n} : ((- x : zmod n) : ℤ) = (- x) % n :=
by rw [←zmod.coe_int_cast, int.cast_neg, zmod.int_cast_zmod_cast]

lemma annoying_thing {a : ℕ} (ha : a.coprime (card G)) :
  (a * (a⁻¹ : zmod (card G)).val : zmod (card G)) = 1 :=
begin
  haveI : ne_zero (card G) := ⟨fintype.card_ne_zero⟩,
  rw [zmod.nat_cast_zmod_val, zmod.coe_mul_inv_eq_one _ ha],
end

@[simp] lemma scale_endo_invert {a : ℕ} (ha : a.coprime (card G)) (g : G) :
  scale_endo a (scale_endo (a⁻¹ : zmod (card G)).val g) = g :=
begin
  rw [←scale_endo_mul_apply, ←scale_endo_val rfl, nat.cast_mul, annoying_thing ha,
    zmod.val_one_eq_one_mod, scale_endo_mod, scale_endo_one_apply]
end

@[simp] lemma scale_endo_invert' {a : ℕ} (ha : a.coprime (card G)) (g : G) :
  scale_endo (a⁻¹ : zmod (card G)).val (scale_endo a g) = g :=
begin
  rw [←scale_endo_mul_apply, ←scale_endo_val rfl, mul_comm, nat.cast_mul, annoying_thing ha,
    zmod.val_one_eq_one_mod, scale_endo_mod, scale_endo_one_apply]
end

lemma scale_endo_bijective {a : ℕ} (ha : a.coprime (card G)) :
  function.bijective (scale_endo a : G → G) :=
function.bijective_iff_has_inverse.2 ⟨_, scale_endo_invert' ha, scale_endo_invert ha⟩

lemma sum_scale_endo {γ : Type*} [add_comm_monoid γ] {a : ℕ} (f : G → γ) (ha : a.coprime (card G)) :
  ∑ g, f (scale_endo a g) = ∑ g, f g :=
sum_nbij _ (λ _ _, mem_univ _) (λ _ _, rfl) (λ _ _ _ _ h, (scale_endo_bijective ha).1 h)
  (λ i _, ⟨_, mem_univ _, (scale_endo_invert ha _).symm⟩)

def dilate (f : G → ℂ) (a : ℕ) (x : G) : ℂ := f (scale_endo (a⁻¹ : zmod (card G)).val x)

lemma monoid_hom.pow_apply
  {α β : Type*} [mul_one_class α] [comm_monoid β] (n : ℕ) (f : α →* β) (x : α) :
  (f ^ n) x = f x ^ n :=
rfl

lemma scale_endo_apply_hom {α β : Type*} [comm_monoid α] [comm_monoid β]
  (a : ℕ) (f : α →* β) (x : α) :
  scale_endo a f x = f (scale_endo a x) :=
by rw [scale_endo_apply_apply, monoid_hom.pow_apply, ←monoid_hom.map_pow, scale_endo_apply_apply]

lemma transform_dilate (f : G → ℂ) (a : ℕ) (χ : character G) (ha : a.coprime (card G)) :
  transform (dilate f a) χ = transform f (scale_endo a χ) :=
begin
  simp_rw [transform, inner_prod_expect, dilate],
  refine expect_nbij' (scale_endo (a⁻¹ : zmod (card G)).val) _ _ (scale_endo a) _
    _ _,
  { simp only [mem_univ, forall_const] },
  { intros x hx,
    rw [coe_coe_eq, coe_coe_eq, scale_endo_apply_hom, scale_endo_invert ha] },
  { simp only [mem_univ, forall_const] },
  { simp only [ha, mem_univ, scale_endo_invert, eq_self_iff_true, forall_const] },
  { simp only [ha, mem_univ, scale_endo_invert', eq_self_iff_true, forall_const] },
end

-- lemma transform_scale_endo (f : G → ℂ) (a : ℕ) (χ : character G)

def is_real {α : Type*} (f : α → ℂ) : Prop := ∀ g, (f g).im = 0
lemma is_real.conj_eq {f : α → ℂ} (hf : is_real f) (g : α) : conj (f g) = f g :=
complex.eq_conj_iff_im.2 (hf _)

lemma is_real.dilate {f : G → ℂ} (hf : is_real f) (a : ℕ) : is_real (dilate f a) := λ g, hf _

lemma transform_inv {f : G → ℂ} (χ : character G) (hf : is_real f) :
  transform f χ⁻¹ = conj (transform f χ) :=
begin
  rw [transform, transform, inner_prod_expect, inner_prod_expect, conj_expect],
  congr' 1 with x : 1,
  rw [map_mul, complex.conj_conj, coe_coe_eq, conj_eq_inv, complex.conj_conj, hf.conj_eq,
    coe_coe_eq]
end

def indicate (A : finset α) [decidable_pred (∈ A)] (x : α) : ℂ := if x ∈ A then 1 else 0

localized "notation (name := indicate) ` 𝟙 ` := indicate" in expectations

lemma indicate_is_real (A : finset α) [decidable_pred (∈ A)] : is_real (indicate A) :=
by { intro g, rw [indicate], split_ifs; simp }

lemma indicate_of_add {A : finset α} [decidable_eq α] [decidable_pred (∈ A)] {x : α} :
  𝟙 (A.image multiplicative.of_add) (multiplicative.of_add x) = 𝟙 A x :=
by simp only [indicate, multiplicative.of_add.injective.mem_finset_image]

lemma expect_indicate (A : finset G) [decidable_pred (∈ A)] :
  𝔼 x, 𝟙 A x = A.card / card G :=
begin
  classical,
  simp only [expect_true_univ, indicate],
  rw [←sum_filter, filter_mem_eq_inter, univ_inter, sum_const, nat.smul_one_eq_coe],
end

lemma transform_indicate_inv (χ : character G) {A : finset G} [decidable_pred (∈ A)] :
  transform (𝟙 A) χ⁻¹ = conj (transform (𝟙 A) χ) :=
transform_inv _ (indicate_is_real _)

lemma transform_indicate_one (A : finset G) [decidable_pred (∈ A)] :
  transform (𝟙 A) 1 = A.card / card G :=
begin
  rw [transform, inner_prod_expect, ←expect_indicate],
  simp only [coe_coe_eq, monoid_hom.one_apply, coe_one_unit_sphere, map_one, one_mul],
end

lemma inner_sum_indicate (A : finset G) [decidable_pred (∈ A)] :
  inner_prod_sum _ (transform (𝟙 A)) (transform (𝟙 A)) = A.card / card G :=
begin
  rw [parseval, inner_prod_expect],
  convert expect_indicate A using 2,
  ext x : 1,
  rw [indicate],
  split_ifs;
  simp only [map_one, mul_one, mul_zero],
end

lemma inner_sum_indicate' (A : finset G) [decidable_pred (∈ A)] :
  ∑ r, (transform (𝟙 A) r).norm_sq = A.card / card G :=
begin
  rw [←complex.of_real_inj, complex.of_real_sum, complex.of_real_div, complex.of_real_nat_cast,
    complex.of_real_nat_cast],
  simp_rw [complex.norm_sq_eq_conj_mul_self],
  exact inner_sum_indicate _,
end

def additive_monoid_hom {α β : Type*} [add_comm_monoid α] [comm_monoid β] :
  additive (multiplicative α →* β) ≃+ (α →+ additive β) :=
add_equiv.mk' (additive.to_mul.trans monoid_hom.to_additive'') $ λ x y, by { ext, refl }

def add_monoid_hom.to_multiplicative₂'' {α β γ : Type*}
  [add_comm_monoid α] [add_comm_monoid β] [comm_monoid γ] (f : α →+ β →+ additive γ) :
  multiplicative α →* multiplicative β →* γ :=
{ to_fun := λ a, (f a.to_add).to_multiplicative'',
  map_one' := by { ext, simp only [to_add_one, map_zero, to_mul_zero, monoid_hom.one_apply,
    add_monoid_hom.to_multiplicative''_apply_apply, add_monoid_hom.zero_apply]},
  map_mul' := λ x y, by { ext z, rw [to_add_mul, map_add], refl } }

lemma injective_thru {α β γ : Type*} [add_comm_monoid α] [add_comm_monoid β] [comm_monoid γ]
  {f : α →+ β →+ additive γ} (hf : function.injective f) :
  function.injective f.to_multiplicative₂'' :=
λ x y h, multiplicative.to_add.injective (hf (add_monoid_hom.to_multiplicative''.injective h))

def to_character (n : ℕ) :
  multiplicative (zmod n) →* character (multiplicative (zmod n)) :=
(mk_character_zmod_hom n).to_multiplicative₂''

lemma to_character_inj {n : ℕ} (hn : n ≠ 0) :
  function.injective (to_character n) :=
injective_thru (mk_character_zmod_inj hn)

def zmod_characters {n : ℕ} (hn : n ≠ 0) :
  multiplicative (zmod n) ≃* character (multiplicative (zmod n)) :=
mul_equiv.of_bijective (to_character n)
begin
  haveI : ne_zero n := ⟨hn⟩,
  rw [fintype.bijective_iff_injective_and_card, card_character],
  exact ⟨to_character_inj hn, rfl⟩,
end

lemma zmod_characters_apply {n : ℕ} (hn : n ≠ 0) (x : multiplicative (zmod n)) :
  zmod_characters hn x = to_character n x :=
rfl

lemma to_character_apply_of_add_apply_of_add {n : ℕ} (x y : zmod n) :
  to_character n (multiplicative.of_add x) (multiplicative.of_add y) =
    ⟨e (x * y / n), e_mem_circle⟩ :=
begin
  ext : 1,
  change e ((((x * y : zmod n) : ℤ) : ℝ) / n) = e _,
  rw [zmod.coe_mul, e_mod_div, int.cast_mul, zmod.int_cast_cast, zmod.int_cast_cast],
end

lemma to_character_apply_apply {n : ℕ} (x y : multiplicative (zmod n)) :
  to_character n x y = ⟨e (x.to_add * y.to_add / n), e_mem_circle⟩ :=
to_character_apply_of_add_apply_of_add _ _

lemma zmod_characters_apply_of_add_apply_of_add {n : ℕ} (hn : n ≠ 0) (x y : zmod n) :
  zmod_characters hn (multiplicative.of_add x) (multiplicative.of_add y) =
    ⟨e (x * y / n), e_mem_circle⟩ :=
to_character_apply_of_add_apply_of_add _ _

lemma zmod_characters_apply_apply {n : ℕ} (hn : n ≠ 0) (x y : multiplicative (zmod n)) :
  zmod_characters hn x y = ⟨e (x.to_add * y.to_add / n), e_mem_circle⟩ :=
zmod_characters_apply_of_add_apply_of_add _ _ _

end general_fourier

open_locale expectations

section one_five

open multiplicative

variables {N : ℕ} {A B C : finset (zmod N)} {α β γ : ℝ} (hN : odd N) [ne_zero N]
  (hα : α = A.card / N) (hβ : β = B.card / N) (hγ : γ = C.card / N)
variables {A' B' C' : finset (multiplicative (zmod N))}
  (hA' : A' = A.image of_add) (hB' : B' = B.image of_add) (hC' : C' = C.image of_add)

@[simp] lemma card_multiplicative {α : Type*} [fintype α] : card (multiplicative α) = card α := rfl

lemma one_five_first_calculation (hN : odd N) :
  𝔼 d x, 𝟙 A' x * 𝟙 B' (x * d) * 𝟙 C' (x * d * d) =
    ∑ r, transform (𝟙 B') (scale_endo 2 r)⁻¹ * (transform (𝟙 A') r * transform (𝟙 C') r) :=
begin
  have : nat.coprime 2 (fintype.card (multiplicative (zmod N))),
  { change nat.coprime 2 (fintype.card (zmod N)),
    rwa [zmod.card, nat.prime_two.coprime_iff_not_dvd, ←even_iff_two_dvd, ←nat.odd_iff_not_even] },
  simp_rw [←transform_convolve_apply, transform_inv _ (indicate_is_real _),
    ←transform_dilate _ _ _ this],
  rw [←inner_prod_sum, parseval, ←expect_product', inner_prod_expect],
  simp_rw [((indicate_is_real B').dilate 2).conj_eq, convolve, mul_expect, ←expect_product',
    univ_product_univ, dilate],
  refine expect_nbij (λ x, (scale_endo 2 (x.1 * x.2), x.2)) _ _ _ _,
  { simp only [mem_univ, forall_const] },
  { rintro ⟨x₁, x₂⟩ -,
    dsimp,
    rw [scale_endo_invert' this, scale_endo_apply_apply, mul_left_comm, ←mul_assoc, mul_comm x₂,
      mul_pow, mul_assoc (x₁ ^ 2), sq, sq x₂, mul_inv_cancel_right, mul_right_comm x₁] },
  { rintro ⟨x₁, x₂⟩ ⟨y₁, y₂⟩ - -,
    rw [prod.mk.inj_iff, prod.mk.inj_iff, (scale_endo_bijective this).injective.eq_iff],
    rintro ⟨h, rfl : x₂ = y₂⟩,
    exact ⟨by simpa using h, rfl⟩ },
  { rintro ⟨y₁, y₂⟩ -,
    refine ⟨(scale_endo ((2 : ℕ) : zmod (card (multiplicative (zmod N))))⁻¹.val y₁ * y₂⁻¹, y₂),
      mem_univ _, prod.mk.inj_iff.2 ⟨_, rfl⟩⟩,
    dsimp,
    rw [inv_mul_cancel_right, scale_endo_invert this], },
end

lemma one_five_second_calculation
  (hα : α = A.card / N) (hβ : β = B.card / N) (hγ : γ = C.card / N)
  (hA' : A' = A.image of_add) (hB' : B' = B.image of_add) (hC' : C' = C.image of_add) :
  ∑ r, transform (𝟙 B') (scale_endo 2 r)⁻¹ * (transform (𝟙 A') r * transform (𝟙 C') r) =
    α * β * γ +
      ∑ r in univ.filter (λ χ : character (multiplicative (zmod N)), χ ≠ 1),
        transform (𝟙 A') r * (transform (𝟙 B') (scale_endo 2 r)⁻¹ * transform (𝟙 C') r) :=
begin
  simp_rw [mul_left_comm, mul_assoc],
  rw [←sum_filter_add_sum_filter_not univ (λ χ : character (multiplicative (zmod N)), χ = 1),
    add_left_inj, sum_filter, sum_ite_eq' _ (1 : character (multiplicative (zmod N))) _,
    if_pos (mem_univ _), map_one, inv_one, transform_indicate_one, transform_indicate_one,
    transform_indicate_one, card_multiplicative, zmod.card, hA', hB', hC', hα, hβ, hγ],
  simp only [card_image_of_injective _ of_add.injective, complex.of_real_div,
    complex.of_real_nat_cast],
end

lemma one_five_third_bound (hN : odd N)
  (hβ : β = B.card / N) (hγ : γ = C.card / N)
  (hB' : B' = B.image of_add) (hC' : C' = C.image of_add) :
  ∑ r in univ.filter (λ χ : character (multiplicative (zmod N)), χ ≠ 1),
        (transform (𝟙 B') (scale_endo 2 r)).abs * (transform (𝟙 C') r).abs ≤ (β * γ).sqrt :=
begin
  have : nat.coprime 2 (fintype.card (character (multiplicative (zmod N)))),
  { rw card_character,
    change nat.coprime 2 (fintype.card (zmod N)),
    rwa [zmod.card, nat.prime_two.coprime_iff_not_dvd, ←even_iff_two_dvd, ←nat.odd_iff_not_even] },
  refine (sum_le_univ_sum_of_nonneg (λ x, _)).trans _,
  { positivity },
  refine (cauchy_schwarz_sqrt _ _ _).trans_eq _,
  simp_rw [complex.sq_abs, sum_scale_endo (λ i, complex.norm_sq (transform (𝟙 B') i)) this,
    inner_sum_indicate', card_multiplicative, zmod.card, hB', hC',
    card_image_of_injective _ of_add.injective, hβ, hγ],
  rw real.sqrt_mul,
  positivity
end

lemma one_five_fourth_bound (hN : odd N)
  (hα : α = A.card / N) (hβ : β = B.card / N) (hγ : γ = C.card / N)
  (hB' : B' = B.image of_add) (hC' : C' = C.image of_add)
  (hf : ∀ χ : character (multiplicative (zmod N)), χ ≠ 1 → (transform (𝟙 A') χ).abs
    ≤ α * (β * γ).sqrt / 2) :
  (∑ r in univ.filter (λ χ : character (multiplicative (zmod N)), χ ≠ 1),
        transform (𝟙 A') r * (transform (𝟙 B') (scale_endo 2 r)⁻¹ * transform (𝟙 C') r)).abs
      ≤ α * β * γ / 2 :=
calc _ ≤ ∑ r in univ.filter (λ χ : character (multiplicative (zmod N)), χ ≠ 1),
        (transform (𝟙 A') r * (transform (𝟙 B') (scale_endo 2 r)⁻¹ * transform (𝟙 C') r)).abs :
          abv_sum_le_sum_abv _ _
   ... = ∑ r in univ.filter (λ χ : character (multiplicative (zmod N)), χ ≠ 1),
        (transform (𝟙 A') r).abs * (transform (𝟙 B') (scale_endo 2 r)⁻¹ * transform (𝟙 C') r).abs :
      by simp_rw [map_mul]
   ... ≤ ∑ r in univ.filter (λ χ : character (multiplicative (zmod N)), χ ≠ 1),
        α * (β * γ).sqrt / 2 * (transform (𝟙 B') (scale_endo 2 r)⁻¹ * transform (𝟙 C') r).abs :
        begin
          refine sum_le_sum _,
          intros i hi,
          exact mul_le_mul_of_nonneg_right (hf _ (by simpa using hi)) (complex.abs.nonneg _),
        end
   ... = α * (β * γ).sqrt / 2 * ∑ r in univ.filter (λ χ : character (multiplicative (zmod N)), χ ≠ 1),
        (transform (𝟙 B') (scale_endo 2 r)⁻¹ * transform (𝟙 C') r).abs :
          by rw mul_sum
   ... = α * (β * γ).sqrt / 2 * ∑ r in univ.filter (λ χ : character (multiplicative (zmod N)), χ ≠ 1),
        (transform (𝟙 B') (scale_endo 2 r)).abs * (transform (𝟙 C') r).abs :
          by simp_rw [map_mul, transform_inv _ (indicate_is_real _), complex.abs_conj]
    ... ≤ _ :
    begin
      refine (mul_le_mul_of_nonneg_left (one_five_third_bound hN hβ hγ hB' hC') _).trans_eq _,
      { rw hα, positivity },
      rw [div_mul_eq_mul_div, mul_assoc, real.mul_self_sqrt, mul_assoc],
      rw [hβ, hγ], positivity
    end

lemma one_five_fifth_calculation
  (hA' : A' = A.image of_add) (hB' : B' = B.image of_add) (hC' : C' = C.image of_add)
  (h : (1 : ℝ) / N < (𝔼 d x, 𝟙 A' x * 𝟙 B' (x * d) * 𝟙 C' (x * d * d)).abs) :
  ∃ x d : zmod N, d ≠ 0 ∧ x ∈ A ∧ x + d ∈ B ∧ x + 2 * d ∈ C :=
begin
  simp only [expect_multiplicative, indicate, hA', hB', hC', ←of_add_add, and_assoc, mul_one,
    of_add.injective.mem_finset_image, ←ite_and_mul_zero] at h,
  simp only [expect_true_univ, zmod.card, ←sum_div, div_div, map_div₀, complex.abs_cast_nat,
    map_mul, sum_boole, ←nat.cast_sum] at h,
  rw [←sum_filter_add_sum_filter_not finset.univ (λ d : zmod N, d = 0), sum_filter,
    sum_ite_eq' _ (0 : zmod N), if_pos (mem_univ _), nat.cast_add, add_div] at h,
  have : ((univ.filter (λ x : zmod N, x ∈ A ∧ x + 0 ∈ B ∧ x + 0 + 0 ∈ C)).card : ℝ) / (N * N) ≤
    1 / N,
  { rw ←div_div,
    refine div_le_div_of_le_of_nonneg (div_le_one_of_le _ (by positivity)) (by positivity),
    exact nat.cast_le.2 ((card_le_univ _).trans_eq (zmod.card _)) },
  replace h := h.trans_le (add_le_add_right this _),
  rw [lt_add_iff_pos_right, lt_div_iff, zero_mul, nat.cast_pos, pos_iff_ne_zero, ne.def,
    sum_eq_zero_iff] at h,
  { simp only [not_forall, mem_filter, mem_univ, true_and, card_eq_zero, exists_prop,
      filter_eq_empty_iff, not_not, add_assoc, ←two_mul] at h,
    obtain ⟨d, hd, x, z⟩ := h,
    exact ⟨_, _, hd, z⟩ },
  rw [←sq, sq_pos_iff, nat.cast_ne_zero],
  exact ne_zero.ne _
end

lemma last_bit {α : ℝ} {δ : ℂ} (h : δ.abs ≤ α / 2) :
  α / 2 ≤ ((α : ℂ) + δ).abs :=
begin
  rw [←sub_neg_eq_add],
  refine le_trans' (complex.abs.le_sub _ _) _,
  rw [absolute_value.map_neg, le_sub_comm],
  apply h.trans _,
  rw [le_sub_iff_add_le, add_halves', complex.abs_of_real],
  exact le_abs_self α,
end

lemma one_five {N : ℕ} {A B C : finset (zmod N)} {α β γ : ℝ} (hN : odd N) [ne_zero N]
  (hα : α = A.card / N) (hβ : β = B.card / N) (hγ : γ = C.card / N)
  (hf : ∀ r : zmod N, r ≠ 0 → (transform (𝟙 (A.image of_add)) (to_character N (of_add r))).abs
    ≤ α * (β * γ).sqrt / 2)
  (hd : (1 : ℝ) / N < α * β * γ / 2) :
  ∃ x d : zmod N, d ≠ 0 ∧ x ∈ A ∧ x + d ∈ B ∧ x + 2 * d ∈ C :=
begin
  refine one_five_fifth_calculation rfl rfl rfl _,
  refine hd.trans_le _,
  rw [one_five_first_calculation hN,  one_five_second_calculation hα hβ hγ rfl rfl rfl,
    ←complex.of_real_mul, ←complex.of_real_mul],
  have hf' : ∀ χ : character (multiplicative (zmod N)), χ ≠ 1 →
    (transform (𝟙 (A.image of_add)) χ).abs ≤ α * (β * γ).sqrt / 2,
  { intros χ hχ,
    convert hf ((zmod_characters (ne_zero.ne _)).symm χ).to_add _ using 1,
    { rw [of_add_to_add, ←zmod_characters_apply, mul_equiv.apply_symm_apply] },
    rwa [ne.def, ←equiv.eq_symm_apply, to_add_symm_eq, of_add_zero,
      mul_equiv_class.map_eq_one_iff] },
  exact last_bit (one_five_fourth_bound hN hα hβ hγ rfl rfl hf'),
end

-- lemma one_five_explicit {N : ℕ} {A B C : finset (zmod N)} {α β γ : ℝ} (hN : odd N) [ne_zero N]
--   (hα : α = A.card / N) (hβ : β = B.card / N) (hγ : γ = C.card / N)
--   (hf : ∀ r : zmod N, r ≠ 0 → (transform (𝟙 (A.image of_add)) (to_character N (of_add r))).abs
--     ≤ α * (β * γ).sqrt / 2)
--   (hd : (1 : ℝ) / N < α * β * γ / 2) :
--   ∃ x d : zmod N, d ≠ 0 ∧ x ∈ A ∧ x + d ∈ B ∧ x + 2 * d ∈ C :=
-- begin
--   simp only [transform, inner_prod_expect, expect_multiplicative,
--     to_character_apply_of_add_apply_of_add, coe_coe_eq, set_like.coe_mk,
--     of_add.injective.mem_finset_image, indicate_of_add, conj_e] at hf,
--   -- simp only [ne.def, set_like.coe_mk] at hf,
--   -- simp only [ne.def, coe_coe_eq] at hf,
-- end

end one_five

section one_six

-- lemma one_add_e (x : ℝ) : 1 + e x = 2 * e (x / 2) * real.cos (π * x) :=
-- begin
--   rw [mul_right_comm, complex.of_real_cos, complex.two_cos, e, e, mul_assoc,
--     complex.of_real_div, complex.of_real_bit0, complex.of_real_one, ←mul_assoc (x / 2 : ℂ),
--     div_mul_cancel (x : ℂ) two_ne_zero', mul_left_comm, mul_comm π, complex.of_real_mul, neg_mul,
--     mul_assoc, add_mul, ←complex.exp_add, ←two_mul, ←complex.exp_add, add_left_neg,
--     complex.exp_zero, add_comm]
-- end

lemma one_sub_e_eq {θ : ℝ} :
  1 - e θ = 2 * real.sin (π * θ) * (- complex.I * e (θ / 2)) :=
begin
  have : complex.exp (π * θ * complex.I) = e (θ / 2),
  { rw [e, complex.of_real_div, ←mul_assoc, ←mul_assoc, complex.of_real_bit0, complex.of_real_one,
      div_mul_cancel _ (two_ne_zero' ℂ), mul_comm (π : ℂ)] },
  rw [complex.of_real_sin, complex.two_sin, mul_assoc, ←mul_assoc complex.I, mul_neg,
    complex.I_mul_I, neg_neg, one_mul, neg_mul, complex.of_real_mul, complex.exp_neg, this,
    ←e_neg, sub_mul, ←e_add, ←e_add, add_left_neg, e_zero, add_halves'],
end

lemma real.sin_le_self {θ : ℝ} (h : 0 ≤ θ) : real.sin θ ≤ θ :=
begin
  rcases eq_or_ne θ 0 with rfl | hθ',
  { rw [real.sin_zero] },
  exact (real.sin_lt (lt_of_le_of_ne' h hθ')).le,
end

lemma real.abs_sin_le_abs : ∀ θ, |real.sin θ| ≤ |θ| :=
begin
  suffices : ∀ θ, 0 ≤ θ → |real.sin θ| ≤ |θ|,
  { intros θ,
    cases le_total 0 θ with hθ hθ,
    { exact this _ hθ },
    { rw [←abs_neg, ←real.sin_neg, ←abs_neg θ],
      exact this _ (by simpa using hθ) } },
  intros θ hθ,
  rw abs_of_nonneg hθ,
  cases le_total θ π,
  { rw [abs_of_nonneg (real.sin_nonneg_of_nonneg_of_le_pi hθ h)],
    exact real.sin_le_self hθ },
  refine (real.abs_sin_le_one _).trans (h.trans' _),
  linarith only [real.pi_gt_three],
end

-- this can also be lower bounded by 4 θ in the same conditions
lemma one_sub_e_le {θ : ℝ} :
  (1 - e θ).abs ≤ 2 * π * |θ| :=
begin
  rw [one_sub_e_eq, map_mul, map_mul, map_mul, absolute_value.map_neg, complex.abs_two,
    ←abs_of_pos real.pi_pos, complex.abs_I, one_mul, abs_e, mul_one, complex.abs_of_real,
    mul_assoc, ←abs_mul, abs_of_pos real.pi_pos],
  exact mul_le_mul_of_nonneg_left (real.abs_sin_le_abs _) (by norm_num),
end

lemma real.abs_le_abs_sin_mul :
  ∀ {θ : ℝ}, |θ| ≤ 1 → |θ| ≤ |real.sin (π / 2 * θ)| :=
begin
  suffices : ∀ θ, 0 ≤ θ → |θ| ≤ 1 → |θ| ≤ |real.sin (π / 2 * θ)|,
  { intros θ hθ',
    cases le_total 0 θ with hθ hθ,
    { exact this _ hθ hθ' },
    { rw [←abs_neg (real.sin _), ←real.sin_neg, ←abs_neg, ←mul_neg],
      exact this (-θ) (by simpa) (by simpa using hθ') } },
  intros θ hθ hθ',
  exact abs_le_abs_of_nonneg hθ (real.le_sin_mul hθ (le_of_abs_le hθ')),
end

-- don't need this for now but it's nice
-- lemma le_one_sub_e {θ : ℝ} (hθ : |θ| ≤ 1 / 2) :
--   4 * |θ| ≤ (1 - e θ).abs :=
-- begin
--   -- have := real.abs_le_abs_sin_mul,
--   rw [one_sub_e_eq, map_mul, map_mul, map_mul, absolute_value.map_neg, complex.abs_two,
--     complex.abs_I, one_mul, abs_e, mul_one, complex.abs_of_real, bit0_eq_two_mul (2 : ℝ),
--     mul_assoc, ←abs_mul, abs_of_pos real.pi_pos],
-- end

lemma abs_lt_one_of_floor_eq {x y : ℝ} (h : ⌊x⌋₊ = ⌊y⌋₊) (hx : 0 ≤ x) (hy : 0 ≤ y) : |x - y| < 1 :=
begin
  apply int.abs_sub_lt_one_of_floor_eq_floor,
  rwa [←nat.cast_floor_eq_int_floor hx, ←nat.cast_floor_eq_int_floor hy, nat.cast_inj],
end

lemma pigeons {s : finset ℝ} {m : ℕ} (hm : m ≠ 0) (hs : m < s.card)
  (hs' : ∀ x ∈ s, x ∈ set.Ico (0 : ℝ) 1) :
  ∃ x y : ℝ, x ≠ y ∧ x ∈ s ∧ y ∈ s ∧ |x - y| < m⁻¹ :=
begin
  let f : ℝ → ℕ := λ x, ⌊x * m⌋₊,
  have : ∀ x ∈ s, f x ∈ range m,
  { intros x hx,
    obtain ⟨l, r⟩ := hs' _ hx,
    rw [mem_range, nat.floor_lt],
    { exact mul_lt_of_lt_one_left (by positivity) r },
    positivity },
  have this' : (range m).card * 1 < s.card,
  { rwa [card_range, mul_one], },
  have := finset.exists_lt_card_fiber_of_mul_lt_card_of_maps_to this this',
  simp only [one_lt_card_iff, mem_filter, mem_range] at this,
  obtain ⟨_, h2, x, y, ⟨hx, h⟩, ⟨hy, rfl⟩, h7⟩ := this,
  have := abs_lt_one_of_floor_eq h (mul_nonneg (hs' _ hx).1 (nat.cast_nonneg _))
    (mul_nonneg (hs' _ hy).1 (nat.cast_nonneg _)),
  rw [←sub_mul, abs_mul, nat.abs_cast, ←lt_div_iff, one_div] at this,
  { exact ⟨x, y, h7, hx, hy, this⟩ },
  positivity
end

lemma pigeons' (f : ℕ → ℝ) (m : ℕ) (hm : m ≠ 0)
  (hs' : ∀ x ≤ m, f x ∈ set.Ico (0 : ℝ) 1) :
  ∃ x y : ℕ, x < y ∧ x ≤ m ∧ y ≤ m ∧ |f x - f y| < m⁻¹ :=
begin
  let g : ℕ → ℕ := λ x, ⌊f x * m⌋₊,
  have : ∀ x ∈ range (m + 1), g x ∈ range m,
  { intros x hx,
    obtain ⟨l, r⟩ := hs' x (by simpa [mem_range_succ_iff] using hx),
    rw [mem_range, nat.floor_lt],
    { exact mul_lt_of_lt_one_left (by positivity) r },
    positivity },
  have this' : (range m).card * 1 < (range (m+1)).card,
  { rwa [card_range, card_range, mul_one], simp },
  have := finset.exists_lt_card_fiber_of_mul_lt_card_of_maps_to this this',
  simp only [one_lt_card_iff, mem_filter, mem_range, mem_range_succ_iff, g] at this,
  obtain ⟨_, h2, x, y, ⟨hx, h⟩, ⟨hy, rfl⟩, h7⟩ := this,
  wlog h8 : x < y generalizing x y,
  { rw not_lt at h8,
    refine this y x hy h7.symm hx (by linarith) h.symm (lt_of_le_of_ne' h8 h7) },
  have := abs_lt_one_of_floor_eq h (mul_nonneg (hs' _ hx).1 (nat.cast_nonneg _))
    (mul_nonneg (hs' _ hy).1 (nat.cast_nonneg _)),
  rw [←sub_mul, abs_mul, nat.abs_cast, ←lt_div_iff, one_div] at this,
  { exact ⟨x, y, h8, hx, hy, this⟩ },
  positivity
end

-- works with `hr : 1 ≤ r`
lemma circular_pigeons (θ : ℝ) {r : ℕ} (hr : r ≠ 0) :
  ∃ d : ℕ, d ≠ 0 ∧ d ≤ r ∧ (1 - e (θ * d)).abs ≤ 2 * π / r :=
begin
  let f : ℕ → ℝ := λ i, int.fract (θ * i),
  obtain ⟨x, y, hxy, hx, hy, hr'⟩ :=
    pigeons' f r hr (λ i hi, ⟨int.fract_nonneg _, int.fract_lt_one _⟩),
  { refine ⟨y - x, (nat.sub_pos_of_lt hxy).ne', (nat.sub_le y x).trans hy, _⟩,
    rw abs_sub_comm at hr',
    rw [nat.cast_sub hxy.le, mul_sub, e_sub, one_sub_div e_ne_zero, ←e_fract (θ * x),
      ←e_fract (θ * y), ←one_sub_div e_ne_zero, ←e_sub],
    { cases lt_or_le r 2,
      { rw [sub_eq_add_neg],
        refine (complex.abs.add_le _ _).trans _,
        rw [absolute_value.map_one, absolute_value.map_neg, abs_e, le_div_iff, ←bit0],
        { refine mul_le_mul_of_nonneg_left _ (by norm_num),
          refine real.pi_gt_three.le.trans' _,
          norm_cast,
          linarith },
        rwa [nat.cast_pos, pos_iff_ne_zero] },
      refine one_sub_e_le.trans _,
      rw div_eq_mul_inv,
      exact mul_le_mul_of_nonneg_left hr'.le (mul_nonneg zero_le_two real.pi_pos.le) } },
end

def finpartition.extend' {α : Type*} [decidable_eq α] [distrib_lattice α] [order_bot α] {a b c : α}
  (P : finpartition a) (hab : disjoint a b) (hc : a ⊔ b = c) :
  finpartition c :=
if hb : b = ⊥ then P.copy (by rw [←hc, hb, sup_bot_eq]) else P.extend hb hab hc

lemma divide_up (s : ℕ) (t : ℕ) (hs : t ≤ s) (ht : t ≠ 0) :
  ∃ P : finpartition (range s), ∀ i ∈ P.parts, (∃ x y, i = Ico x y) ∧ t ≤ i.card ∧ i.card < 2 * t :=
begin
  set n := s / t with ←hn,
  have hnl : n * t ≤ s := nat.div_mul_le_self _ _,
  have hnu : s < (n + 1) * t,
  { rw [add_one_mul],
    exact nat.lt_div_mul_add ht.bot_lt },
  clear_value n,
  clear hn,
  induction n with n ih generalizing s,
  { simp only [one_mul] at hnu,
    cases hs.not_lt hnu },
  cases n,
  { refine ⟨finpartition.indiscrete _, λ i hi, _⟩,
    { simp only [bot_eq_empty, ne.def, range_eq_empty_iff],
      linarith },
    rw [finpartition.indiscrete_parts, mem_singleton] at hi,
    rw one_mul at hnl,
    subst i,
    refine ⟨⟨0, s, by rw range_eq_Ico⟩, _⟩,
    simpa [hnl] using hnu },
  simp only [nat.succ_eq_add_one] at hnl hnu ih,
  have h₂ : (n + 1) * t ≤ s - t,
  { apply le_tsub_of_add_le_left,
    linarith only [hnl] },
  have h₃ : s - t < (n + 1 + 1) * t,
  { rw [tsub_lt_iff_left hs],
    linarith only [hnu] },
  have h₁ : t ≤ s - t,
  { apply h₂.trans' _,
    apply nat.le_mul_of_pos_left,
    simp },
  have : disjoint (range (s - t)) (Ico (s - t) s),
  { rw [range_eq_Ico],
    exact Ico_disjoint_Ico_consecutive 0 (s - t) s },
  obtain ⟨P, hP⟩ := ih (s - t) h₁ h₂ h₃,
  refine ⟨P.extend' this _, _⟩,
  { rw [range_eq_Ico, sup_eq_union, Ico_union_Ico_eq_Ico],
    { simp },
    { exact nat.sub_le _ _ } },
  intros i hi,
  rw [finpartition.extend'] at hi,
  split_ifs at hi,
  { exact hP _ (by simpa using hi) },
  rw [finpartition.extend_parts, mem_insert] at hi,
  rcases hi with rfl | hi,
  { refine ⟨⟨_, _, rfl⟩, _⟩,
    rw [nat.card_Ico, nat.sub_sub_self hs],
    exact ⟨le_rfl, lt_two_mul_self ht.bot_lt⟩ },
  exact hP _ hi
end

lemma divide_up' (s : ℕ) (t : ℕ) (hs : t ≤ s) (ht₀ : t ≠ 0) :
  ∃ P : finpartition (range s), ∀ p : finset ℕ, p ∈ P.parts →
    t ≤ p.card ∧ p.card < 2 * t ∧ (∃ i n, p = (range n).image (λ x, i + x)) :=
begin
  obtain ⟨P, hP⟩ := divide_up s t hs ht₀,
  refine ⟨P, λ p hp, _⟩,
  obtain ⟨⟨x, y, rfl⟩, ht⟩ := hP p hp,
  refine ⟨ht.1, ht.2, x, y - x, _⟩,
  rw [range_eq_Ico, image_add_left_Ico, add_tsub_cancel_of_le, add_zero],
  replace ht : 0 < _ := ht.1.trans' ht₀.bot_lt,
  rw nat.card_Ico at ht,
  refine le_of_lt _,
  rwa ←tsub_pos_iff_lt,
end

def mod_partitions (s d : ℕ) (hd : d ≠ 0) (h : d ≤ s) : finpartition (range s) :=
{ parts := (range d).image (λ i, (range s).filter (λ j, j % d = i)),
  sup_indep :=
  begin
    rw [sup_indep_iff_pairwise_disjoint, coe_image, set.inj_on.pairwise_disjoint_image],
    { simp only [set.pairwise_disjoint, function.on_fun, set.pairwise, mem_coe, mem_range,
        disjoint_left, function.comp.left_id, mem_filter, not_and, and_imp],
      rintro x hx y hy hxy a ha rfl _,
      exact hxy },
    simp only [set.inj_on, coe_range, set.mem_Iio],
    intros x₁ hx₁ x₂ hx₂ h',
    have : x₁ ∈ (range s).filter (λ j, j % d = x₂),
    { rw [←h', mem_filter, mem_range, nat.mod_eq_of_lt hx₁],
      simp only [hx₁.trans_le h, eq_self_iff_true, and_self] },
    rw [mem_filter, nat.mod_eq_of_lt hx₁] at this,
    exact this.2
  end,
  sup_parts :=
  begin
    rw [sup_image, function.comp.left_id],
    refine subset.antisymm _ _,
    { rw [finset.sup_eq_bUnion, bUnion_subset],
      simp only [filter_subset, implies_true_iff] },
    intros i hi,
    have : 0 < d := hd.bot_lt,
    simpa [mem_sup, nat.mod_lt _ this] using hi,
  end,
  not_bot_mem :=
  begin
    simp only [bot_eq_empty, mem_image, mem_range, exists_prop, not_exists, not_and,
      filter_eq_empty_iff, not_forall, not_not],
    intros i hi,
    exact ⟨_, hi.trans_le h, nat.mod_eq_of_lt hi⟩,
  end }

lemma mod_partitions_parts_eq (s d : ℕ) (hd : d ≠ 0) (h : d ≤ s) :
  (mod_partitions s d hd h).parts =
    (range d).image (λ i, (range ((s - i - 1) / d + 1)).image (λ x, i + d * x)) :=
begin
  rw [mod_partitions],
  ext x,
  simp only [mem_image, mem_range],
  refine bex_congr (λ i hi, _),
  suffices : (range ((s - i - 1) / d + 1)).image (λ x, i + d * x) =
    (range s).filter (λ j, j % d = i),
  { rw this },
  clear x,
  ext j,
  simp only [mem_image, mem_filter, mem_range, nat.lt_add_one_iff],
  split,
  { rintro ⟨j, hj, rfl⟩,
    rw [nat.add_mul_mod_self_left, nat.mod_eq_of_lt hi, eq_self_iff_true, and_true,
      ←lt_tsub_iff_left, mul_comm],
    rwa [nat.le_div_iff_mul_le hd.bot_lt, nat.le_sub_iff_right, nat.succ_le_iff] at hj,
    rw [nat.succ_le_iff],
    exact nat.sub_pos_of_lt (hi.trans_le h) },
  { rintro ⟨hj, rfl⟩,
    refine ⟨j / d, _, nat.mod_add_div _ _⟩,
    rwa [nat.le_div_iff_mul_le' hd.bot_lt, le_tsub_iff_right, le_tsub_iff_left, ←add_assoc,
      mul_comm, nat.mod_add_div, nat.add_one_le_iff],
    { exact hi.le.trans h },
    rw [nat.succ_le_iff],
    exact nat.sub_pos_of_lt (hi.trans_le h) }
end

lemma ineq_thing {s d i : ℕ}
  (hd : d ≠ 0)
  (h : d ≤ s)
  (hi : i < d) :
  s / d ≤ (s - i - 1) / d + 1 :=
begin
  rw [←nat.succ_eq_add_one, ←nat.add_div_right _ hd.bot_lt],
  { apply nat.div_le_div_right,
    rw [nat.sub_sub, ←nat.sub_add_comm, nat.add_sub_assoc],
    { apply le_self_add },
    { rwa nat.succ_le_iff },
    rw nat.succ_le_iff,
    apply hi.trans_le h },
end

lemma injective_affine {a d : ℕ} (hd : d ≠ 0) : function.injective (λ x, a + d * x) :=
begin
  intros x y,
  rw [add_right_inj],
  simp [hd]
end

lemma mod_partitions_parts_card {s d : ℕ} {i : finset ℕ} (hd : d ≠ 0) (h : d ≤ s)
  (hi : i ∈ (mod_partitions s d hd h).parts) : s / d ≤ i.card :=
begin
  simp only [mod_partitions_parts_eq, mem_image, mem_range] at hi,
  obtain ⟨i, hi, rfl⟩ := hi,
  rw [card_image_of_injective, card_range],
  { exact ineq_thing hd h hi },
  apply injective_affine hd
end

lemma image_injective {α β : Type*} [decidable_eq β] (f : α → β) (hf : function.injective f) :
  function.injective (finset.image f) :=
begin
  intros i j h,
  rw [←coe_inj, ←hf.image_injective.eq_iff, ←coe_image, h, coe_image],
end

@[simps]
def finpartition.push {α β : Type*} [decidable_eq α] [decidable_eq β] {a : finset α}
  (P : finpartition a) (f : α → β) (hf : function.injective f) :
  finpartition (a.image f) :=
{ parts := P.parts.image (λ i, i.image f),
  sup_indep :=
  begin
    rw [sup_indep_iff_pairwise_disjoint, coe_image, set.inj_on.pairwise_disjoint_image],
    simp only [set.pairwise_disjoint, set.pairwise, mem_coe, function.on_fun, ne.def,
      function.comp.left_id, disjoint_image hf],
    { exact P.disjoint },
    apply function.injective.inj_on,
    exact image_injective _ hf
  end,
  sup_parts :=
  begin
    ext i,
    simp only [mem_sup, mem_image, exists_prop, id.def, exists_exists_and_eq_and],
    split,
    { rintro ⟨j, hj, i, hij, rfl⟩,
      exact ⟨_, P.le hj hij, rfl⟩ },
    rintro ⟨j, hj, rfl⟩,
    rw ←P.sup_parts at hj,
    simp only [mem_sup, id.def, exists_prop] at hj,
    obtain ⟨b, hb, hb'⟩ := hj,
    exact ⟨b, hb, _, hb', rfl⟩,
  end,
  not_bot_mem :=
  begin
    simp only [bot_eq_empty, mem_image, image_eq_empty, exists_prop, exists_eq_right],
    exact P.not_bot_mem
  end
}

lemma partitions_one (N t r d : ℕ) (hrN : r ≤ N) (ht : t ≤ N / r) (ht' : t ≠ 0)
  (hd : d ≠ 0) (hdr : d ≤ r) :
  ∃ P : finpartition (range N), ∀ p : finset ℕ, p ∈ P.parts →
    t ≤ p.card ∧ p.card < 2 * t ∧ (∃ i n, p = (range n).image (λ x, i + d * x)) :=
begin
  -- obtain ⟨d, hd, hdr, hd'⟩ := circular_pigeons θ hr,
  -- use d,
  let P' := mod_partitions N d hd (hdr.trans hrN),
  have hQ' : ∀ p ∈ P'.parts, ∃ Q : finpartition p, ∀ q : finset ℕ, q ∈ Q.parts →
    t ≤ q.card ∧ q.card < 2 * t ∧ (∃ i n, q = (range n).image (λ x, i + d * x)),
  { intros p hp,
    simp only [mod_partitions_parts_eq, mem_image, mem_range] at hp,
    obtain ⟨a, ha, rfl⟩ := hp,
    obtain ⟨Q, hQ⟩ := divide_up' ((N - a - 1) / d + 1) t (ht.trans ((ineq_thing hd
      (hdr.trans hrN) ha).trans' (nat.div_le_div_left hdr hd.bot_lt))) ht',
    refine ⟨Q.push _ (injective_affine hd), _⟩,
    intros q hq,
    rw [finpartition.push_parts, mem_image] at hq,
    obtain ⟨q, hq, rfl⟩ := hq,
    obtain ⟨hin1, hin2, i, n, rfl⟩ := hQ _ hq,
    rw card_image_of_injective,
    { refine ⟨hin1, hin2, a + d * i, n, _⟩,
      rw image_image,
      congr' 1 with x,
      ring_nf },
    exact injective_affine hd },
  choose Q hQ using hQ',
  refine ⟨P'.bind Q, _⟩,
  intros p hp,
  rw finpartition.mem_bind at hp,
  obtain ⟨p', hp', hp''⟩ := hp,
  exact hQ _ _ _ hp''
end

lemma many_triangles_aux {θ z : ℝ} {d b : ℕ} (h : (1 - e (θ * d)).abs ≤ z) :
  (1 - e (θ * d * b)).abs ≤ b * z :=
begin
  induction b with b ih,
  { rw [nat.cast_zero, mul_zero, e_zero, sub_self, map_zero, zero_mul] },
  rw [nat.cast_add_one, mul_add_one, e_add, add_one_mul],
  refine (complex.abs.sub_le _ _ _).trans (add_le_add ih _),
  rwa [←mul_one_sub, map_mul, abs_e, one_mul],
end

lemma many_triangles {θ z : ℝ} {d t a b : ℕ} (h : (1 - e (θ * d)).abs ≤ z)
  (ha : a < t) (hb : b < t) :
  (e (θ * d * a) - e (θ * d * b)).abs ≤ t * z :=
begin
  wlog hab : a ≤ b generalizing a b,
  { rw absolute_value.map_sub,
    exact this hb ha (le_of_not_le hab) },
  obtain ⟨b, rfl⟩ := nat.exists_eq_add_of_le hab,
  rw [nat.cast_add, mul_add, e_add, ←mul_one_sub, map_mul, abs_e, one_mul],
  apply (many_triangles_aux h).trans _,
  have : b ≤ t := by linarith,
  refine mul_le_mul_of_nonneg_right _ (h.trans' (complex.abs.nonneg _)),
  exact_mod_cast this,
end

-- 4 π t / r ≤ ε
-- t ≤ N / r

-- 4 π N / r ^ 2 ≤ ε
-- sqrt(4 π N / ε) ≤ r
-- 1 / r ≤ sqrt(ε / 4 π N)
-- t ≤ sqrt (N ε / 4 π)
lemma partitions_two (θ : ℝ) (N t r : ℕ) (hr : r ≠ 0) (hrN : r ≤ N) (ht : t ≤ N / r) (ht' : t ≠ 0) :
  ∃ d ≠ 0, ∃ P : finpartition (range N), ∀ p : finset ℕ, p ∈ P.parts →
    t ≤ p.card ∧ (∃ i n, p = (range n).image (λ x, i + d * x)) ∧
    ∀ x y : ℕ, x ∈ p → y ∈ p → (e (θ * x) - e (θ * y)).abs ≤ 4 * π * t / r :=
begin
  obtain ⟨d, hd, hdr, hd'⟩ := circular_pigeons θ hr,
  obtain ⟨P, hP⟩ := partitions_one N t r d hrN ht ht' hd hdr,
  refine ⟨d, hd, P, _⟩,
  intros p hp,
  obtain ⟨htn, htn', i, n, rfl⟩ := hP p hp,
  refine ⟨htn, ⟨i, n, rfl⟩, _⟩,
  simp only [mem_image, mem_range, exists_prop, forall_exists_index, and_imp],
  rintro _ _ a ha rfl b hb rfl,
  rw [nat.cast_add, nat.cast_add, mul_add, mul_add, e_add, e_add, ←mul_sub, map_mul, abs_e, one_mul,
    nat.cast_mul, nat.cast_mul, ←mul_assoc, ←mul_assoc],
  apply (many_triangles hd' ha hb).trans _,
  rw [mul_comm (4 * π), bit0_eq_two_mul (2 : ℝ), mul_assoc, ←mul_assoc, mul_div_assoc (_ * _),
    mul_comm (t : ℝ)],
  refine mul_le_mul_of_nonneg_right _ _,
  rw [card_image_of_injective _ (injective_affine hd), card_range] at htn',
  exact_mod_cast htn'.le,
  exact div_nonneg real.two_pi_pos.le (nat.cast_nonneg _),
end

end one_six

#exit

section final

lemma first_order_bernoulli_lt {x y : ℝ} (hx : 0 < x) (hy : 1 < y) : 1 + y * x < (1 + x) ^ y :=
begin
  let f := λ x, (1 + x) ^ y - (1 + y * x),
  let f' := λ x, 1 * y * (1 + x) ^ (y - 1) - y * 1,
  have hf' : ∀ x, f' x = y * ((1 + x) ^ (y - 1) - 1),
  { intro x,
    simp only [f'],
    ring },
  have hf : ∀ z, has_deriv_at f (f' z) z,
  { intro z,
    exact (((has_deriv_at_id' _).const_add _).rpow_const (or.inr hy.le)).sub
      (((has_deriv_at_id' z).const_mul y).const_add _) },
  have hf₁ : continuous f,
  { rw continuous_iff_continuous_at,
    intro x,
    exact (hf x).continuous_at },
  have hf₃ : ∀ z ∈ interior (set.Ici (0 : ℝ)), 0 < deriv f z,
  { intros z hz,
    rw interior_Ici at hz,
    simp only [(hf z).deriv, hf', one_mul],
    refine mul_pos (by linarith) (sub_pos_of_lt _),
    exact (real.one_lt_rpow (lt_add_of_pos_right _ hz) (sub_pos_of_lt hy)) },
  have := convex.strict_mono_on_of_deriv_pos (convex_Ici 0) hf₁.continuous_on
    hf₃ set.left_mem_Ici hx.le hx,
  simp only [f] at this,
  simpa using this
end

lemma first_order_bernoulli_le {x y : ℝ} (hx : 0 ≤ x) (hy : 1 ≤ y) : 1 + y * x ≤ (1 + x) ^ y :=
begin
  rcases hx.eq_or_lt with rfl | hx,
  { simp },
  rcases hy.eq_or_lt with rfl | hy,
  { simp },
  exact (first_order_bernoulli_lt hx hy).le,
end

lemma second_order_bernoulli_lt {x y : ℝ} (hx : 0 < x) (hy : 2 < y) :
  1 + y * x + y * (y - 1) / 2 * x ^ 2 < (1 + x) ^ y :=
begin
  let f := λ x, (1 + x) ^ y - (1 + (y * x + y * (y - 1) / 2 * x ^ 2)),
  let f' := λ x, 1 * y * (1 + x) ^ (y - 1) - (y * 1 + y * (y - 1) / 2 * ((2 : ℕ) * x ^ 1)),
  have hf' : ∀ x, f' x = y * ((1 + x) ^ (y - 1) - (1 + (y - 1) * x)),
  { intro x,
    simp only [f', nat.cast_two, pow_one],
    ring },
  have hf : ∀ z, has_deriv_at f (f' z) z,
  { intro z,
    refine has_deriv_at.sub _ _,
    { exact (has_deriv_at.rpow_const ((has_deriv_at_id' _).const_add _) (or.inr (by linarith))) },
    refine (((has_deriv_at_id' _).const_mul y).add (has_deriv_at.const_mul _ _)).const_add _,
    refine has_deriv_at_pow _ _ },
  have hf₁ : continuous f,
  { rw continuous_iff_continuous_at,
    intro x,
    exact (hf x).continuous_at },
  have hf₃ : ∀ z ∈ interior (set.Ici (0 : ℝ)), 0 < deriv f z,
  { intros z hz,
    rw interior_Ici at hz,
    simp only [(hf z).deriv, hf', one_mul],
    refine mul_pos (by linarith) _,
    rw sub_pos,
    exact first_order_bernoulli_lt hz (by linarith) },
  have := convex.strict_mono_on_of_deriv_pos (convex_Ici 0) hf₁.continuous_on hf₃ set.left_mem_Ici
    hx.le hx,
  simp only [f] at this,
  simpa [add_assoc] using this
end

lemma second_order_bernoulli_le {x y : ℝ} (hx : 0 ≤ x) (hy : 2 ≤ y) :
  1 + y * x + y * (y - 1) / 2 * x ^ 2 ≤ (1 + x) ^ y :=
begin
  rcases hx.eq_or_lt with rfl | hx,
  { simp },
  rcases hy.eq_or_lt with rfl | hy,
  { norm_cast, ring_nf },
  exact (second_order_bernoulli_lt hx hy).le,
end

def density_change (k δ : ℝ) : ℝ := δ * (1 + δ / k)

lemma density_change_gt {k δ : ℝ} (hk : 0 < k) (hδ : 0 < δ) : δ < density_change k δ :=
begin
  refine lt_mul_right hδ _,
  rw lt_add_iff_pos_right,
  positivity,
end

lemma density_change_iterate_gt {k δ : ℝ} {m : ℕ} (hk : 0 < k) (hδ : 0 < δ) :
  δ ≤ (density_change k^[m] δ) :=
begin
  induction m,
  { simp },
  apply m_ih.trans _,
  rw function.iterate_succ_apply',
  exact (density_change_gt hk (hδ.trans_le m_ih)).le,
end

lemma density_change_iterate_le {k δ : ℝ} {m n : ℕ} (hk : 0 < k) (hδ : 0 < δ) (hmn : m ≤ n) :
  (density_change k^[m] δ) ≤ (density_change k^[n] δ) :=
begin
  obtain ⟨_, rfl⟩ := exists_add_of_le hmn,
  rw [add_comm, function.iterate_add_apply],
  exact density_change_iterate_gt hk (hδ.trans_le (density_change_iterate_gt hk hδ)),
end

lemma density_change_pos {k δ : ℝ} (hk : 0 < k) (hδ : 0 < δ) : 0 < density_change k δ :=
hδ.trans (density_change_gt hk hδ)

lemma density_change_iterate_pos {k δ : ℝ} {m : ℕ} (hk : 0 < k) (hδ : 0 < δ) :
  0 < (density_change k^[m] δ) :=
hδ.trans_le (density_change_iterate_gt hk hδ)

lemma density_change_mono {k δ₁ δ₂ : ℝ} (hk : 0 ≤ k) (hδ₁ : 0 ≤ δ₁) (hδ₂ : δ₁ ≤ δ₂) :
  density_change k δ₁ ≤ density_change k δ₂ :=
mul_le_mul hδ₂ (add_le_add_left (div_le_div_of_le_of_nonneg hδ₂ hk) _)
  (add_nonneg zero_le_one (div_nonneg hδ₁ hk)) (by linarith)

lemma density_change_iterate_mono {k δ₁ δ₂ : ℝ} {m : ℕ} (hk : 0 < k) (hδ₁ : 0 < δ₁)
  (hδ₂ : δ₁ ≤ δ₂) :
  density_change k^[m] δ₁ ≤ (density_change k^[m] δ₂) :=
begin
  induction m with m ih,
  { simp [hδ₂] },
  rw [function.iterate_succ_apply', function.iterate_succ_apply'],
  exact density_change_mono hk.le (density_change_iterate_pos hk hδ₁).le ih,
end

lemma helper {k δ x : ℝ} (hk : 0 < k) (hδ : 0 < δ) (hx : 1 ≤ x) :
  density_change k δ * x ≤ density_change k (δ * x) :=
begin
  rw [density_change, density_change, mul_right_comm],
  refine mul_le_mul_of_nonneg_left (add_le_add_left _ _) (by nlinarith),
  exact div_le_div_of_le_of_nonneg (by nlinarith) hk.le,
end

lemma density_change_iterate_gt_pow {k δ : ℝ} {m : ℕ} (hk : 0 < k) (hδ : 0 < δ) :
  δ * (1 + δ / k) ^ m ≤ (density_change k^[m] δ) :=
begin
  induction m with m ih,
  { simp },
  rw function.iterate_succ_apply',
  refine ((helper hk hδ _).trans_eq' _).trans (density_change_mono hk.le _ ih),
  { refine one_le_pow_of_one_le _ _,
    simp only [le_add_iff_nonneg_right],
    positivity },
  { rw [pow_succ, ←mul_assoc],
    refl },
  positivity,
end

lemma density_change_basic {k δ : ℝ} {m : ℕ} (hk : 0 < k) (hδ : 0 < δ) :
  δ * (1 + m * (δ / k)) ≤ (density_change k^[m] δ) :=
(density_change_iterate_gt_pow hk hδ).trans' $
begin
  refine mul_le_mul_of_nonneg_left (one_add_mul_le_pow _ _) hδ.le,
  exact (div_nonneg hδ.le hk.le).trans' (by norm_num),
end

lemma density_change_daniel {δ : ℝ} (hδ : 0 < δ) (hδ' : δ < 3) :
  2 * δ ≤ (density_change 40^[⌊40 / δ⌋₊] δ) :=
begin
  have h₁ : 3 / 2 * δ ≤ (density_change 40^[⌈20 / δ⌉₊] δ),
  { rw [mul_comm],
    refine (density_change_basic (by norm_num) hδ).trans' (mul_le_mul_of_nonneg_left _ hδ.le),
    have : (1 / 2 : ℝ) ≤ ⌈20 / δ⌉₊ * (δ / 40),
    { refine (mul_le_mul_of_nonneg_right (nat.le_ceil _) (by positivity)).trans_eq' _,
      rw div_mul_div_cancel _ hδ.ne',
      norm_num },
    linarith },
  have h₂ : 2 * δ ≤ (density_change 40^[⌈(80 / 9) / δ⌉₊] (3 / 2 * δ)),
  { refine (density_change_basic (by norm_num) _).trans' _,
    { linarith },
    rw mul_right_comm,
    refine mul_le_mul_of_nonneg_right _ hδ.le,
    have : (1 / 3 : ℝ) ≤ ↑⌈(80 / 9) / δ⌉₊ * (3 / 2 * δ / 40),
    { refine (mul_le_mul_of_nonneg_right (nat.le_ceil _) (by positivity)).trans_eq' _,
      rw [div_mul_div_comm, mul_comm _ δ, mul_div_assoc, mul_div_mul_left _ _ hδ.ne'],
      norm_num },
    rw [←div_le_iff', ←sub_le_iff_le_add'],
    { norm_num [this] },
    { norm_num } },
  have h₃ : (⌈20 / δ⌉₊ : ℝ) + ⌈(80 / 9) / δ⌉₊ ≤ ⌊40 / δ⌋₊,
  { refine (add_le_add (nat.ceil_lt_add_one (by positivity)).le
      (nat.ceil_lt_add_one _).le).trans ((nat.sub_one_lt_floor _).le.trans' _),
    { positivity },
    rw [div_add_one hδ.ne', div_sub_one hδ.ne', div_add_one hδ.ne', div_add_div_same],
    apply div_le_div_of_le_of_nonneg _ hδ.le,
    linarith },
  refine h₂.trans ((density_change_iterate_mono (by norm_num) _ h₁).trans _),
  { positivity },
  rw [←function.iterate_add_apply, add_comm],
  refine density_change_iterate_le (by norm_num) hδ (by exact_mod_cast h₃),
end

lemma density_change_third {k δ : ℝ} {m : ℕ} (hk : 0 < k) (hδ : 0 < δ) (hm : 2 ≤ m):
  δ * (1 + m * δ / k + m * (m - 1) / 2 * δ ^ 2 / k ^ 2) ≤ (density_change k^[m] δ) :=
begin
  refine ((density_change_iterate_gt_pow hk hδ).trans' (mul_le_mul_of_nonneg_left _ hδ.le)),
  rw [←real.rpow_nat_cast _ m, mul_div_assoc, mul_div_assoc, ←div_pow],
  exact (second_order_bernoulli_le (by positivity) (by exact_mod_cast hm)),
end

lemma density_change_me {δ : ℝ} (hδ : 0 < δ) (hδ₁ : δ ≤ 1) :
  2 * δ ≤ (density_change 40^[⌊40 / δ⌋₊] δ) :=
begin
  refine (density_change_third (by norm_num) hδ _).trans' _,
  { rw [nat.le_floor_iff', le_div_iff hδ, nat.cast_two],
    { linarith },
    { linarith } },
  rw [mul_comm],
  refine mul_le_mul_of_nonneg_left _ hδ.le,
  have : 40 / δ - 1 ≤ ⌊40 / δ⌋₊ := (nat.sub_one_lt_floor _).le,
  have : 1 + (40 / δ - 1) * δ / 40 + (40 / δ - 1) * (40 / δ - 1 - 1) / 2 * δ ^ 2 / 40 ^ 2 ≤
    1 + (⌊40 / δ⌋₊ : ℝ) * δ / 40 + ⌊40 / δ⌋₊ * (⌊40 / δ⌋₊ - 1) / 2 * δ ^ 2 / 40 ^ 2,
  { refine add_le_add_three le_rfl (by nlinarith) _,
    refine div_le_div_of_le_of_nonneg (mul_le_mul_of_nonneg_right _ (by nlinarith)) (by norm_num),
    refine div_le_div_of_le_of_nonneg (mul_le_mul this (by linarith) _ (by simp)) (by norm_num),
    rw [le_sub_iff_add_le, le_sub_iff_add_le, le_div_iff hδ, ←le_div_iff'],
    { norm_num1, linarith },
    { norm_num } },
  refine this.trans' _,
  field_simp [hδ.ne'],
  rw le_div_iff,
  { ring_nf SOP,
    nlinarith },
  positivity
end

lemma density_change_overall {δ : ℝ} (hδ : 0 < δ) (hδ' : δ ≤ 1) :
  ∃ m ≤ ⌊80 / δ⌋₊, 1 < (density_change 40^[m] δ) :=
begin
  have ih : ∀ n, 2 ^ n * δ ≤ 1 →
    2 ^ (n + 1) * δ ≤ (density_change 40^[∑ i in range (n+1), ⌊40 / (2 ^ i * δ)⌋₊] δ),
  { intro n,
    induction n with n ih,
    { simp only [pow_zero, one_mul, pow_one, range_one, sum_singleton],
      exact density_change_me hδ },
    intro hδ',
    refine ((density_change_me (by positivity) hδ').trans_eq' _).trans _,
    { rw [←mul_assoc, ←pow_succ] },
    have : 2 ^ n * δ ≤ 1 :=
      hδ'.trans' (mul_le_mul_of_nonneg_right (pow_le_pow (by norm_num) (nat.le_succ _)) hδ.le),
    refine (density_change_iterate_mono (by norm_num) _ (ih this)).trans _,
    { positivity },
    rw [sum_range_succ _ (n+1), ←function.iterate_add_apply, add_comm] },
  let n := ⌊- real.logb 2 δ⌋₊,
  have : ∑ (i : ℕ) in range (n + 1), ⌊40 / (2 ^ i * δ)⌋₊ ≤ ⌊80 / δ⌋₊,
  { rw [nat.le_floor_iff (show 0 ≤ 80 / δ, by positivity), nat.cast_sum],
    have : ∑ x in range (n + 1), (⌊40 / (2 ^ x * δ)⌋₊ : ℝ) ≤
      ∑ x in range (n + 1), 40 / (2 ^ x * δ),
    { exact sum_le_sum (λ i hi, nat.floor_le (by positivity)) },
    refine this.trans _,
    simp_rw [←div_div, ←sum_div, div_eq_mul_inv, range_eq_Ico, ←inv_pow, ←mul_sum],
    refine mul_le_mul_of_nonneg_right _ (by positivity),
    refine (mul_le_mul_of_nonneg_left (geom_sum_Ico_le_of_lt_one (by norm_num) _) _).trans_eq _,
    { norm_num },
    { norm_num },
    { norm_num } },
  refine ⟨_, this, _⟩,
  refine (ih _ _).trans_lt' _,
  { rw [←le_div_iff hδ, ←real.rpow_nat_cast, ←real.le_logb_iff_rpow_le, one_div, real.logb_inv],
    { apply nat.floor_le _,
      rw neg_nonneg,
      exact real.logb_nonpos (by norm_num) hδ.le hδ' },
    { norm_num },
    { positivity } },
  rw [←div_lt_iff hδ, one_div, ←real.rpow_nat_cast, ←real.logb_lt_iff_lt_rpow, real.logb_inv,
    nat.cast_add_one],
  { exact nat.lt_floor_add_one _ },
  { norm_num },
  { positivity },
end

lemma density_change_overall' {δ : ℝ} (hδ : 0 < δ) (hδ' : δ ≤ 1) :
  1 < (density_change 40^[⌊80 / δ⌋₊] δ) :=
begin
  obtain ⟨m, hm, hm'⟩ := density_change_overall hδ hδ',
  exact hm'.trans_le (density_change_iterate_le (by norm_num) hδ hm),
end

end final
