/-
Copyright (c) 2022 Damiano Testa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Damiano Testa
-/
import data.finsupp.basic

/-!
#  `ne_locus` for finitely supported functions

Let `α N` be two Types, and assume that `N` has a `0` and let `f g : α →₀ N` be finitely supported
functions.

## Main definition

* `finsupp.ne_locus f g : finset α`, the finite subset of `α` where `f` and `g` differ.

In the case in which `N` is an additive group, `finsupp.ne_locus f g` coincides with
`finsupp.support (f - g)`.
-/

variables {α N : Type*}

namespace finsupp
variables [decidable_eq α] [decidable_eq N]

section ne_locus

section N_has_zero
variables [has_zero N] {f g : α →₀ N}

/--  Given two finitely supported functions `f g : α →₀ N`, `finsupp.ne_locus f g` is the `finset`
where `f` and `g` differ. This generalizes `(f - g).support` to situations without subtraction. -/
def ne_locus (f g : α →₀ N) : finset α :=
(f.support ∪ g.support).filter (λ x, f x ≠ g x)

@[simp]
lemma mem_ne_locus {a : α} : a ∈ f.ne_locus g ↔ f a ≠ g a :=
by simpa only [ne_locus, finset.mem_filter, finset.mem_union, mem_support_iff,
    and_iff_right_iff_imp] using ne.ne_or_ne _

lemma coe_ne_locus : ↑(f.ne_locus g) = {x | f x ≠ g x} :=
by { ext, exact mem_ne_locus }

@[simp] lemma ne_locus_eq_empty : f.ne_locus g = ∅ ↔ f = g :=
begin
  refine ⟨λ h, _, λ h, h ▸ by simp [ne_locus]⟩,
  ext a,
  exact not_not.mp (mem_ne_locus.not.mp (finset.eq_empty_iff_forall_not_mem.mp h a)),
end

@[simp] lemma nonempty_ne_locus_iff : (f.ne_locus g).nonempty ↔ f ≠ g :=
finset.nonempty_iff_ne_empty.trans ne_locus_eq_empty.not

variables (f g)

lemma ne_locus_comm (f g : α →₀ N) : f.ne_locus g = g.ne_locus f :=
by simp_rw [ne_locus, finset.union_comm, ne_comm]

@[simp]
lemma ne_locus_zero_right : f.ne_locus 0 = f.support :=
by { ext, rw [mem_ne_locus, mem_support_iff, coe_zero, pi.zero_apply] }

@[simp]
lemma ne_locus_zero_left : (0 : α →₀ N).ne_locus f = f.support :=
(ne_locus_comm _ _).trans (ne_locus_zero_right _)

lemma subset_map_range_ne_locus {M} [decidable_eq M] [has_zero M] {F : N → M} (F0 : F 0 = 0) :
  (f.map_range F F0).ne_locus (g.map_range F F0) ⊆ f.ne_locus g :=
begin
  refine λ x, _,
  simp only [mem_ne_locus, map_range_apply, not_imp_not],
  exact congr_arg _,
end

lemma map_range_ne_locus_eq {M} [decidable_eq M] [has_zero M]
  {F : N → M} (F0 : F 0 = 0) (hF : function.injective F) :
  (f.map_range F F0).ne_locus (g.map_range F F0) = f.ne_locus g :=
by { ext, simpa only [mem_ne_locus] using hF.ne_iff }

end N_has_zero

lemma add_ne_locus_add_eq_left [add_left_cancel_monoid N] (f g h : α →₀ N) :
  (f + g).ne_locus (f + h) = g.ne_locus h  :=
begin
  ext,
  simp only [ne_locus, ne.def, add_right_inj, finset.mem_filter, finset.mem_union, mem_support_iff,
    coe_add, pi.add_apply, and.congr_left_iff],
  exact λ bc, ⟨λ h, ne.ne_or_ne 0 bc, λ h, ne.ne_or_ne _ ((add_right_inj _).not.mpr bc)⟩,
end

--  can this proof by replaced by the previous one applied to `Nᵃᵒᵖ` and interlaced with `op unop`?
lemma add_ne_locus_add_eq_right [add_right_cancel_monoid N] (f g h : α →₀ N) :
  (f + h).ne_locus (g + h) = f.ne_locus g  :=
begin
  ext,
  simp only [ne_locus, ne.def, add_left_inj, finset.mem_filter, finset.mem_union, mem_support_iff,
    coe_add, pi.add_apply, and.congr_left_iff],
  exact λ bc, ⟨λ h, ne.ne_or_ne 0 bc, λ h, ne.ne_or_ne _ ((add_left_inj _).not.mpr bc)⟩,
end

lemma ne_locus_neg [add_group N] (f g : α →₀ N) : (- f).ne_locus g = f.ne_locus (- g) :=
begin
  nth_rewrite 0 ← neg_neg g,
  exact map_range_ne_locus_eq _ _ neg_zero neg_injective,
end

@[simp] lemma ne_locus_eq_support_sub [add_group N] (f g : α →₀ N) :
  f.ne_locus g = (f - g).support :=
by rw [← add_ne_locus_add_eq_right _ _ (- g), add_right_neg, ne_locus_zero_right, sub_eq_add_neg]

end ne_locus

end finsupp
