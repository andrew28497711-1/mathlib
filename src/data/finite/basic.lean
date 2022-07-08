/-
Copyright (c) 2022 Kyle Miller. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kyle Miller
-/
import data.fintype.basic

/-!
# Finite types

This module defines a finiteness predicate on types called `finite`.
A type is `finite` if it is equivalent to `fin n` for some `n`, and
otherwise it is `infinite` (see `finite_or_infinite`). This predicate is
a `class`, and finiteness proofs are given as instances.

The `finite` predicate has no computational relevance and, being
`Prop`-valued, gets to enjoy proof irrelevance -- it represents the mere fact
that the type is finite.
While the `fintype` class also represents finiteness of a type, a key
difference is that a `fintype` instance represents finiteness in a
computable way: it gives a concrete algorithm to produce a `finset` whose
elements enumerate the terms of the given type. As such, one generally
relies on congruence lemmas when rewriting expressions involving
`fintype` instances.

Every `fintype` instance automatically gives a `finite` instance, but not
vice versa. Every `fintype` instance should be computable since they are meant
for computation. If it's not possible to write a computable `fintype` instance,
one should prefer writing a `finite` instance instead.

## Main definitions

* `finite α` denotes that `α` is a finite type.
* `finite.of_fintype` creates a `finite` instance from a `fintype` instance.
* `fintype.of_finite` noncomputably creates a `fintype` instance from a `finite` instance.
* `finite_or_infinite` is that every type is either `finite` or `infinite`.

## Implementation notes

The definition of `finite α` is not just `nonempty (fintype α)` since `fintype` requires
that `α : Type*`, and the definition in this module allows for `α : Sort*`. This means
we can write the instance `finite.prop`.

There is an apparent duplication of many `fintype` instances in this module,
however they follow a pattern: if a `fintype` instance depends on `decidable`
instances or other `fintype` instances, then we need to "lower" the instance
to be a `finite` instance by removing the `decidable` instances and switching
the `fintype` instances to `finite` instances. These are precisely the ones
that cannot be inferred using `finite.of_fintype'`. (However, when using
`open_locale classical` or the `classical` tactic the instances relying only
on `decidable` instances will give `finite` instances.) In the future we might
consider writing automation to create these "lowered" instances.

## Tags

finiteness, finite types

-/

noncomputable theory
open_locale classical

variables {α β γ : Type*}

lemma of_subsingleton {α : Sort*} [subsingleton α] : finite α := finite.of_equiv _ equiv.plift

@[nolint instance_priority]
instance finite.prop (p : Prop) : finite p := of_subsingleton

namespace finite

lemma exists_max [finite α] [nonempty α] [linear_order β] (f : α → β) :
  ∃ x₀ : α, ∀ x, f x ≤ f x₀ :=
by { haveI := fintype.of_finite α, exact fintype.exists_max f }

lemma exists_min [finite α] [nonempty α] [linear_order β] (f : α → β) :
  ∃ x₀ : α, ∀ x, f x₀ ≤ f x :=
by { haveI := fintype.of_finite α, exact fintype.exists_min f }

@[priority 100] -- see Note [lower instance priority]
instance of_is_empty {α : Sort*} [is_empty α] : finite α := finite.of_equiv _ equiv.plift

instance [finite α] [finite β] : finite (α × β) :=
by { haveI := fintype.of_finite α, haveI := fintype.of_finite β, apply_instance }

instance {α β : Sort*} [finite α] [finite β] : finite (pprod α β) :=
of_equiv _ equiv.pprod_equiv_prod_plift.symm

lemma prod_left (β) [finite (α × β)] [nonempty β] : finite α :=
of_surjective (prod.fst : α × β → α) prod.fst_surjective

lemma prod_right (α) [finite (α × β)] [nonempty α] : finite β :=
of_surjective (prod.snd : α × β → β) prod.snd_surjective

instance [finite α] [finite β] : finite (α ⊕ β) :=
by { haveI := fintype.of_finite α, haveI := fintype.of_finite β, apply_instance }

lemma sum_left (β) [finite (α ⊕ β)] : finite α :=
of_injective (sum.inl : α → α ⊕ β) sum.inl_injective

lemma sum_right (α) [finite (α ⊕ β)] : finite β :=
of_injective (sum.inr : β → α ⊕ β) sum.inr_injective

instance {β : α → Type*} [finite α] [Π a, finite (β a)] : finite (Σ a, β a) :=
by { letI := fintype.of_finite α, letI := λ a, fintype.of_finite (β a), apply_instance }

instance {ι : Sort*} {π : ι → Sort*} [finite ι] [Π i, finite (π i)] : finite (Σ' i, π i) :=
of_equiv _ (equiv.psigma_equiv_sigma_plift π).symm

end finite

/-- This instance also provides `[finite s]` for `s : set α`. -/
instance subtype.finite {α : Sort*} [finite α] {p : α → Prop} : finite {x // p x} :=
finite.of_injective coe subtype.coe_injective

instance pi.finite {α : Sort*} {β : α → Sort*} [finite α] [∀ a, finite (β a)] : finite (Π a, β a) :=
begin
  haveI := fintype.of_finite (plift α),
  haveI := λ a, fintype.of_finite (plift (β a)),
  exact finite.of_equiv (Π (a : plift α), plift (β (equiv.plift a)))
    (equiv.Pi_congr equiv.plift (λ _, equiv.plift)),
end

instance vector.finite {α : Type*} [finite α] {n : ℕ} : finite (vector α n) :=
by { haveI := fintype.of_finite α, apply_instance }

instance quot.finite {α : Sort*} [finite α] (r : α → α → Prop) : finite (quot r) :=
finite.of_surjective _ (surjective_quot_mk r)

instance quotient.finite {α : Sort*} [finite α] (s : setoid α) : finite (quotient s) :=
quot.finite _

instance function.embedding.finite {α β : Sort*} [finite β] : finite (α ↪ β) :=
begin
  casesI nonempty_fintype (plift β),
  exact finite.of_equiv (plift α ↪ plift β) (equiv.plift.embedding_congr equiv.plift)
end

instance equiv.finite_right {α β : Sort*} [finite β] : finite (α ≃ β) :=
finite.of_injective equiv.to_embedding $ λ e₁ e₂ h, equiv.ext $
  by convert fun_like.congr_fun h

instance equiv.finite_left {α β : Sort*} [finite α] : finite (α ≃ β) :=
finite.of_equiv _ ⟨equiv.symm, equiv.symm, equiv.symm_symm, equiv.symm_symm⟩

instance [finite α] {n : ℕ} : finite (sym α n) :=
by { haveI := fintype.of_finite α, apply_instance }
