/-
Copyright (c) 2020 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anne Baanen
-/
import field_theory.minpoly.field

/-!
# Power basis

> THIS FILE IS SYNCHRONIZED WITH MATHLIB4.
> Any changes to this file require a corresponding PR to mathlib4.

This file defines a structure `power_basis R S`, giving a basis of the
`R`-algebra `S` as a finite list of powers `1, x, ..., x^n`.
For example, if `x` is algebraic over a ring/field, adjoining `x`
gives a `power_basis` structure generated by `x`.

## Definitions

* `power_basis R A`: a structure containing an `x` and an `n` such that
`1, x, ..., x^n` is a basis for the `R`-algebra `A` (viewed as an `R`-module).

* `finrank (hf : f ≠ 0) : finite_dimensional.finrank K (adjoin_root f) = f.nat_degree`,
  the dimension of `adjoin_root f` equals the degree of `f`

* `power_basis.lift (pb : power_basis R S)`: if `y : S'` satisfies the same
  equations as `pb.gen`, this is the map `S →ₐ[R] S'` sending `pb.gen` to `y`

* `power_basis.equiv`: if two power bases satisfy the same equations, they are
  equivalent as algebras

## Implementation notes

Throughout this file, `R`, `S`, `A`, `B` ... are `comm_ring`s, and `K`, `L`, ... are `field`s.
`S` is an `R`-algebra, `B` is an `A`-algebra, `L` is a `K`-algebra.

## Tags

power basis, powerbasis

-/

open polynomial
open_locale polynomial

variables {R S T : Type*} [comm_ring R] [ring S] [algebra R S]
variables {A B : Type*} [comm_ring A] [comm_ring B] [is_domain B] [algebra A B]
variables {K : Type*} [field K]

/-- `pb : power_basis R S` states that `1, pb.gen, ..., pb.gen ^ (pb.dim - 1)`
is a basis for the `R`-algebra `S` (viewed as `R`-module).

This is a structure, not a class, since the same algebra can have many power bases.
For the common case where `S` is defined by adjoining an integral element to `R`,
the canonical power basis is given by `{algebra,intermediate_field}.adjoin.power_basis`.
-/
@[nolint has_nonempty_instance]
structure power_basis (R S : Type*) [comm_ring R] [ring S] [algebra R S] :=
(gen : S)
(dim : ℕ)
(basis : basis (fin dim) R S)
(basis_eq_pow : ∀ i, basis i = gen ^ (i : ℕ))

-- this is usually not needed because of `basis_eq_pow` but can be needed in some cases;
-- in such circumstances, add it manually using `@[simps dim gen basis]`.
initialize_simps_projections power_basis (-basis)

namespace power_basis

@[simp] lemma coe_basis (pb : power_basis R S) :
  ⇑pb.basis = λ (i : fin pb.dim), pb.gen ^ (i : ℕ) :=
funext pb.basis_eq_pow

/-- Cannot be an instance because `power_basis` cannot be a class. -/
lemma finite_dimensional [algebra K S] (pb : power_basis K S) : finite_dimensional K S :=
finite_dimensional.of_fintype_basis pb.basis

lemma finrank [algebra K S] (pb : power_basis K S) : finite_dimensional.finrank K S = pb.dim :=
by rw [finite_dimensional.finrank_eq_card_basis pb.basis, fintype.card_fin]

lemma mem_span_pow' {x y : S} {d : ℕ} :
  y ∈ submodule.span R (set.range (λ (i : fin d), x ^ (i : ℕ))) ↔
    ∃ f : R[X], f.degree < d ∧ y = aeval x f :=
begin
  have : set.range (λ (i : fin d), x ^ (i : ℕ)) = (λ (i : ℕ), x ^ i) '' ↑(finset.range d),
  { ext n,
    simp_rw [set.mem_range, set.mem_image, finset.mem_coe, finset.mem_range],
    exact ⟨λ ⟨⟨i, hi⟩, hy⟩, ⟨i, hi, hy⟩, λ ⟨i, hi, hy⟩, ⟨⟨i, hi⟩, hy⟩⟩ },
  simp only [this, finsupp.mem_span_image_iff_total, degree_lt_iff_coeff_zero,
    exists_iff_exists_finsupp, coeff, aeval, eval₂_ring_hom', eval₂_eq_sum, polynomial.sum, support,
    finsupp.mem_supported', finsupp.total, finsupp.sum, algebra.smul_def, eval₂_zero, exists_prop,
    linear_map.id_coe, eval₂_one, id.def, not_lt, finsupp.coe_lsum, linear_map.coe_smul_right,
    finset.mem_range, alg_hom.coe_mk, finset.mem_coe],
  simp_rw [@eq_comm _ y],
  exact iff.rfl
end

lemma mem_span_pow {x y : S} {d : ℕ} (hd : d ≠ 0) :
  y ∈ submodule.span R (set.range (λ (i : fin d), x ^ (i : ℕ))) ↔
    ∃ f : R[X], f.nat_degree < d ∧ y = aeval x f :=
begin
  rw mem_span_pow',
  split;
  { rintros ⟨f, h, hy⟩,
    refine ⟨f, _, hy⟩,
    by_cases hf : f = 0,
    { simp only [hf, nat_degree_zero, degree_zero] at h ⊢,
      exact lt_of_le_of_ne (nat.zero_le d) hd.symm <|> exact with_bot.bot_lt_coe d },
    simpa only [degree_eq_nat_degree hf, with_bot.coe_lt_coe] using h },
end

lemma dim_ne_zero [h : nontrivial S] (pb : power_basis R S) : pb.dim ≠ 0 :=
λ h, not_nonempty_iff.mpr (h.symm ▸ fin.is_empty : is_empty (fin pb.dim)) pb.basis.index_nonempty

lemma dim_pos [nontrivial S] (pb : power_basis R S) : 0 < pb.dim :=
nat.pos_of_ne_zero pb.dim_ne_zero

lemma exists_eq_aeval [nontrivial S] (pb : power_basis R S) (y : S) :
  ∃ f : R[X], f.nat_degree < pb.dim ∧ y = aeval pb.gen f :=
(mem_span_pow pb.dim_ne_zero).mp (by simpa using pb.basis.mem_span y)

lemma exists_eq_aeval' (pb : power_basis R S) (y : S) :
  ∃ f : R[X], y = aeval pb.gen f :=
begin
  nontriviality S,
  obtain ⟨f, _, hf⟩ := exists_eq_aeval pb y,
  exact ⟨f, hf⟩
end

lemma alg_hom_ext {S' : Type*} [semiring S'] [algebra R S']
  (pb : power_basis R S) ⦃f g : S →ₐ[R] S'⦄ (h : f pb.gen = g pb.gen) :
  f = g :=
begin
  ext x,
  obtain ⟨f, rfl⟩ := pb.exists_eq_aeval' x,
  rw [← polynomial.aeval_alg_hom_apply, ← polynomial.aeval_alg_hom_apply, h]
end

section minpoly

open_locale big_operators

variable [algebra A S]

/-- `pb.minpoly_gen` is the minimal polynomial for `pb.gen`. -/
noncomputable def minpoly_gen (pb : power_basis A S) : A[X] :=
X ^ pb.dim -
  ∑ (i : fin pb.dim), C (pb.basis.repr (pb.gen ^ pb.dim) i) * X ^ (i : ℕ)

lemma aeval_minpoly_gen (pb : power_basis A S) : aeval pb.gen (minpoly_gen pb) = 0 :=
begin
  simp_rw [minpoly_gen, alg_hom.map_sub, alg_hom.map_sum, alg_hom.map_mul, alg_hom.map_pow,
           aeval_C, ← algebra.smul_def, aeval_X],
  refine sub_eq_zero.mpr ((pb.basis.total_repr (pb.gen ^ pb.dim)).symm.trans _),
  rw [finsupp.total_apply, finsupp.sum_fintype];
    simp only [pb.coe_basis, zero_smul, eq_self_iff_true, implies_true_iff]
end

lemma minpoly_gen_monic (pb : power_basis A S) : monic (minpoly_gen pb) :=
begin
  nontriviality A,
  apply (monic_X_pow _).sub_of_left _,
  rw degree_X_pow,
  exact degree_sum_fin_lt _
end

lemma dim_le_nat_degree_of_root (pb : power_basis A S) {p : A[X]}
  (ne_zero : p ≠ 0) (root : aeval pb.gen p = 0) :
  pb.dim ≤ p.nat_degree :=
begin
  refine le_of_not_lt (λ hlt, ne_zero _),
  rw [p.as_sum_range' _ hlt, finset.sum_range],
  refine fintype.sum_eq_zero _ (λ i, _),
  simp_rw [aeval_eq_sum_range' hlt, finset.sum_range, ← pb.basis_eq_pow] at root,
  have := fintype.linear_independent_iff.1 pb.basis.linear_independent _ root,
  dsimp only at this,
  rw [this, monomial_zero_right],
end

lemma dim_le_degree_of_root (h : power_basis A S) {p : A[X]}
  (ne_zero : p ≠ 0) (root : aeval h.gen p = 0) :
  ↑h.dim ≤ p.degree :=
by { rw [degree_eq_nat_degree ne_zero, with_bot.coe_le_coe],
     exact h.dim_le_nat_degree_of_root ne_zero root }

lemma degree_minpoly_gen [nontrivial A] (pb : power_basis A S) :
  degree (minpoly_gen pb) = pb.dim :=
begin
  unfold minpoly_gen,
  rw degree_sub_eq_left_of_degree_lt; rw degree_X_pow,
  apply degree_sum_fin_lt
end

lemma nat_degree_minpoly_gen [nontrivial A] (pb : power_basis A S) :
  nat_degree (minpoly_gen pb) = pb.dim :=
nat_degree_eq_of_degree_eq_some pb.degree_minpoly_gen

@[simp]
lemma minpoly_gen_eq (pb : power_basis A S) : pb.minpoly_gen = minpoly A pb.gen :=
begin
  nontriviality A,
  refine minpoly.unique' A _ pb.minpoly_gen_monic
    pb.aeval_minpoly_gen (λ q hq, or_iff_not_imp_left.2 $ λ hn0 h0, _),
  exact (pb.dim_le_degree_of_root hn0 h0).not_lt (pb.degree_minpoly_gen ▸ hq),
end

lemma is_integral_gen (pb : power_basis A S) : is_integral A pb.gen :=
⟨minpoly_gen pb, minpoly_gen_monic pb, aeval_minpoly_gen pb⟩

@[simp]
lemma degree_minpoly [nontrivial A] (pb : power_basis A S) : degree (minpoly A pb.gen) = pb.dim :=
by rw [← minpoly_gen_eq, degree_minpoly_gen]

@[simp]
lemma nat_degree_minpoly [nontrivial A] (pb : power_basis A S) :
  (minpoly A pb.gen).nat_degree = pb.dim :=
by rw [← minpoly_gen_eq, nat_degree_minpoly_gen]

protected lemma left_mul_matrix (pb : power_basis A S) :
  algebra.left_mul_matrix pb.basis pb.gen = matrix.of
    (λ i j, if ↑j + 1 = pb.dim then -pb.minpoly_gen.coeff ↑i else if ↑i = ↑j + 1 then 1 else 0) :=
begin
  casesI subsingleton_or_nontrivial A, { apply subsingleton.elim },
  rw [algebra.left_mul_matrix_apply, ← linear_equiv.eq_symm_apply, linear_map.to_matrix_symm],
  refine pb.basis.ext (λ k, _),
  simp_rw [matrix.to_lin_self, matrix.of_apply, pb.basis_eq_pow],
  apply (pow_succ _ _).symm.trans,
  split_ifs with h h,
  { simp_rw [h, neg_smul, finset.sum_neg_distrib, eq_neg_iff_add_eq_zero],
    convert pb.aeval_minpoly_gen,
    rw [add_comm, aeval_eq_sum_range, finset.sum_range_succ, ← leading_coeff,
        pb.minpoly_gen_monic.leading_coeff, one_smul, nat_degree_minpoly_gen, finset.sum_range] },
  { rw [fintype.sum_eq_single (⟨↑k + 1, lt_of_le_of_ne k.2 h⟩ : fin pb.dim), if_pos, one_smul],
    { refl }, { refl }, intros x hx, rw [if_neg, zero_smul], apply mt fin.ext hx },
end

end minpoly

section equiv

variables [algebra A S] {S' : Type*} [ring S'] [algebra A S']

lemma constr_pow_aeval (pb : power_basis A S) {y : S'}
  (hy : aeval y (minpoly A pb.gen) = 0) (f : A[X]) :
  pb.basis.constr A (λ i, y ^ (i : ℕ)) (aeval pb.gen f) = aeval y f :=
begin
  casesI subsingleton_or_nontrivial A,
  { rw [(subsingleton.elim _ _ : f = 0), aeval_zero, map_zero, aeval_zero] },
  rw [← aeval_mod_by_monic_eq_self_of_root (minpoly.monic pb.is_integral_gen) (minpoly.aeval _ _),
      ← @aeval_mod_by_monic_eq_self_of_root _ _ _ _ _ f _ (minpoly.monic pb.is_integral_gen) y hy],
  by_cases hf : f %ₘ minpoly A pb.gen = 0,
  { simp only [hf, alg_hom.map_zero, linear_map.map_zero] },
  have : (f %ₘ minpoly A pb.gen).nat_degree < pb.dim,
  { rw ← pb.nat_degree_minpoly,
    apply nat_degree_lt_nat_degree hf,
    exact degree_mod_by_monic_lt _ (minpoly.monic pb.is_integral_gen) },
  rw [aeval_eq_sum_range' this, aeval_eq_sum_range' this, linear_map.map_sum],
  refine finset.sum_congr rfl (λ i (hi : i ∈ finset.range pb.dim), _),
  rw finset.mem_range at hi,
  rw linear_map.map_smul,
  congr,
  rw [← fin.coe_mk hi, ← pb.basis_eq_pow ⟨i, hi⟩, basis.constr_basis]
end

lemma constr_pow_gen (pb : power_basis A S) {y : S'}
  (hy : aeval y (minpoly A pb.gen) = 0) :
  pb.basis.constr A (λ i, y ^ (i : ℕ)) pb.gen = y :=
by { convert pb.constr_pow_aeval hy X; rw aeval_X }

lemma constr_pow_algebra_map (pb : power_basis A S) {y : S'}
  (hy : aeval y (minpoly A pb.gen) = 0) (x : A) :
  pb.basis.constr A (λ i, y ^ (i : ℕ)) (algebra_map A S x) = algebra_map A S' x :=
by { convert pb.constr_pow_aeval hy (C x); rw aeval_C }

lemma constr_pow_mul (pb : power_basis A S) {y : S'}
  (hy : aeval y (minpoly A pb.gen) = 0) (x x' : S) :
  pb.basis.constr A (λ i, y ^ (i : ℕ)) (x * x') =
    pb.basis.constr A (λ i, y ^ (i : ℕ)) x * pb.basis.constr A (λ i, y ^ (i : ℕ)) x' :=
begin
  obtain ⟨f, rfl⟩ := pb.exists_eq_aeval' x,
  obtain ⟨g, rfl⟩ := pb.exists_eq_aeval' x',
  simp only [← aeval_mul, pb.constr_pow_aeval hy]
end

/-- `pb.lift y hy` is the algebra map sending `pb.gen` to `y`,
where `hy` states the higher powers of `y` are the same as the higher powers of `pb.gen`.

See `power_basis.lift_equiv` for a bundled equiv sending `⟨y, hy⟩` to the algebra map.
-/
noncomputable def lift (pb : power_basis A S) (y : S')
  (hy : aeval y (minpoly A pb.gen) = 0) :
  S →ₐ[A] S' :=
{ map_one' := by { convert pb.constr_pow_algebra_map hy 1 using 2; rw ring_hom.map_one },
  map_zero' := by { convert pb.constr_pow_algebra_map hy 0 using 2; rw ring_hom.map_zero },
  map_mul' := pb.constr_pow_mul hy,
  commutes' := pb.constr_pow_algebra_map hy,
  .. pb.basis.constr A (λ i, y ^ (i : ℕ)) }

@[simp] lemma lift_gen (pb : power_basis A S) (y : S')
  (hy : aeval y (minpoly A pb.gen) = 0) :
  pb.lift y hy pb.gen = y :=
pb.constr_pow_gen hy

@[simp] lemma lift_aeval (pb : power_basis A S) (y : S')
  (hy : aeval y (minpoly A pb.gen) = 0) (f : A[X]) :
  pb.lift y hy (aeval pb.gen f) = aeval y f :=
pb.constr_pow_aeval hy f

/-- `pb.lift_equiv` states that roots of the minimal polynomial of `pb.gen` correspond to
maps sending `pb.gen` to that root.

This is the bundled equiv version of `power_basis.lift`.
If the codomain of the `alg_hom`s is an integral domain, then the roots form a multiset,
see `lift_equiv'` for the corresponding statement.
-/
@[simps]
noncomputable def lift_equiv (pb : power_basis A S) :
  (S →ₐ[A] S') ≃ {y : S' // aeval y (minpoly A pb.gen) = 0} :=
{ to_fun := λ f, ⟨f pb.gen, by rw [aeval_alg_hom_apply, minpoly.aeval, f.map_zero]⟩,
  inv_fun := λ y, pb.lift y y.2,
  left_inv := λ f, pb.alg_hom_ext $ lift_gen _ _ _,
  right_inv := λ y, subtype.ext $ lift_gen _ _ y.prop }

/-- `pb.lift_equiv'` states that elements of the root set of the minimal
polynomial of `pb.gen` correspond to maps sending `pb.gen` to that root. -/
@[simps {fully_applied := ff}]
noncomputable def lift_equiv' (pb : power_basis A S) :
  (S →ₐ[A] B) ≃ {y : B // y ∈ ((minpoly A pb.gen).map (algebra_map A B)).roots} :=
pb.lift_equiv.trans ((equiv.refl _).subtype_equiv (λ x,
  begin
    rw [mem_roots, is_root.def, equiv.refl_apply, ← eval₂_eq_eval_map, ← aeval_def],
    exact map_monic_ne_zero (minpoly.monic pb.is_integral_gen)
  end))

/-- There are finitely many algebra homomorphisms `S →ₐ[A] B` if `S` is of the form `A[x]`
and `B` is an integral domain. -/
noncomputable def alg_hom.fintype (pb : power_basis A S) :
  fintype (S →ₐ[A] B) :=
by letI := classical.dec_eq B; exact
fintype.of_equiv _ pb.lift_equiv'.symm

/-- `pb.equiv_of_root pb' h₁ h₂` is an equivalence of algebras with the same power basis,
where "the same" means that `pb` is a root of `pb'`s minimal polynomial and vice versa.

See also `power_basis.equiv_of_minpoly` which takes the hypothesis that the
minimal polynomials are identical.
-/
@[simps apply {attrs := []}]
noncomputable def equiv_of_root
  (pb : power_basis A S) (pb' : power_basis A S')
  (h₁ : aeval pb.gen (minpoly A pb'.gen) = 0) (h₂ : aeval pb'.gen (minpoly A pb.gen) = 0) :
  S ≃ₐ[A] S' :=
alg_equiv.of_alg_hom
  (pb.lift pb'.gen h₂)
  (pb'.lift pb.gen h₁)
  (by { ext x, obtain ⟨f, hf, rfl⟩ := pb'.exists_eq_aeval' x, simp })
  (by { ext x, obtain ⟨f, hf, rfl⟩ := pb.exists_eq_aeval' x, simp })

@[simp]
lemma equiv_of_root_aeval
  (pb : power_basis A S) (pb' : power_basis A S')
  (h₁ : aeval pb.gen (minpoly A pb'.gen) = 0) (h₂ : aeval pb'.gen (minpoly A pb.gen) = 0)
  (f : A[X]) :
  pb.equiv_of_root pb' h₁ h₂ (aeval pb.gen f) = aeval pb'.gen f :=
pb.lift_aeval _ h₂ _

@[simp]
lemma equiv_of_root_gen
  (pb : power_basis A S) (pb' : power_basis A S')
  (h₁ : aeval pb.gen (minpoly A pb'.gen) = 0) (h₂ : aeval pb'.gen (minpoly A pb.gen) = 0) :
  pb.equiv_of_root pb' h₁ h₂ pb.gen = pb'.gen :=
pb.lift_gen _ h₂

@[simp]
lemma equiv_of_root_symm
  (pb : power_basis A S) (pb' : power_basis A S')
  (h₁ : aeval pb.gen (minpoly A pb'.gen) = 0) (h₂ : aeval pb'.gen (minpoly A pb.gen) = 0) :
  (pb.equiv_of_root pb' h₁ h₂).symm = pb'.equiv_of_root pb h₂ h₁ :=
rfl

/-- `pb.equiv_of_minpoly pb' h` is an equivalence of algebras with the same power basis,
where "the same" means that they have identical minimal polynomials.

See also `power_basis.equiv_of_root` which takes the hypothesis that each generator is a root of the
other basis' minimal polynomial; `power_basis.equiv_root` is more general if `A` is not a field.
-/
@[simps apply {attrs := []}]
noncomputable def equiv_of_minpoly
  (pb : power_basis A S) (pb' : power_basis A S')
  (h : minpoly A pb.gen = minpoly A pb'.gen) :
  S ≃ₐ[A] S' :=
pb.equiv_of_root pb' (h ▸ minpoly.aeval _ _) (h.symm ▸ minpoly.aeval _ _)

@[simp]
lemma equiv_of_minpoly_aeval
  (pb : power_basis A S) (pb' : power_basis A S')
  (h : minpoly A pb.gen = minpoly A pb'.gen)
  (f : A[X]) :
  pb.equiv_of_minpoly pb' h (aeval pb.gen f) = aeval pb'.gen f :=
pb.equiv_of_root_aeval pb' _ _ _

@[simp]
lemma equiv_of_minpoly_gen
  (pb : power_basis A S) (pb' : power_basis A S')
  (h : minpoly A pb.gen = minpoly A pb'.gen) :
  pb.equiv_of_minpoly pb' h pb.gen = pb'.gen :=
pb.equiv_of_root_gen pb' _ _

@[simp]
lemma equiv_of_minpoly_symm
  (pb : power_basis A S) (pb' : power_basis A S')
  (h : minpoly A pb.gen = minpoly A pb'.gen) :
  (pb.equiv_of_minpoly pb' h).symm = pb'.equiv_of_minpoly pb h.symm :=
rfl

end equiv

end power_basis

open power_basis

/-- Useful lemma to show `x` generates a power basis:
the powers of `x` less than the degree of `x`'s minimal polynomial are linearly independent. -/
lemma linear_independent_pow [algebra K S] (x : S) :
  linear_independent K (λ (i : fin (minpoly K x).nat_degree), x ^ (i : ℕ)) :=
begin
  by_cases is_integral K x, swap,
  { rw [minpoly.eq_zero h, nat_degree_zero], exact linear_independent_empty_type },
  refine fintype.linear_independent_iff.2 (λ g hg i, _),
  simp only at hg,
  simp_rw [algebra.smul_def, ← aeval_monomial, ← map_sum] at hg,
  apply (λ hn0, (minpoly.degree_le_of_ne_zero K x (mt (λ h0, _) hn0) hg).not_lt).mtr,
  { simp_rw ← C_mul_X_pow_eq_monomial,
    exact (degree_eq_nat_degree $ minpoly.ne_zero h).symm ▸ degree_sum_fin_lt _ },
  { apply_fun lcoeff K i at h0,
    simp_rw [map_sum, lcoeff_apply, coeff_monomial, fin.coe_eq_coe, finset.sum_ite_eq'] at h0,
    exact (if_pos $ finset.mem_univ _).symm.trans h0 },
end

lemma is_integral.mem_span_pow [nontrivial R] {x y : S} (hx : is_integral R x)
  (hy : ∃ f : R[X], y = aeval x f) :
  y ∈ submodule.span R (set.range (λ (i : fin (minpoly R x).nat_degree), x ^ (i : ℕ))) :=
begin
  obtain ⟨f, rfl⟩ := hy,
  apply mem_span_pow'.mpr _,
  have := minpoly.monic hx,
  refine ⟨f %ₘ minpoly R x, (degree_mod_by_monic_lt _ this).trans_le degree_le_nat_degree, _⟩,
  conv_lhs { rw ← mod_by_monic_add_div f this },
  simp only [add_zero, zero_mul, minpoly.aeval, aeval_add, alg_hom.map_mul]
end

namespace power_basis

section map

variables {S' : Type*} [comm_ring S'] [algebra R S']

/-- `power_basis.map pb (e : S ≃ₐ[R] S')` is the power basis for `S'` generated by `e pb.gen`. -/
@[simps dim gen basis]
noncomputable def map (pb : power_basis R S) (e : S ≃ₐ[R] S') : power_basis R S' :=
{ dim := pb.dim,
  basis := pb.basis.map e.to_linear_equiv,
  gen := e pb.gen,
  basis_eq_pow :=
    λ i, by rw [basis.map_apply, pb.basis_eq_pow, e.to_linear_equiv_apply, e.map_pow] }

variables [algebra A S] [algebra A S']

@[simp]
lemma minpoly_gen_map (pb : power_basis A S) (e : S ≃ₐ[A] S') :
  (pb.map e).minpoly_gen = pb.minpoly_gen :=
by { dsimp only [minpoly_gen, map_dim], -- Turn `fin (pb.map e).dim` into `fin pb.dim`
     simp only [linear_equiv.trans_apply, map_basis, basis.map_repr,
        map_gen, alg_equiv.to_linear_equiv_apply, e.to_linear_equiv_symm, alg_equiv.map_pow,
        alg_equiv.symm_apply_apply, sub_right_inj] }

@[simp]
lemma equiv_of_root_map (pb : power_basis A S) (e : S ≃ₐ[A] S')
  (h₁ h₂) :
  pb.equiv_of_root (pb.map e) h₁ h₂ = e :=
by { ext x, obtain ⟨f, rfl⟩ := pb.exists_eq_aeval' x, simp [aeval_alg_equiv] }

@[simp]
lemma equiv_of_minpoly_map (pb : power_basis A S) (e : S ≃ₐ[A] S')
  (h : minpoly A pb.gen = minpoly A (pb.map e).gen) :
  pb.equiv_of_minpoly (pb.map e) h = e :=
pb.equiv_of_root_map _ _ _

end map

section adjoin

open algebra

lemma adjoin_gen_eq_top (B : power_basis R S) : adjoin R ({B.gen} : set S) = ⊤ :=
begin
  rw [← to_submodule_eq_top, _root_.eq_top_iff, ← B.basis.span_eq, submodule.span_le],
  rintros x ⟨i, rfl⟩,
  rw [B.basis_eq_pow i],
  exact subalgebra.pow_mem _ (subset_adjoin (set.mem_singleton _)) _,
end

lemma adjoin_eq_top_of_gen_mem_adjoin {B : power_basis R S} {x : S}
  (hx : B.gen ∈ adjoin R ({x} : set S)) : adjoin R ({x} : set S) = ⊤ :=
begin
  rw [_root_.eq_top_iff, ← B.adjoin_gen_eq_top],
  refine adjoin_le _,
  simp [hx],
end

end adjoin

end power_basis
