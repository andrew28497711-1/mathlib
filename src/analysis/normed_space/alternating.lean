/-
Copyright (c) 2020 Sébastien Gouëzel. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sébastien Gouëzel, Yury Kudryashov
-/
import analysis.normed_space.multilinear
import topology.algebra.module.alternating

/-!
# Operator norm on the space of continuous alternating maps

-/

noncomputable theory
open_locale big_operators nnreal
open finset metric

local attribute [instance, priority 1001]
add_comm_group.to_add_comm_monoid normed_add_comm_group.to_add_comm_group normed_space.to_module'

/-!
### Type variables

We use the following type variables in this file:

* `𝕜` : a `nontrivially_normed_field`;
* `ι`, `ι'` : finite index types with decidable equality;
* `E`, `E₁` : families of normed vector spaces over `𝕜` indexed by `i : ι`;
* `E'` : a family of normed vector spaces over `𝕜` indexed by `i' : ι'`;
* `Ei` : a family of normed vector spaces over `𝕜` indexed by `i : fin (nat.succ n)`;
* `G`, `G'` : normed vector spaces over `𝕜`.
-/

universes u v v' wE wE₁ wE' wEi wG wG'
variables {𝕜 : Type u} {n : ℕ}
  {E : Type wE} {E₁ : Type wE₁} {E' : Type wE'} {Ei : Type wEi}
  {G : Type wG} {G' : Type wG'} {ι : Type v} {ι' : Type v'}
  [fintype ι] [fintype ι'] [nontrivially_normed_field 𝕜]
  [normed_add_comm_group E] [normed_space 𝕜 E]
  [normed_add_comm_group E₁] [normed_space 𝕜 E₁]
  [normed_add_comm_group E'] [normed_space 𝕜 E']
  [normed_add_comm_group Ei] [ normed_space 𝕜 Ei]
  [normed_add_comm_group G] [normed_space 𝕜 G] [normed_add_comm_group G'] [normed_space 𝕜 G']

/-!
### Continuity properties of alternating maps

We relate continuity of alternating maps to the inequality `‖f m‖ ≤ C * ∏ i, ‖m i‖`, in
both directions. Along the way, we prove useful bounds on the difference `‖f m₁ - f m₂‖`.
-/
namespace alternating_map

variable (f : alternating_map 𝕜 E G ι)

/-- TODO -/
lemma bound_of_shell {ε : ℝ} {C : ℝ} (hε : 0 < ε) {c : 𝕜} (hc : 1 < ‖c‖)
  (hf : ∀ m : ι → E, (∀ i, ε / ‖c‖ ≤ ‖m i‖) → (∀ i, ‖m i‖ < ε) → ‖f m‖ ≤ C * ∏ i, ‖m i‖)
  (m : ι → E) : ‖f m‖ ≤ C * ∏ i, ‖m i‖ :=
f.to_multilinear_map.bound_of_shell (λ _, hε) (λ _, hc) hf m

/-- If a alternating map in finitely many variables on normed spaces is continuous, then it
satisfies the inequality `‖f m‖ ≤ C * ∏ i, ‖m i‖`, for some `C` which can be chosen to be
positive. -/
theorem exists_bound_of_continuous (hf : continuous f) :
  ∃ (C : ℝ), 0 < C ∧ (∀ m, ‖f m‖ ≤ C * ∏ i, ‖m i‖) :=
f.to_multilinear_map.exists_bound_of_continuous hf

/-- If `f` satisfies a boundedness property around `0`, one can deduce a bound on `f m₁ - f m₂`
using the multilinearity. Here, we give a precise but hard to use version. See
`norm_image_sub_le_of_bound` for a less precise but more usable version. The bound reads
`‖f m - f m'‖ ≤
  C * ‖m 1 - m' 1‖ * max ‖m 2‖ ‖m' 2‖ * max ‖m 3‖ ‖m' 3‖ * ... * max ‖m n‖ ‖m' n‖ + ...`,
where the other terms in the sum are the same products where `1` is replaced by any `i`. -/
lemma norm_image_sub_le_of_bound' [decidable_eq ι] {C : ℝ} (hC : 0 ≤ C)
  (H : ∀ m, ‖f m‖ ≤ C * ∏ i, ‖m i‖) (m₁ m₂ : ι → E) :
  ‖f m₁ - f m₂‖ ≤
  C * ∑ i, ∏ j, if j = i then ‖m₁ i - m₂ i‖ else max ‖m₁ j‖ ‖m₂ j‖ :=
f.to_multilinear_map.norm_image_sub_le_of_bound' hC H m₁ m₂

/-- If `f` satisfies a boundedness property around `0`, one can deduce a bound on `f m₁ - f m₂`
using the multilinearity. Here, we give a usable but not very precise version. See
`norm_image_sub_le_of_bound'` for a more precise but less usable version. The bound is
`‖f m - f m'‖ ≤ C * card ι * ‖m - m'‖ * (max ‖m‖ ‖m'‖) ^ (card ι - 1)`. -/
lemma norm_image_sub_le_of_bound {C : ℝ} (hC : 0 ≤ C)
  (H : ∀ m, ‖f m‖ ≤ C * ∏ i, ‖m i‖) (m₁ m₂ : ι → E) :
  ‖f m₁ - f m₂‖ ≤ C * (fintype.card ι) * (max ‖m₁‖ ‖m₂‖) ^ (fintype.card ι - 1) * ‖m₁ - m₂‖ :=
f.to_multilinear_map.norm_image_sub_le_of_bound hC H m₁ m₂

/-- If a alternating map satisfies an inequality `‖f m‖ ≤ C * ∏ i, ‖m i‖`, then it is
continuous. -/
theorem continuous_of_bound (C : ℝ) (H : ∀ m, ‖f m‖ ≤ C * ∏ i, ‖m i‖) :
  continuous f :=
f.to_multilinear_map.continuous_of_bound C H

/-- Constructing a continuous alternating map from a alternating map satisfying a boundedness
condition. -/
def mk_continuous (C : ℝ) (H : ∀ m, ‖f m‖ ≤ C * ∏ i, ‖m i‖) : Λ^ι⟮𝕜; E; G⟯ :=
{ cont := f.continuous_of_bound C H, ..f }

@[simp] lemma coe_mk_continuous (C : ℝ) (H : ∀ m, ‖f m‖ ≤ C * ∏ i, ‖m i‖) :
  ⇑(f.mk_continuous C H) = f :=
rfl

end alternating_map

/-!
### Continuous alternating maps

We define the norm `‖f‖` of a continuous alternating map `f` in finitely many variables as the
smallest number such that `‖f m‖ ≤ ‖f‖ * ∏ i, ‖m i‖` for all `m`. We show that this
defines a normed space structure on `continuous_multilinear_map 𝕜 E G`.
-/
namespace continuous_alternating_map

variables (c : 𝕜) (f g : Λ^ι⟮𝕜; E; G⟯) (m : ι → E)

theorem bound : ∃ (C : ℝ), 0 < C ∧ (∀ m, ‖f m‖ ≤ C * ∏ i, ‖m i‖) :=
f.to_continuous_multilinear_map.bound

instance : normed_add_comm_group (Λ^ι⟮𝕜; E; G⟯) :=
normed_add_comm_group.induced _ _
  (to_multilinear_add_hom : Λ^ι⟮𝕜; E; G⟯ →+ _)
  to_continuous_multilinear_map_injective

@[simp] lemma norm_to_continuous_multilinear_map : ‖f.1‖ = ‖f‖ := rfl

lemma embedding_to_continuous_multilinear_map :
  embedding (to_continuous_multilinear_map : Λ^ι⟮𝕜; E; G⟯ →
    continuous_multilinear_map 𝕜 (λ _ : ι, E) G) :=
to_continuous_multilinear_map_injective.embedding_induced

lemma uniform_embedding_to_continuous_multilinear_map :
  uniform_embedding (to_continuous_multilinear_map : Λ^ι⟮𝕜; E; G⟯ →
    continuous_multilinear_map 𝕜 (λ _ : ι, E) G) :=
⟨⟨rfl⟩, to_continuous_multilinear_map_injective⟩

lemma is_closed_range_to_continuous_multilinear_map :
  is_closed (set.range (to_continuous_multilinear_map : Λ^ι⟮𝕜; E; G⟯ →
    continuous_multilinear_map 𝕜 (λ _ : ι, E) G)) :=
begin
  simp only [range_to_continuous_multilinear_map, set.set_of_forall],
  repeat { apply is_closed_Inter, intro },
  exact is_closed_singleton.preimage (continuous_multilinear_map.continuous_eval_left _)
end

lemma closed_embedding_to_continuous_multilinear_map :
  closed_embedding (to_continuous_multilinear_map : Λ^ι⟮𝕜; E; G⟯ →
    continuous_multilinear_map 𝕜 (λ _ : ι, E) G) :=
⟨embedding_to_continuous_multilinear_map, is_closed_range_to_continuous_multilinear_map⟩

lemma continuous_to_continuous_multilinear_map :
  continuous (to_continuous_multilinear_map : Λ^ι⟮𝕜; E; G⟯ →
    continuous_multilinear_map 𝕜 (λ _ : ι, E) G) :=
embedding_to_continuous_multilinear_map.continuous

lemma norm_def : ‖f‖ = Inf {c | 0 ≤ (c : ℝ) ∧ ∀ m, ‖f m‖ ≤ c * ∏ i, ‖m i‖} := rfl

-- So that invocations of `le_cInf` make sense: we show that the set of
-- bounds is nonempty and bounded below.
lemma bounds_nonempty {f : Λ^ι⟮𝕜; E; G⟯} :
  ∃ c, c ∈ {c | 0 ≤ c ∧ ∀ m, ‖f m‖ ≤ c * ∏ i, ‖m i‖} :=
continuous_multilinear_map.bounds_nonempty

lemma bounds_bdd_below {f : Λ^ι⟮𝕜; E; G⟯} :
  bdd_below {c | 0 ≤ c ∧ ∀ m, ‖f m‖ ≤ c * ∏ i, ‖m i‖} :=
continuous_multilinear_map.bounds_bdd_below

/-- The fundamental property of the operator norm of a continuous alternating map:
`‖f m‖` is bounded by `‖f‖` times the product of the `‖m i‖`. -/
theorem le_op_norm : ‖f m‖ ≤ ‖f‖ * ∏ i, ‖m i‖ := f.1.le_op_norm m

theorem le_of_op_norm_le {C : ℝ} (h : ‖f‖ ≤ C) : ‖f m‖ ≤ C * ∏ i, ‖m i‖ :=
f.1.le_of_op_norm_le m h

theorem le_op_norm_of_le {C : ι → ℝ} (h : ∀ i, ‖m i‖ ≤ C i) : ‖f m‖ ≤ ‖f‖ * ∏ i, C i :=
(f.le_op_norm m).trans $ mul_le_mul_of_nonneg_left
  (prod_le_prod (λ _ _, norm_nonneg _) $ λ i hi, h i) (norm_nonneg _)

lemma ratio_le_op_norm : ‖f m‖ / ∏ i, ‖m i‖ ≤ ‖f‖ := f.1.ratio_le_op_norm m

/-- The image of the unit ball under a continuous alternating map is bounded. -/
lemma unit_le_op_norm (h : ‖m‖ ≤ 1) : ‖f m‖ ≤ ‖f‖ := f.1.unit_le_op_norm m h

/-- If one controls the norm of every `f x`, then one controls the norm of `f`. -/
lemma op_norm_le_bound {M : ℝ} (hMp : 0 ≤ M) (hM : ∀ m, ‖f m‖ ≤ M * ∏ i, ‖m i‖) :
  ‖f‖ ≤ M :=
f.1.op_norm_le_bound hMp hM

section
variables {𝕜' : Type*} [normed_field 𝕜'] [normed_space 𝕜' G] [smul_comm_class 𝕜 𝕜' G]

instance normed_space : normed_space 𝕜' (Λ^ι⟮𝕜; E; G⟯) :=
⟨λ c f, f.1.op_norm_smul_le c⟩

variable (𝕜')

@[simps]
def to_continuous_multilinear_mapL :
  Λ^ι⟮𝕜; E; G⟯ →L[𝕜'] continuous_multilinear_map 𝕜 (λ _ : ι, E) G :=
⟨to_continuous_multilinear_map_linear⟩

variable {𝕜'}

theorem le_op_norm_mul_prod_of_le {b : ι → ℝ} (hm : ∀ i, ‖m i‖ ≤ b i) : ‖f m‖ ≤ ‖f‖ * ∏ i, b i :=
f.1.le_op_norm_mul_prod_of_le m hm

theorem le_op_norm_mul_pow_card_of_le {b : ℝ} (hm : ∀ i, ‖m i‖ ≤ b) :
  ‖f m‖ ≤ ‖f‖ * b ^ fintype.card ι :=
f.1.le_op_norm_mul_pow_card_of_le m hm

theorem le_op_norm_mul_pow_of_le (f : continuous_alternating_map 𝕜 E G (fin n)) (m : fin n → E)
  {b : ℝ} (hm : ‖m‖ ≤ b) :
  ‖f m‖ ≤ ‖f‖ * b ^ n :=
f.1.le_op_norm_mul_pow_of_le m hm

/-- The fundamental property of the operator norm of a continuous alternating map:
`‖f m‖` is bounded by `‖f‖` times the product of the `‖m i‖`, `nnnorm` version. -/
theorem le_op_nnnorm : ‖f m‖₊ ≤ ‖f‖₊ * ∏ i, ‖m i‖₊ := f.1.le_op_nnnorm m

theorem le_of_op_nnnorm_le {C : ℝ≥0} (h : ‖f‖₊ ≤ C) : ‖f m‖₊ ≤ C * ∏ i, ‖m i‖₊ :=
f.1.le_of_op_nnnorm_le m h

lemma op_norm_prod (f : Λ^ι⟮𝕜; E; G⟯)
  (g : continuous_alternating_map 𝕜 E G' ι) :
  ‖f.prod g‖ = max (‖f‖) (‖g‖) :=
f.1.op_norm_prod g.1

lemma norm_pi {ι' : Type v'} [fintype ι'] {E' : ι' → Type wE'} [Π i', normed_add_comm_group (E' i')]
  [Π i', normed_space 𝕜 (E' i')] (f : Π i', continuous_alternating_map 𝕜 E (E' i') ι) :
  ‖pi f‖ = ‖f‖ :=
continuous_multilinear_map.norm_pi $ λ i, (f i).1

section
variables (𝕜 G)

lemma norm_of_subsingleton_le [subsingleton ι] (i' : ι) : ‖of_subsingleton 𝕜 G i'‖ ≤ 1 :=
continuous_multilinear_map.norm_of_subsingleton_le 𝕜 G i'

@[simp] lemma norm_of_subsingleton [subsingleton ι] [nontrivial G] (i' : ι) :
  ‖of_subsingleton 𝕜 G i'‖ = 1 :=
continuous_multilinear_map.norm_of_subsingleton 𝕜 G i'

lemma nnnorm_of_subsingleton_le [subsingleton ι] (i' : ι) :
  ‖of_subsingleton 𝕜 G i'‖₊ ≤ 1 :=
norm_of_subsingleton_le _ _ _

@[simp] lemma nnnorm_of_subsingleton [subsingleton ι] [nontrivial G] (i' : ι) :
  ‖of_subsingleton 𝕜 G i'‖₊ = 1 :=
nnreal.eq $ norm_of_subsingleton _ _ _

variables {G} (E)

@[simp] lemma norm_const_of_is_empty [is_empty ι] (x : G) : ‖const_of_is_empty 𝕜 E ι x‖ = ‖x‖ :=
continuous_multilinear_map.norm_const_of_is_empty _ _ _

@[simp] lemma nnnorm_const_of_is_empty [is_empty ι] (x : G) : ‖const_of_is_empty 𝕜 E ι x‖₊ = ‖x‖₊ :=
nnreal.eq $ norm_const_of_is_empty _ _ _

end

section

variables (𝕜 E E' G G')

/-- `continuous_multilinear_map.prod` as a `linear_isometry_equiv`. -/
def prodₗᵢ :
  (Λ^ι⟮𝕜; E; G⟯) × (continuous_alternating_map 𝕜 E G' ι) ≃ₗᵢ[𝕜]
    continuous_alternating_map 𝕜 E (G × G') ι :=
{ to_fun := λ f, f.1.prod f.2,
  inv_fun := λ f, ((continuous_linear_map.fst 𝕜 G G').comp_continuous_alternating_map f,
    (continuous_linear_map.snd 𝕜 G G').comp_continuous_alternating_map f),
  map_add' := λ f g, rfl,
  map_smul' := λ c f, rfl,
  left_inv := λ f, by ext; refl,
  right_inv := λ f, by ext; refl,
  norm_map' := λ f, op_norm_prod f.1 f.2 }

/-- `continuous_multilinear_map.pi` as a `linear_isometry_equiv`. -/
def piₗᵢ {ι' : Type v'} [fintype ι'] {G : ι' → Type wE'} [Π i', normed_add_comm_group (G i')]
  [Π i', normed_space 𝕜 (G i')] :
  @linear_isometry_equiv 𝕜 𝕜 _ _ (ring_hom.id 𝕜) _ _ _
    (Π i', Λ^ι⟮𝕜; E; G i'⟯) Λ^ι⟮𝕜; E; Π i, G i⟯
      _ _ (@pi.module ι' _ 𝕜 _ _ (λ i', infer_instance)) _ :=
{ to_linear_equiv := pi_linear_equiv,
  norm_map' := norm_pi }

end

end

section restrict_scalars

variables {𝕜' : Type*} [nontrivially_normed_field 𝕜'] [normed_algebra 𝕜' 𝕜]
variables [normed_space 𝕜' G] [is_scalar_tower 𝕜' 𝕜 G]
variables [normed_space 𝕜' E] [is_scalar_tower 𝕜' 𝕜 E]

@[simp] lemma norm_restrict_scalars : ‖f.restrict_scalars 𝕜'‖ = ‖f‖ := rfl

variable (𝕜')

/-- `continuous_multilinear_map.restrict_scalars` as a `linear_isometry`. -/
def restrict_scalarsₗᵢ : Λ^ι⟮𝕜; E; G⟯ →ₗᵢ[𝕜'] Λ^ι⟮𝕜'; E; G⟯ :=
{ to_fun := restrict_scalars 𝕜',
  map_add' := λ m₁ m₂, rfl,
  map_smul' := λ c m, rfl,
  norm_map' := λ _, rfl }

variable {𝕜'}

lemma continuous_restrict_scalars :
  continuous (restrict_scalars 𝕜' : Λ^ι⟮𝕜; E; G⟯ → Λ^ι⟮𝕜'; E; G⟯) :=
(restrict_scalarsₗᵢ 𝕜').continuous

end restrict_scalars

/-- The difference `f m₁ - f m₂` is controlled in terms of `‖f‖` and `‖m₁ - m₂‖`, precise version.
For a less precise but more usable version, see `norm_image_sub_le`. The bound reads
`‖f m - f m'‖ ≤
  ‖f‖ * ‖m 1 - m' 1‖ * max ‖m 2‖ ‖m' 2‖ * max ‖m 3‖ ‖m' 3‖ * ... * max ‖m n‖ ‖m' n‖ + ...`,
where the other terms in the sum are the same products where `1` is replaced by any `i`.-/
lemma norm_image_sub_le' [decidable_eq ι] (m₁ m₂ : ι → E) :
  ‖f m₁ - f m₂‖ ≤
  ‖f‖ * ∑ i, ∏ j, if j = i then ‖m₁ i - m₂ i‖ else max ‖m₁ j‖ ‖m₂ j‖ :=
f.1.norm_image_sub_le' m₁ m₂

/-- The difference `f m₁ - f m₂` is controlled in terms of `‖f‖` and `‖m₁ - m₂‖`, less precise
version. For a more precise but less usable version, see `norm_image_sub_le'`.
The bound is `‖f m - f m'‖ ≤ ‖f‖ * card ι * ‖m - m'‖ * (max ‖m‖ ‖m'‖) ^ (card ι - 1)`.-/
lemma norm_image_sub_le (m₁ m₂ : ι → E) :
  ‖f m₁ - f m₂‖ ≤ ‖f‖ * (fintype.card ι) * (max ‖m₁‖ ‖m₂‖) ^ (fintype.card ι - 1) * ‖m₁ - m₂‖ :=
f.1.norm_image_sub_le m₁ m₂

/-- Applying a alternating map to a vector is continuous in both coordinates. -/
lemma continuous_eval :
  continuous (λ p : Λ^ι⟮𝕜; E; G⟯ × (ι → E), p.1 p.2) :=
(@continuous_multilinear_map.continuous_eval 𝕜 ι (λ _, E) G _ _ _ _ _ _).comp
  (continuous_to_continuous_multilinear_map.prod_map continuous_id)

lemma continuous_eval_left (m : ι → E) :
  continuous (λ p : Λ^ι⟮𝕜; E; G⟯, p m) :=
(@continuous_eval 𝕜 E G ι _ _ _ _ _ _).comp₂ continuous_id continuous_const

lemma has_sum_eval {α : Type*} {p : α → Λ^ι⟮𝕜; E; G⟯}
  {q : Λ^ι⟮𝕜; E; G⟯}
  (h : has_sum p q) (m : ι → E) : has_sum (λ a, p a m) (q m) :=
begin
  dsimp [has_sum] at h ⊢,
  convert ((continuous_eval_left m).tendsto _).comp h,
  ext s,
  simp
end

lemma tsum_eval {α : Type*} {p : α → Λ^ι⟮𝕜; E; G⟯} (hp : summable p)
  (m : ι → E) : (∑' a, p a) m = ∑' a, p a m :=
(has_sum_eval hp.has_sum m).tsum_eq.symm

open_locale topology
open filter

/-- If the target space is complete, the space of continuous alternating maps with its norm is also
complete. -/
instance [complete_space G] : complete_space (Λ^ι⟮𝕜; E; G⟯) :=
(complete_space_iff_is_complete_range uniform_embedding_to_continuous_multilinear_map.1).2
  is_closed_range_to_continuous_multilinear_map.is_complete

end continuous_alternating_map

/-- If a continuous alternating map is constructed from a alternating map via the constructor
`mk_continuous`, then its norm is bounded by the bound given to the constructor if it is
nonnegative. -/
lemma alternating_map.mk_continuous_norm_le (f : alternating_map 𝕜 E G ι) {C : ℝ} (hC : 0 ≤ C)
  (H : ∀ m, ‖f m‖ ≤ C * ∏ i, ‖m i‖) : ‖f.mk_continuous C H‖ ≤ C :=
f.to_multilinear_map.mk_continuous_norm_le hC H

/-- If a continuous alternating map is constructed from a alternating map via the constructor
`mk_continuous`, then its norm is bounded by the bound given to the constructor if it is
nonnegative. -/
lemma alternating_map.mk_continuous_norm_le' (f : alternating_map 𝕜 E G ι) {C : ℝ}
  (H : ∀ m, ‖f m‖ ≤ C * ∏ i, ‖m i‖) : ‖f.mk_continuous C H‖ ≤ max C 0 :=
continuous_multilinear_map.op_norm_le_bound _ (le_max_right _ _) $
  λ m, (H m).trans $ mul_le_mul_of_nonneg_right (le_max_left _ _)
    (prod_nonneg $ λ _ _, norm_nonneg _)

namespace continuous_linear_map

lemma norm_comp_continuous_alternating_map_le (g : G →L[𝕜] G') (f : Λ^ι⟮𝕜; E; G⟯) :
  ‖g.comp_continuous_alternating_map f‖ ≤ ‖g‖ * ‖f‖ :=
g.norm_comp_continuous_multilinear_map_le f.1

variables (𝕜 E G G')

/-- `continuous_linear_map.comp_continuous_alternating_map` as a bundled continuous bilinear map. -/
def comp_continuous_alternating_mapL :
  (G →L[𝕜] G') →L[𝕜] Λ^ι⟮𝕜; E; G⟯ →L[𝕜] Λ^ι⟮𝕜; E; G'⟯ :=
linear_map.mk_continuous₂
  (linear_map.mk₂ 𝕜 comp_continuous_alternating_map (λ f₁ f₂ g, rfl) (λ c f g, rfl)
    (λ f g₁ g₂, by { ext1, apply f.map_add }) (λ c f g, by { ext1, simp }))
  1 $ λ f g, by { rw one_mul, exact f.norm_comp_continuous_alternating_map_le g }

variables {𝕜 G G'}

/-- `continuous_linear_map.comp_continuous_alternating_map` as a bundled
continuous linear equiv. -/
def _root_.continuous_linear_equiv.comp_continuous_alternating_mapL (g : G ≃L[𝕜] G') :
  Λ^ι⟮𝕜; E; G⟯ ≃L[𝕜] Λ^ι⟮𝕜; E; G'⟯ :=
{ inv_fun := comp_continuous_alternating_mapL 𝕜 _ _ _ g.symm.to_continuous_linear_map,
  continuous_to_fun :=
    (comp_continuous_alternating_mapL 𝕜 _ _ _ g.to_continuous_linear_map).continuous,
  continuous_inv_fun :=
    (comp_continuous_alternating_mapL 𝕜 _ _ _ g.symm.to_continuous_linear_map).continuous,
  .. comp_continuous_alternating_mapL 𝕜 _ _ _ g.to_continuous_linear_map,
  .. g.comp_continuous_alternating_map }

@[simp] lemma _root_.continuous_linear_equiv.comp_continuous_alternating_mapL_symm
  (g : G ≃L[𝕜] G') :
  (g.comp_continuous_alternating_mapL E :
    Λ^ι⟮𝕜; E; G⟯ ≃L[𝕜] continuous_alternating_map 𝕜 E G' ι).symm =
    g.symm.comp_continuous_alternating_mapL E := rfl

variables {E}

@[simp] lemma _root_.continuous_linear_equiv.comp_continuous_alternating_mapL_apply
  (g : G ≃L[𝕜] G') (f : Λ^ι⟮𝕜; E; G⟯) :
  g.comp_continuous_alternating_mapL E f = (g : G →L[𝕜] G').comp_continuous_alternating_map f :=
rfl

/-- Flip arguments in `f : G →L[𝕜] Λ^ι⟮𝕜; E; G⟯'` to get `Λ^ι⟮𝕜; E; G →L[𝕜] G'⟯` -/
def flip_alternating (f : G →L[𝕜] Λ^ι⟮𝕜; E; G'⟯) : Λ^ι⟮𝕜; E; G →L[𝕜] G'⟯ :=
{ to_continuous_multilinear_map :=
    ((continuous_alternating_map.to_continuous_multilinear_mapL 𝕜).comp f).flip_multilinear,
  map_eq_zero_of_eq' := λ v i j hv hne, by { ext x, simp [(f x).map_eq_zero_of_eq v hv hne] } }

end continuous_linear_map

lemma linear_isometry.norm_comp_continuous_alternating_map (g : G →ₗᵢ[𝕜] G') (f : Λ^ι⟮𝕜; E; G⟯) :
  ‖g.to_continuous_linear_map.comp_continuous_alternating_map f‖ = ‖f‖ :=
g.norm_comp_continuous_multilinear_map f.1

open continuous_alternating_map

section

variables {𝕜 E E' G G'}

lemma continuous_alternating_map.norm_comp_continuous_linear_map_le
  (f : Λ^ι⟮𝕜; E'; G⟯) (g : E →L[𝕜] E') :
  ‖f.comp_continuous_linear_map g‖ ≤ ‖f‖ * (‖g‖ ^ fintype.card ι) :=
(f.1.norm_comp_continuous_linear_le _).trans_eq $ by simp [fintype.card]

def continuous_alternating_map.comp_continuous_linear_mapL (f : E →L[𝕜] E') :
  Λ^ι⟮𝕜; E'; G⟯ →L[𝕜] Λ^ι⟮𝕜; E; G⟯ :=
linear_map.mk_continuous
  { to_fun := λ g, g.comp_continuous_linear_map f,
    map_add' := λ g g', by { ext, simp },
    map_smul' := λ c g, by { ext, simp } }
  (‖f‖ ^ fintype.card ι) $ λ g, (g.norm_comp_continuous_linear_map_le f).trans_eq (mul_comm _ _)

def continuous_alternating_map.comp_continuous_linear_equivL (f : E ≃L[𝕜] E') :
  Λ^ι⟮𝕜; E; G⟯ ≃L[𝕜] Λ^ι⟮𝕜; E'; G⟯ :=
{ continuous_inv_fun := (continuous_alternating_map.comp_continuous_linear_mapL (f : E →L[𝕜] E')).cont,
  continuous_to_fun := (continuous_alternating_map.comp_continuous_linear_mapL (f.symm : E' →L[𝕜] E)).cont,
  .. continuous_alternating_map.comp_continuous_linear_mapL (f.symm : E' →L[𝕜] E),
  .. f.continuous_alternating_map_comp }

def continuous_linear_equiv.continuous_alternating_map_congrL (e : E ≃L[𝕜] E') (e' : G ≃L[𝕜] G') :
  Λ^ι⟮𝕜; E; G⟯ ≃L[𝕜] Λ^ι⟮𝕜; E'; G'⟯ :=
(continuous_alternating_map.comp_continuous_linear_equivL e).trans $
  e'.comp_continuous_alternating_mapL E'

@[simp] lemma continuous_linear_equiv.continuous_alternating_map_congrL_apply (e : E ≃L[𝕜] E')
  (e' : G ≃L[𝕜] G') (f : Λ^ι⟮𝕜; E; G⟯) :
  e.continuous_alternating_map_congrL e' f =
  e'.comp_continuous_alternating_map (f.comp_continuous_linear_map ↑e.symm) :=
rfl

end

/-

namespace multilinear_map

/-- Given a map `f : G →ₗ[𝕜] alternating_map 𝕜 E G ι'` and an estimate
`H : ∀ x m, ‖f x m‖ ≤ C * ‖x‖ * ∏ i, ‖m i‖`, construct a continuous linear
map from `G` to `Λ^ι⟮𝕜; E; G⟯'`.

In order to lift, e.g., a map `f : (alternating_map 𝕜 E G ι) →ₗ[𝕜] multilinear_map 𝕜 E' G'`
to a map `(Λ^ι⟮𝕜; E; G⟯) →L[𝕜] continuous_alternating_map 𝕜 E' G'`,
one can apply this construction to `f.comp continuous_alternating_map.to_alternating_map_linear`
which is a linear map from `Λ^ι⟮𝕜; E; G⟯` to `multilinear_map 𝕜 E' G'`. -/
def mk_continuous_linear (f : G →ₗ[𝕜] alternating_map 𝕜 E G ι') (C : ℝ)
  (H : ∀ x m, ‖f x m‖ ≤ C * ‖x‖ * ∏ i, ‖m i‖) :
  G →L[𝕜] Λ^ι⟮𝕜; E; G⟯' :=
linear_map.mk_continuous
  { to_fun := λ x, (f x).mk_continuous (C * ‖x‖) $ H x,
    map_add' := λ x y, by { ext1, simp only [_root_.map_add], refl },
    map_smul' := λ c x, by { ext1, simp only [smul_hom_class.map_smul], refl } }
  (max C 0) $ λ x, ((f x).mk_continuous_norm_le' _).trans_eq $
    by rw [max_mul_of_nonneg _ _ (norm_nonneg x), zero_mul]

lemma mk_continuous_linear_norm_le' (f : G →ₗ[𝕜] alternating_map 𝕜 E G ι') (C : ℝ)
  (H : ∀ x m, ‖f x m‖ ≤ C * ‖x‖ * ∏ i, ‖m i‖) :
  ‖mk_continuous_linear f C H‖ ≤ max C 0 :=
begin
  dunfold mk_continuous_linear,
  exact linear_map.mk_continuous_norm_le _ (le_max_right _ _) _
end

lemma mk_continuous_linear_norm_le (f : G →ₗ[𝕜] alternating_map 𝕜 E G ι') {C : ℝ} (hC : 0 ≤ C)
  (H : ∀ x m, ‖f x m‖ ≤ C * ‖x‖ * ∏ i, ‖m i‖) :
  ‖mk_continuous_linear f C H‖ ≤ C :=
(mk_continuous_linear_norm_le' f C H).trans_eq (max_eq_left hC)

/-- Given a map `f : multilinear_map 𝕜 E (multilinear_map 𝕜 E' G)` and an estimate
`H : ∀ m m', ‖f m m'‖ ≤ C * ∏ i, ‖m i‖ * ∏ i, ‖m' i‖`, upgrade all `multilinear_map`s in the type to
`continuous_alternating_map`s. -/
def mk_continuous_alternating (f : multilinear_map 𝕜 E (multilinear_map 𝕜 E' G)) (C : ℝ)
  (H : ∀ m₁ m₂, ‖f m₁ m₂‖ ≤ C * (∏ i, ‖m₁ i‖) * ∏ i, ‖m₂ i‖) :
  continuous_alternating_map 𝕜 E (continuous_alternating_map 𝕜 E' G) :=
mk_continuous
  { to_fun := λ m, mk_continuous (f m) (C * ∏ i, ‖m i‖) $ H m,
    map_add' := λ _ m i x y, by { ext1, simp },
    map_smul' := λ _ m i c x, by { ext1, simp } }
  (max C 0) $ λ m, ((f m).mk_continuous_norm_le' _).trans_eq $
    by { rw [max_mul_of_nonneg, zero_mul], exact prod_nonneg (λ _ _, norm_nonneg _) }

@[simp] lemma mk_continuous_alternating_apply (f : multilinear_map 𝕜 E (multilinear_map 𝕜 E' G))
  {C : ℝ} (H : ∀ m₁ m₂, ‖f m₁ m₂‖ ≤ C * (∏ i, ‖m₁ i‖) * ∏ i, ‖m₂ i‖) (m : ι → E) :
  ⇑(mk_continuous_alternating f C H m) = f m :=
rfl

lemma mk_continuous_alternating_norm_le' (f : multilinear_map 𝕜 E (multilinear_map 𝕜 E' G)) (C : ℝ)
  (H : ∀ m₁ m₂, ‖f m₁ m₂‖ ≤ C * (∏ i, ‖m₁ i‖) * ∏ i, ‖m₂ i‖) :
  ‖mk_continuous_alternating f C H‖ ≤ max C 0 :=
begin
  dunfold mk_continuous_alternating,
  exact mk_continuous_norm_le _ (le_max_right _ _) _
end

lemma mk_continuous_alternating_norm_le (f : multilinear_map 𝕜 E (multilinear_map 𝕜 E' G)) {C : ℝ}
  (hC : 0 ≤ C) (H : ∀ m₁ m₂, ‖f m₁ m₂‖ ≤ C * (∏ i, ‖m₁ i‖) * ∏ i, ‖m₂ i‖) :
  ‖mk_continuous_alternating f C H‖ ≤ C :=
(mk_continuous_alternating_norm_le' f C H).trans_eq (max_eq_left hC)

end multilinear_map

namespace continuous_alternating_map

lemma norm_comp_continuous_linear_le (g : continuous_alternating_map 𝕜 E₁ G)
  (f : ι → E →L[𝕜] E₁ i) :
  ‖g.comp_continuous_linear_map f‖ ≤ ‖g‖ * ∏ i, ‖f i‖ :=
op_norm_le_bound _ (mul_nonneg (norm_nonneg _) $ prod_nonneg $ λ i hi, norm_nonneg _) $ λ m,
calc ‖g (λ i, f i (m i))‖ ≤ ‖g‖ * ∏ i, ‖f i (m i)‖ : g.le_op_norm _
... ≤ ‖g‖ * ∏ i, (‖f i‖ * ‖m i‖) :
  mul_le_mul_of_nonneg_left
    (prod_le_prod (λ _ _, norm_nonneg _) (λ i hi, (f i).le_op_norm (m i))) (norm_nonneg g)
... = (‖g‖ * ∏ i, ‖f i‖) * ∏ i, ‖m i‖ : by rw [prod_mul_distrib, mul_assoc]

lemma norm_comp_continuous_linear_isometry_le (g : continuous_alternating_map 𝕜 E₁ G)
  (f : ι → E →ₗᵢ[𝕜] E₁ i) :
  ‖g.comp_continuous_linear_map (λ i, (f i).to_continuous_linear_map)‖ ≤ ‖g‖ :=
begin
  apply op_norm_le_bound _ (norm_nonneg _) (λ m, _),
  apply (g.le_op_norm _).trans _,
  simp only [continuous_linear_map.to_linear_map_eq_coe, continuous_linear_map.coe_coe,
    linear_isometry.coe_to_continuous_linear_map, linear_isometry.norm_map]
end

lemma norm_comp_continuous_linear_isometry_equiv (g : continuous_alternating_map 𝕜 E₁ G)
  (f : ι → E ≃ₗᵢ[𝕜] E₁ i) :
  ‖g.comp_continuous_linear_map (λ i, (f i : E i →L[𝕜] E₁ i))‖ = ‖g‖ :=
begin
  apply le_antisymm (g.norm_comp_continuous_linear_isometry_le (λ i, (f i).to_linear_isometry)),
  have : g = (g.comp_continuous_linear_map (λ i, (f i : E i →L[𝕜] E₁ i)))
    .comp_continuous_linear_map (λ i, ((f i).symm : E₁ i →L[𝕜] E i)),
  { ext1 m,
    simp only [comp_continuous_linear_map_apply, linear_isometry_equiv.coe_coe'',
      linear_isometry_equiv.apply_symm_apply] },
  conv_lhs { rw this },
  apply (g.comp_continuous_linear_map (λ i, (f i : E i →L[𝕜] E₁ i)))
    .norm_comp_continuous_linear_isometry_le (λ i, (f i).symm.to_linear_isometry),
end

/-- `continuous_alternating_map.comp_continuous_linear_map` as a bundled continuous linear map.
This implementation fixes `f : ι → E →L[𝕜] E₁ i`.

TODO: Actually, the map is multilinear in `f` but an attempt to formalize this failed because of
issues with class instances. -/
def comp_continuous_linear_mapL (f : ι → E →L[𝕜] E₁ i) :
  continuous_alternating_map 𝕜 E₁ G →L[𝕜] Λ^ι⟮𝕜; E; G⟯ :=
linear_map.mk_continuous
  { to_fun := λ g, g.comp_continuous_linear_map f,
    map_add' := λ g₁ g₂, rfl,
    map_smul' := λ c g, rfl }
  (∏ i, ‖f i‖) $ λ g, (norm_comp_continuous_linear_le _ _).trans_eq (mul_comm _ _)

@[simp] lemma comp_continuous_linear_mapL_apply
  (g : continuous_alternating_map 𝕜 E₁ G) (f : ι → E →L[𝕜] E₁ i) :
  comp_continuous_linear_mapL f g = g.comp_continuous_linear_map f :=
rfl

lemma norm_comp_continuous_linear_mapL_le (f : ι → E →L[𝕜] E₁ i) :
  ‖@comp_continuous_linear_mapL 𝕜 ι E E₁ G _ _ _ _ _ _ _ _ f‖ ≤ (∏ i, ‖f i‖) :=
linear_map.mk_continuous_norm_le _ (prod_nonneg $ λ i _, norm_nonneg _) _

variable (G)

/-- `continuous_alternating_map.comp_continuous_linear_map` as a bundled continuous linear equiv,
given `f : ι → E ≃L[𝕜] E₁ i`. -/
def comp_continuous_linear_map_equivL (f : ι → E ≃L[𝕜] E₁ i) :
  continuous_alternating_map 𝕜 E₁ G ≃L[𝕜] Λ^ι⟮𝕜; E; G⟯ :=
{ inv_fun := comp_continuous_linear_mapL (λ i, ((f i).symm : E₁ i →L[𝕜] E i)),
  continuous_to_fun := (comp_continuous_linear_mapL (λ i, (f i : E i →L[𝕜] E₁ i))).continuous,
  continuous_inv_fun :=
    (comp_continuous_linear_mapL (λ i, ((f i).symm : E₁ i →L[𝕜] E i))).continuous,
  left_inv := begin
    assume g,
    ext1 m,
    simp only [continuous_linear_map.to_linear_map_eq_coe, linear_map.to_fun_eq_coe,
      continuous_linear_map.coe_coe, comp_continuous_linear_mapL_apply,
      comp_continuous_linear_map_apply, continuous_linear_equiv.coe_coe,
      continuous_linear_equiv.apply_symm_apply],
  end,
  right_inv := begin
    assume g,
    ext1 m,
    simp only [continuous_linear_map.to_linear_map_eq_coe, comp_continuous_linear_mapL_apply,
      linear_map.to_fun_eq_coe, continuous_linear_map.coe_coe, comp_continuous_linear_map_apply,
      continuous_linear_equiv.coe_coe, continuous_linear_equiv.symm_apply_apply],
  end,
  .. comp_continuous_linear_mapL (λ i, (f i : E i →L[𝕜] E₁ i)) }

@[simp] lemma comp_continuous_linear_map_equivL_symm (f : ι → E ≃L[𝕜] E₁ i) :
  (comp_continuous_linear_map_equivL G f).symm =
    comp_continuous_linear_map_equivL G (λ (i : ι), (f i).symm) :=
rfl

variable {G}

@[simp] lemma comp_continuous_linear_map_equivL_apply
  (g : continuous_alternating_map 𝕜 E₁ G) (f : ι → E ≃L[𝕜] E₁ i) :
  comp_continuous_linear_map_equivL G f g =
    g.comp_continuous_linear_map (λ i, (f i : E i →L[𝕜] E₁ i)) := rfl

end continuous_alternating_map

section smul

variables {R : Type*} [semiring R] [module R G] [smul_comm_class 𝕜 R G]
  [has_continuous_const_smul R G]

instance : has_continuous_const_smul R (Λ^ι⟮𝕜; E; G⟯) :=
⟨λ c, (continuous_linear_map.comp_continuous_alternating_mapL 𝕜 _ G G
  (c • continuous_linear_map.id 𝕜 G)).2⟩

end smul

section currying
/-!
### Currying

We associate to a continuous multilinear map in `n+1` variables (i.e., based on `fin n.succ`) two
curried functions, named `f.curry_left` (which is a continuous linear map on `E 0` taking values
in continuous multilinear maps in `n` variables) and `f.curry_right` (which is a continuous
multilinear map in `n` variables taking values in continuous linear maps on `E (last n)`).
The inverse operations are called `uncurry_left` and `uncurry_right`.

We also register continuous linear equiv versions of these correspondences, in
`continuous_alternating_curry_left_equiv` and `continuous_alternating_curry_right_equiv`.
-/
open fin function

lemma continuous_linear_map.norm_map_tail_le
  (f : Ei 0 →L[𝕜] (continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.succ) G)) (m : Πi, Ei i) :
  ‖f (m 0) (tail m)‖ ≤ ‖f‖ * ∏ i, ‖m i‖ :=
calc
  ‖f (m 0) (tail m)‖ ≤ ‖f (m 0)‖ * ∏ i, ‖(tail m) i‖ : (f (m 0)).le_op_norm _
  ... ≤ (‖f‖ * ‖m 0‖) * ∏ i, ‖(tail m) i‖ :
    mul_le_mul_of_nonneg_right (f.le_op_norm _) (prod_nonneg (λi hi, norm_nonneg _))
  ... = ‖f‖ * (‖m 0‖ * ∏ i, ‖(tail m) i‖) : by ring
  ... = ‖f‖ * ∏ i, ‖m i‖ : by { rw prod_univ_succ, refl }

lemma continuous_alternating_map.norm_map_init_le
  (f : continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.cast_succ) (Ei (last n) →L[𝕜] G))
  (m : Πi, Ei i) :
  ‖f (init m) (m (last n))‖ ≤ ‖f‖ * ∏ i, ‖m i‖ :=
calc
  ‖f (init m) (m (last n))‖ ≤ ‖f (init m)‖ * ‖m (last n)‖ : (f (init m)).le_op_norm _
  ... ≤ (‖f‖ * (∏ i, ‖(init m) i‖)) * ‖m (last n)‖ :
    mul_le_mul_of_nonneg_right (f.le_op_norm _) (norm_nonneg _)
  ... = ‖f‖ * ((∏ i, ‖(init m) i‖) * ‖m (last n)‖) : mul_assoc _ _ _
  ... = ‖f‖ * ∏ i, ‖m i‖ : by { rw prod_univ_cast_succ, refl }

lemma continuous_alternating_map.norm_map_cons_le
  (f : continuous_alternating_map 𝕜 Ei G) (x : Ei 0) (m : Π(i : fin n), Ei i.succ) :
  ‖f (cons x m)‖ ≤ ‖f‖ * ‖x‖ * ∏ i, ‖m i‖ :=
calc
  ‖f (cons x m)‖ ≤ ‖f‖ * ∏ i, ‖cons x m i‖ : f.le_op_norm _
  ... = (‖f‖ * ‖x‖) * ∏ i, ‖m i‖ : by { rw prod_univ_succ, simp [mul_assoc] }

lemma continuous_alternating_map.norm_map_snoc_le
  (f : continuous_alternating_map 𝕜 Ei G) (m : Π(i : fin n), Ei i.cast_succ) (x : Ei (last n)) :
  ‖f (snoc m x)‖ ≤ ‖f‖ * (∏ i, ‖m i‖) * ‖x‖ :=
calc
  ‖f (snoc m x)‖ ≤ ‖f‖ * ∏ i, ‖snoc m x i‖ : f.le_op_norm _
  ... = ‖f‖ * (∏ i, ‖m i‖) * ‖x‖ : by { rw prod_univ_cast_succ, simp [mul_assoc] }

/-! #### Left currying -/

/-- Given a continuous linear map `f` from `E 0` to continuous multilinear maps on `n` variables,
construct the corresponding continuous multilinear map on `n+1` variables obtained by concatenating
the variables, given by `m ↦ f (m 0) (tail m)`-/
def continuous_linear_map.uncurry_left
  (f : Ei 0 →L[𝕜] (continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.succ) G)) :
  continuous_alternating_map 𝕜 Ei G :=
(@linear_map.uncurry_left 𝕜 n Ei G _ _ _ _ _
  (continuous_alternating_map.to_alternating_map_linear.comp f.to_linear_map)).mk_continuous
    (‖f‖) (λm, continuous_linear_map.norm_map_tail_le f m)

@[simp] lemma continuous_linear_map.uncurry_left_apply
  (f : Ei 0 →L[𝕜] (continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.succ) G)) (m : Πi, Ei i) :
  f.uncurry_left m = f (m 0) (tail m) := rfl

/-- Given a continuous multilinear map `f` in `n+1` variables, split the first variable to obtain
a continuous linear map into continuous multilinear maps in `n` variables, given by
`x ↦ (m ↦ f (cons x m))`. -/
def continuous_alternating_map.curry_left
  (f : continuous_alternating_map 𝕜 Ei G) :
  Ei 0 →L[𝕜] (continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.succ) G) :=
linear_map.mk_continuous
{ -- define a linear map into `n` continuous multilinear maps from an `n+1` continuous multilinear
  -- map
  to_fun    := λx, (f.to_alternating_map.curry_left x).mk_continuous
    (‖f‖ * ‖x‖) (f.norm_map_cons_le x),
  map_add'  := λx y, by { ext m, exact f.cons_add m x y },
  map_smul' := λc x, by { ext m, exact f.cons_smul m c x } }
  -- then register its continuity thanks to its boundedness properties.
(‖f‖) (λx, multilinear_map.mk_continuous_norm_le _ (mul_nonneg (norm_nonneg _) (norm_nonneg _)) _)

@[simp] lemma continuous_alternating_map.curry_left_apply
  (f : continuous_alternating_map 𝕜 Ei G) (x : Ei 0) (m : Π(i : fin n), Ei i.succ) :
  f.curry_left x m = f (cons x m) := rfl

@[simp] lemma continuous_linear_map.curry_uncurry_left
  (f : Ei 0 →L[𝕜] (continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.succ) G)) :
  f.uncurry_left.curry_left = f :=
begin
  ext m x,
  simp only [tail_cons, continuous_linear_map.uncurry_left_apply,
             continuous_alternating_map.curry_left_apply],
  rw cons_zero
end

@[simp] lemma continuous_alternating_map.uncurry_curry_left
  (f : continuous_alternating_map 𝕜 Ei G) : f.curry_left.uncurry_left = f :=
continuous_alternating_map.to_alternating_map_injective $ f.to_alternating_map.uncurry_curry_left

variables (𝕜 Ei G)

/-- The space of continuous multilinear maps on `Π(i : fin (n+1)), E i` is canonically isomorphic to
the space of continuous linear maps from `E 0` to the space of continuous multilinear maps on
`Π(i : fin n), E i.succ `, by separating the first variable. We register this isomorphism in
`continuous_alternating_curry_left_equiv 𝕜 E E₂`. The algebraic version (without topology) is given
in `multilinear_curry_left_equiv 𝕜 E E₂`.

The direct and inverse maps are given by `f.uncurry_left` and `f.curry_left`. Use these
unless you need the full framework of linear isometric equivs. -/
def continuous_alternating_curry_left_equiv :
  (Ei 0 →L[𝕜] (continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.succ) G)) ≃ₗᵢ[𝕜]
  (continuous_alternating_map 𝕜 Ei G) :=
linear_isometry_equiv.of_bounds
  { to_fun    := continuous_linear_map.uncurry_left,
    map_add'  := λf₁ f₂, by { ext m, refl },
    map_smul' := λc f, by { ext m, refl },
    inv_fun   := continuous_alternating_map.curry_left,
    left_inv  := continuous_linear_map.curry_uncurry_left,
    right_inv := continuous_alternating_map.uncurry_curry_left }
  (λ f, multilinear_map.mk_continuous_norm_le _ (norm_nonneg f) _)
  (λ f, linear_map.mk_continuous_norm_le _ (norm_nonneg f) _)

variables {𝕜 Ei G}

@[simp] lemma continuous_alternating_curry_left_equiv_apply
  (f : Ei 0 →L[𝕜] (continuous_alternating_map 𝕜 (λ i : fin n, Ei i.succ) G)) (v : Π i, Ei i) :
  continuous_alternating_curry_left_equiv 𝕜 Ei G f v = f (v 0) (tail v) := rfl

@[simp] lemma continuous_alternating_curry_left_equiv_symm_apply
  (f : continuous_alternating_map 𝕜 Ei G) (x : Ei 0) (v : Π i : fin n, Ei i.succ) :
  (continuous_alternating_curry_left_equiv 𝕜 Ei G).symm f x v = f (cons x v) := rfl

@[simp] lemma continuous_alternating_map.curry_left_norm
  (f : continuous_alternating_map 𝕜 Ei G) : ‖f.curry_left‖ = ‖f‖ :=
(continuous_alternating_curry_left_equiv 𝕜 Ei G).symm.norm_map f

@[simp] lemma continuous_linear_map.uncurry_left_norm
  (f : Ei 0 →L[𝕜] (continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.succ) G)) :
  ‖f.uncurry_left‖ = ‖f‖ :=
(continuous_alternating_curry_left_equiv 𝕜 Ei G).norm_map f

/-! #### Right currying -/

/-- Given a continuous linear map `f` from continuous multilinear maps on `n` variables to
continuous linear maps on `E 0`, construct the corresponding continuous multilinear map on `n+1`
variables obtained by concatenating the variables, given by `m ↦ f (init m) (m (last n))`. -/
def continuous_alternating_map.uncurry_right
  (f : continuous_alternating_map 𝕜 (λ i : fin n, Ei i.cast_succ) (Ei (last n) →L[𝕜] G)) :
  continuous_alternating_map 𝕜 Ei G :=
let f' : multilinear_map 𝕜 (λ(i : fin n), Ei i.cast_succ) (Ei (last n) →ₗ[𝕜] G) :=
{ to_fun    := λ m, (f m).to_linear_map,
  map_add'  := λ _ m i x y, by simp,
  map_smul' := λ _ m i c x, by simp } in
(@multilinear_map.uncurry_right 𝕜 n Ei G _ _ _ _ _ f').mk_continuous
  (‖f‖) (λm, f.norm_map_init_le m)

@[simp] lemma continuous_alternating_map.uncurry_right_apply
  (f : continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.cast_succ) (Ei (last n) →L[𝕜] G))
  (m : Πi, Ei i) :
  f.uncurry_right m = f (init m) (m (last n)) := rfl

/-- Given a continuous multilinear map `f` in `n+1` variables, split the last variable to obtain
a continuous multilinear map in `n` variables into continuous linear maps, given by
`m ↦ (x ↦ f (snoc m x))`. -/
def continuous_alternating_map.curry_right
  (f : continuous_alternating_map 𝕜 Ei G) :
  continuous_alternating_map 𝕜 (λ i : fin n, Ei i.cast_succ) (Ei (last n) →L[𝕜] G) :=
let f' : multilinear_map 𝕜 (λ(i : fin n), Ei i.cast_succ) (Ei (last n) →L[𝕜] G) :=
{ to_fun    := λm, (f.to_alternating_map.curry_right m).mk_continuous
    (‖f‖ * ∏ i, ‖m i‖) $ λx, f.norm_map_snoc_le m x,
  map_add'  := λ _ m i x y, by { simp, refl },
  map_smul' := λ _ m i c x, by { simp, refl } } in
f'.mk_continuous (‖f‖) (λm, linear_map.mk_continuous_norm_le _
  (mul_nonneg (norm_nonneg _) (prod_nonneg (λj hj, norm_nonneg _))) _)

@[simp] lemma continuous_alternating_map.curry_right_apply
  (f : continuous_alternating_map 𝕜 Ei G) (m : Π i : fin n, Ei i.cast_succ) (x : Ei (last n)) :
  f.curry_right m x = f (snoc m x) := rfl

@[simp] lemma continuous_alternating_map.curry_uncurry_right
  (f : continuous_alternating_map 𝕜 (λ i : fin n, Ei i.cast_succ) (Ei (last n) →L[𝕜] G)) :
  f.uncurry_right.curry_right = f :=
begin
  ext m x,
  simp only [snoc_last, continuous_alternating_map.curry_right_apply,
             continuous_alternating_map.uncurry_right_apply],
  rw init_snoc
end

@[simp] lemma continuous_alternating_map.uncurry_curry_right
  (f : continuous_alternating_map 𝕜 Ei G) : f.curry_right.uncurry_right = f :=
by { ext m, simp }

variables (𝕜 Ei G)

/--
The space of continuous multilinear maps on `Π(i : fin (n+1)), Ei i` is canonically isomorphic to
the space of continuous multilinear maps on `Π(i : fin n), Ei i.cast_succ` with values in the space
of continuous linear maps on `Ei (last n)`, by separating the last variable. We register this
isomorphism as a continuous linear equiv in `continuous_alternating_curry_right_equiv 𝕜 Ei G`.
The algebraic version (without topology) is given in `multilinear_curry_right_equiv 𝕜 Ei G`.

The direct and inverse maps are given by `f.uncurry_right` and `f.curry_right`. Use these
unless you need the full framework of linear isometric equivs.
-/
def continuous_alternating_curry_right_equiv :
  (continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.cast_succ) (Ei (last n) →L[𝕜] G)) ≃ₗᵢ[𝕜]
  (continuous_alternating_map 𝕜 Ei G) :=
linear_isometry_equiv.of_bounds
  { to_fun    := continuous_alternating_map.uncurry_right,
    map_add'  := λf₁ f₂, by { ext m, refl },
    map_smul' := λc f, by { ext m, refl },
    inv_fun   := continuous_alternating_map.curry_right,
    left_inv  := continuous_alternating_map.curry_uncurry_right,
    right_inv := continuous_alternating_map.uncurry_curry_right }
  (λ f, multilinear_map.mk_continuous_norm_le _ (norm_nonneg f) _)
  (λ f, multilinear_map.mk_continuous_norm_le _ (norm_nonneg f) _)

variables (n G')

/-- The space of continuous multilinear maps on `Π(i : fin (n+1)), G` is canonically isomorphic to
the space of continuous multilinear maps on `Π(i : fin n), G` with values in the space
of continuous linear maps on `G`, by separating the last variable. We register this
isomorphism as a continuous linear equiv in `continuous_alternating_curry_right_equiv' 𝕜 n G G'`.
For a version allowing dependent types, see `continuous_alternating_curry_right_equiv`. When there
are no dependent types, use the primed version as it helps Lean a lot for unification.

The direct and inverse maps are given by `f.uncurry_right` and `f.curry_right`. Use these
unless you need the full framework of linear isometric equivs. -/
def continuous_alternating_curry_right_equiv' :
  (G [×n]→L[𝕜] (G →L[𝕜] G')) ≃ₗᵢ[𝕜] (G [×n.succ]→L[𝕜] G') :=
continuous_alternating_curry_right_equiv 𝕜 (λ (i : fin n.succ), G) G'

variables {n 𝕜 G Ei G'}

@[simp] lemma continuous_alternating_curry_right_equiv_apply
  (f : (continuous_alternating_map 𝕜 (λ(i : fin n), Ei i.cast_succ) (Ei (last n) →L[𝕜] G)))
  (v : Π i, Ei i) :
  (continuous_alternating_curry_right_equiv 𝕜 Ei G) f v = f (init v) (v (last n)) := rfl

@[simp] lemma continuous_alternating_curry_right_equiv_symm_apply
  (f : continuous_alternating_map 𝕜 Ei G)
  (v : Π (i : fin n), Ei i.cast_succ) (x : Ei (last n)) :
  (continuous_alternating_curry_right_equiv 𝕜 Ei G).symm f v x = f (snoc v x) := rfl

@[simp] lemma continuous_alternating_curry_right_equiv_apply'
  (f : G [×n]→L[𝕜] (G →L[𝕜] G')) (v : fin (n + 1) → G) :
  continuous_alternating_curry_right_equiv' 𝕜 n G G' f v = f (init v) (v (last n)) := rfl

@[simp] lemma continuous_alternating_curry_right_equiv_symm_apply'
  (f : G [×n.succ]→L[𝕜] G') (v : fin n → G) (x : G) :
  (continuous_alternating_curry_right_equiv' 𝕜 n G G').symm f v x = f (snoc v x) := rfl

@[simp] lemma continuous_alternating_map.curry_right_norm
  (f : continuous_alternating_map 𝕜 Ei G) : ‖f.curry_right‖ = ‖f‖ :=
(continuous_alternating_curry_right_equiv 𝕜 Ei G).symm.norm_map f

@[simp] lemma continuous_alternating_map.uncurry_right_norm
  (f : continuous_alternating_map 𝕜 (λ i : fin n, Ei i.cast_succ) (Ei (last n) →L[𝕜] G)) :
  ‖f.uncurry_right‖ = ‖f‖ :=
(continuous_alternating_curry_right_equiv 𝕜 Ei G).norm_map f

/-!
#### Currying with `0` variables

The space of multilinear maps with `0` variables is trivial: such a multilinear map is just an
arbitrary constant (note that multilinear maps in `0` variables need not map `0` to `0`!).
Therefore, the space of continuous multilinear maps on `(fin 0) → G` with values in `E₂` is
isomorphic (and even isometric) to `E₂`. As this is the zeroth step in the construction of iterated
derivatives, we register this isomorphism. -/

section

variables {𝕜 G G'}

/-- Associating to a continuous multilinear map in `0` variables the unique value it takes. -/
def continuous_alternating_map.uncurry0
  (f : continuous_alternating_map 𝕜 (λ (i : fin 0), G) G') : G' := f 0

variables (𝕜 G)
/-- Associating to an element `x` of a vector space `E₂` the continuous multilinear map in `0`
variables taking the (unique) value `x` -/
def continuous_alternating_map.curry0 (x : G') : G [×0]→L[𝕜] G' :=
continuous_alternating_map.const_of_is_empty 𝕜 _ x

variable {G}
@[simp] lemma continuous_alternating_map.curry0_apply (x : G') (m : (fin 0) → G) :
  continuous_alternating_map.curry0 𝕜 G x m = x := rfl

variable {𝕜}
@[simp] lemma continuous_alternating_map.uncurry0_apply (f : G [×0]→L[𝕜] G') :
  f.uncurry0 = f 0 := rfl

@[simp] lemma continuous_alternating_map.apply_zero_curry0 (f : G [×0]→L[𝕜] G') {x : fin 0 → G} :
  continuous_alternating_map.curry0 𝕜 G (f x) = f :=
by { ext m, simp [(subsingleton.elim _ _ : x = m)] }

lemma continuous_alternating_map.uncurry0_curry0 (f : G [×0]→L[𝕜] G') :
  continuous_alternating_map.curry0 𝕜 G (f.uncurry0) = f :=
by simp

variables (𝕜 G)
@[simp] lemma continuous_alternating_map.curry0_uncurry0 (x : G') :
  (continuous_alternating_map.curry0 𝕜 G x).uncurry0 = x := rfl

@[simp] lemma continuous_alternating_map.curry0_norm (x : G')  :
  ‖continuous_alternating_map.curry0 𝕜 G x‖ = ‖x‖ :=
norm_const_of_is_empty _ _ _

variables {𝕜 G}
@[simp] lemma continuous_alternating_map.fin0_apply_norm (f : G [×0]→L[𝕜] G') {x : fin 0 → G} :
  ‖f x‖ = ‖f‖ :=
begin
  obtain rfl : x = 0 := subsingleton.elim _ _,
  refine le_antisymm (by simpa using f.le_op_norm 0) _,
  have : ‖continuous_alternating_map.curry0 𝕜 G (f.uncurry0)‖ ≤ ‖f.uncurry0‖ :=
    continuous_alternating_map.op_norm_le_bound _ (norm_nonneg _) (λm,
      by simp [-continuous_alternating_map.apply_zero_curry0]),
  simpa
end

lemma continuous_alternating_map.uncurry0_norm (f : G [×0]→L[𝕜] G') : ‖f.uncurry0‖ = ‖f‖ :=
by simp

variables (𝕜 G G')
/-- The continuous linear isomorphism between elements of a normed space, and continuous multilinear
maps in `0` variables with values in this normed space.

The direct and inverse maps are `uncurry0` and `curry0`. Use these unless you need the full
framework of linear isometric equivs. -/
def continuous_alternating_curry_fin0 : (G [×0]→L[𝕜] G') ≃ₗᵢ[𝕜] G' :=
{ to_fun    := λf, continuous_alternating_map.uncurry0 f,
  inv_fun   := λf, continuous_alternating_map.curry0 𝕜 G f,
  map_add'  := λf g, rfl,
  map_smul' := λc f, rfl,
  left_inv  := continuous_alternating_map.uncurry0_curry0,
  right_inv := continuous_alternating_map.curry0_uncurry0 𝕜 G,
  norm_map' := continuous_alternating_map.uncurry0_norm }

variables {𝕜 G G'}

@[simp] lemma continuous_alternating_curry_fin0_apply (f : G [×0]→L[𝕜] G') :
  continuous_alternating_curry_fin0 𝕜 G G' f = f 0 := rfl

@[simp] lemma continuous_alternating_curry_fin0_symm_apply (x : G') (v : (fin 0) → G) :
  (continuous_alternating_curry_fin0 𝕜 G G').symm x v = x := rfl

end

/-! #### With 1 variable -/

variables (𝕜 G G')

/-- Continuous multilinear maps from `G^1` to `G'` are isomorphic with continuous linear maps from
`G` to `G'`. -/
def continuous_alternating_curry_fin1 : (G [×1]→L[𝕜] G') ≃ₗᵢ[𝕜] (G →L[𝕜] G') :=
(continuous_alternating_curry_right_equiv 𝕜 (λ (i : fin 1), G) G').symm.trans
(continuous_alternating_curry_fin0 𝕜 G (G →L[𝕜] G'))

variables {𝕜 G G'}

@[simp] lemma continuous_alternating_curry_fin1_apply (f : G [×1]→L[𝕜] G') (x : G) :
  continuous_alternating_curry_fin1 𝕜 G G' f x = f (fin.snoc 0 x) := rfl

@[simp] lemma continuous_alternating_curry_fin1_symm_apply
  (f : G →L[𝕜] G') (v : (fin 1) → G) :
  (continuous_alternating_curry_fin1 𝕜 G G').symm f v = f (v 0) := rfl

namespace continuous_alternating_map

variables (𝕜 G G')

/-- An equivalence of the index set defines a linear isometric equivalence between the spaces
of multilinear maps. -/
def dom_dom_congr (σ : ι ≃ ι') :
  continuous_alternating_map 𝕜 (λ _ : ι, G) G' ≃ₗᵢ[𝕜]
    continuous_alternating_map 𝕜 (λ _ : ι', G) G' :=
linear_isometry_equiv.of_bounds
  { to_fun := λ f, (multilinear_map.dom_dom_congr σ f.to_alternating_map).mk_continuous ‖f‖ $
      λ m, (f.le_op_norm (λ i, m (σ i))).trans_eq $ by rw [← σ.prod_comp],
    inv_fun := λ f, (multilinear_map.dom_dom_congr σ.symm f.to_alternating_map).mk_continuous ‖f‖ $
      λ m, (f.le_op_norm (λ i, m (σ.symm i))).trans_eq $ by rw [← σ.symm.prod_comp],
    left_inv := λ f, ext $ λ m, congr_arg f $ by simp only [σ.symm_apply_apply],
    right_inv := λ f, ext $ λ m, congr_arg f $ by simp only [σ.apply_symm_apply],
    map_add' := λ f g, rfl,
    map_smul' := λ c f, rfl }
  (λ f, multilinear_map.mk_continuous_norm_le _ (norm_nonneg f) _)
  (λ f, multilinear_map.mk_continuous_norm_le _ (norm_nonneg f) _)

variables {𝕜 G G'}

section

/-- A continuous multilinear map with variables indexed by `ι ⊕ ι'` defines a continuous multilinear
map with variables indexed by `ι` taking values in the space of continuous multilinear maps with
variables indexed by `ι'`. -/
def curry_sum (f : continuous_alternating_map 𝕜 (λ x : ι ⊕ ι', G) G') :
  continuous_alternating_map 𝕜 (λ x : ι, G) (continuous_alternating_map 𝕜 (λ x : ι', G) G') :=
multilinear_map.mk_continuous_alternating (multilinear_map.curry_sum f.to_alternating_map) (‖f‖) $
  λ m m', by simpa [fintype.prod_sum_type, mul_assoc] using f.le_op_norm (sum.elim m m')

@[simp] lemma curry_sum_apply (f : continuous_alternating_map 𝕜 (λ x : ι ⊕ ι', G) G')
  (m : ι → G) (m' : ι' → G) :
  f.curry_sum m m' = f (sum.elim m m') :=
rfl

/-- A continuous multilinear map with variables indexed by `ι` taking values in the space of
continuous multilinear maps with variables indexed by `ι'` defines a continuous multilinear map with
variables indexed by `ι ⊕ ι'`. -/
def uncurry_sum
  (f : continuous_alternating_map 𝕜 (λ x : ι, G) (continuous_alternating_map 𝕜 (λ x : ι', G) G')) :
  continuous_alternating_map 𝕜 (λ x : ι ⊕ ι', G) G' :=
multilinear_map.mk_continuous
  (to_alternating_map_linear.comp_alternating_map f.to_alternating_map).uncurry_sum (‖f‖) $ λ m,
  by simpa [fintype.prod_sum_type, mul_assoc]
    using (f (m ∘ sum.inl)).le_of_op_norm_le (m ∘ sum.inr) (f.le_op_norm _)

@[simp] lemma uncurry_sum_apply
  (f : continuous_alternating_map 𝕜 (λ x : ι, G) (continuous_alternating_map 𝕜 (λ x : ι', G) G'))
  (m : ι ⊕ ι' → G) :
  f.uncurry_sum m = f (m ∘ sum.inl) (m ∘ sum.inr) :=
rfl

variables (𝕜 ι ι' G G')

/-- Linear isometric equivalence between the space of continuous multilinear maps with variables
indexed by `ι ⊕ ι'` and the space of continuous multilinear maps with variables indexed by `ι`
taking values in the space of continuous multilinear maps with variables indexed by `ι'`.

The forward and inverse functions are `continuous_alternating_map.curry_sum`
and `continuous_alternating_map.uncurry_sum`. Use this definition only if you need
some properties of `linear_isometry_equiv`. -/
def curry_sum_equiv : continuous_alternating_map 𝕜 (λ x : ι ⊕ ι', G) G' ≃ₗᵢ[𝕜]
  continuous_alternating_map 𝕜 (λ x : ι, G) (continuous_alternating_map 𝕜 (λ x : ι', G) G') :=
linear_isometry_equiv.of_bounds
  { to_fun := curry_sum,
    inv_fun := uncurry_sum,
    map_add' := λ f g, by { ext, refl },
    map_smul' := λ c f, by { ext, refl },
    left_inv := λ f, by { ext m, exact congr_arg f (sum.elim_comp_inl_inr m) },
    right_inv := λ f, by { ext m₁ m₂, change f _ _ = f _ _,
      rw [sum.elim_comp_inl, sum.elim_comp_inr] } }
  (λ f, multilinear_map.mk_continuous_alternating_norm_le _ (norm_nonneg f) _)
  (λ f, multilinear_map.mk_continuous_norm_le _ (norm_nonneg f) _)

end

section

variables (𝕜 G G') {k l : ℕ} {s : finset (fin n)}

/-- If `s : finset (fin n)` is a finite set of cardinality `k` and its complement has cardinality
`l`, then the space of continuous multilinear maps `G [×n]→L[𝕜] G'` of `n` variables is isomorphic
to the space of continuous multilinear maps `G [×k]→L[𝕜] G [×l]→L[𝕜] G'` of `k` variables taking
values in the space of continuous multilinear maps of `l` variables. -/
def curry_fin_finset {k l n : ℕ} {s : finset (fin n)}
  (hk : s.card = k) (hl : sᶜ.card = l) :
  (G [×n]→L[𝕜] G') ≃ₗᵢ[𝕜] (G [×k]→L[𝕜] G [×l]→L[𝕜] G') :=
(dom_dom_congr 𝕜 G G' (fin_sum_equiv_of_finset hk hl).symm).trans
  (curry_sum_equiv 𝕜 (fin k) (fin l) G G')

variables {𝕜 G G'}

@[simp] lemma curry_fin_finset_apply (hk : s.card = k) (hl : sᶜ.card = l)
  (f : G [×n]→L[𝕜] G') (mk : fin k → G) (ml : fin l → G) :
  curry_fin_finset 𝕜 G G' hk hl f mk ml =
    f (λ i, sum.elim mk ml ((fin_sum_equiv_of_finset hk hl).symm i)) :=
rfl

@[simp] lemma curry_fin_finset_symm_apply (hk : s.card = k) (hl : sᶜ.card = l)
  (f : G [×k]→L[𝕜] G [×l]→L[𝕜] G') (m : fin n → G) :
  (curry_fin_finset 𝕜 G G' hk hl).symm f m =
    f (λ i, m $ fin_sum_equiv_of_finset hk hl (sum.inl i))
      (λ i, m $ fin_sum_equiv_of_finset hk hl (sum.inr i)) :=
rfl

@[simp] lemma curry_fin_finset_symm_apply_piecewise_const (hk : s.card = k) (hl : sᶜ.card = l)
  (f : G [×k]→L[𝕜] G [×l]→L[𝕜] G') (x y : G) :
  (curry_fin_finset 𝕜 G G' hk hl).symm f (s.piecewise (λ _, x) (λ _, y)) = f (λ _, x) (λ _, y) :=
multilinear_map.curry_fin_finset_symm_apply_piecewise_const hk hl _ x y

@[simp] lemma curry_fin_finset_symm_apply_const (hk : s.card = k) (hl : sᶜ.card = l)
  (f : G [×k]→L[𝕜] G [×l]→L[𝕜] G') (x : G) :
  (curry_fin_finset 𝕜 G G' hk hl).symm f (λ _, x) = f (λ _, x) (λ _, x) :=
rfl

@[simp] lemma curry_fin_finset_apply_const (hk : s.card = k) (hl : sᶜ.card = l)
  (f : G [×n]→L[𝕜] G') (x y : G) :
  curry_fin_finset 𝕜 G G' hk hl f (λ _, x) (λ _, y) = f (s.piecewise (λ _, x) (λ _, y)) :=
begin
  refine (curry_fin_finset_symm_apply_piecewise_const hk hl _ _ _).symm.trans _, -- `rw` fails
  rw linear_isometry_equiv.symm_apply_apply
end

end

end continuous_alternating_map

end currying
-/
