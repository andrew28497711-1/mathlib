/-
Copyright (c) 2021 Bhavik Mehta, Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Bhavik Mehta, Alena Gusakov, Yaël Dillies
-/
import algebra.big_operators.basic
import data.nat.interval
import order.antichain
import order.polytope.grade

/-!
# `n`-sets and slice

> THIS FILE IS SYNCHRONIZED WITH MATHLIB4.
> Any changes to this file require a corresponding PR to mathlib4.

This file defines the `n`-th slice of a set family and provides a way to say that a set family is
made of `n`-sets.

An `n`-set is a finset of cardinality `n` (aka of *size* `n`). The `n`-th slice of a set family is
the set family made of its `n`-sets.

## Main declarations

* `set.sized`: `s.sized n` means that `s` only contains `n`-sets.
* `finset.slice`: `s.slice n` is the set of `n`-sets in `s`.

## Notation

`s # n` is notation for `s.slice n` in locale `finset_family`.
-/

open finset nat
open_locale big_operators

variables {𝕆 α : Type*} {ι : Sort*} {κ : ι → Sort*}

namespace set
section preorder
variables [preorder 𝕆] [preorder α] [grade_order 𝕆 α] {s t : set α} {n : 𝕆}

/-! ### Families of `n`-sets -/

/-- `sized n s` means that every element in `s` has grade `n`. -/
def sized (n : 𝕆) (s : set α) : Prop := ∀ ⦃a⦄, a ∈ s → grade 𝕆 a = n

lemma sized.mono (h : s ⊆ t) (ht : t.sized n) : s.sized n := λ a ha, ht $ h ha

lemma sized_union : (s ∪ t).sized n ↔ s.sized n ∧ t.sized n :=
⟨λ hs, ⟨hs.mono $ subset_union_left _ _, hs.mono $ subset_union_right _ _⟩,
  λ hs a ha, ha.elim (λ h, hs.1 h) $ λ h, hs.2 h⟩

alias sized_union ↔ _ sized.union

--TODO: A `forall_Union` lemma would be handy here.
@[simp] lemma sized_Union {f : ι → set α} : (⋃ i, f i).sized n ↔ ∀ i, (f i).sized n :=
by { simp_rw [set.sized, set.mem_Union, forall_exists_index], exact forall_swap }

@[simp] lemma sized_Union₂ {f : Π i, κ i → set α} :
  (⋃ i j, f i j).sized n ↔ ∀ i j, (f i j).sized n :=
by simp_rw sized_Union

lemma sized_powerset_len (s : finset α) (r : ℕ) : (powerset_len r s : set (finset α)).sized n :=
λ t ht, (mem_powerset_len.1 ht).2

end preorder

section partial_order
variables [preorder 𝕆] [partial_order α] [grade_order 𝕆 α] {s : set α} {n : 𝕆}

protected lemma sized.is_antichain (hs : s.sized n) : is_antichain (≤) s :=
λ a ha b hb h hab, (grade_strict_mono $ hab.lt_of_ne h).ne $ (hs ha).trans (hs hb).symm

end partial_order

section order_bot
variables [partial_order 𝕆] [order_bot 𝕆] [partial_order α] [order_bot α] [grade_min_order 𝕆 α]
  {s : set α}

lemma sized.subset_singleton_bot (hs : s.sized (⊥ : 𝕆)) : s ⊆ {⊥} :=
λ a ha, (is_min_grade_iff.1 $ by { rw hs ha, exact is_min_bot }).eq_bot

@[simp] lemma sized_bot_iff : s.sized (⊥ : 𝕆) ↔ s ⊆ {⊥} :=
⟨λ hs a ha, (is_min_grade_iff.1 $ by { rw hs ha, exact is_min_bot }).eq_bot,
  λ hs, sized.mono hs $ λ a ha, ((is_min_iff_eq_bot.2 ha).grade 𝕆).eq_bot⟩

alias sized_bot_iff ↔ set.sized.subset_singleton_bot _

protected lemma sized.subsingleton (hs : s.sized (⊥ : 𝕆)) : s.subsingleton :=
subsingleton_of_subset_singleton hs.subset_singleton_bot

end order_bot

section order_top
variables [partial_order 𝕆] [order_top 𝕆] [partial_order α] [order_top α] [grade_max_order 𝕆 α]
  {s : set α}

lemma sized.subset_singleton_top (hs : s.sized (⊤ : 𝕆)) : s ⊆ {⊤} :=
λ a ha, (is_max_grade_iff.1 $ by { rw hs ha, exact is_max_top }).eq_top

@[simp] lemma sized_top_iff : s.sized (⊤ : 𝕆) ↔ s ⊆ {⊤} :=
⟨λ hs a ha, (is_max_grade_iff.1 $ by { rw hs ha, exact is_max_top }).eq_top,
  λ hs, sized.mono hs $ λ a ha, ((is_max_iff_eq_top.2 ha).grade 𝕆).eq_top⟩

alias sized_top_iff ↔ set.sized.subset_singleton_top _

protected lemma sized.subsingleton' (hs : s.sized (⊤ : 𝕆)) : s.subsingleton :=
subsingleton_of_subset_singleton hs.subset_singleton_top

end order_top
end set

namespace finset
section sized
variables [fintype α] {𝒜 : finset (finset α)} {s : finset α} {n : ℕ}

lemma subset_powerset_len_univ_iff : 𝒜 ⊆ powerset_len n univ ↔ (𝒜 : set (finset α)).sized n :=
forall_congr $ λ s, by rw [mem_powerset_len_univ_iff, finset.grade, mem_coe]

alias subset_powerset_len_univ_iff  ↔ _ _root_.set.sized.subset_powerset_len_univ

lemma _root_.set.sized.card_le (h𝒜 : (𝒜 : set (finset α)).sized n) :
  card 𝒜 ≤ (fintype.card α).choose n :=
begin
  rw [fintype.card, ←card_powerset_len],
  exact card_le_of_subset h𝒜.subset_powerset_len_univ,
end

end sized

/-! ### Slices -/

section slice
section preorder
variables [decidable_eq 𝕆] [preorder 𝕆] [preorder α] [grade_order 𝕆 α] {s : finset α} {a b c : α}
  {m n : 𝕆}

/-- The `n`-th slice of a set family is the subset of its elements which have cardinality `n`. -/
def slice (s : finset α) (n : 𝕆) : finset α := s.filter (λ a, grade 𝕆 a = n)

localized "infix (name := finset.slice) ` # `:90 := finset.slice" in finset_family

/-- `a` is in the `n`-th slice of `s` iff it's in `s` and has grade `n`. -/
lemma mem_slice : a ∈ s # n ↔ a ∈ s ∧ grade 𝕆 a = n := mem_filter

/-- The `n`-th slice of `s` is a subset of `s`. -/
lemma slice_subset : s # n ⊆ s := filter_subset _ _

/-- Everything in the `n`-th slice of `s` has size `n`. -/
lemma sized_slice : (s # n : set α).sized n := λ _, and.right ∘ mem_slice.mp

lemma eq_of_mem_slice (h₁ : a ∈ s # m) (h₂ : a ∈ s # n) : m = n :=
(sized_slice h₁).symm.trans $ sized_slice h₂

/-- Elements in distinct slices must be distinct. -/
lemma ne_of_mem_slice (ha : a ∈ s # m) (hb : b ∈ s # n) : m ≠ n → a ≠ b :=
mt $ λ h, (sized_slice ha).symm.trans ((congr_arg (grade 𝕆) h).trans (sized_slice hb))

lemma pairwise_disjoint_slice : (set.univ : set 𝕆).pairwise_disjoint (slice s) :=
λ m _ n _ hmn, disjoint_filter.2 $ λ s hs hm hn, hmn $ hm.symm.trans hn

end preorder

variables [preorder α] [grade_order ℕ α] [fintype α] (𝒜 : finset (finset α))

@[simp] lemma bUnion_slice [decidable_eq α] : (Iic $ fintype.card α).bUnion 𝒜.slice = 𝒜 :=
subset.antisymm (bUnion_subset.2 $ λ r _, slice_subset) $ λ s hs,
  mem_bUnion.2 ⟨s.card, mem_Iic.2 $ s.card_le_univ, mem_slice.2 $ ⟨hs, rfl⟩⟩

@[simp] lemma sum_card_slice : ∑ r in Iic (fintype.card α), (𝒜 # r).card = 𝒜.card :=
begin
  letI := classical.dec_eq α,
  rw [←card_bUnion, bUnion_slice],
  exact finset.pairwise_disjoint_slice.subset (set.subset_univ _),
end

end slice
end finset
