/-
Copyright (c) 2021 Justus Springer. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Justus Springer
-/

import category_theory.sites.spaces
import topology.sheaves.sheaf
import category_theory.sites.dense_subsite

/-!

# Coverings and sieves; from sheaves on sites and sheaves on spaces

In this file, we connect coverings in a topological space to sieves in the associated Grothendieck
topology, in preparation of connecting the sheaf condition on sites to the various sheaf conditions
on spaces.

We also specialize results about sheaves on sites to sheaves on spaces; we show that the inclusion
functor from a topological basis to `topological_space.opens` is cover_dense, that open maps
induce cover_preserving functors, and that open embeddings induce compatible_preserving functors.

-/

noncomputable theory

universes w v u

open category_theory topological_space

namespace Top.presheaf

variables {X : Top.{w}}

/--
Given a presieve `R` on `U`, we obtain a covering family of open sets in `X`, by taking as index
type the type of dependent pairs `(V, f)`, where `f : V ⟶ U` is in `R`.
-/
def covering_of_presieve (U : opens X) (R : presieve U) : (Σ V, {f : V ⟶ U // R f}) → opens X :=
λ f, f.1

@[simp]
lemma covering_of_presieve_apply (U : opens X) (R : presieve U) (f : Σ V, {f : V ⟶ U // R f}) :
  covering_of_presieve U R f = f.1 := rfl

namespace covering_of_presieve

variables (U : opens X) (R : presieve U)

/--
If `R` is a presieve in the grothendieck topology on `opens X`, the covering family associated to
`R` really is _covering_, i.e. the union of all open sets equals `U`.
-/
lemma supr_eq_of_mem_grothendieck (hR : sieve.generate R ∈ opens.grothendieck_topology X U) :
  supr (covering_of_presieve U R) = U :=
begin
  apply le_antisymm,
  { refine supr_le _,
    intro f,
    exact f.2.1.le, },
  intros x hxU,
  rw [opens.mem_coe, opens.mem_supr],
  obtain ⟨V, iVU, ⟨W, iVW, iWU, hiWU, -⟩, hxV⟩ := hR x hxU,
  exact ⟨⟨W, ⟨iWU, hiWU⟩⟩, iVW.le hxV⟩,
end

end covering_of_presieve

/--
Given a family of opens `U : ι → opens X` and any open `Y : opens X`, we obtain a presieve
on `Y` by declaring that a morphism `f : V ⟶ Y` is a member of the presieve if and only if
there exists an index `i : ι` such that `V = U i`.
-/
def presieve_of_covering_aux {ι : Type v} (U : ι → opens X) (Y : opens X) : presieve Y :=
λ V f, ∃ i, V = U i

/-- Take `Y` to be `supr U` and obtain a presieve over `supr U`. -/
def presieve_of_covering {ι : Type v} (U : ι → opens X) : presieve (supr U) :=
presieve_of_covering_aux U (supr U)

/-- Given a presieve `R` on `Y`, if we take its associated family of opens via
    `covering_of_presieve` (which may not cover `Y` if `R` is not covering), and take
    the presieve on `Y` associated to the family of opens via `presieve_of_covering_aux`,
    then we get back the original presieve `R`. -/
@[simp] lemma covering_presieve_eq_self {Y : opens X} (R : presieve Y) :
  presieve_of_covering_aux (covering_of_presieve Y R) Y = R :=
by { ext Z f, exact ⟨λ ⟨⟨_,_,h⟩,rfl⟩, by convert h, λ h, ⟨⟨Z,f,h⟩,rfl⟩⟩ }

namespace presieve_of_covering

variables {ι : Type v} (U : ι → opens X)

/--
The sieve generated by `presieve_of_covering U` is a member of the grothendieck topology.
-/
lemma mem_grothendieck_topology :
  sieve.generate (presieve_of_covering U) ∈ opens.grothendieck_topology X (supr U) :=
begin
  intros x hx,
  obtain ⟨i, hxi⟩ := opens.mem_supr.mp hx,
  exact ⟨U i, opens.le_supr U i, ⟨U i, 𝟙 _, opens.le_supr U i, ⟨i, rfl⟩, category.id_comp _⟩, hxi⟩,
end

/--
An index `i : ι` can be turned into a dependent pair `(V, f)`, where `V` is an open set and
`f : V ⟶ supr U` is a member of `presieve_of_covering U f`.
-/
def hom_of_index (i : ι) : Σ V, {f : V ⟶ supr U // presieve_of_covering U f} :=
⟨U i, opens.le_supr U i, i, rfl⟩

/--
By using the axiom of choice, a dependent pair `(V, f)` where `f : V ⟶ supr U` is a member of
`presieve_of_covering U f` can be turned into an index `i : ι`, such that `V = U i`.
-/
def index_of_hom (f : Σ V, {f : V ⟶ supr U // presieve_of_covering U f}) : ι := f.2.2.some

lemma index_of_hom_spec (f : Σ V, {f : V ⟶ supr U // presieve_of_covering U f}) :
  f.1 = U (index_of_hom U f) := f.2.2.some_spec

end presieve_of_covering

end Top.presheaf

namespace Top.opens

variables {X : Top} {ι : Type*}

lemma cover_dense_iff_is_basis [category ι] (B : ι ⥤ opens X) :
  cover_dense (opens.grothendieck_topology X) B ↔ opens.is_basis (set.range B.obj) :=
begin
  rw opens.is_basis_iff_nbhd,
  split, intros hd U x hx, rcases hd.1 U x hx with ⟨V,f,⟨i,f₁,f₂,hc⟩,hV⟩,
  exact ⟨B.obj i, ⟨i,rfl⟩, f₁.le hV, f₂.le⟩,
  intro hb, split, intros U x hx, rcases hb hx with ⟨_,⟨i,rfl⟩,hx,hi⟩,
  exact ⟨B.obj i, ⟨⟨hi⟩⟩, ⟨⟨i, 𝟙 _, ⟨⟨hi⟩⟩, rfl⟩⟩, hx⟩,
end

lemma cover_dense_induced_functor {B : ι → opens X} (h : opens.is_basis (set.range B)) :
  cover_dense (opens.grothendieck_topology X) (induced_functor B) :=
(cover_dense_iff_is_basis _).2 h

end Top.opens

section open_embedding

open Top.presheaf opposite

variables {C : Type u} [category.{v} C]
variables {X Y : Top.{w}} {f : X ⟶ Y} {F : Y.presheaf C}

lemma open_embedding.compatible_preserving (hf : open_embedding f) :
  compatible_preserving (opens.grothendieck_topology Y) hf.is_open_map.functor :=
begin
  haveI : mono f := (Top.mono_iff_injective f).mpr hf.inj,
  apply compatible_preserving_of_downwards_closed,
  intros U V i,
  refine ⟨(opens.map f).obj V, eq_to_iso $ opens.ext $ set.image_preimage_eq_of_subset $ λ x h, _⟩,
  obtain ⟨_, _, rfl⟩ := i.le h,
  exact ⟨_, rfl⟩
end

lemma is_open_map.cover_preserving (hf : is_open_map f) :
  cover_preserving (opens.grothendieck_topology X) (opens.grothendieck_topology Y) hf.functor :=
begin
  constructor,
  rintros U S hU _ ⟨x, hx, rfl⟩,
  obtain ⟨V, i, hV, hxV⟩ := hU x hx,
  exact ⟨_, hf.functor.map i, ⟨_, i, 𝟙 _, hV, rfl⟩, set.mem_image_of_mem f hxV⟩
end

lemma Top.presheaf.is_sheaf_of_open_embedding (h : open_embedding f)
  (hF : F.is_sheaf) : is_sheaf (h.is_open_map.functor.op ⋙ F) :=
pullback_is_sheaf_of_cover_preserving h.compatible_preserving h.is_open_map.cover_preserving ⟨_, hF⟩

end open_embedding

namespace Top.sheaf

open Top opposite

variables {C : Type u} [category.{v} C]
variables {X : Top.{w}} {ι : Type*} {B : ι → opens X}
variables (F : X.presheaf C) (F' : sheaf C X) (h : opens.is_basis (set.range B))

/-- The empty component of a sheaf is terminal -/
def is_terminal_of_empty (F : sheaf C X) : limits.is_terminal (F.val.obj (op ∅)) :=
F.is_terminal_of_bot_cover ∅ (by tidy)

/-- A variant of `is_terminal_of_empty` that is easier to `apply`. -/
def is_terminal_of_eq_empty (F : X.sheaf C) {U : opens X} (h : U = ∅) :
  limits.is_terminal (F.val.obj (op U)) :=
by convert F.is_terminal_of_empty

/-- If a family `B` of open sets forms a basis of the topology on `X`, and if `F'`
    is a sheaf on `X`, then a homomorphism between a presheaf `F` on `X` and `F'`
    is equivalent to a homomorphism between their restrictions to the indexing type
    `ι` of `B`, with the induced category structure on `ι`. -/
def restrict_hom_equiv_hom :
  ((induced_functor B).op ⋙ F ⟶ (induced_functor B).op ⋙ F'.1) ≃ (F ⟶ F'.1) :=
@cover_dense.restrict_hom_equiv_hom _ _ _ _ _ _ _ _ (opens.cover_dense_induced_functor h)
  _ F F'

@[simp] lemma extend_hom_app (α : ((induced_functor B).op ⋙ F ⟶ (induced_functor B).op ⋙ F'.1))
  (i : ι) : (restrict_hom_equiv_hom F F' h α).app (op (B i)) = α.app (op i) :=
by { nth_rewrite 1 ← (restrict_hom_equiv_hom F F' h).left_inv α, refl }

include h
lemma hom_ext {α β : F ⟶ F'.1} (he : ∀ i, α.app (op (B i)) = β.app (op (B i))) : α = β :=
by { apply (restrict_hom_equiv_hom F F' h).symm.injective, ext i, exact he i.unop }

end Top.sheaf
