/-
Copyright (c) 2022 Russell Emerine. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Russell Emerine
-/
import computability.regular_expressions
import computability.NFA

/-!
# Generalized Nondeterministic Finite Automata

This file contains the definition of a Generalized Nondeterministic Finite Automaton, a state
machine which determines whether a string (implemented as a list over an arbitrary alphabet) is in
a regular set by evaluating the string over every possible series of regular expressions. We show 
that GNFA's are equivalent to NFA's, and that GNFA's are equivalent to smaller GNFA's with a state
"ripped" out. Through this mechanism, we show that NFA's are equivalent to regular expressions.
Unlike for DFA's and NFA's, GNFA's can only be made with a `fin` as the state type.

## References

TODO: someone please tell me how to best cite this file?
* <https://courses.engr.illinois.edu/cs373/sp2013/Lectures/lec07.pdf>
-/

namespace fin

/-
TODO: Is there a short way to write this inline? I want to cause a contradiction against
a hypothesis of fin.cast_succ i = fin.last n, but ne_of_lt and is_lt don't quite work there.
Also, maybe move to data/fin.
-/
theorem cast_succ_ne_last {n i} : fin.cast_succ i ≠ fin.last n :=
begin
  apply ne_of_lt,
  exact is_lt i,
end

end fin

universes u v

/--
A GNFA is a set of `n + 2` states and a transition function between two states. The transition
function takes the starting state or any internal state as the first state, and the accepting
state or any internal state as the second state. There is a transition between *all* of these
combinations, in the form of a regular expression. When following a transition, some matching
prefix of the input string is taken. "No transition" can be simulated by using the regular
expression `0`, which accepts no strings.
-/
structure GNFA (α : Type u) (n : ℕ) :=
  (step : option (fin n) → option (fin n) → regular_expression α)

variables {α : Type u} {σ : Type v} {n : ℕ}

namespace regular_expression

/--
A string matches the sum of a list of regular expressions if and only if there is some regular
expression in the list that it matches. This is because the sum of regular expressions matches the
union of their respective languages.

TODO: probably move to computability/regular_expression
-/
theorem mem_sum_iff_exists_mem (x : list α) (rs : list (regular_expression α)) :
  (list.sum rs).matches x ↔ (∃ (r : regular_expression α), r ∈ rs ∧ r.matches x) :=
begin
  split,
  { rw ← rs.reverse_reverse,
    induction rs.reverse,
    case nil {
      assume hx,
      cases hx,      
    },
    case cons : r rs ih {
      assume hx,
      unfold list.sum at hx,
      simp at *,
      cases hx,
      case inl {
        rcases ih hx with ⟨r, mem, matches⟩,
        exact ⟨r, or.inl mem, matches⟩,
      },
      case inr {
        exact ⟨r, or.inr rfl, hx⟩,
      },
    },
  },
  { rw ← rs.reverse_reverse,
    induction rs.reverse,
    case nil {
      assume hx,
      simp at hx,
      contradiction,
    },
    case cons : r rs ih {
      assume hx,
      unfold list.sum,
      simp at *,
      rcases hx with ⟨r', hr', matches⟩,
      cases hr',
      case inl {
        left,
        exact ih r' hr' matches,
      },
      case inr {
        right,
        rw hr' at matches,
        exact matches,
      },
    },
  },
end

end regular_expression

namespace GNFA

instance : inhabited (GNFA α n) := ⟨ GNFA.mk (λ _ _, 0) ⟩

/--
A `trace` of a string and an internal state of a GNFA represents a way to get to the state via
transitions of the GNFA that match parts of the string.
-/
inductive trace (M : GNFA α n) : list α → fin n → Prop
| start : ∀ {x q}, x ∈ (M.step none (some q)).matches → trace x q
| step : ∀ {x y z} p {q}, trace y p → z ∈ (M.step (some p) (some q)).matches → x = y ++ z → trace x q

/--
An `accepts` of a string represents a way to get to the accepting state of a GNFA via transitions
of the GNFA that match parts of the string. Since this is the definition of when a GNFA accepts
a string, this also is how the accepting language of a GNFA is described.

TODO: make description clearer
-/
inductive accepts (M : GNFA α n) : language α
| start : ∀ {x}, x ∈ (M.step none none).matches → accepts x
| step : ∀ {x y z} q, M.trace y q → z ∈ (M.step (some q) none).matches → x = y ++ z → accepts x

/--
"Rips" an internal state out of a GNFA, making it smaller by one without changing its accepting
language.
-/
def rip (M : GNFA α n.succ) : GNFA α n :=
⟨
  λ p q,
  let p := p.map fin.cast_succ in
  let q := q.map fin.cast_succ in
  let n : option (fin n.succ) := some ⟨n, lt_add_one n⟩ in
  M.step p q + M.step p n * (M.step n n).star * M.step n q
⟩

lemma rip_trace_aux (M : GNFA α n.succ) {x q} (t : M.trace x q) :
  (∃ p, q = fin.cast_succ p ∧ M.rip.trace x p) ∨
  q = fin.last n ∧
    ( ∃ y z (xs : list (list α)) p,
      (option.map (λ p, M.rip.trace y p) p).get_or_else (y = []) ∧
      z ∈ (M.step (p.map fin.cast_succ) (some (fin.last n))).matches ∧
      (∀ x ∈ xs, x ∈ (M.step (some (fin.last n)) (some (fin.last n))).matches) ∧
      x = y ++ z ++ xs.join) :=
begin
  induction t,
  case start : x q matches {
    revert matches,
    refine fin.last_cases _ _ q,
    { assume matches,
      right,
      refine ⟨rfl, _⟩,
      refine ⟨[], x, [], none, by simp, matches, _, by simp⟩,
      assume x mem,
      cases mem,
    },
    { assume q matches,
      left,
      refine ⟨q, rfl, _⟩,
      exact trace.start (or.inl matches),
    },
  },
  case step : x y z p q t matches eq ih {
    rw eq, clear eq x,
    revert ih matches,
    refine fin.last_cases _ _ p; refine fin.last_cases _ _ q,
    { assume ih matches,
      right,
      refine ⟨rfl, _⟩,
      cases ih,
      case inl {
        rcases ih with ⟨p, eq, t⟩,
        exfalso,
        exact fin.cast_succ_ne_last eq.symm,
      },
      rcases ih with ⟨_, y, z', xs, p, t', matches', x_matches, eq⟩,
      rw eq, clear eq,
      refine ⟨y, z', xs ++ [z], p, t', matches', _, by simp⟩,
      { assume x mem,
        simp at mem,
        cases mem,
        case inl {
          exact x_matches x mem,
        },
        case inr {
          rw mem,
          exact matches,
        },
      },
    },
    { assume q ih matches,
      left,
      refine ⟨q, rfl, _⟩,
      cases ih,
      case inl {
        rcases ih with ⟨p, eq, t⟩,
        exfalso,
        exact fin.cast_succ_ne_last eq.symm,
      },
      rcases ih with ⟨_, y, z', xs, p, t', matches', x_matches, eq⟩,
      rw eq, clear eq,
      cases p,
      case none {
        simp at t',
        rw t', clear t' y,
        refine trace.start (or.inr _),
        simp,
        rw ← list.append_assoc,
        refine ⟨_, _, _, matches, rfl⟩,
        refine ⟨_, _, matches', _, rfl⟩,
        exact ⟨_, rfl, x_matches⟩,
      },
      case some {
        simp at t',
        rw list.append_assoc,
        rw list.append_assoc,
        refine trace.step _ t' _ rfl,
        right,
        rw ← list.append_assoc,
        refine ⟨_, _, _, matches, rfl⟩,
        refine ⟨_, _, matches', _, rfl⟩,
        exact ⟨_, rfl, x_matches⟩,
      },
    },
    { assume p ih matches,
      right,
      refine ⟨rfl, _⟩,
      cases ih,
      case inl {
        rcases ih with ⟨p', eq, t⟩,
        simp at eq, rw ← eq at t, clear eq p',
        refine ⟨y, z, [], some p, by simp [t], matches, _, by simp⟩,
        assume x mem,
        cases mem,
      },
      case inr {
        rcases ih with ⟨eq, _⟩,
        exfalso,
        exact fin.cast_succ_ne_last eq,
      },
    },
    { assume q p ih matches,
      cases ih,
      case inl {
        rcases ih with ⟨p', eq, t⟩,
        simp at eq, rw ← eq at t, clear eq p',
        left,
        refine ⟨q, rfl, _⟩,
        exact trace.step _ t (or.inl matches) rfl,
      },
      case inr {
        rcases ih with ⟨eq, _⟩,
        exfalso,
        exact fin.cast_succ_ne_last eq,
      },
    },
  },
end

lemma rip_trace_correct (M : GNFA α n.succ) {x} {q : fin n} : M.trace x (fin.cast_succ q) ↔ M.rip.trace x q :=
begin
  split,
  { assume t,
    cases M.rip_trace_aux t,
    case inl {
      rcases h with ⟨p, eq, t⟩,
      simp at eq,
      rw eq,
      exact t,
    },
    case inr {
      cases h with eq _,
      exfalso,
      exact fin.cast_succ_ne_last eq,
    },
  },
  { assume t,
    induction t,
    case start : x q matches { 
      cases matches,
      case inl {
        exact trace.start matches,
      },
      case inr {
        rcases matches with ⟨y, z, hy, hz, eq⟩,
        rw ← eq, clear eq x,
        refine trace.step ⟨n, lt_add_one n⟩ _ hz rfl,
        clear hz z,
        rcases hy with ⟨y, z, hy, hz, eq⟩,
        rw ← eq, clear eq,        
        rcases hz with ⟨xs, join, matches⟩,
        rw join, clear join,
        revert matches,
        rw ← xs.reverse_reverse,
        induction xs.reverse,
        case nil {
          simp,
          exact trace.start hy,
        },
        case cons : x xs ih {
          assume matches,
          simp at *,
          rw ← list.append_assoc,
          refine trace.step _ (ih _) (matches x (or.inr rfl)) rfl,
          assume y mem,
          exact matches y (or.inl mem),
        },
      },
    },
    case step : x y z p q t matches eq ih {
      cases matches,
      case inl {
        exact trace.step _ ih matches eq,
      },
      case inr {
        rw eq, clear eq x,
        rcases matches with ⟨w, x, hw, hx, eq⟩,
        rw ← eq, clear eq z,
        rw ← list.append_assoc,
        refine trace.step _ _ hx rfl,
        rcases hw with ⟨w, x, hw, hx, eq⟩,
        rw ← eq, clear eq,
        rw ← list.append_assoc,
        rcases hx with ⟨xs, join, matches⟩,
        rw join, clear join x,
        revert matches,
        rw ← xs.reverse_reverse,
        induction xs.reverse,
        case nil {
          assume matches,
          simp at *,
          exact trace.step _ ih hw rfl,
        },
        case cons : x xs ih {
          assume matches,
          simp at *,
          rw ← list.append_assoc,
          rw ← list.append_assoc,
          refine trace.step _ _ (matches x (or.inr rfl)) rfl,
          rw list.append_assoc,
          apply ih,
          assume y mem,
          exact matches y (or.inl mem),
        },
      },
    },
  },
end

/- TODO: maybe mark as @simp -/
theorem rip_correct (M : GNFA α n.succ) : M.rip.accepts = M.accepts :=
begin
  ext,
  split,
  { assume t,
    cases t,
    case start : x matches {
      cases matches,
      case inl {
        simp at matches,
        exact accepts.start matches,
      },
      case inr {
        rcases matches with ⟨y, z, y_matches, z_matches, eq⟩,
        rw ← eq,
        refine accepts.step _ _ z_matches rfl,
        rcases y_matches with ⟨y, z, y_matches, z_matches, eq⟩,
        rw ← eq, clear eq,
        rcases z_matches with ⟨xs, join, x_matches⟩,
        rw join, clear join,
        revert x_matches,
        rw ← xs.reverse_reverse,
        induction xs.reverse,
        case nil {
          assume x_matches,
          refine trace.start _,
          simpa,
        },
        case cons : x xs ih {
          assume x_matches,
          simp at *,
          rw ← list.append_assoc,
          refine trace.step _ _ (x_matches x (or.inr rfl)) rfl,
          apply ih,
          assume x mem,
          exact x_matches x (or.inl mem),
        },
      },
    },
    case step : x y z q t matches eq {
      rw eq, clear eq x,
      cases matches,
      case inl {
        refine accepts.step _ _ matches rfl,
        rw rip_trace_correct,
        exact t,
      },
      case inr {
        rcases matches with ⟨z, x, z_matches, x_matches, eq⟩,
        rw ← eq, clear eq,
        rw ← list.append_assoc,
        refine accepts.step _ _ x_matches rfl,
        clear x_matches x,
        rcases z_matches with ⟨z, x, z_matches, x_matches, eq⟩,
        rw ← eq, clear eq,
        rw ← list.append_assoc,
        rcases x_matches with ⟨xs, join, x_matches⟩,
        rw join, clear join,
        revert x_matches,
        rw ← xs.reverse_reverse,
        induction xs.reverse,
        case nil {
          assume matches,
          simp,
          refine trace.step _ _ z_matches rfl,
          rw rip_trace_correct,
          exact t,
        },
        case cons : x xs ih {
          assume matches,
          simp at *,
          rw ← list.append_assoc,
          rw ← list.append_assoc,
          refine trace.step _ _ (matches x (or.inr rfl)) rfl,
          rw list.append_assoc,
          apply ih,
          assume x mem,
          exact matches x (or.inl mem),
        },
      },
    },
  },
  { assume t,
    cases t,
    case start : x matches {
      refine accepts.start (or.inl matches),
    },
    case step : x y z q t matches eq {
      rw eq, clear eq x,
      cases M.rip_trace_aux t,
      case inl {
        rcases h with ⟨q, eq, t⟩,
        rw eq at matches, clear eq,
        exact accepts.step _ t (or.inl matches) rfl,
      },
      case inr {
        rcases h with ⟨eq, h⟩,
        rw eq at *, clear eq,
        rcases h with ⟨y, w, xs, p, t', w_matches, x_matches, eq⟩,
        rw eq, clear eq,
        cases p,
        case none {
          simp at *,
          rw t', clear t' y,
          simp,
          refine accepts.start _,
          rw ← list.append_assoc,
          right,
          refine ⟨_, _, _, matches, rfl⟩,
          refine ⟨_, _, w_matches, _, rfl⟩,
          exact ⟨xs, rfl, x_matches⟩,
        },
        case some {
          simp at *,
          refine accepts.step _ t' _ rfl,
          right,
          rw ← list.append_assoc,
          refine ⟨_, _, _, matches, rfl⟩,
          refine ⟨_, _, w_matches, _, rfl⟩,
          exact ⟨xs, rfl, x_matches⟩,
        },
      },
    },
  },
end

/--
Convert a GNA to a regular expression by repeatedly removing internal states. When there are no
internal states left, there will only be one transition, from the starting state to the accepting
state. Its regular expression will accept the same language as the original GNFA.
-/
def to_regular_expression : Π {n}, GNFA α n → regular_expression α
| 0 M := M.step none none
| (nat.succ n) M := M.rip.to_regular_expression

theorem to_regular_expression_correct (M : GNFA α n) : M.accepts = M.to_regular_expression.matches :=
begin
  induction n,
  case zero {
    ext,
    split,
    { assume hx,
      cases hx,
      case start : x matches {
        exact matches,
      },
      case step : x y z q t matches eq {
        exact fin.elim0 q,        
      },
    },
    { assume matches,
      exact accepts.start matches,
    },
  },
  case succ : n ih {
    rw ← M.rip_correct,
    rw ih M.rip,
    refl,
  },
end

end GNFA

namespace NFA

/--
Given an equivalence between `σ` and `τ`, convert an NFA with state type `σ` into the corresponding
NFA with state type `τ`.

TODO: possibly move to computability/NFA
-/
def convert (M : NFA α σ) {τ} (equiv : σ ≃ τ) : NFA α τ :=
⟨
  (λ p a q, M.step (equiv.inv_fun p) a (equiv.inv_fun q)),
  (λ q, M.start (equiv.inv_fun q)),
  (λ q, M.accept (equiv.inv_fun q))
⟩

/- TODO: maybe mark as @simp -/
theorem convert_correct (M : NFA α σ) {τ} (equiv : σ ≃ τ) : M.accepts = (M.convert equiv).accepts :=
begin
  ext,
  split,
  { rintros ⟨q, accept, eval⟩,
    refine ⟨equiv.to_fun q, _, _⟩,
    { unfold convert,
      rw set.mem_def at *,
      simpa,
    },
    { clear accept,
      revert eval,
      rw ← x.reverse_reverse,
      induction x.reverse generalizing q,
      case nil {
        assume hx,
        unfold convert,
        rw set.mem_def at *,
        simpa,
      },
      case cons : a as ih {
        assume hx,
        simp at *,
        rw NFA.mem_step_set at *,
        rcases hx with ⟨p, mem, step⟩,
        refine ⟨equiv.to_fun p, ih p mem, _⟩,
        unfold convert,
        rw set.mem_def at *,
        simpa,
      },
    },        
  },
  { rintros ⟨q, accept, eval⟩,
    refine ⟨equiv.inv_fun q, accept, _⟩,
    clear accept,
    revert eval,
    rw ← x.reverse_reverse,
    induction x.reverse generalizing q,
    case nil {
      assume hx,
      exact hx,
    },
    case cons : a as ih {
      assume hx,
      simp at *,
      rw NFA.mem_step_set at *,
      rcases hx with ⟨p, mem, step⟩,
      exact ⟨equiv.inv_fun p, ih p mem, step⟩,
    },
  },
end

variables
  (M : NFA α (fin n))
  [dec_start : decidable_pred M.start]
  [dec_accept : decidable_pred M.accept]
  [dec_step : ∀ p a q, decidable (M.step p a q)]
  (as : list α)

include dec_start dec_accept dec_step

/--
Convert an NFA with state type `fin n` to the corresponding GNFA.

Note: needs decidability for each of the NFA's functions, and a list of all the elements of the
alphabet.

TODO: would it be a good idea to make a separate "decidable NFA" structure?
-/
def to_GNFA : GNFA α n :=
⟨
  λ p q,
  match (p, q) with
  | (none, none) := 0
  | (none, some q) := if M.start q then 1 else 0
  | (some p, none) := if M.accept p then 1 else 0
  | (some p, some q) :=
    list.sum $
      list.map (λ a, regular_expression.char a) $
        list.filter (λ a, M.step p a q) as
  end
⟩

/- TODO: maybe mark as @simp -/
theorem to_GNFA_correct (univ : ∀ a, a ∈ as) : M.accepts = (M.to_GNFA as).accepts :=
begin
  ext,
  split,
  { rintros ⟨q, accept, eval⟩,
    refine GNFA.accepts.step q _ _ x.append_nil.symm,
    swap,
    { rw set.mem_def,
      unfold to_GNFA,
      simp,
      unfold to_GNFA._match_1,
      rw set.mem_def at accept,
      simp [accept],
      exact rfl,
    },
    clear accept,
    revert eval,
    rw ← x.reverse_reverse,
    induction x.reverse generalizing q,
    case nil {
      assume hx,
      simp,
      refine GNFA.trace.start _,
      unfold to_GNFA,
      simp,
      unfold to_GNFA._match_1,
      rw set.mem_def at hx,
      simp at hx,
      simp [hx],
    },
    case cons : a as ih {
      assume hx,
      simp at *,
      rw NFA.mem_step_set at hx,
      rcases hx with ⟨p, mem, step⟩,
      refine GNFA.trace.step p (ih p mem) _ rfl,
      rw set.mem_def,
      unfold to_GNFA,
      simp,
      unfold to_GNFA._match_1,
      rw regular_expression.mem_sum_iff_exists_mem,      
      refine ⟨regular_expression.char a, _, rfl⟩,
      simpa [univ],
    },
  },
  { assume hx,
    cases hx with x step x y z q t step eq,
    case start { cases step,},
    unfold to_GNFA at step,
    rw set.mem_def at step,
    simp at step,
    unfold to_GNFA._match_1 at step,
    by_cases M.accept q,
    swap, simp [h] at step, cases step,
    simp [h] at step,
    cases step,
    refine ⟨q, h, _⟩,
    simp at eq, cases eq,
    clear h eq step,
    revert t,
    rw ← x.reverse_reverse,
    induction x.reverse generalizing q,
    case nil {
      assume hx,
      simp at *,
      cases hx,
      case start : x step {
        unfold to_GNFA at step,
        rw set.mem_def at step,
        simp at step,
        unfold to_GNFA._match_1 at step,
        by_cases M.start x,
        exact h,
        simp [h] at step,
        cases step,
      },
      case step : x y z p t step eq {
        simp at eq,
        rw eq.2 at *,
        unfold to_GNFA at step,
        rw set.mem_def at step,
        simp at step,
        unfold to_GNFA._match_1 at step,
        rw regular_expression.mem_sum_iff_exists_mem at step,
        rcases step with ⟨r, mem, matches⟩,
        simp at mem,
        rcases mem with ⟨a, _, eq⟩,
        rw ← eq at matches,
        cases matches,
      },
    },
    case cons : a as ih {
      assume hx,
      simp at *,
      rw NFA.mem_step_set,
      cases hx,
      case start : q step {
        unfold to_GNFA at step,
        simp at step,
        rw set.mem_def at step,
        unfold to_GNFA._match_1 at step,
        by_cases M.start q,
        { simp [h] at step,
          by_cases as.reverse.append [a] = [],
          { have h : as.reverse ++ [a] = list.nil := h,
            rw ← list.reverse_cons a as at h,
            rw list.reverse_eq_nil at h,
            contradiction,
          },
          { rcases list.exists_cons_of_ne_nil h with ⟨a, as, h⟩,
            rw h at step,
            cases step,
          },
        },
        { simp [h] at step,
          cases step,
        },
      },
      case step : y z p q t step eq {
        unfold to_GNFA at step,
        rw set.mem_def at step,
        simp at step,
        unfold to_GNFA._match_1 at step,
        replace eq : as.reverse ++ [a] = y ++ z := eq,
        rw regular_expression.mem_sum_iff_exists_mem at step,
        rcases step with ⟨r, mem, matches⟩,
        simp at mem,
        rcases mem with ⟨b, ⟨_, step⟩, eq⟩,
        rw ← eq at matches,
        cases matches,
        rw ← list.reverse_inj at eq,
        simp at eq,
        rw ← eq.1 at step,
        refine ⟨p, _, step⟩,
        rw ← y.reverse_reverse at t,
        rw ← eq.2 at t,
        exact ih p t,        
      },
    },
  },
end

omit dec_start dec_accept dec_step

/--
Given an NFA with a `fintype` state, there is a regular expression that matches the same language.

TODO:
 * I'd like to call the NFA parameter `M`, but the name is already taken in the `variables`
   declaration earlier, so compiler doesn't like it. Is there a way around this besides listing
   out all the parameters in both of the earlier declarations?
 * This does not follow the precedent that `to_DFA` and `to_NFA` are both constructive definitions
   that give back just the resulting machine, and have `to_DFA_correct` and `to_NFA_correct`
   separately. Change the name? Find some other way?
-/
theorem to_regular_expression (M₀ : NFA α σ) [fintype α] [fintype σ] : ∃ (r : regular_expression α), M₀.accepts = r.matches :=
begin
  classical,
  rcases fintype.exists_univ_list α with ⟨as, _, univ⟩,
  let M₁ := M₀.convert (fintype.equiv_fin σ),
  let M₂ := M₁.to_GNFA as,
  let r := M₂.to_regular_expression,
  use r,
  rw ← GNFA.to_regular_expression_correct,
  rw ← to_GNFA_correct _ _ univ,
  rw ← convert_correct,
end

end NFA
