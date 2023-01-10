/-
Copyright (c) 2018 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Chris Hughes
-/
import algebra.algebra.basic
import data.polynomial.field_division
import field_theory.minpoly.basic
import ring_theory.adjoin.basic
import ring_theory.finite_presentation
import ring_theory.finite_type
import ring_theory.power_basis
import ring_theory.principal_ideal_domain

/-!
# Adjoining roots of polynomials

This file defines the commutative ring `adjoin_root f`, the ring R[X]/(f) obtained from a
commutative ring `R` and a polynomial `f : R[X]`. If furthermore `R` is a field and `f` is
irreducible, the field structure on `adjoin_root f` is constructed.

We suggest stating results on `is_adjoin_root` instead of `adjoin_root` to achieve higher
generality, since `is_adjoin_root` works for all different constructions of `R[α]`
including `adjoin_root f = R[X]/(f)` itself.

## Main definitions and results

The main definitions are in the `adjoin_root` namespace.

*  `mk f : R[X] →+* adjoin_root f`, the natural ring homomorphism.

*  `of f : R →+* adjoin_root f`, the natural ring homomorphism.

* `root f : adjoin_root f`, the image of X in R[X]/(f).

* `lift (i : R →+* S) (x : S) (h : f.eval₂ i x = 0) : (adjoin_root f) →+* S`, the ring
  homomorphism from R[X]/(f) to S extending `i : R →+* S` and sending `X` to `x`.

* `lift_hom (x : S) (hfx : aeval x f = 0) : adjoin_root f →ₐ[R] S`, the algebra
  homomorphism from R[X]/(f) to S extending `algebra_map R S` and sending `X` to `x`

* `equiv : (adjoin_root f →ₐ[F] E) ≃ {x // x ∈ (f.map (algebra_map F E)).roots}` a
  bijection between algebra homomorphisms from `adjoin_root` and roots of `f` in `S`

-/
noncomputable theory
open_locale classical
open_locale big_operators polynomial

universes u v w

variables {R : Type u} {S : Type v} {K : Type w}

open polynomial ideal

/-- Adjoin a root of a polynomial `f` to a commutative ring `R`. We define the new ring
as the quotient of `R[X]` by the principal ideal generated by `f`. -/
def adjoin_root [comm_ring R] (f : R[X]) : Type u :=
polynomial R ⧸ (span {f} : ideal R[X])

namespace adjoin_root

section comm_ring
variables [comm_ring R] (f : R[X])

instance : comm_ring (adjoin_root f) := ideal.quotient.comm_ring _

instance : inhabited (adjoin_root f) := ⟨0⟩

instance : decidable_eq (adjoin_root f) := classical.dec_eq _

protected lemma nontrivial [is_domain R] (h : degree f ≠ 0) : nontrivial (adjoin_root f) :=
ideal.quotient.nontrivial
begin
  simp_rw [ne.def, span_singleton_eq_top, polynomial.is_unit_iff, not_exists, not_and],
  rintro x hx rfl,
  exact h (degree_C hx.ne_zero),
end

/-- Ring homomorphism from `R[x]` to `adjoin_root f` sending `X` to the `root`. -/
def mk : R[X] →+* adjoin_root f := ideal.quotient.mk _

@[elab_as_eliminator]
theorem induction_on {C : adjoin_root f → Prop} (x : adjoin_root f)
  (ih : ∀ p : R[X], C (mk f p)) : C x :=
quotient.induction_on' x ih

/-- Embedding of the original ring `R` into `adjoin_root f`. -/
def of : R →+* adjoin_root f := (mk f).comp C

instance [comm_semiring S] [algebra S R] : algebra S (adjoin_root f) :=
ideal.quotient.algebra S

instance [comm_semiring S] [comm_semiring K] [has_smul S K] [algebra S R] [algebra K R]
  [is_scalar_tower S K R] :
  is_scalar_tower S K (adjoin_root f) :=
submodule.quotient.is_scalar_tower _ _

instance [comm_semiring S] [comm_semiring K] [algebra S R] [algebra K R] [smul_comm_class S K R] :
  smul_comm_class S K (adjoin_root f) :=
submodule.quotient.smul_comm_class _ _

@[simp] lemma algebra_map_eq : algebra_map R (adjoin_root f) = of f := rfl

variables (S)

lemma algebra_map_eq' [comm_semiring S] [algebra S R] :
  algebra_map S (adjoin_root f) = (of f).comp (algebra_map S R) := rfl

variables {S}

lemma finite_type : algebra.finite_type R (adjoin_root f) :=
(algebra.finite_type.polynomial R).of_surjective _ (ideal.quotient.mkₐ_surjective R _)

lemma finite_presentation : algebra.finite_presentation R (adjoin_root f) :=
(algebra.finite_presentation.polynomial R).quotient (submodule.fg_span_singleton f)

/-- The adjoined root. -/
def root : adjoin_root f := mk f X

variables {f}

instance has_coe_t : has_coe_t R (adjoin_root f) := ⟨of f⟩

/-- Two `R`-`alg_hom` from `adjoin_root f` to the same `R`-algebra are the same iff
    they agree on `root f`. -/
@[ext] lemma alg_hom_ext [semiring S] [algebra R S] {g₁ g₂ : adjoin_root f →ₐ[R] S}
  (h : g₁ (root f) = g₂ (root f)) : g₁ = g₂ :=
ideal.quotient.alg_hom_ext R $ polynomial.alg_hom_ext h

@[simp] lemma mk_eq_mk {g h : R[X]} : mk f g = mk f h ↔ f ∣ g - h :=
ideal.quotient.eq.trans ideal.mem_span_singleton

@[simp] lemma mk_self : mk f f = 0 :=
quotient.sound' $ quotient_add_group.left_rel_apply.mpr (mem_span_singleton.2 $ by simp)

@[simp] lemma mk_C (x : R) : mk f (C x) = x := rfl

@[simp] lemma mk_X : mk f X = root f := rfl

@[simp] lemma aeval_eq (p : R[X]) : aeval (root f) p = mk f p :=
polynomial.induction_on p (λ x, by { rw aeval_C, refl })
  (λ p q ihp ihq, by rw [alg_hom.map_add, ring_hom.map_add, ihp, ihq])
  (λ n x ih, by { rw [alg_hom.map_mul, aeval_C, alg_hom.map_pow, aeval_X,
    ring_hom.map_mul, mk_C, ring_hom.map_pow, mk_X], refl })

theorem adjoin_root_eq_top : algebra.adjoin R ({root f} : set (adjoin_root f)) = ⊤ :=
algebra.eq_top_iff.2 $ λ x, induction_on f x $ λ p,
(algebra.adjoin_singleton_eq_range_aeval R (root f)).symm ▸ ⟨p, aeval_eq p⟩

@[simp] lemma eval₂_root (f : R[X]) : f.eval₂ (of f) (root f) = 0 :=
by rw [← algebra_map_eq, ← aeval_def, aeval_eq, mk_self]

lemma is_root_root (f : R[X]) : is_root (f.map (of f)) (root f) :=
by rw [is_root, eval_map, eval₂_root]

lemma is_algebraic_root (hf : f ≠ 0) : is_algebraic R (root f) :=
⟨f, hf, eval₂_root f⟩

variables [comm_ring S]

/-- Lift a ring homomorphism `i : R →+* S` to `adjoin_root f →+* S`. -/
def lift (i : R →+* S) (x : S) (h : f.eval₂ i x = 0) : (adjoin_root f) →+* S :=
begin
  apply ideal.quotient.lift _ (eval₂_ring_hom i x),
  intros g H,
  rcases mem_span_singleton.1 H with ⟨y, hy⟩,
  rw [hy, ring_hom.map_mul, coe_eval₂_ring_hom, h, zero_mul]
end

variables {i : R →+* S} {a : S} (h : f.eval₂ i a = 0)

@[simp] lemma lift_mk (g : R[X]) : lift i a h (mk f g) = g.eval₂ i a :=
ideal.quotient.lift_mk _ _ _

@[simp] lemma lift_root : lift i a h (root f) = a := by rw [root, lift_mk, eval₂_X]

@[simp] lemma lift_of {x : R} : lift i a h x = i x :=
by rw [← mk_C x, lift_mk, eval₂_C]

@[simp] lemma lift_comp_of : (lift i a h).comp (of f) = i :=
ring_hom.ext $ λ _, @lift_of _ _ _ _ _ _ _ h _

variables (f) [algebra R S]

/-- Produce an algebra homomorphism `adjoin_root f →ₐ[R] S` sending `root f` to
a root of `f` in `S`. -/
def lift_hom (x : S) (hfx : aeval x f = 0) : adjoin_root f →ₐ[R] S :=
{ commutes' := λ r, show lift _ _ hfx r = _, from lift_of hfx,
  .. lift (algebra_map R S) x hfx }

@[simp] lemma coe_lift_hom (x : S) (hfx : aeval x f = 0) :
  (lift_hom f x hfx : adjoin_root f →+* S) = lift (algebra_map R S) x hfx := rfl

@[simp] lemma aeval_alg_hom_eq_zero (ϕ : adjoin_root f →ₐ[R] S) : aeval (ϕ (root f)) f = 0 :=
begin
  have h : ϕ.to_ring_hom.comp (of f) = algebra_map R S := ring_hom.ext_iff.mpr (ϕ.commutes),
  rw [aeval_def, ←h, ←ring_hom.map_zero ϕ.to_ring_hom, ←eval₂_root f, hom_eval₂],
  refl,
end

@[simp] lemma lift_hom_eq_alg_hom (f : R[X]) (ϕ : adjoin_root f →ₐ[R] S) :
  lift_hom f (ϕ (root f)) (aeval_alg_hom_eq_zero f ϕ) = ϕ :=
begin
  suffices : ϕ.equalizer (lift_hom f (ϕ (root f)) (aeval_alg_hom_eq_zero f ϕ)) = ⊤,
  { exact (alg_hom.ext (λ x, (set_like.ext_iff.mp (this) x).mpr algebra.mem_top)).symm },
  rw [eq_top_iff, ←adjoin_root_eq_top, algebra.adjoin_le_iff, set.singleton_subset_iff],
  exact (@lift_root _ _ _ _ _ _ _ (aeval_alg_hom_eq_zero f ϕ)).symm,
end

variables (hfx : aeval a f = 0)

@[simp] lemma lift_hom_mk {g : R[X]} : lift_hom f a hfx (mk f g) = aeval a g :=
lift_mk hfx g

@[simp] lemma lift_hom_root : lift_hom f a hfx (root f) = a :=
lift_root hfx

@[simp] lemma lift_hom_of {x : R} : lift_hom f a hfx (of f x) = algebra_map _ _ x :=
lift_of hfx

section adjoin_inv

@[simp] lemma root_is_inv (r : R) : of _ r * root (C r * X - 1) = 1 :=
by convert sub_eq_zero.1 ((eval₂_sub _).symm.trans $ eval₂_root $ C r * X - 1);
  simp only [eval₂_mul, eval₂_C, eval₂_X, eval₂_one]

lemma alg_hom_subsingleton {S : Type*} [comm_ring S] [algebra R S] {r : R} :
  subsingleton (adjoin_root (C r * X - 1) →ₐ[R] S) :=
⟨λ f g, alg_hom_ext (@inv_unique _ _ (algebra_map R S r) _ _
  (by rw [← f.commutes, ← f.map_mul, algebra_map_eq, root_is_inv, map_one])
  (by rw [← g.commutes, ← g.map_mul, algebra_map_eq, root_is_inv, map_one]))⟩

end adjoin_inv

end comm_ring

section irreducible

variables [field K] {f : K[X]}

instance span_maximal_of_irreducible [fact (irreducible f)] : (span {f}).is_maximal :=
principal_ideal_ring.is_maximal_of_irreducible $ fact.out _

noncomputable instance field [fact (irreducible f)] : field (adjoin_root f) :=
{ ..adjoin_root.comm_ring f,
  ..ideal.quotient.field (span {f} : ideal K[X]) }

lemma coe_injective (h : degree f ≠ 0) : function.injective (coe : K → adjoin_root f) :=
have _ := adjoin_root.nontrivial f h, by exactI (of f).injective

lemma coe_injective' [fact (irreducible f)] : function.injective (coe : K → adjoin_root f) :=
(of f).injective

variable (f)

lemma mul_div_root_cancel [fact (irreducible f)] :
  ((X - C (root f)) * (f.map (of f) / (X - C (root f)))) = f.map (of f) :=
mul_div_eq_iff_is_root.2 $ is_root_root _

end irreducible

section is_noetherian_ring

instance [comm_ring R] [is_noetherian_ring R] {f : R[X]} : is_noetherian_ring (adjoin_root f) :=
ideal.quotient.is_noetherian_ring _

end is_noetherian_ring

section power_basis

variables [comm_ring R] {g : R[X]}

lemma is_integral_root' (hg : g.monic) : is_integral R (root g) :=
⟨g, hg, eval₂_root g⟩

/-- `adjoin_root.mod_by_monic_hom` sends the equivalence class of `f` mod `g` to `f %ₘ g`.

This is a well-defined right inverse to `adjoin_root.mk`, see `adjoin_root.mk_left_inverse`. -/
def mod_by_monic_hom (hg : g.monic) :
  adjoin_root g →ₗ[R] R[X] :=
(submodule.liftq _ (polynomial.mod_by_monic_hom g)
  (λ f (hf : f ∈ (ideal.span {g}).restrict_scalars R),
    (mem_ker_mod_by_monic hg).mpr (ideal.mem_span_singleton.mp hf))).comp $
(submodule.quotient.restrict_scalars_equiv R (ideal.span {g} : ideal R[X]))
  .symm.to_linear_map

@[simp] lemma mod_by_monic_hom_mk (hg : g.monic) (f : R[X]) :
  mod_by_monic_hom hg (mk g f) = f %ₘ g := rfl

lemma mk_left_inverse (hg : g.monic) :
  function.left_inverse (mk g) (mod_by_monic_hom hg) :=
λ f, induction_on g f $ λ f, begin
  rw [mod_by_monic_hom_mk hg, mk_eq_mk, mod_by_monic_eq_sub_mul_div _ hg,
      sub_sub_cancel_left, dvd_neg],
  apply dvd_mul_right
end

lemma mk_surjective (hg : g.monic) : function.surjective (mk g) :=
(mk_left_inverse hg).surjective

/-- The elements `1, root g, ..., root g ^ (d - 1)` form a basis for `adjoin_root g`,
where `g` is a monic polynomial of degree `d`. -/
def power_basis_aux' (hg : g.monic) :
  basis (fin g.nat_degree) R (adjoin_root g) :=
basis.of_equiv_fun
{ to_fun := λ f i, (mod_by_monic_hom hg f).coeff i,
  inv_fun := λ c, mk g $ ∑ (i : fin g.nat_degree), monomial i (c i),
  map_add' := λ f₁ f₂, funext $ λ i,
    by simp only [(mod_by_monic_hom hg).map_add, coeff_add, pi.add_apply],
  map_smul' := λ f₁ f₂, funext $ λ i,
    by simp only [(mod_by_monic_hom hg).map_smul, coeff_smul, pi.smul_apply, ring_hom.id_apply],
  left_inv := λ f, induction_on g f (λ f, eq.symm $ mk_eq_mk.mpr $
    by { simp only [mod_by_monic_hom_mk, sum_mod_by_monic_coeff hg degree_le_nat_degree],
         rw [mod_by_monic_eq_sub_mul_div _ hg, sub_sub_cancel],
         exact dvd_mul_right _ _ }),
  right_inv := λ x, funext $ λ i, begin
    nontriviality R,
    simp only [mod_by_monic_hom_mk],
    rw [(mod_by_monic_eq_self_iff hg).mpr, finset_sum_coeff, finset.sum_eq_single i];
      try { simp only [coeff_monomial, eq_self_iff_true, if_true] },
    { intros j _ hj, exact if_neg (fin.coe_injective.ne hj) },
    { intros, have := finset.mem_univ i, contradiction },
    { refine (degree_sum_le _ _).trans_lt ((finset.sup_lt_iff _).mpr (λ j _, _)),
      { exact bot_lt_iff_ne_bot.mpr (mt degree_eq_bot.mp hg.ne_zero) },
      { refine (degree_monomial_le _ _).trans_lt _,
        rw [degree_eq_nat_degree hg.ne_zero, with_bot.coe_lt_coe],
        exact j.2 } },
  end}

-- This was moved after the definition to prevent a timeout
attribute [simp] power_basis_aux'

/-- The power basis `1, root g, ..., root g ^ (d - 1)` for `adjoin_root g`,
where `g` is a monic polynomial of degree `d`. -/
@[simps] def power_basis' (hg : g.monic) : power_basis R (adjoin_root g) :=
{ gen := root g,
  dim := g.nat_degree,
  basis := power_basis_aux' hg,
  basis_eq_pow := λ i, begin
    simp only [power_basis_aux', basis.coe_of_equiv_fun, linear_equiv.coe_symm_mk],
    rw finset.sum_eq_single i,
    { rw [function.update_same, monomial_one_right_eq_X_pow, (mk g).map_pow, mk_X] },
    { intros j _ hj,
      rw ← monomial_zero_right _,
      convert congr_arg _ (function.update_noteq hj _ _) }, -- Fix `decidable_eq` mismatch
    { intros, have := finset.mem_univ i, contradiction },
  end}

variables [field K] {f : K[X]}

lemma is_integral_root (hf : f ≠ 0) : is_integral K (root f) :=
is_algebraic_iff_is_integral.mp (is_algebraic_root hf)

lemma minpoly_root (hf : f ≠ 0) : minpoly K (root f) = f * C (f.leading_coeff⁻¹) :=
begin
  have f'_monic : monic _ := monic_mul_leading_coeff_inv hf,
  refine (minpoly.unique K _ f'_monic _ _).symm,
  { rw [alg_hom.map_mul, aeval_eq, mk_self, zero_mul] },
  intros q q_monic q_aeval,
  have commutes : (lift (algebra_map K (adjoin_root f)) (root f) q_aeval).comp (mk q) = mk f,
  { ext,
    { simp only [ring_hom.comp_apply, mk_C, lift_of], refl },
    { simp only [ring_hom.comp_apply, mk_X, lift_root] } },
  rw [degree_eq_nat_degree f'_monic.ne_zero, degree_eq_nat_degree q_monic.ne_zero,
      with_bot.coe_le_coe, nat_degree_mul hf, nat_degree_C, add_zero],
  apply nat_degree_le_of_dvd,
  { have : mk f q = 0, by rw [←commutes, ring_hom.comp_apply, mk_self, ring_hom.map_zero],
    rwa [←ideal.mem_span_singleton, ←ideal.quotient.eq_zero_iff_mem] },
  { exact q_monic.ne_zero },
  { rwa [ne.def, C_eq_zero, inv_eq_zero, leading_coeff_eq_zero] },
end

/-- The elements `1, root f, ..., root f ^ (d - 1)` form a basis for `adjoin_root f`,
where `f` is an irreducible polynomial over a field of degree `d`. -/
def power_basis_aux (hf : f ≠ 0) : basis (fin f.nat_degree) K (adjoin_root f) :=
begin
  set f' := f * C (f.leading_coeff⁻¹) with f'_def,
  have deg_f' : f'.nat_degree = f.nat_degree,
  { rw [nat_degree_mul hf, nat_degree_C, add_zero],
    { rwa [ne.def, C_eq_zero, inv_eq_zero, leading_coeff_eq_zero] } },
  have minpoly_eq : minpoly K (root f) = f' := minpoly_root hf,
  apply @basis.mk _ _ _ (λ (i : fin f.nat_degree), (root f ^ i.val)),
  { rw [← deg_f', ← minpoly_eq],
    exact (is_integral_root hf).linear_independent_pow },
  { rintros y -,
    rw [← deg_f', ← minpoly_eq],
    apply (is_integral_root hf).mem_span_pow,
    obtain ⟨g⟩ := y,
    use g,
    rw aeval_eq,
    refl }
end

/-- The power basis `1, root f, ..., root f ^ (d - 1)` for `adjoin_root f`,
where `f` is an irreducible polynomial over a field of degree `d`. -/
@[simps] def power_basis (hf : f ≠ 0) :
  power_basis K (adjoin_root f) :=
{ gen := root f,
  dim := f.nat_degree,
  basis := power_basis_aux hf,
  basis_eq_pow := basis.mk_apply _ _ }

lemma minpoly_power_basis_gen (hf : f ≠ 0) :
  minpoly K (power_basis hf).gen = f * C (f.leading_coeff⁻¹) :=
by rw [power_basis_gen, minpoly_root hf]

lemma minpoly_power_basis_gen_of_monic (hf : f.monic) (hf' : f ≠ 0 := hf.ne_zero) :
  minpoly K (power_basis hf').gen = f :=
by rw [minpoly_power_basis_gen hf', hf.leading_coeff, inv_one, C.map_one, mul_one]

end power_basis

section equiv

section minpoly

variables [comm_ring R] [comm_ring S] [algebra R S] (x : S) (R)

open algebra polynomial

/-- The surjective algebra morphism `R[X]/(minpoly R x) → R[x]`.
If `R` is a GCD domain and `x` is integral, this is an isomorphism,
see `adjoin_root.minpoly.equiv_adjoin`. -/
@[simps] def minpoly.to_adjoin : adjoin_root (minpoly R x) →ₐ[R] adjoin R ({x} : set S) :=
lift_hom _ ⟨x, self_mem_adjoin_singleton R x⟩
  (by simp [← subalgebra.coe_eq_zero, aeval_subalgebra_coe])

variables {R x}

lemma minpoly.to_adjoin_apply' (a : adjoin_root (minpoly R x)) : minpoly.to_adjoin R x a =
  lift_hom (minpoly R x) (⟨x, self_mem_adjoin_singleton R x⟩ : adjoin R ({x} : set S))
  (by simp [← subalgebra.coe_eq_zero, aeval_subalgebra_coe]) a := rfl

lemma minpoly.to_adjoin.apply_X : minpoly.to_adjoin R x (mk (minpoly R x) X) =
  ⟨x, self_mem_adjoin_singleton R x⟩ :=
by simp

variables (R x)

lemma minpoly.to_adjoin.surjective : function.surjective (minpoly.to_adjoin R x) :=
begin
  rw [← range_top_iff_surjective, _root_.eq_top_iff, ← adjoin_adjoin_coe_preimage],
  refine adjoin_le _,
  simp only [alg_hom.coe_range, set.mem_range],
  rintro ⟨y₁, y₂⟩ h,
  refine ⟨mk (minpoly R x) X, by simpa using h.symm⟩
end

end minpoly

section is_domain

variables [comm_ring R] [is_domain R] [comm_ring S] [is_domain S] [algebra R S]
variables (g : R[X]) (pb : _root_.power_basis R S)

/-- If `S` is an extension of `R` with power basis `pb` and `g` is a monic polynomial over `R`
such that `pb.gen` has a minimal polynomial `g`, then `S` is isomorphic to `adjoin_root g`.

Compare `power_basis.equiv_of_root`, which would require
`h₂ : aeval pb.gen (minpoly R (root g)) = 0`; that minimal polynomial is not
guaranteed to be identical to `g`. -/
@[simps {fully_applied := ff}]
def equiv' (h₁ : aeval (root g) (minpoly R pb.gen) = 0) (h₂ : aeval pb.gen g = 0) :
  adjoin_root g ≃ₐ[R] S :=
{ to_fun := adjoin_root.lift_hom g pb.gen h₂,
  inv_fun := pb.lift (root g) h₁,
  left_inv := λ x, induction_on g x $ λ f, by rw [lift_hom_mk, pb.lift_aeval, aeval_eq],
  right_inv := λ x, begin
    obtain ⟨f, hf, rfl⟩ := pb.exists_eq_aeval x,
    rw [pb.lift_aeval, aeval_eq, lift_hom_mk]
  end,
  .. adjoin_root.lift_hom g pb.gen h₂ }

@[simp] lemma equiv'_to_alg_hom
  (h₁ : aeval (root g) (minpoly R pb.gen) = 0) (h₂ : aeval pb.gen g = 0) :
  (equiv' g pb h₁ h₂).to_alg_hom = adjoin_root.lift_hom g pb.gen h₂ :=
rfl

@[simp] lemma equiv'_symm_to_alg_hom
  (h₁ : aeval (root g) (minpoly R pb.gen) = 0) (h₂ : aeval pb.gen g = 0) :
  (equiv' g pb h₁ h₂).symm.to_alg_hom = pb.lift (root g) h₁ :=
rfl

end is_domain

section field

variables (K) (L F : Type*) [field F] [field K] [field L] [algebra F K] [algebra F L]
variables (pb : _root_.power_basis F K)

/-- If `L` is a field extension of `F` and `f` is a polynomial over `F` then the set
of maps from `F[x]/(f)` into `L` is in bijection with the set of roots of `f` in `L`. -/
def equiv (f : F[X]) (hf : f ≠ 0) :
  (adjoin_root f →ₐ[F] L) ≃ {x // x ∈ (f.map (algebra_map F L)).roots} :=
(power_basis hf).lift_equiv'.trans ((equiv.refl _).subtype_equiv (λ x,
  begin
    rw [power_basis_gen, minpoly_root hf, polynomial.map_mul, roots_mul,
        polynomial.map_C, roots_C, add_zero, equiv.refl_apply],
    { rw ← polynomial.map_mul, exact map_monic_ne_zero (monic_mul_leading_coeff_inv hf) }
  end))

end field

end equiv

section

open ideal double_quot polynomial

variables [comm_ring R] (I : ideal R) (f : R[X])

/-- The natural isomorphism `R[α]/(I[α]) ≅ R[α]/((I[x] ⊔ (f)) / (f))` for `α` a root of
`f : R[X]` and `I : ideal R`.

See `adjoin_root.quot_map_of_equiv` for the isomorphism with `(R/I)[X] / (f mod I)`. -/
def quot_map_of_equiv_quot_map_C_map_span_mk :
  adjoin_root f ⧸ I.map (of f) ≃+*
    adjoin_root f ⧸ (I.map (C : R →+* R[X])).map (span {f})^.quotient.mk :=
ideal.quot_equiv_of_eq (by rw [of, adjoin_root.mk, ideal.map_map])

@[simp]
lemma quot_map_of_equiv_quot_map_C_map_span_mk_mk (x : adjoin_root f) :
  quot_map_of_equiv_quot_map_C_map_span_mk I f (ideal.quotient.mk (I.map (of f)) x) =
    ideal.quotient.mk _ x :=
rfl

--this lemma should have the simp tag but this causes a lint issue
lemma quot_map_of_equiv_quot_map_C_map_span_mk_symm_mk (x : adjoin_root f) :
  (quot_map_of_equiv_quot_map_C_map_span_mk I f).symm
  (ideal.quotient.mk ((I.map (C : R →+* R[X])).map (span {f})^.quotient.mk) x) =
    ideal.quotient.mk (I.map (of f)) x :=
by rw [quot_map_of_equiv_quot_map_C_map_span_mk, ideal.quot_equiv_of_eq_symm, quot_equiv_of_eq_mk]

/-- The natural isomorphism `R[α]/((I[x] ⊔ (f)) / (f)) ≅ (R[x]/I[x])/((f) ⊔ I[x] / I[x])`
  for `α` a root of `f : R[X]` and `I : ideal R`-/
def quot_map_C_map_span_mk_equiv_quot_map_C_quot_map_span_mk :
  (adjoin_root f) ⧸ (I.map (C : R →+* R[X])).map (span ({f} : set R[X]))^.quotient.mk ≃+*
    (R[X] ⧸ I.map (C : R →+* R[X])) ⧸ (span ({f} : set R[X])).map
    (I.map (C : R →+* R[X]))^.quotient.mk :=
quot_quot_equiv_comm (ideal.span ({f} : set R[X])) (I.map (C : R →+* R[X]))

@[simp]
lemma quot_map_C_map_span_mk_equiv_quot_map_C_quot_map_span_mk_mk (p : R[X]) :
  quot_map_C_map_span_mk_equiv_quot_map_C_quot_map_span_mk I f (ideal.quotient.mk _ (mk f p)) =
    quot_quot_mk (I.map C) (span {f}) p :=
rfl

@[simp]
lemma quot_map_C_map_span_mk_equiv_quot_map_C_quot_map_span_mk_symm_quot_quot_mk (p : R[X]) :
  (quot_map_C_map_span_mk_equiv_quot_map_C_quot_map_span_mk I f).symm
  (quot_quot_mk (I.map C) (span {f}) p) = (ideal.quotient.mk _ (mk f p)) :=
rfl

/-- The natural isomorphism `(R/I)[x]/(f mod I) ≅ (R[x]/I*R[x])/(f mod I[x])` where
  `f : R[X]` and `I : ideal R`-/
def polynomial.quot_quot_equiv_comm :
  (R ⧸ I)[X] ⧸ span ({f.map (I^.quotient.mk)} : set (polynomial (R ⧸ I))) ≃+*
    (R[X] ⧸ map C I) ⧸ span ({(ideal.quotient.mk (I.map C)) f} : set (R[X] ⧸ map C I)) :=
quotient_equiv (span ({f.map (I^.quotient.mk)} : set (polynomial (R ⧸ I))))
  (span {ideal.quotient.mk (I.map polynomial.C) f})
  (polynomial_quotient_equiv_quotient_polynomial I)
  (by rw [map_span, set.image_singleton, ring_equiv.coe_to_ring_hom,
    polynomial_quotient_equiv_quotient_polynomial_map_mk I f])

@[simp]
lemma polynomial.quot_quot_equiv_comm_mk (p : R[X]) :
  (polynomial.quot_quot_equiv_comm I f) (ideal.quotient.mk  _ (p.map I^.quotient.mk)) =
  (ideal.quotient.mk _ (ideal.quotient.mk _ p)) :=
by simp only [polynomial.quot_quot_equiv_comm, quotient_equiv_mk,
  polynomial_quotient_equiv_quotient_polynomial_map_mk]

@[simp]
lemma polynomial.quot_quot_equiv_comm_symm_mk_mk (p : R[X]) :
  (polynomial.quot_quot_equiv_comm I f).symm (ideal.quotient.mk _ (ideal.quotient.mk _ p)) =
    (ideal.quotient.mk  _ (p.map I^.quotient.mk)) :=
by simp only [polynomial.quot_quot_equiv_comm, quotient_equiv_symm_mk,
  polynomial_quotient_equiv_quotient_polynomial_symm_mk]

/-- The natural isomorphism `R[α]/I[α] ≅ (R/I)[X]/(f mod I)` for `α` a root of `f : R[X]`
  and `I : ideal R`.-/
def quot_adjoin_root_equiv_quot_polynomial_quot : (adjoin_root f) ⧸ (I.map (of f)) ≃+*
  (R ⧸ I)[X] ⧸ (span ({f.map (I^.quotient.mk)} : set (R ⧸ I)[X])) :=
(quot_map_of_equiv_quot_map_C_map_span_mk I f).trans
  ((quot_map_C_map_span_mk_equiv_quot_map_C_quot_map_span_mk I f).trans
  ((ideal.quot_equiv_of_eq
  (show (span ({f} : set R[X])).map (I.map (C : R →+* R[X]))^.quotient.mk =
    span ({(ideal.quotient.mk (I.map polynomial.C)) f} : set (R[X] ⧸ map C I)),
    from by rw [map_span, set.image_singleton])).trans
  (polynomial.quot_quot_equiv_comm I f).symm))

@[simp]
lemma quot_adjoin_root_equiv_quot_polynomial_quot_mk_of (p : R[X]) :
  quot_adjoin_root_equiv_quot_polynomial_quot I f (ideal.quotient.mk (I.map (of f)) (mk f p)) =
    ideal.quotient.mk (span ({f.map (I^.quotient.mk)} : set (R ⧸ I)[X]))
    (p.map I^.quotient.mk) :=
by rw [quot_adjoin_root_equiv_quot_polynomial_quot, ring_equiv.trans_apply, ring_equiv.trans_apply,
    ring_equiv.trans_apply, quot_map_of_equiv_quot_map_C_map_span_mk_mk,
    quot_map_C_map_span_mk_equiv_quot_map_C_quot_map_span_mk_mk, quot_quot_mk, ring_hom.comp_apply,
    quot_equiv_of_eq_mk, polynomial.quot_quot_equiv_comm_symm_mk_mk]

@[simp]
lemma quot_adjoin_root_equiv_quot_polynomial_quot_symm_mk_mk (p : R[X]) :
  (quot_adjoin_root_equiv_quot_polynomial_quot I f).symm
  (ideal.quotient.mk (span ({f.map (I^.quotient.mk)} : set (R ⧸ I)[X]))
    (p.map I^.quotient.mk)) = (ideal.quotient.mk (I.map (of f)) (mk f p)) :=
by rw [quot_adjoin_root_equiv_quot_polynomial_quot, ring_equiv.symm_trans_apply,
    ring_equiv.symm_trans_apply, ring_equiv.symm_trans_apply, ring_equiv.symm_symm,
    polynomial.quot_quot_equiv_comm_mk, ideal.quot_equiv_of_eq_symm,
    ideal.quot_equiv_of_eq_mk, ← ring_hom.comp_apply, ← double_quot.quot_quot_mk,
    quot_map_C_map_span_mk_equiv_quot_map_C_quot_map_span_mk_symm_quot_quot_mk,
    quot_map_of_equiv_quot_map_C_map_span_mk_symm_mk]

/-- Promote `adjoin_root.quot_adjoin_root_equiv_quot_polynomial_quot` to an alg_equiv.  -/
@[simps apply symm_apply]
noncomputable def quot_equiv_quot_map (f : R[X]) (I : ideal R) :
  ((adjoin_root f) ⧸ (ideal.map (of f) I)) ≃ₐ[R]
     ((R ⧸ I) [X]) ⧸ (ideal.span ({polynomial.map I^.quotient.mk f} : set ((R ⧸ I) [X]))) :=
alg_equiv.of_ring_equiv (show ∀ x, (quot_adjoin_root_equiv_quot_polynomial_quot I f)
  (algebra_map R _ x) = algebra_map R _ x, from λ x, begin
    have : algebra_map R ((adjoin_root f) ⧸ (ideal.map (of f) I)) x = ideal.quotient.mk
      (ideal.map (adjoin_root.of f) I) ((mk f) (C x)) := rfl,
    simpa only [this, quot_adjoin_root_equiv_quot_polynomial_quot_mk_of, map_C]
  end)

@[simp]
lemma quot_equiv_quot_map_apply_mk (f g : R[X]) (I : ideal R)  :
  adjoin_root.quot_equiv_quot_map f I (ideal.quotient.mk _ (adjoin_root.mk f g)) =
    ideal.quotient.mk _ (g.map I^.quotient.mk) :=
by rw [adjoin_root.quot_equiv_quot_map_apply,
    adjoin_root.quot_adjoin_root_equiv_quot_polynomial_quot_mk_of]

@[simp]
lemma quot_equiv_quot_map_symm_apply_mk (f g : R[X]) (I : ideal R)  :
  (adjoin_root.quot_equiv_quot_map f I).symm (ideal.quotient.mk _ (map (ideal.quotient.mk I) g)) =
    ideal.quotient.mk _ (adjoin_root.mk f g) :=
by rw [adjoin_root.quot_equiv_quot_map_symm_apply,
    adjoin_root.quot_adjoin_root_equiv_quot_polynomial_quot_symm_mk_mk]

end

end adjoin_root

namespace power_basis

open adjoin_root alg_equiv

variables [comm_ring R] [is_domain R] [comm_ring S] [is_domain S] [algebra R S]

/-- Let `α` have minimal polynomial `f` over `R` and `I` be an ideal of `R`,
then `R[α] / (I) = (R[x] / (f)) / pS = (R/p)[x] / (f mod p)`. -/
@[simps apply symm_apply]
noncomputable def quotient_equiv_quotient_minpoly_map (pb : power_basis R S)
  (I : ideal R) :
  (S ⧸ I.map (algebra_map R S)) ≃ₐ[R] (polynomial (R ⧸ I)) ⧸
    (ideal.span ({(minpoly R pb.gen).map I^.quotient.mk} : set (polynomial (R ⧸ I)))) :=
(of_ring_equiv
  (show ∀ x, (ideal.quotient_equiv _ (ideal.map (adjoin_root.of (minpoly R pb.gen)) I)
    (adjoin_root.equiv' (minpoly R pb.gen) pb
    (by rw [adjoin_root.aeval_eq, adjoin_root.mk_self])
    (minpoly.aeval _ _)).symm.to_ring_equiv
    (by rw [ideal.map_map, alg_equiv.to_ring_equiv_eq_coe, ← alg_equiv.coe_ring_hom_commutes,
          ← adjoin_root.algebra_map_eq, alg_hom.comp_algebra_map]))
    (algebra_map R (S ⧸ I.map (algebra_map R S)) x) = algebra_map R _ x, from
  (λ x, by rw [← ideal.quotient.mk_algebra_map, ideal.quotient_equiv_apply,
    ring_hom.to_fun_eq_coe, ideal.quotient_map_mk, alg_equiv.to_ring_equiv_eq_coe,
    ring_equiv.coe_to_ring_hom, alg_equiv.coe_ring_equiv, alg_equiv.commutes,
    quotient.mk_algebra_map]))).trans (adjoin_root.quot_equiv_quot_map _ _)

@[simp]
lemma quotient_equiv_quotient_minpoly_map_apply_mk (pb : power_basis R S) (I : ideal R)
  (g : R[X]) : pb.quotient_equiv_quotient_minpoly_map I
  (ideal.quotient.mk _ (aeval pb.gen g)) = ideal.quotient.mk _ (g.map I^.quotient.mk) :=
by rw [power_basis.quotient_equiv_quotient_minpoly_map, alg_equiv.trans_apply,
    alg_equiv.of_ring_equiv_apply, quotient_equiv_mk, alg_equiv.coe_ring_equiv',
    adjoin_root.equiv'_symm_apply, power_basis.lift_aeval,
    adjoin_root.aeval_eq, adjoin_root.quot_equiv_quot_map_apply_mk]

@[simp]
lemma quotient_equiv_quotient_minpoly_map_symm_apply_mk (pb : power_basis R S) (I : ideal R)
  (g : R[X]) : (pb.quotient_equiv_quotient_minpoly_map I).symm
  (ideal.quotient.mk _ (g.map I^.quotient.mk)) = (ideal.quotient.mk _ (aeval pb.gen g)) :=
begin simp only [quotient_equiv_quotient_minpoly_map, to_ring_equiv_eq_coe, symm_trans_apply,
    quot_equiv_quot_map_symm_apply_mk, of_ring_equiv_symm_apply, quotient_equiv_symm_mk,
    to_ring_equiv_symm, ring_equiv.symm_symm, adjoin_root.equiv'_apply, coe_ring_equiv,
    lift_hom_mk, symm_to_ring_equiv],

end

end power_basis
