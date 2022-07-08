/-
Copyright (c) 2022 Kyle Miller. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kyle Miller
-/
import logic.equiv.basic

/-!
# Definition of the `finite` typeclass

This file defines a typeclass `finite` saying that `α : Sort*` is finite. A type is `finite` if it
is equivalent to `fin n` for some `n`.

The `finite` predicate has no computational relevance and, being `Prop`-valued, gets to enjoy proof
irrelevance -- it represents the mere fact that the type is finite.  While the `fintype` class also
represents finiteness of a type, a key difference is that a `fintype` instance represents finiteness
in a computable way: it gives a concrete algorithm to produce a `finset` whose elements enumerate
the terms of the given type. As such, one generally relies on congruence lemmas when rewriting
expressions involving `fintype` instances.

## Tags

finite, fintype
-/

universes u v
open function
variables {α β : Sort*}

/-- A type is `finite` if it is in bijective correspondence to some
`fin n`.

While this could be defined as `nonempty (fintype α)`, it is defined
in this way to allow there to be `finite` instances for propositions.
-/
class inductive finite (α : Sort*) : Prop
| intro {n : ℕ} : α ≃ fin n → finite

lemma finite.exists_equiv_fin (α : Sort*) [h : finite α] : ∃ (n : ℕ), nonempty (α ≃ fin n) :=
by { casesI h with n f, exact ⟨n, ⟨f⟩⟩ }

lemma finite.of_equiv (α : Sort*) [h : finite α] (f : α ≃ β) : finite β :=
by { casesI h with n e, exact finite.intro (f.symm.trans e) }

lemma equiv.finite_iff (f : α ≃ β) : finite α ↔ finite β :=
⟨λ _, by exactI finite.of_equiv _ f, λ _, by exactI finite.of_equiv _ f.symm⟩

lemma function.bijective.finite_iff {f : α → β} (h : bijective f) : finite α ↔ finite β :=
(equiv.of_bijective f h).finite_iff

namespace finite

lemma of_bijective [finite α] {f : α → β} (h : bijective f) : finite β := h.finite_iff.mp ‹_›

instance [finite α] : finite (plift α) := of_equiv α equiv.plift.symm
instance {α : Type v} [finite α] : finite (ulift.{u} α) := of_equiv α equiv.ulift.symm

end finite
