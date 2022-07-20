/-
Copyright (c) 2022 Jujian Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Andrew Yang, Jujian Zhang
-/

import group_theory.monoid_localization
import ring_theory.localization.basic

/-!
# Localized Module

Given a commutative ring `R`, a multiplicative subset `S ⊆ R` and an `R`-module `M`, we can localize
`M` by `S`. This gives us a `localization S`-module.

## Main definitions

* `localized_module.r` : the equivalence relation defining this localization, namely
  `(m, s) ≈ (m', s')` if and only if if there is some `u : S` such that `u • s' • m = u • s • m'`.
* `localized_module M S` : the localized module by `S`.
* `localized_module.mk`  : the canonical map sending `(m, s) : M × S ↦ m/s : localized_module M S`
* `localized_module.lift_on` : any well defined function `f : M × S → α` respecting `r` descents to
  a function `localized_module M S → α`
* `localized_module.lift_on₂` : any well defined function `f : M × S → M × S → α` respecting `r`
  descents to a function `localized_module M S → localized_module M S`
* `localized_module.mk_add_mk` : in the localized module
  `mk m s + mk m' s' = mk (s' • m + s • m') (s * s')`
* `localized_module.mk_smul_mk` : in the localized module, for any `r : R`, `s t : S`, `m : M`,
  we have `mk r s • mk m t = mk (r • m) (s * t)` where `mk r s : localization S` is localized ring
  by `S`.
* `localized_module.is_module` : `localized_module M S` is a `localization S`-module.

## Future work

 * Redefine `localization` for monoids and rings to coincide with `localized_module`.
-/


namespace localized_module

universes u v

variables {R : Type u} [comm_semiring R] (S : submonoid R)
variables (M : Type v) [add_comm_monoid M] [module R M]

/--The equivalence relation on `M × S` where `(m1, s1) ≈ (m2, s2)` if and only if
for some (u : S), u * (s2 • m1 - s1 • m2) = 0-/
def r : (M × S) → (M × S) → Prop
| ⟨m1, s1⟩ ⟨m2, s2⟩ := ∃ (u : S), u • s1 • m2 = u • s2 • m1

lemma r.is_equiv : is_equiv _ (r S M) :=
{ refl := λ ⟨m, s⟩, ⟨1, by rw [one_smul]⟩,
  trans := λ ⟨m1, s1⟩ ⟨m2, s2⟩ ⟨m3, s3⟩ ⟨u1, hu1⟩ ⟨u2, hu2⟩, begin
    use u1 * u2 * s2,
    -- Put everything in the same shape, sorting the terms using `simp`
    have hu1' := congr_arg ((•) (u2 * s3)) hu1,
    have hu2' := congr_arg ((•) (u1 * s1)) hu2,
    simp only [← mul_smul, smul_assoc, mul_assoc, mul_comm, mul_left_comm] at ⊢ hu1' hu2',
    rw [hu2', hu1']
  end,
  symm := λ ⟨m1, s1⟩ ⟨m2, s2⟩ ⟨u, hu⟩, ⟨u, hu.symm⟩ }


instance r.setoid : setoid (M × S) :=
{ r := r S M,
  iseqv := ⟨(r.is_equiv S M).refl, (r.is_equiv S M).symm, (r.is_equiv S M).trans⟩ }

/--
If `S` is a multiplicative subset of a ring `R` and `M` an `R`-module, then
we can localize `M` by `S`.
-/
@[nolint has_inhabited_instance]
def _root_.localized_module : Type (max u v) := quotient (r.setoid S M)

section
variables {M S}

/--The canonical map sending `(m, s) ↦ m/s`-/
def mk (m : M) (s : S) : localized_module S M :=
quotient.mk ⟨m, s⟩

lemma mk_eq {m m' : M} {s s' : S} : mk m s = mk m' s' ↔ ∃ (u : S), u • s • m' = u • s' • m :=
quotient.eq

@[elab_as_eliminator]
lemma induction_on {β : localized_module S M → Prop} (h : ∀ (m : M) (s : S), β (mk m s)) :
  ∀ (x : localized_module S M), β x :=
by { rintro ⟨⟨m, s⟩⟩, exact h m s }

@[elab_as_eliminator]
lemma induction_on₂ {β : localized_module S M → localized_module S M → Prop}
  (h : ∀ (m m' : M) (s s' : S), β (mk m s) (mk m' s')) : ∀ x y, β x y :=
by { rintro ⟨⟨m, s⟩⟩ ⟨⟨m', s'⟩⟩, exact h m m' s s' }

/--If `f : M × S → α` respects the equivalence relation `localized_module.r`, then
`f` descents to a map `localized_module M S → α`.
-/
def lift_on {α : Type*} (x : localized_module S M) (f : M × S → α)
  (wd : ∀ (p p' : M × S) (h1 : p ≈ p'), f p = f p') : α :=
quotient.lift_on x f wd

lemma lift_on_mk {α : Type*} {f : M × S → α}
  (wd : ∀ (p p' : M × S) (h1 : p ≈ p'), f p = f p')
  (m : M) (s : S) :
  lift_on (mk m s) f wd = f ⟨m, s⟩ :=
by convert quotient.lift_on_mk f wd ⟨m, s⟩

/--If `f : M × S → M × S → α` respects the equivalence relation `localized_module.r`, then
`f` descents to a map `localized_module M S → localized_module M S → α`.
-/
def lift_on₂ {α : Type*} (x y : localized_module S M) (f : (M × S) → (M × S) → α)
  (wd : ∀ (p q p' q' : M × S) (h1 : p ≈ p') (h2 : q ≈ q'), f p q = f p' q') : α :=
quotient.lift_on₂ x y f wd

lemma lift_on₂_mk {α : Type*} (f : (M × S) → (M × S) → α)
  (wd : ∀ (p q p' q' : M × S) (h1 : p ≈ p') (h2 : q ≈ q'), f p q = f p' q')
  (m m' : M) (s s' : S) :
  lift_on₂ (mk m s) (mk m' s') f wd = f ⟨m, s⟩ ⟨m', s'⟩ :=
by convert quotient.lift_on₂_mk f wd _ _

instance : has_zero (localized_module S M) := ⟨mk 0 1⟩
lemma zero_mk (s : S) : mk (0 : M) s = 0 :=
mk_eq.mpr ⟨1, by rw [one_smul, smul_zero, smul_zero, one_smul]⟩

instance : has_add (localized_module S M) :=
{ add := λ p1 p2, lift_on₂ p1 p2 (λ x y, mk (y.2 • x.1 + x.2 • y.1) (x.2 * y.2)) $
    λ ⟨m1, s1⟩ ⟨m2, s2⟩ ⟨m1', s1'⟩ ⟨m2', s2'⟩ ⟨u1, hu1⟩ ⟨u2, hu2⟩, mk_eq.mpr ⟨u1 * u2, begin
      -- Put everything in the same shape, sorting the terms using `simp`
      have hu1' := congr_arg ((•) (u2 * s2 * s2')) hu1,
      have hu2' := congr_arg ((•) (u1 * s1 * s1')) hu2,
      simp only [smul_add, ← mul_smul, smul_assoc, mul_assoc, mul_comm, mul_left_comm]
        at ⊢ hu1' hu2',
      rw [hu1', hu2']
    end⟩ }

lemma mk_add_mk {m1 m2 : M} {s1 s2 : S} :
  mk m1 s1 + mk m2 s2 = mk (s2 • m1 + s1 • m2) (s1 * s2) :=
mk_eq.mpr $ ⟨1, by dsimp only; rw [one_smul]⟩

private lemma add_assoc' (x y z : localized_module S M) :
  x + y + z = x + (y + z) :=
begin
  induction x using localized_module.induction_on with mx sx,
  induction y using localized_module.induction_on with my sy,
  induction z using localized_module.induction_on with mz sz,
  simp only [mk_add_mk, smul_add],
  refine mk_eq.mpr ⟨1, _⟩,
  rw [one_smul, one_smul],
  congr' 1,
  { rw [mul_assoc] },
  { rw [mul_comm, add_assoc, mul_smul, mul_smul, ←mul_smul sx sz, mul_comm, mul_smul], },
end

private lemma add_comm' (x y : localized_module S M) :
  x + y = y + x :=
localized_module.induction_on₂ (λ m m' s s', by rw [mk_add_mk, mk_add_mk, add_comm, mul_comm]) x y

private lemma zero_add' (x : localized_module S M) : 0 + x = x :=
induction_on (λ m s, by rw [← zero_mk s, mk_add_mk, smul_zero, zero_add, mk_eq];
  exact ⟨1, by rw [one_smul, mul_smul, one_smul]⟩) x

private lemma add_zero' (x : localized_module S M) : x + 0 = x :=
induction_on (λ m s, by rw [← zero_mk s, mk_add_mk, smul_zero, add_zero, mk_eq];
  exact ⟨1, by rw [one_smul, mul_smul, one_smul]⟩) x

instance has_nat_smul : has_smul ℕ (localized_module S M) :=
{ smul := λ n, nsmul_rec n }

private lemma nsmul_zero' (x : localized_module S M) : (0 : ℕ) • x = 0 :=
localized_module.induction_on (λ _ _, rfl) x
private lemma nsmul_succ' (n : ℕ) (x : localized_module S M) :
  n.succ • x = x + n • x :=
localized_module.induction_on (λ _ _, rfl) x

instance : add_comm_monoid (localized_module S M) :=
{ add := (+),
  add_assoc := add_assoc',
  zero := 0,
  zero_add := zero_add',
  add_zero := add_zero',
  nsmul := (•),
  nsmul_zero' := nsmul_zero',
  nsmul_succ' := nsmul_succ',
  add_comm := add_comm' }

instance : has_smul (localization S) (localized_module S M) :=
{ smul := λ f x, localization.lift_on f (λ r s, lift_on x (λ p, mk (r • p.1) (s * p.2))
    begin
      rintros ⟨m1, t1⟩ ⟨m2, t2⟩ ⟨u, h⟩,
      refine mk_eq.mpr ⟨u, _⟩,
      have h' := congr_arg ((•) (s • r)) h,
      simp only [← mul_smul, smul_assoc, mul_comm, mul_left_comm, submonoid.smul_def,
        submonoid.coe_mul] at ⊢ h',
      rw h',
    end) begin
      induction x using localized_module.induction_on with m t,
      rintros r r' s s' h,
      simp only [lift_on_mk, lift_on_mk, mk_eq],
      obtain ⟨u, eq1⟩ := localization.r_iff_exists.mp h,
      use u,
      have eq1' := congr_arg (• (t • m)) eq1,
      simp only [← mul_smul, smul_assoc, submonoid.smul_def, submonoid.coe_mul] at ⊢ eq1',
      ring_nf at ⊢ eq1',
      rw eq1'
    end }

lemma mk_smul_mk (r : R) (m : M) (s t : S) :
  localization.mk r s • mk m t = mk (r • m) (s * t) :=
begin
  unfold has_smul.smul,
  rw [localization.lift_on_mk, lift_on_mk],
end

private lemma one_smul' (m : localized_module S M) :
  (1 : localization S) • m = m :=
begin
  induction m using localized_module.induction_on with m s,
  rw [← localization.mk_one, mk_smul_mk, one_smul, one_mul],
end

private lemma mul_smul' (x y : localization S) (m : localized_module S M) :
  (x * y) • m = x • y • m :=
begin
  induction x using localization.induction_on with data,
  induction y using localization.induction_on with data',
  rcases ⟨data, data'⟩ with ⟨⟨r, s⟩, ⟨r', s'⟩⟩,

  induction m using localized_module.induction_on with m t,
  rw [localization.mk_mul, mk_smul_mk, mk_smul_mk, mk_smul_mk, mul_smul, mul_assoc],
end

private lemma smul_add' (x : localization S) (y z : localized_module S M) :
  x • (y + z) = x • y + x • z :=
begin
  induction x using localization.induction_on with data,
  rcases data with ⟨r, u⟩,
  induction y using localized_module.induction_on with m s,
  induction z using localized_module.induction_on with n t,
  rw [mk_smul_mk, mk_smul_mk, mk_add_mk, mk_smul_mk, mk_add_mk, mk_eq],
  use 1,
  simp only [one_smul, smul_add, ← mul_smul, submonoid.smul_def, submonoid.coe_mul],
  ring_nf
end

private lemma smul_zero' (x : localization S) :
  x • (0 : localized_module S M) = 0 :=
begin
  induction x using localization.induction_on with data,
  rcases data with ⟨r, s⟩,
  rw [←zero_mk s, mk_smul_mk, smul_zero, zero_mk, zero_mk],
end

private lemma add_smul' (x y : localization S) (z : localized_module S M) :
  (x + y) • z = x • z + y • z :=
begin
  induction x using localization.induction_on with datax,
  induction y using localization.induction_on with datay,
  induction z using localized_module.induction_on with m t,
  rcases ⟨datax, datay⟩ with ⟨⟨r, s⟩, ⟨r', s'⟩⟩,
  rw [localization.add_mk, mk_smul_mk, mk_smul_mk, mk_smul_mk, mk_add_mk, mk_eq],
  use 1,
  simp only [one_smul, add_smul, smul_add, ← mul_smul, submonoid.smul_def, submonoid.coe_mul,
    submonoid.coe_one],
  rw add_comm, -- Commutativity of addition in the module is not applied by `ring`.
  ring_nf,
end

private lemma zero_smul' (x : localized_module S M) :
  (0 : localization S) • x = 0 :=
begin
  induction x using localized_module.induction_on with m s,
  rw [← localization.mk_zero s, mk_smul_mk, zero_smul, zero_mk],
end

instance is_module : module (localization S) (localized_module S M) :=
{ smul := (•),
  one_smul := one_smul',
  mul_smul := mul_smul',
  smul_add := smul_add',
  smul_zero := smul_zero',
  add_smul := add_smul',
  zero_smul := zero_smul' }

instance is_module' : module R (localized_module S M) :=
{ smul := λ r x, lift_on x (λ p, mk (r • p.1) p.2) $ λ ⟨a, b⟩ ⟨a', b'⟩ ⟨c, eq1⟩, mk_eq.mpr ⟨c,
    begin
      dsimp only,
      change (c : R) • (b : R) • _ = (c : R) • (b' : R) • _ at eq1,
      change (c : R) • (b : R) • _ = (c : R) • (b' : R) • _,
      simp only [←mul_smul, ←mul_assoc, mul_comm (↑c * ↑b) r, mul_comm (↑c * ↑b') r],
      simp only [mul_smul, eq1],
    end⟩,
  one_smul := λ x, induction_on (λ m s,
    begin
      change mk _ _ = _,
      rw [one_smul],
    end) x,
  mul_smul := λ r r' x , induction_on (λ m s,
    begin
      change mk _ _ = mk _ _,
      simp only [mul_smul],
    end) x,
  smul_add := λ r x y, induction_on₂ (λ m m' s s',
    begin
      change mk _ _ = mk _ _ + mk _ _,
      simp only [mk_add_mk, smul_add],
      congr' 1,
      change r • (s' : R) • _ + r • (s : R) • _ = (s' : R) • _ + (s : R) • _,
      simp only [←mul_smul],
      congr' 2;
      ring
    end) x y,
  smul_zero := λ r, begin
    change mk _ _ = _,
    rw [smul_zero, zero_mk],
  end,
  add_smul := λ r s x, induction_on (λ m t,
    begin
      change mk _ _ = mk _ _ + mk _ _,
      simp only [mk_add_mk],
      refine mk_eq.mpr ⟨1, _⟩,
      rw [one_smul, one_smul, ←smul_add, ←mul_smul],
      congr,
      rw add_smul,
    end) x,
  zero_smul := λ x, induction_on (λ m t,
    begin
      change mk _ _ = _,
      rw [zero_smul, zero_mk],
    end) x }

section

variables (S M)

/--
The map `m ↦ m / 1` is `R`-linear.export
-/
def mk_linear_map : M →ₗ[R] localized_module S M :=
{ to_fun := λ m, mk m 1,
  map_add' := λ x y, by simp [mk_add_mk],
  map_smul' := λ r x, rfl }

end

/--
For any `r : R`, there is an `R`-linear map given by `a/b ↦ r • a/b = (r • a)/b`.
-/
def mul_by (s : R) : localized_module S M →ₗ[R] localized_module S M :=
{ to_fun := (•) s,
  map_add' := λ _ _, by simp,
  map_smul' := λ r p,
  begin
    change (s : R) • _ = r • (s : R) • _,
    simp only [←mul_smul],
    ring_nf,
  end }

/--
The bilinear map `r ↦ z ↦ r • z`.
-/
def mul : R →ₗ[R] localized_module S M →ₗ[R] localized_module S M :=
{ to_fun := λ r, mul_by r,
  map_add' := λ x y, fun_like.ext _ _ $ λ z, z.induction_on
  begin
    intros m s,
    change mk _ _ = mk _ _ + mk _ _,
    simp only [add_smul, mk_add_mk],
    refine mk_eq.mpr ⟨1, _⟩,
    simp only [one_smul, ←smul_add, mul_smul],
  end,
  map_smul' := λ r x, fun_like.ext _ _ $ λ z, z.induction_on
  begin
    intros m s,
    change mk _ _ = mk _ _,
    simp [mul_smul],
  end }

/--
For any `s : S`, there is an `R`-linear map given by `a/b ↦ a/(b*s)`.
-/
def div_by (s : S) : localized_module S M →ₗ[R] localized_module S M :=
{ to_fun := λ p, p.lift_on (λ p, mk p.1 (s * p.2)) $ λ ⟨a, b⟩ ⟨a', b'⟩ ⟨c, eq1⟩, mk_eq.mpr ⟨c,
  begin
    change (c : R) • ((s : R) * b) • a' = (c : R) • ((s : R) * b') • a,
    change (c : R) • (b : R) • a' = (c : R) • (b' : R) • a at eq1,
    simp only [←mul_smul, ←mul_assoc, mul_comm (c : R) s],
    simp only [mul_smul, eq1],
  end⟩,
  map_add' := λ x y,
  begin
    induction x using localized_module.induction_on with m t,
    induction y using localized_module.induction_on with m' t',
    simp only [mk_add_mk, lift_on_mk],
    refine mk_eq.mpr ⟨1, _⟩,
    simp only [one_smul, mul_smul, ←smul_add],
    congr' 2,
    rw [←mul_smul, ←mul_smul, mul_comm _ s],
  end,
  map_smul' := λ r x,
  begin
    induction x using localized_module.induction_on with m t,
    refl,
  end }

lemma div_by_mul_by (s : S) (p : localized_module S M) : div_by s (mul_by ↑s p) = p :=
begin
  induction p using localized_module.induction_on with a b,
  change mk _ _ = _,
  refine mk_eq.mpr ⟨1, _⟩,
  simp only [one_smul, submonoid.coe_subtype],
  rw [mul_comm, mul_smul],
  refl,
end

lemma mul_by_div_by (s : S) (p : localized_module S M) : mul_by ↑s (div_by s p) = p :=
begin
  induction p using localized_module.induction_on with a b,
  change mk _ _ = _,
  refine mk_eq.mpr ⟨1, _⟩,
  simp only [one_smul, submonoid.coe_subtype],
  rw [mul_comm, mul_smul],
  refl,
end

end

end localized_module

section is_localized_module

universes u v

variables {R : Type u} [comm_ring R] (S : submonoid R)
variables {M M' M'' : Type u} [add_comm_monoid M] [add_comm_monoid M'] [add_comm_monoid M'']
variables [module R M] [module R M'] [module R M''] (f : M →ₗ[R] M') (g : M →ₗ[R] M'')

/--
The characteristic predicate for localized module.
`is_localized_module S f` describes that `f : M ⟶ M'` is the localization map identifying `M'` as
`localized_module S M`.
-/
class is_localized_module : Prop :=
(map_units [] : ∀ (x : S), is_unit (algebra_map R (module.End R M') x))
(surj [] : ∀ y : M', ∃ (x : M × S), x.2 • y = f x.1)
(eq_iff_exists [] : ∀ {x₁ x₂}, f x₁ = f x₂ ↔ ∃ c : S, c • x₂ = c • x₁)

instance localized_module_is_localized_module :
  is_localized_module S (localized_module.mk_linear_map S M) :=
{ map_units := λ s, ⟨⟨localized_module.mul_by s, localized_module.div_by s,
    fun_like.ext _ _ $ localized_module.mul_by_div_by _,
    fun_like.ext _ _ $ localized_module.div_by_mul_by _⟩,
    fun_like.ext _ _ $ λ p, p.induction_on $ by { intros, refl }⟩,
  surj := λ p, localized_module.induction_on (λ m t, ⟨(m, t),
    begin
      simp [localized_module.mk_linear_map],
      change localized_module.mk _ _ = _,
      refine localized_module.mk_eq.mpr ⟨1, _⟩,
      simp [one_smul],
      refl,
    end⟩) p,
  eq_iff_exists := λ m1 m2,
  { mp := λ eq1, by simpa only [one_smul] using localized_module.mk_eq.mp eq1,
    mpr := λ ⟨c, eq1⟩, localized_module.mk_eq.mpr ⟨c, by simpa only [one_smul] using eq1⟩ } }

section

@[simps]
noncomputable def from_localized_module [is_localized_module S f] :
  localized_module S M →ₗ[R] M' :=
{ to_fun := λ p, p.lift_on (λ x, (is_localized_module.map_units f x.2).unit⁻¹ (f x.1))
  begin
    rintros ⟨a, b⟩ ⟨a', b'⟩ ⟨c, eq1⟩,
    dsimp,
    generalize_proofs h1 h2,
    erw [module.End_algebra_map_is_unit_inv_apply_eq_iff, ←h2.unit⁻¹.1.map_smul,
      module.End_algebra_map_is_unit_inv_apply_eq_iff', ←linear_map.map_smul, ←linear_map.map_smul],
    exact ((is_localized_module.eq_iff_exists S f).mpr ⟨c, eq1⟩).symm,
  end,
  map_add' := λ x y,
  begin
    induction x using localized_module.induction_on with a b,
    induction y using localized_module.induction_on with a' b',
    simp only [localized_module.mk_add_mk, localized_module.lift_on_mk],
    generalize_proofs h1 h2 h3,
    erw [module.End_algebra_map_is_unit_inv_apply_eq_iff, smul_add, ←h2.unit⁻¹.1.map_smul,
      ←h3.unit⁻¹.1.map_smul, map_add],
    congr' 1,
    { erw [module.End_algebra_map_is_unit_inv_apply_eq_iff'],
      dsimp,
      erw [mul_smul, f.map_smul],
      refl, },
    { erw [module.End_algebra_map_is_unit_inv_apply_eq_iff'],
      dsimp,
      erw [mul_comm, f.map_smul, mul_smul],
      refl, },
  end,
  map_smul' := λ r x,
  begin
    induction x using localized_module.induction_on with a b,
    erw [localized_module.lift_on_mk, localized_module.lift_on_mk],
    generalize_proofs h1,
    dsimp,
    erw [f.map_smul, h1.unit⁻¹.1.map_smul],
    refl,
  end }

lemma from_localized_module.inj [is_localized_module S f] :
  function.injective $ from_localized_module S f := λ x y eq1,
begin
  induction x using localized_module.induction_on with a b,
  induction y using localized_module.induction_on with a' b',
  simp only [from_localized_module, linear_map.coe_mk, localized_module.lift_on_mk] at eq1,
  generalize_proofs h1 h2 at eq1,
  erw [module.End_algebra_map_is_unit_inv_apply_eq_iff, ←linear_map.map_smul,
    module.End_algebra_map_is_unit_inv_apply_eq_iff'] at eq1,
  erw [localized_module.mk_eq, ←is_localized_module.eq_iff_exists S f, f.map_smul, f.map_smul, eq1],
  refl,
end

lemma from_localized_module.surj [is_localized_module S f] :
  function.surjective $ from_localized_module S f := λ x,
begin
  rcases is_localized_module.surj S f x with ⟨⟨m, s⟩, eq1⟩,
  refine ⟨localized_module.mk m s, _⟩,
  rw [from_localized_module, linear_map.coe_mk, localized_module.lift_on_mk,
    module.End_algebra_map_is_unit_inv_apply_eq_iff, ←eq1],
  refl,
end

lemma from_localized_module.bij [is_localized_module S f] :
  function.bijective $ from_localized_module S f :=
⟨from_localized_module.inj _ _, from_localized_module.surj _ _⟩

@[simps]
noncomputable def iso [is_localized_module S f] :
  localized_module S M ≃ₗ[R] M' :=
{ ..from_localized_module S f,
  ..equiv.of_bijective (from_localized_module S f) $ from_localized_module.bij _ _}

lemma iso_apply_mk [is_localized_module S f] (m : M) (s : S) :
  iso S f (localized_module.mk m s) = (is_localized_module.map_units f s).unit⁻¹ (f m) :=
rfl

private lemma iso_symm_apply_aux [is_localized_module S f] (m : M') :
  (iso S f).symm m = localized_module.mk (is_localized_module.surj S f m).some.1
    (is_localized_module.surj S f m).some.2 :=
begin
  generalize_proofs _ h2,
  apply_fun (iso S f) using linear_equiv.injective _,
  rw [linear_equiv.apply_symm_apply],
  simp only [iso_apply, linear_map.to_fun_eq_coe, from_localized_module_apply],
  erw [localized_module.lift_on_mk, module.End_algebra_map_is_unit_inv_apply_eq_iff', h2.some_spec],
end

lemma iso_symm_apply' [is_localized_module S f] (m : M') (a : M) (b : S) (eq1 : b • m = f a) :
  (iso S f).symm m = localized_module.mk a b :=
(iso_symm_apply_aux S f m).trans $ localized_module.mk_eq.mpr $
begin
  generalize_proofs h1,
  erw [←is_localized_module.eq_iff_exists S f, f.map_smul, f.map_smul, ←h1.some_spec],
  dsimp,
  erw [←mul_smul, mul_comm, mul_smul, eq1],
  refl,
end

noncomputable def unique_up_to_iso [is_localized_module S f] [is_localized_module S g] :
  M' ≃ₗ[R] M'' :=
(iso S f).symm.trans (iso S g)

noncomputable instance has_localization_smul [is_localized_module S f] :
  has_smul (localization S) M' :=
{ smul := λ x m, iso S f $ x • (iso S f).symm m }

lemma has_localization_smul.mk_smul [is_localized_module S f] (r : R) (s : S) (x : M'):
  (localization.mk r s : localization S) • x =
  (is_localized_module.map_units f s).unit⁻¹ (r • x) :=
begin
  rw [module.End_algebra_map_is_unit_inv_apply_eq_iff'],
  change r • x = s • iso S f _,
  rcases is_localized_module.surj S f x with ⟨⟨a, b⟩, eq1⟩,
  dsimp at eq1,
  rw [iso_symm_apply' S f x _ _ eq1, localized_module.mk_smul_mk],
  simp only [localized_module.lift_on_mk, submonoid.coe_mul, map_mul, iso_apply,
    linear_map.to_fun_eq_coe, from_localized_module_apply, linear_map.map_smulₛₗ, ring_hom.id_apply],
  generalize_proofs h1,
  erw [←linear_map.map_smul],
  rw [←map_mul] at h1,
  convert (module.End_algebra_map_is_unit_inv_apply_eq_iff' h1 (s • r • f a) (r • x)).mpr _,
  { rw map_mul },
  conv_rhs { rw [←mul_smul, mul_assoc, mul_comm _ r, mul_smul, mul_smul] },
  erw [eq1],
  refl,
end

noncomputable instance localization_mul_action [is_localized_module S f] : mul_action (localization S) M' :=
{ one_smul := λ b,
  begin
    change iso S _ _ = _,
    rw [one_smul, linear_equiv.apply_symm_apply],
  end,
  mul_smul := λ x y m,
  begin
    induction x using localization.induction_on with a,
    induction y using localization.induction_on with a',
    rcases ⟨a, a'⟩ with ⟨⟨a, b⟩, ⟨a', b'⟩⟩,
    rw [localization.mk_mul, has_localization_smul.mk_smul, has_localization_smul.mk_smul,
      has_localization_smul.mk_smul],
    dsimp,
    generalize_proofs h1 h2 h3,
    erw [module.End_algebra_map_is_unit_inv_apply_eq_iff, ←linear_map.map_smul,
      module.End_algebra_map_is_unit_inv_apply_eq_iff', ←linear_map.map_smul, ←linear_map.map_smul,
      module.End_algebra_map_is_unit_inv_apply_eq_iff, mul_comm b, mul_smul, mul_smul],
    refl,
  end,
  ..has_localization_smul S f }

noncomputable instance localization_distrib_mul_action [is_localized_module S f] :
  distrib_mul_action (localization S) M' :=
{ smul_add := λ r x y,
  begin
    change iso _ _ _ = iso _ _ _ + iso _ _ _,
    simp only [←map_add, ←smul_add],
  end,
  smul_zero := λ r,
  begin
    change iso _ _ _ = _,
    simp only [map_zero, smul_zero],
  end,
  ..localization_mul_action S f }

noncomputable instance localization_module [is_localized_module S f] :
  module (localization S) M' :=
{ add_smul := λ r s x,
  begin
    change iso _ _ _ = iso _ _ _ + iso _ _ _,
    simp only [←map_add, ←add_smul],
  end,
  zero_smul := λ x,
  begin
    change iso _ _ _ = _,
    simp only [zero_smul, map_zero],
  end,
  ..localization_distrib_mul_action S f }

private lemma iso_localization_smul_aux [is_localized_module S f] (r : R) (s : S)
  (m : M) (t : S) :
  (localization.mk r s) • iso S f (localized_module.mk m t) =
  iso S f (localized_module.mk (r • m) (s * t)) :=
begin
  rw [iso_apply_mk, iso_apply_mk],
  unfold has_smul.smul,
  rw [localization.lift_on_mk],
  generalize_proofs h0 h1 h2 h3,
  rcases is_localized_module.surj S f (h1.unit⁻¹ (f m)) with ⟨⟨a, b⟩, eq1⟩,
  rw [iso_symm_apply' S f _ _ _ eq1, localized_module.lift_on_mk, iso_apply_mk],
  generalize_proofs h4,
  erw [module.End_algebra_map_is_unit_inv_apply_eq_iff, ←linear_map.map_smul,
    module.End_algebra_map_is_unit_inv_apply_eq_iff'],
  dsimp only at *,
  apply_fun h1.unit at eq1,
  erw [linear_map.map_smul, module.End_is_unit_apply_inv_apply] at eq1,
  change ↑b • f m = ↑t • f a at eq1,
  simp only [submonoid.coe_mul, mul_smul, linear_map.map_smul],
  simp only [←mul_smul, mul_comm _ r, ←mul_assoc],
  simp only [mul_smul, eq1],
end

lemma iso_localization_smul [is_localized_module S f] (r : R) (s : S) (x : localized_module S M) :
  (localization.mk r s) • iso S f x = iso S f (localization.mk r s • x) :=
x.induction_on
begin
  intros m t,
  convert iso_localization_smul_aux S f r s m t,
  unfold has_smul.smul,
  rw [localization.lift_on_mk, iso_symm_apply' S (localized_module.mk_linear_map S M)
    (localized_module.mk m t) m t _, localized_module.lift_on_mk, iso_apply_mk,
    module.End_algebra_map_is_unit_inv_apply_eq_iff],
  work_on_goal 2
  { change localized_module.mk _ _ = localized_module.mk _ _,
    refine localized_module.mk_eq.mpr ⟨1, _⟩,
    simp only [one_smul],
    refl },
  dsimp,
  change localized_module.mk _ _ = localized_module.mk _ _,
  refine localized_module.mk_eq.mpr ⟨1, _⟩,
  simp only [one_smul, mul_smul],
  refl,
end

noncomputable def from_localized_module_as_localization_module [is_localized_module S f] :
  localized_module S M →ₗ[localization S] M' :=
{ to_fun := iso S f,
  map_add' := map_add _,
  map_smul' := λ r x, r.induction_on
  begin
    rintros ⟨a, b⟩,
    induction x using localized_module.induction_on with a' b',
    rw [ring_hom.id_apply, iso_localization_smul],
  end }

noncomputable def iso_as_localization_module [is_localized_module S f] :
  localized_module S M ≃ₗ[localization S] M' :=
{ ..from_localized_module_as_localization_module S f,
  ..equiv.of_bijective (from_localized_module_as_localization_module S f)
    (from_localized_module.bij S f)}

noncomputable def unique_up_to_iso_as_localization_module
  [is_localized_module S f] [is_localized_module S g] :
  M' ≃ₗ[localization S] M'' :=
(iso_as_localization_module S f).symm.trans (iso_as_localization_module S g)

end

end is_localized_module
