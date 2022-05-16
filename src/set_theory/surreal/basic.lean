/-
Copyright (c) 2019 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Scott Morrison, Violeta Hernández Palacios, Junyan Xu
-/

import set_theory.game.basic
import tactic.fin_cases

/-!
# Surreal numbers

The basic theory of surreal numbers, built on top of the theory of combinatorial (pre-)games.

A pregame is `numeric` if all the Left options are strictly smaller than all the Right options, and
all those options are themselves numeric. In terms of combinatorial games, the numeric games have
"frozen"; you can only make your position worse by playing, and Left is some definite "number" of
moves ahead (or behind) Right.

A surreal number is an equivalence class of numeric pregames.

In fact, the surreals form a complete ordered field, containing a copy of the reals (and much else
besides!) but we do not yet have a complete development.

## Order properties

Surreal numbers inherit the relations `≤` and `<` from games, and these relations satisfy the axioms
of a partial order.

## Algebraic operations

We show that the surreals form a linear ordered commutative group.

One can also map all the ordinals into the surreals!

## References
* [Conway, *On numbers and games*][conway2001]
* [Schleicher, Stoll, *An introduction to Conway's games and numbers*][schleicher_stoll]
-/

universes u

local infix ` ≈ ` := pgame.equiv
local infix ` ⧏ `:50 := pgame.lf

open relation

namespace pgame

/-- A pre-game is numeric if everything in the L set is less than everything in the R set,
and all the elements of L and R are also numeric. -/
def numeric : pgame → Prop
| ⟨l, r, L, R⟩ :=
  (∀ i j, L i < R j) ∧ (∀ i, numeric (L i)) ∧ (∀ i, numeric (R i))

lemma numeric_def (x : pgame) : numeric x ↔ (∀ i j, x.move_left i < x.move_right j) ∧
  (∀ i, numeric (x.move_left i)) ∧ (∀ i, numeric (x.move_right i)) :=
by { cases x, refl }

lemma numeric.left_lt_right {x : pgame} (o : numeric x) (i : x.left_moves) (j : x.right_moves) :
  x.move_left i < x.move_right j :=
by { cases x with xl xr xL xR, exact o.1 i j }
lemma numeric.move_left {x : pgame} (o : numeric x) (i : x.left_moves) :
  numeric (x.move_left i) :=
by { cases x with xl xr xL xR, exact o.2.1 i }
lemma numeric.move_right {x : pgame} (o : numeric x) (j : x.right_moves) :
  numeric (x.move_right j) :=
by { cases x with xl xr xL xR, exact o.2.2 j }

@[elab_as_eliminator]
theorem numeric_rec {C : pgame → Prop}
  (H : ∀ l r (L : l → pgame) (R : r → pgame),
    (∀ i j, L i < R j) → (∀ i, numeric (L i)) → (∀ i, numeric (R i)) →
    (∀ i, C (L i)) → (∀ i, C (R i)) → C ⟨l, r, L, R⟩) :
  ∀ x, numeric x → C x
| ⟨l, r, L, R⟩ ⟨h, hl, hr⟩ :=
  H _ _ _ _ h hl hr (λ i, numeric_rec _ (hl i)) (λ i, numeric_rec _ (hr i))

theorem lf_asymm {x y : pgame} (ox : numeric x) (oy : numeric y) : x ⧏ y → ¬ y ⧏ x :=
begin
  refine numeric_rec (λ xl xr xL xR hx oxl oxr IHxl IHxr, _) x ox y oy,
  refine numeric_rec (λ yl yr yL yR hy oyl oyr IHyl IHyr, _),
  rw [mk_lf_mk, mk_lf_mk], rintro (⟨i, h₁⟩ | ⟨j, h₁⟩) (⟨i, h₂⟩ | ⟨j, h₂⟩),
  { exact IHxl _ _ (oyl _) (move_left_lf_of_le _ h₁) (move_left_lf_of_le _ h₂) },
  { exact (le_trans h₂ h₁).not_lf (lf_of_lt (hy _ _)) },
  { exact (le_trans h₁ h₂).not_lf (lf_of_lt (hx _ _)) },
  { exact IHxr _ _ (oyr _) (lf_move_right_of_le _ h₁) (lf_move_right_of_le _ h₂) },
end

theorem le_of_lf {x y : pgame} (h : x ⧏ y) (ox : numeric x) (oy : numeric y) : x ≤ y :=
not_lf.1 (lf_asymm ox oy h)

alias le_of_lf ← pgame.lf.le

theorem lt_of_lf {x y : pgame} (h : x ⧏ y) (ox : numeric x) (oy : numeric y) : x < y :=
(lt_or_fuzzy_of_lf h).resolve_right (not_fuzzy_of_le (h.le ox oy))

alias lt_of_lf ← pgame.lf.lt

theorem lf_iff_lt {x y : pgame} (ox : numeric x) (oy : numeric y) : x ⧏ y ↔ x < y :=
⟨λ h, h.lt ox oy, lf_of_lt⟩

/-- Definition of `x ≤ y` on numeric pre-games, in terms of `<` -/
theorem le_def_lt {x y : pgame} (ox : x.numeric) (oy : y.numeric) :
  x ≤ y ↔ (∀ i, x.move_left i < y) ∧ ∀ j, x < y.move_right j :=
begin
  rw le_def_lf,
  convert iff.rfl;
  refine propext (forall_congr $ λ i, (lf_iff_lt _ _).symm);
  apply_rules [numeric.move_left, numeric.move_right]
end

/-- Definition of `x < y` on numeric pre-games, in terms of `≤` -/
theorem lt_def_le {x y : pgame} (ox : x.numeric) (oy : y.numeric) :
  x < y ↔ (∃ i, x ≤ y.move_left i) ∨ ∃ j, x.move_right j ≤ y :=
by rw [←lf_iff_lt ox oy, lf_def_le]

/-- The definition of `x < y` on numeric pre-games, in terms of `<` two moves later. -/
theorem lt_def {x y : pgame} (ox : x.numeric) (oy : y.numeric) : x < y ↔
  (∃ i, (∀ i', x.move_left i' < y.move_left i)  ∧ ∀ j, x < (y.move_left i).move_right j) ∨
   ∃ j, (∀ i, (x.move_right j).move_left i < y) ∧ ∀ j', x.move_right j < y.move_right j' :=
begin
  rw [←lf_iff_lt ox oy, lf_def],
  convert iff.rfl;
  ext;
  convert iff.rfl;
  refine propext (forall_congr $ λ i, lf_iff_lt _ _);
  apply_rules [numeric.move_left, numeric.move_right]
end

theorem not_fuzzy {x y : pgame} (ox : numeric x) (oy : numeric y) : ¬ fuzzy x y :=
λ h, not_lf.2 ((lf_of_fuzzy h).le ox oy) h.2

theorem lt_or_equiv_or_gt {x y : pgame} (ox : numeric x) (oy : numeric y) : x < y ∨ x ≈ y ∨ y < x :=
begin
  rcases lf_or_equiv_or_gf x y with h | h | h,
  { exact or.inl (h.lt ox oy) },
  { exact or.inr (or.inl h) },
  { exact or.inr (or.inr (h.lt oy ox)) }
end

theorem lt_or_equiv_of_le {x y : pgame} (h : x ≤ y) (ox : x.numeric) (oy : y.numeric) :
  x < y ∨ x ≈ y :=
by { rw ←lf_iff_lt ox oy, exact lf_or_equiv_of_le h }

theorem numeric_zero : numeric 0 :=
⟨by rintros ⟨⟩ ⟨⟩, ⟨by rintros ⟨⟩, by rintros ⟨⟩⟩⟩
theorem numeric_one : numeric 1 :=
⟨by rintros ⟨⟩ ⟨⟩, ⟨λ x, numeric_zero, by rintros ⟨⟩⟩⟩

theorem numeric.neg : Π {x : pgame} (o : numeric x), numeric (-x)
| ⟨l, r, L, R⟩ o := ⟨λ j i, neg_lt_iff.2 (o.1 i j), λ j, (o.2.2 j).neg, λ i, (o.2.1 i).neg⟩

theorem numeric.move_left_lt {x : pgame} (o : numeric x) (i) : x.move_left i < x :=
(pgame.move_left_lf i).lt (o.move_left i) o
theorem numeric.move_left_le {x : pgame} (o : numeric x) (i) : x.move_left i ≤ x :=
(o.move_left_lt i).le

theorem numeric.lt_move_right {x : pgame} (o : numeric x) (j) : x < x.move_right j :=
(pgame.lf_move_right j).lt o (o.move_right j)
theorem numeric.le_move_right {x : pgame} (o : numeric x) (j) : x ≤ x.move_right j :=
(o.lt_move_right j).le

theorem numeric.add : Π {x y : pgame} (ox : numeric x) (oy : numeric y), numeric (x + y)
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ox oy :=
⟨begin
   rintros (ix|iy) (jx|jy),
   { exact add_lt_add_right (ox.1 ix jx) _ },
   { exact (add_lf_add_of_lf_of_le (pgame.lf_mk _ _ ix) (oy.le_move_right jy)).lt
     ((ox.move_left ix).add oy) (ox.add (oy.move_right jy)) },
   { exact (add_lf_add_of_lf_of_le (pgame.mk_lf _ _ jx) (oy.move_left_le iy)).lt
      (ox.add (oy.move_left iy)) ((ox.move_right jx).add oy) },
   { exact add_lt_add_left (oy.1 iy jy) ⟨xl, xr, xL, xR⟩ }
 end,
 begin
   split,
   { rintros (ix|iy),
     { exact (ox.move_left ix).add oy },
     { exact ox.add (oy.move_left iy) } },
   { rintros (jx|jy),
     { apply (ox.move_right jx).add oy },
     { apply ox.add (oy.move_right jy) } }
 end⟩
using_well_founded { dec_tac := pgame_wf_tac }

lemma numeric.sub {x y : pgame} (ox : numeric x) (oy : numeric y) : numeric (x - y) := ox.add oy.neg

/-- Pre-games defined by natural numbers are numeric. -/
theorem numeric_nat : Π (n : ℕ), numeric n
| 0 := numeric_zero
| (n + 1) := (numeric_nat n).add numeric_one

/-- The pre-game `half` is numeric. -/
theorem numeric_half : numeric half :=
begin
  split,
  { rintros ⟨ ⟩ ⟨ ⟩,
    exact zero_lt_one },
  split; rintro ⟨ ⟩,
  { exact numeric_zero },
  { exact numeric_one }
end

end pgame

/-- The equivalence on numeric pre-games. -/
def surreal.equiv (x y : {x // pgame.numeric x}) : Prop := x.1.equiv y.1

open pgame

instance surreal.setoid : setoid {x // pgame.numeric x} :=
⟨λ x y, x.1 ≈ y.1,
 λ x, equiv_rfl,
 λ x y, pgame.equiv.symm,
 λ x y z, pgame.equiv.trans⟩

/-- The type of surreal numbers. These are the numeric pre-games quotiented
by the equivalence relation `x ≈ y ↔ x ≤ y ∧ y ≤ x`. In the quotient,
the order becomes a total order. -/
def surreal := quotient surreal.setoid

namespace surreal

/-- Construct a surreal number from a numeric pre-game. -/
def mk (x : pgame) (h : x.numeric) : surreal := quotient.mk ⟨x, h⟩

instance : has_zero surreal :=
{ zero := ⟦⟨0, numeric_zero⟩⟧ }
instance : has_one surreal :=
{ one := ⟦⟨1, numeric_one⟩⟧ }

instance : inhabited surreal := ⟨0⟩

/-- Lift an equivalence-respecting function on pre-games to surreals. -/
def lift {α} (f : ∀ x, numeric x → α)
  (H : ∀ {x y} (hx : numeric x) (hy : numeric y), x.equiv y → f x hx = f y hy) : surreal → α :=
quotient.lift (λ x : {x // numeric x}, f x.1 x.2) (λ x y, H x.2 y.2)

/-- Lift a binary equivalence-respecting function on pre-games to surreals. -/
def lift₂ {α} (f : ∀ x y, numeric x → numeric y → α)
  (H : ∀ {x₁ y₁ x₂ y₂} (ox₁ : numeric x₁) (oy₁ : numeric y₁) (ox₂ : numeric x₂) (oy₂ : numeric y₂),
    x₁.equiv x₂ → y₁.equiv y₂ → f x₁ y₁ ox₁ oy₁ = f x₂ y₂ ox₂ oy₂) : surreal → surreal → α :=
lift (λ x ox, lift (λ y oy, f x y ox oy) (λ y₁ y₂ oy₁ oy₂ h, H _ _ _ _ equiv_rfl h))
  (λ x₁ x₂ ox₁ ox₂ h, funext $ quotient.ind $ by exact λ ⟨y, oy⟩, H _ _ _ _ h equiv_rfl)

instance : has_le surreal :=
⟨lift₂ (λ x y _ _, x ≤ y) (λ x₁ y₁ x₂ y₂ _ _ _ _ hx hy, propext (le_congr hx hy))⟩

instance : has_lt surreal :=
⟨lift₂ (λ x y _ _, x < y) (λ x₁ y₁ x₂ y₂ _ _ _ _ hx hy, propext (lt_congr hx hy))⟩

/-- Addition on surreals is inherited from pre-game addition:
the sum of `x = {xL | xR}` and `y = {yL | yR}` is `{xL + y, x + yL | xR + y, x + yR}`. -/
instance : has_add surreal  :=
⟨surreal.lift₂
  (λ (x y : pgame) (ox) (oy), ⟦⟨x + y, ox.add oy⟩⟧)
  (λ x₁ y₁ x₂ y₂ _ _ _ _ hx hy, quotient.sound (pgame.add_congr hx hy))⟩

/-- Negation for surreal numbers is inherited from pre-game negation:
the negation of `{L | R}` is `{-R | -L}`. -/
instance : has_neg surreal  :=
⟨surreal.lift
  (λ x ox, ⟦⟨-x, ox.neg⟩⟧)
  (λ _ _ _ _ a, quotient.sound (pgame.neg_congr a))⟩

instance : ordered_add_comm_group surreal :=
{ add               := (+),
  add_assoc         := by { rintros ⟨_⟩ ⟨_⟩ ⟨_⟩, exact quotient.sound add_assoc_equiv },
  zero              := 0,
  zero_add          := by { rintros ⟨_⟩, exact quotient.sound (pgame.zero_add_equiv a) },
  add_zero          := by { rintros ⟨_⟩, exact quotient.sound (pgame.add_zero_equiv a) },
  neg               := has_neg.neg,
  add_left_neg      := by { rintros ⟨_⟩, exact quotient.sound (pgame.add_left_neg_equiv a) },
  add_comm          := by { rintros ⟨_⟩ ⟨_⟩, exact quotient.sound pgame.add_comm_equiv },
  le                := (≤),
  lt                := (<),
  le_refl           := by { rintros ⟨_⟩, apply @le_rfl pgame },
  le_trans          := by { rintros ⟨_⟩ ⟨_⟩ ⟨_⟩, apply @le_trans pgame },
  lt_iff_le_not_le  := by { rintros ⟨_, ox⟩ ⟨_, oy⟩, exact lt_iff_le_not_le },
  le_antisymm       := by { rintros ⟨_⟩ ⟨_⟩ h₁ h₂, exact quotient.sound ⟨h₁, h₂⟩ },
  add_le_add_left   := by { rintros ⟨_⟩ ⟨_⟩ hx ⟨_⟩, exact @add_le_add_left pgame _ _ _ _ _ hx _ } }

noncomputable instance : linear_ordered_add_comm_group surreal :=
{ le_total := by rintro ⟨⟨x, ox⟩⟩ ⟨⟨y, oy⟩⟩; classical; exact
    or_iff_not_imp_left.2 (λ h, (pgame.not_le.1 h).le oy ox),
  decidable_le := classical.dec_rel _,
  ..surreal.ordered_add_comm_group }

end surreal

namespace pgame

/-- To prove that surreal multiplication is well-defined, we use a modified argument by Schleicher.
We simultaneously prove two assertions on numeric pre-games:

- `P1 x y` means `x * y` is numeric.
- `P2 x₁ x₂ y` means all of the following hold:
- - If `x₁ ≈ x₂` then `x₁ * y ≈ x₂ * y`,
- - If `x₁ < x₂`, then
- - - For every left move `yL`, `x₂ * yL + x₁ * y < x₁ * yL + x₂ * y`,
- - - For every right move `yR`, `x₂ * y + x₁ * yR < x₁ * y + x₂ * yR`.

We prove this by providing a well-founded relation on `mul_args` such that each proposition depends
only on propositions with lesser arguments. See `mul_args.has_lt.lt` for a description of this
relation. -/
inductive mul_args : Type (u+1)
| P1 (x y : pgame.{u}) : mul_args
| P2 (x₁ x₂ y : pgame.{u}) : mul_args

end pgame

section comm_lemmas

variables {a b c d e f g h : game.{u}}

/-! A few auxiliary results for the surreal multiplication proof. -/

private theorem add_add_lt_cancel_left : a + b + c < a + d + e ↔ b + c < d + e :=
by rw [add_assoc, add_assoc, add_lt_add_iff_left]

private theorem add_add_lt_cancel_mid : a + b + c < d + b + e ↔ a + c < d + e :=
by rw [add_comm a, add_comm d, add_add_lt_cancel_left]

private theorem add_comm₂ : a + b < c + d ↔ b + a < d + c :=
by abel

end comm_lemmas

section cut_expand
variable {α : Type*}

def cut_expand (r : α → α → Prop) (s' s : multiset α) : Prop :=
∃ (t : multiset α) (a ∈ s), (∀ a' ∈ t, r a' a) ∧ s' + {a} = s + t

variable {r : α → α → Prop}

theorem cut_expand.wf (h : well_founded r) : well_founded (cut_expand r) :=
sorry

theorem multiset.pair_comm {x y : α} : ({x, y} : multiset α) = {y, x} :=
multiset.cons_swap x y ∅

theorem cut_expand_add_left {x s} (h : ∀ x' ∈ s, r x' x) (t) : cut_expand r (s + t) ({x} + t) :=
begin
  refine ⟨s, x, multiset.mem_cons_self x t, h, _⟩,
  rw [add_comm s, add_assoc, add_comm s, ←add_assoc, add_comm t]
end

theorem cut_expand_add_right {x t} (s) (h : ∀ x' ∈ t, r x' x) : cut_expand r (s + t) (s + {x}) :=
begin
  refine ⟨t, x, multiset.mem_add.2 (or.inr (multiset.mem_singleton_self x)), h, _⟩,
  rw [add_assoc, add_comm t, ←add_assoc]
end

theorem cut_add_singleton_left {x x'} (h : r x' x) (t) :
  cut_expand r ({x'} + t) ({x} + t) :=
begin
  apply cut_expand_add_left (λ a h, _),
  rw multiset.mem_singleton at h,
  rwa h
end

theorem cut_add_singleton_right (s) {y y'} (h : r y' y) :
  cut_expand r (s + {y'}) (s + {y}) :=
begin
  apply cut_expand_add_right s (λ a h, _),
  rw multiset.mem_singleton at h,
  rwa h
end

theorem cut_expand_pair_left {x s} (h : ∀ x' ∈ s, r x' x) (y) : cut_expand r (s + {y}) {x, y} :=
cut_expand_add_left h {y}

theorem cut_expand_pair_right (x) {y s} (h : ∀ y' ∈ s, r y' y) : cut_expand r ({x} + s) {x, y} :=
cut_expand_add_right {x} h

theorem cut_pair_left {x x'} (h : r x' x) (y) : cut_expand r {x', y} {x, y} :=
cut_add_singleton_left h {y}

theorem cut_pair_right (x) {y y'} (h : r y' y) : cut_expand r {x, y'} {x, y} :=
cut_add_singleton_right {x} h

end cut_expand

namespace pgame

private theorem quot_mul_comm₂ {a b c d : pgame} :
  ⟦a * b⟧ = ⟦c * d⟧ ↔ ⟦b * a⟧ = ⟦d * c⟧ :=
by rw [quot_mul_comm a, quot_mul_comm c]

private theorem quot_mul_comm₄ {a b c d e f g h : pgame} :
  ⟦a * b⟧ + ⟦c * d⟧ < ⟦e * f⟧ + ⟦g * h⟧ ↔ ⟦b * a⟧ + ⟦d * c⟧ < ⟦f * e⟧ + ⟦h * g⟧ :=
by rw [quot_mul_comm a, quot_mul_comm c, quot_mul_comm e, quot_mul_comm g]

namespace mul_args

/-- The multiset of arguments to either `P1` or `P2`. This is used in defining the well-founded
relation on `pgame`. -/
def to_multiset : mul_args → multiset pgame
| (P1 x y) := {x, y}
| (P2 x₁ x₂ y) := {x₁, x₂, y}

/-- This is the statement we wish to prove. -/
def hypothesis : mul_args → Prop
| (P1 x y)     := numeric x  → numeric y  → numeric (x * y)
| (P2 x₁ x₂ y) := numeric x₁ → numeric x₂ → numeric y →
                    (x₁ ≈ x₂ → x₁ * y ≈ x₂ * y) ∧
                    (x₁ < x₂ →
                      (∀ i, x₂ * y.move_left i + x₁ * y  < x₁ * y.move_left i + x₂ * y) ∧
                       ∀ j, x₂ * y + x₁ * y.move_right j < x₁ * y + x₂ * y.move_right j)

/-- We say that `x < y` for two `mul_args` whenever one can get from the multiset of parameters of
`y` to the multiset of parameters of `x` by repeatedly:

- Removing some parameter from `y`.
- Replacing it with an arbitrary multiset of subsequent games.

This relation is well-founded, and is used in the proof of `mul_args.result`. -/
instance : has_lt mul_args :=
⟨inv_image (trans_gen $ cut_expand subsequent) to_multiset⟩

instance : is_trans mul_args (<) :=
⟨by apply inv_image.trans _ _ transitive_trans_gen⟩

instance : has_well_founded mul_args :=
{ r := (<),
  wf := inv_image.wf _ (cut_expand.wf wf_subsequent).trans_gen }

theorem lt_of_cut_expand {x y : mul_args} :
  cut_expand subsequent x.to_multiset y.to_multiset → x < y :=
trans_gen.single

theorem cut_left_lt_P1 {x x'} (h : subsequent x' x) (y) : P1 x' y < P1 x y :=
lt_of_cut_expand $ cut_pair_left h y

theorem cut_right_lt_P1 (x) {y y'} (h : subsequent y' y) : P1 x y' < P1 x y :=
lt_of_cut_expand $ cut_pair_right x h

theorem cut_both_lt_P1 {x x' y y'} (hx : subsequent x' x) (hy : subsequent y' y) :
  P1 x' y' < P1 x y :=
trans (cut_left_lt_P1 hx y') (cut_right_lt_P1 _ hy)

theorem cut_right_lt_P2 (x₁ x₂) {y y'} (h : subsequent y' y) : P2 x₁ x₂ y' < P2 x₁ x₂ y :=
lt_of_cut_expand $ cut_add_singleton_right {x₁, x₂} h

theorem cut_expand_left_lt_P1 {x₁ x₂ x} (hx₁ : subsequent x₁ x) (hx₂ : subsequent x₂ x) (y) :
  P2 x₁ x₂ y < P1 x y :=
begin
  refine lt_of_cut_expand (cut_expand_pair_left (λ a ∈ {x₁, x₂}, _) y),
  fin_cases H; assumption
end

theorem cut_expand_right_lt_P1 (x) {y₁ y₂ y} (hy₁ : subsequent y₁ y) (hy₂ : subsequent y₂ y) :
  P2 x y₁ y₂ < P1 x y :=
begin
  refine lt_of_cut_expand (cut_expand_pair_right x (λ a ∈ {y₁, y₂}, _)),
  fin_cases H; assumption
end

/-- The hypothesis is true for any arguments. -/
theorem result : ∀ x : mul_args, x.hypothesis
| (P1 ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩) := λ ox oy, begin
  let x : pgame := ⟨xl, xr, xL, xR⟩,
  let y : pgame := ⟨yl, yr, yL, yR⟩,

  -- Reused applications of the inductive hypothesis.
  have HR₁ := λ {ix ix'}, let wf : P2 (xL ix) (xL ix') y < P1 x y :=
    cut_expand_left_lt_P1 (subsequent.mk_left _ _ ix) (subsequent.mk_left _ _ ix') y in
    result (P2 _ _ _) (ox.move_left ix)  (ox.move_left ix')  oy,
  have HR₂ := λ {iy iy'}, let wf : P2 (yL iy) (yL iy') x < P1 x y := sorry in
    result (P2 _ _ _) (oy.move_left iy)  (oy.move_left iy')  ox,
  have HR₃ := λ {jx jx'}, let wf : P2 (xR jx) (xR jx') y < P1 x y :=
    cut_expand_left_lt_P1 (subsequent.mk_right _ _ jx) (subsequent.mk_right _ _ jx') y in
    result (P2 _ _ _) (ox.move_right jx) (ox.move_right jx') oy,
  have HR₄ := λ {jy jy'}, let wf : P2 (yR jy) (yR jy') x < P1 x y := sorry in
    result (P2 _ _ _) (oy.move_right jy) (oy.move_right jy') ox,

  have HS₃ := λ {ix jx}, let wf : P2 (xL ix) (xR jx) y < P1 x y :=
    cut_expand_left_lt_P1 (subsequent.mk_left _ _ ix) (subsequent.mk_right _ _ jx) y in
    (result (P2 _ _ _) (ox.move_left ix) (ox.move_right jx) oy).2 (ox.left_lt_right ix jx),
  have HS₄ := λ {iy jy}, let wf : P2 (yL iy) (yR jy) x < P1 x y := sorry in
    (result (P2 _ _ _) (oy.move_left iy) (oy.move_right jy) ox).2 (oy.left_lt_right iy jy),

  have HN₁ := λ {ix},
    let wf : P1 (xL ix) y < P1 x y := cut_left_lt_P1 (subsequent.mk_left _ _ ix) y in
    result (P1 _ _) (ox.move_left ix)  oy,
  have HN₂ := λ {jx},
    let wf : P1 (xR jx) y < P1 x y := cut_left_lt_P1 (subsequent.mk_right _ _ jx) y in
    result (P1 _ _) (ox.move_right jx) oy,

  refine (numeric_def _).2 ⟨_, _, _⟩,

  -- Prove all left options of `x * y` are less than the right options.
  { rintro (⟨ix, iy⟩ | ⟨jx, jy⟩) (⟨ix', jy'⟩ | ⟨jx', iy'⟩),
    { rcases lt_or_equiv_or_gt (ox.move_left ix) (ox.move_left ix') with h | h | h,
      { have H₁ : ⟦xL ix * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix * yL iy⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix' * yL iy⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid, add_comm₂],
          apply (HR₁.2 h).1 },
        have H₂ : ⟦xL ix' * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix' * yL iy⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix' * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, add_comm₂, quot_mul_comm₄],
          apply HS₄.1 },
        exact H₁.trans H₂ },
      { change (⟦_⟧ : game) < ⟦_⟧, dsimp,
        have H₁ : ⟦xL ix * _⟧ = ⟦xL ix' * _⟧ := quot.sound (HR₁.1 h),
        let wf : P2 (xL ix) (xL ix') (yR jy') < P1 x y := sorry,
        have H₂ : ⟦xL ix * yR jy'⟧ = ⟦xL ix' * yR jy'⟧ := quot.sound
          ((result (P2 _ _ _) (ox.move_left ix) (ox.move_left ix') (oy.move_right jy')).1 h),
        rw [H₁, ←H₂, sub_lt_sub_iff, add_add_lt_cancel_left, add_comm₂, quot_mul_comm₄],
        apply HS₄.1 },
      { have H₁ : ⟦xL ix * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix * yL iy⟧ <
          ⟦xL ix * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, add_comm₂, quot_mul_comm₄],
          apply HS₄.1 },
        have H₂ : ⟦xL ix * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix * yR jy'⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix' * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid],
          apply (HR₁.2 h).2 },
        exact H₁.trans H₂ } },
    { rcases lt_or_equiv_or_gt (oy.move_left iy) (oy.move_left iy') with h | h | h,
      { have H₁ : ⟦xL ix * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix * yL iy⟧ <
          ⟦xL ix * y⟧ + ⟦x * yL iy'⟧ - ⟦xL ix * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, add_comm₂, quot_mul_comm₄],
          apply (HR₂.2 h).1 },
        have H₂ : ⟦xL ix * y⟧ + ⟦x * yL iy'⟧ - ⟦xL ix * yL iy'⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx' * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid, add_comm₂],
          apply HS₃.1 },
        exact H₁.trans H₂ },
      { change (⟦_⟧ : game) < ⟦_⟧, dsimp,
        have H₁ : ⟦x * yL iy⟧ = ⟦x * yL iy'⟧,
        { rw quot_mul_comm₂,
          exact quot.sound (HR₂.1 h) },
        have H₂ : ⟦xR jx' * yL iy⟧ = ⟦xR jx' * yL iy'⟧,
        { rw quot_mul_comm₂,
          let wf : P2 (yL iy) (yL iy') (xR jx') < P1 x y := sorry,
          exact quot.sound
            ((result (P2 _ _ _) (oy.move_left iy) (oy.move_left iy') (ox.move_right jx')).1 h) },
        rw [H₁, ←H₂, sub_lt_sub_iff, add_add_lt_cancel_mid, add_comm₂],
        apply HS₃.1 },
      { have H₁ : ⟦xL ix * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix * yL iy⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yL iy⟧ - ⟦xR jx' * yL iy⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid, add_comm₂],
          apply HS₃.1 },
        have H₂ : ⟦xR jx' * y⟧ + ⟦x * yL iy⟧ - ⟦xR jx' * yL iy⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx' * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, quot_mul_comm₄],
          apply (HR₂.2 h).2 },
        exact H₁.trans H₂ } },
    -- These are pretty similar to the previous cases in inverse, just changing `L` with `R`.
    { rcases lt_or_equiv_or_gt (oy.move_right jy') (oy.move_right jy) with h | h | h,
      { have H₁ : ⟦xR jx * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx * yR jy⟧ <
          ⟦xR jx * y⟧ + ⟦x * yR jy'⟧ - ⟦xR jx * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, quot_mul_comm₄],
          apply (HR₄.2 h).2 },
        have H₂ : ⟦xR jx * y⟧ + ⟦x * yR jy'⟧ - ⟦xR jx * yR jy'⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix' * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid],
          apply HS₃.2 },
        exact H₁.trans H₂ },
      { change (⟦_⟧ : game) < ⟦_⟧, dsimp,
        have H₁ : ⟦x * yR jy'⟧ = ⟦x * yR jy⟧,
        { rw quot_mul_comm₂,
          exact quot.sound (HR₄.1 h) },
        have H₂ : ⟦xL ix' * yR jy'⟧ = ⟦xL ix' * yR jy⟧,
        { rw quot_mul_comm₂,
          let wf : P2 (yR jy') (yR jy) (xL ix') < P1 x y := sorry,
          exact quot.sound
            ((result (P2 _ _ _) (oy.move_right jy') (oy.move_right jy) (ox.move_left ix')).1 h) },
        rw [H₁, H₂, sub_lt_sub_iff, add_add_lt_cancel_mid],
        apply HS₃.2 },
      { have H₁ : ⟦xR jx * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx * yR jy⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yR jy⟧ - ⟦xL ix' * yR jy⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid],
          apply HS₃.2 },
        have H₂ : ⟦xL ix' * y⟧ + ⟦x * yR jy⟧ - ⟦xL ix' * yR jy⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix' * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, add_comm₂, quot_mul_comm₄],
          apply (HR₄.2 h).1 },
        exact H₁.trans H₂ } },
    { rcases lt_or_equiv_or_gt (ox.move_right jx') (ox.move_right jx) with h | h | h,
      { have H₁ : ⟦xR jx * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx * yR jy⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx' * yR jy⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid],
          apply (HR₃.2 h).2 },
        have H₂ : ⟦xR jx' * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx' * yR jy⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx' * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, quot_mul_comm₄],
          apply HS₄.2 },
        exact H₁.trans H₂ },
      { change (⟦_⟧ : game) < ⟦_⟧, dsimp,
        have H₁ : ⟦xR jx' * _⟧ = ⟦xR jx * _⟧ := quot.sound (HR₃.1 h),
        let wf : P2 (xR jx') (xR jx) (yL iy') < P1 x y := sorry,
        have H₂ : ⟦xR jx' * yL iy'⟧ = ⟦xR jx * yL iy'⟧ := quot.sound
          ((result (P2 _ _ _) (ox.move_right jx') (ox.move_right jx) (oy.move_left iy')).1 h),
        rw [H₁, H₂, sub_lt_sub_iff, add_add_lt_cancel_left, quot_mul_comm₄],
        apply HS₄.2 },
      { have H₁ : ⟦xR jx * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx * yR jy⟧ <
          ⟦xR jx * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, quot_mul_comm₄],
          apply HS₄.2 },
        have H₂ : ⟦xR jx * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx * yL iy'⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx' * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid, add_comm₂],
          apply (HR₃.2 h).1 },
        exact H₁.trans H₂ } } },

  -- Prove that all options of `x * y` are numeric.
  { rintro (⟨ix, iy⟩ | ⟨jx, jy⟩),
    { let wf₁ : P1 x (yL iy) < P1 x y := cut_right_lt_P1 x (subsequent.mk_left _ _ iy),
      let wf₂ : P1 (xL ix) (yL iy) < P1 x y :=
        cut_both_lt_P1 (subsequent.mk_left _ _ ix) (subsequent.mk_left _ _ iy),
      exact (HN₁.add (result (P1 _ _) ox (oy.move_left iy))).sub
        (result (P1 _ _) (ox.move_left ix) (oy.move_left iy)) },
    { let wf₁ : P1 x (yR jy) < P1 x y := cut_right_lt_P1 x (subsequent.mk_right _ _ jy),
      let wf₂ : P1 (xR jx) (yR jy) < P1 x y :=
        cut_both_lt_P1 (subsequent.mk_right _ _ jx) (subsequent.mk_right _ _ jy),
      exact (HN₂.add (result (P1 _ _) ox (oy.move_right jy))).sub
        (result (P1 _ _) (ox.move_right jx) (oy.move_right jy)) } },
  { rintro (⟨ix, jy⟩ | ⟨jx, iy⟩),
    { let wf₁ : P1 x (yR jy) < P1 x y := cut_right_lt_P1 x (subsequent.mk_right _ _ jy),
      let wf₂ : P1 (xL ix) (yR jy) < P1 x y :=
        cut_both_lt_P1 (subsequent.mk_left _ _ ix) (subsequent.mk_right _ _ jy),
      exact (HN₁.add (result (P1 _ _) ox (oy.move_right jy))).sub
        (result (P1 _ _) (ox.move_left ix) (oy.move_right jy)) },
    { let wf₁ : P1 x (yL iy) < P1 x y := cut_right_lt_P1 x (subsequent.mk_left _ _ iy),
      let wf₂ : P1 (xR jx) (yL iy) < P1 x y :=
        cut_both_lt_P1 (subsequent.mk_right _ _ jx) (subsequent.mk_left _ _ iy),
      exact (HN₂.add (result (P1 _ _) ox (oy.move_left iy))).sub
        (result (P1 _ _) (ox.move_right jx) (oy.move_left iy)) } }
end
| (P2 ⟨x₁l, x₁r, x₁L, x₁R⟩ ⟨x₂l, x₂r, x₂L, x₂R⟩ ⟨yl, yr, yL, yR⟩) := λ ox₁ ox₂ oy, begin
  let x₁ : pgame := ⟨x₁l, x₁r, x₁L, x₁R⟩,
  let x₂ : pgame := ⟨x₂l, x₂r, x₂L, x₂R⟩,
  let y  : pgame := ⟨yl, yr, yL, yR⟩,

  -- Reused applications of the inductive hypothesis.
  let wf₁ : P1 x₁ y < P2 x₁ x₂ y := sorry,
  have HN₁ := result (P1 x₁ y) ox₁ oy,
  let wf₂ : P1 x₂ y < P2 x₁ x₂ y := sorry,
  have HN₂ := result (P1 x₂ y) ox₂ oy,

  have HR₁ := λ {jx₁},
    let wf : P2 (x₁R jx₁) x₂ y < P2 x₁ x₂ y := sorry in
    result (P2 _ _ _) (ox₁.move_right jx₁) ox₂ oy,
  have HR₂ := λ {ix₂},
    let wf : P2 x₁ (x₂L ix₂) y < P2 x₁ x₂ y := sorry in
    result (P2 _ _ _) ox₁ (ox₂.move_left ix₂) oy,

  have HS₁ := λ ix₂ iy, HN₂.move_left_lt (sum.inl (ix₂, iy)),
  have HS₂ := λ ix₂ jy, HN₂.lt_move_right (sum.inl (ix₂, jy)),
  have HS₃ := λ jx₁ iy, HN₁.lt_move_right (sum.inr (jx₁, iy)),
  have HS₄ := λ jx₁ jy, HN₁.move_left_lt (sum.inr (jx₁, jy)),

  have HT₁ := λ iy, let wf : P2 x₁ x₂ (yL iy) < P2 x₁ x₂ y :=
    cut_right_lt_P2 x₁ x₂ (subsequent.mk_left _ _ iy) in
    (result (P2 _ _ _) ox₁ ox₂ (oy.move_left iy)).1,
  have HT₂ := λ jy, let wf : P2 x₁ x₂ (yR jy) < P2 x₁ x₂ y :=
    cut_right_lt_P2 x₁ x₂ (subsequent.mk_right _ _ jy) in
    (result (P2 _ _ _) ox₁ ox₂ (oy.move_right jy)).1,
  have HT₃ := λ iy, let wf : P2 x₂ x₁ (yL iy) < P2 x₁ x₂ y := sorry in
    (result (P2 _ _ _) ox₂ ox₁ (oy.move_left iy)).1,
  have HT₄ := λ jy, let wf : P2 x₂ x₁ (yR jy) < P2 x₁ x₂ y := sorry in
    (result (P2 _ _ _) ox₂ ox₁ (oy.move_right jy)).1,

  have HU₁ := λ ix₁ h,
    let wf : P2 (x₁L ix₁) x₂ y < P2 x₁ x₂ y := sorry in
    (result (P2 _ _ _) (ox₁.move_left ix₁) ox₂ oy).2 ((ox₁.move_left_lt ix₁).trans_le h),
  have HU₂ := λ ix₂ h,
    let wf : P2 (x₂L ix₂) x₁ y < P2 x₁ x₂ y := sorry in
    (result (P2 _ _ _) (ox₂.move_left ix₂) ox₁ oy).2 ((ox₂.move_left_lt ix₂).trans_le h),
  have HU₃ := λ jx₁ (h : _ ≤ _),
    let wf : P2 x₂ (x₁R jx₁) y < P2 x₁ x₂ y := sorry in
    (result (P2 _ _ _) ox₂ (ox₁.move_right jx₁) oy).2 (h.trans_lt (ox₁.lt_move_right jx₁)),
  have HU₄ := λ jx₂ (h : _ ≤ _),
    let wf : P2 x₁ (x₂R jx₂) y < P2 x₁ x₂ y := sorry in
    (result (P2 _ _ _) ox₁ (ox₂.move_right jx₂) oy).2 (h.trans_lt (ox₂.lt_move_right jx₂)),

  -- Prove that if `x₁ ≈ x₂`, then `x₁ * y ≈ x₂ * y`.
  refine ⟨λ h, ⟨le_def_lf.2 ⟨_, _⟩, le_def_lf.2 ⟨_, _⟩⟩, λ h, _⟩,
  { rintro (⟨ix₁, iy⟩ | ⟨jx₁, jy⟩);
    apply lf_of_lt;
    change (⟦_⟧ : game) < ⟦_⟧; dsimp,
    { have H : ⟦x₁ * _⟧ = ⟦_⟧ := quot.sound (HT₁ iy h),
      dsimp at H,
      rw [sub_lt_iff_lt_add, H, add_comm₂],
      apply (HU₁ ix₁ h.1).1 },
    { have H : ⟦x₁ * _⟧ = ⟦_⟧ := quot.sound (HT₂ jy h),
      dsimp at H,
      rw [sub_lt_iff_lt_add, H],
      apply (HU₃ jx₁ h.2).2 } },
  { rintro (⟨ix₂, jy⟩ | ⟨jx₂, iy⟩);
    apply lf_of_lt;
    change (⟦_⟧ : game) < ⟦_⟧; dsimp,
    { have H : ⟦x₁ * _⟧ = ⟦_⟧ := quot.sound (HT₂ jy h),
      dsimp at H,
      rw [lt_sub_iff_add_lt, ←H],
      apply (HU₂ ix₂ h.2).2 },
    { have H : ⟦x₁ * _⟧ = ⟦_⟧ := quot.sound (HT₁ iy h),
      dsimp at H,
      rw [lt_sub_iff_add_lt, ←H, add_comm₂],
      apply (HU₄ jx₂ h.1).1 } },
  -- These are just the same but with `x₁` and `x₂` swapped.
  { rintro (⟨ix₂, iy⟩ | ⟨jx₂, jy⟩);
    apply lf_of_lt;
    change (⟦_⟧ : game) < ⟦_⟧; dsimp,
    { have H : ⟦x₂ * _⟧ = ⟦_⟧ := quot.sound (HT₃ iy h.symm),
      dsimp at H,
      rw [sub_lt_iff_lt_add, H, add_comm₂],
      apply (HU₂ ix₂ h.2).1 },
    { have H : ⟦x₂ * _⟧ = ⟦_⟧ := quot.sound (HT₄ jy h.symm),
      dsimp at H,
      rw [sub_lt_iff_lt_add, H],
      apply (HU₄ jx₂ h.1).2 } },
  { rintro (⟨ix₁, jy⟩ | ⟨jx₁, iy⟩);
    apply lf_of_lt;
    change (⟦_⟧ : game) < ⟦_⟧; dsimp,
    { have H : ⟦x₂ * _⟧ = ⟦_⟧ := quot.sound (HT₄ jy h.symm),
      dsimp at H,
      rw [lt_sub_iff_add_lt, ←H],
      apply (HU₁ ix₁ h.1).2 },
    { have H : ⟦x₂ * _⟧ = ⟦_⟧ := quot.sound (HT₃ iy h.symm),
      dsimp at H,
      rw [lt_sub_iff_add_lt, ←H, add_comm₂],
      apply (HU₃ jx₁ h.2).1 } },

  -- Prove that if `x₁ < x₂`, then `x₂ * yL + x₁ * y < x₁ * yL + x₂ * y` and
  -- `x₂ * y + x₁ * yR < x₁ * y + x₂ * yR`.
  rcases lf_def_le.1 h.lf with ⟨ix₂, h⟩ | ⟨jx₁, h⟩,
  { cases lt_or_equiv_of_le h ox₁ (ox₂.move_left ix₂) with h h;
    refine ⟨λ iy, _, λ jy, _⟩,
    { have H : (⟦_⟧ : game) < ⟦_⟧ := add_lt_add ((HR₂.2 h).1 iy) (HS₁ ix₂ iy),
      dsimp at H, abel at H,
      rwa [←add_assoc ⟦x₂ * y⟧, add_comm ⟦x₂ * y⟧, add_assoc, add_lt_add_iff_left,
        add_comm ⟦_ * y⟧] at H },
    { have H : (⟦_⟧ : game) < ⟦_⟧ := add_lt_add ((HR₂.2 h).2 jy) (HS₂ ix₂ jy),
      dsimp at H, abel at H,
      rwa [←add_assoc ⟦x₂ * y⟧, add_comm ⟦x₂ * y⟧, add_assoc, add_lt_add_iff_left,
        add_comm ⟦_ * yR jy⟧] at H },
    { have H₁ : (⟦_⟧ : game) < ⟦_⟧ := HS₁ ix₂ iy,
      have H₂ : (⟦_⟧ : game) = ⟦_⟧ := quot.sound (HR₂.1 h),
      let wf : P2 x₁ (x₂L ix₂) (yL iy) < P2 x₁ x₂ y := sorry,
      have H₃ : (⟦_⟧ : game) = ⟦_⟧ := quot.sound
        ((result (P2 _ _ _) ox₁ (ox₂.move_left ix₂) (oy.move_left iy)).1 h),
      dsimp at H₁ H₂ H₃,
      rwa [sub_lt_iff_lt_add, ←H₂, ←H₃, add_comm₂] at H₁ },
    { have H₁ : (⟦_⟧ : game) < ⟦_⟧ := HS₂ ix₂ jy,
      have H₂ : (⟦_⟧ : game) = ⟦_⟧ := quot.sound (HR₂.1 h),
      let wf : P2 x₁ (x₂L ix₂) (yR jy) < P2 x₁ x₂ y := sorry,
      have H₃ : (⟦_⟧ : game) = ⟦_⟧ := quot.sound
        ((result (P2 _ _ _) ox₁ (ox₂.move_left ix₂) (oy.move_right jy)).1 h),
      dsimp at H₁ H₂ H₃,
      rwa [lt_sub_iff_add_lt, ←H₂, ←H₃] at H₁ } },
  { cases lt_or_equiv_of_le h (ox₁.move_right jx₁) ox₂ with h h;
    refine ⟨λ iy, _, λ jy, _⟩,
    { have H : (⟦_⟧ : game) < ⟦_⟧ := add_lt_add ((HR₁.2 h).1 iy) (HS₃ jx₁ iy),
      dsimp at H, abel at H,
      rwa [←add_assoc, add_comm ⟦_ * y⟧, add_assoc ⟦x₁R jx₁ * _⟧, add_lt_add_iff_left,
        add_comm] at H },
    { have H : (⟦_⟧ : game) < ⟦_⟧ := add_lt_add ((HR₁.2 h).2 jy) (HS₄ jx₁ jy),
      dsimp at H, abel at H,
      rwa [←add_assoc ⟦x₁ * _⟧, add_comm ⟦x₁ * y⟧, add_assoc ⟦x₁R jx₁ * _⟧, add_lt_add_iff_left,
        add_comm] at H },
    { have H₁ : (⟦_⟧ : game) < ⟦_⟧ := HS₃ jx₁ iy,
      have H₂ : (⟦_⟧ : game) = ⟦_⟧ := quot.sound (HR₁.1 h),
      let wf : P2 (x₁R jx₁) x₂ (yL iy) < P2 x₁ x₂ y := sorry,
      have H₃ : (⟦_⟧ : game) = ⟦_⟧ := quot.sound
        ((result (P2 _ _ _) (ox₁.move_right jx₁) ox₂ (oy.move_left iy)).1 h),
      dsimp at H₁ H₂ H₃,
      rwa [lt_sub_iff_add_lt, H₂, H₃, add_comm₂] at H₁ },
    { have H₁ : (⟦_⟧ : game) < ⟦_⟧ := HS₄ jx₁ jy,
      have H₂ : (⟦_⟧ : game) = ⟦_⟧ := quot.sound (HR₁.1 h),
      let wf : P2 (x₁R jx₁) x₂ (yR jy) < P2 x₁ x₂ y := sorry,
      have H₃ : (⟦_⟧ : game) = ⟦_⟧ := quot.sound
        ((result (P2 _ _ _) (ox₁.move_right jx₁) ox₂ (oy.move_right jy)).1 h),
      dsimp at H₁ H₂ H₃,
      rwa [sub_lt_iff_lt_add, H₂, H₃] at H₁ } }
end
using_well_founded { dec_tac := tactic.assumption }

end mul_args

theorem numeric_mul {x y : pgame} : numeric x → numeric y → numeric (x * y) :=
(mul_args.P1 x y).result

theorem mul_congr_left {x₁ x₂ y : pgame} (ox₁ : numeric x₁) (ox₂ : numeric x₂) (oy : numeric y) :
  x₁ ≈ x₂ → x₁ * y ≈ x₂ * y :=
((mul_args.P2 x₁ x₂ y).result ox₁ ox₂ oy).1

theorem mul_congr_right {x y₁ y₂ : pgame} (ox : numeric x) (oy₁ : numeric y₁) (oy₂ : numeric y₂)
  (h : y₁ ≈ y₂) : x * y₁ ≈ x * y₂ :=
(mul_comm_equiv _ _).trans ((mul_congr_left oy₁ oy₂ ox h).trans (mul_comm_equiv _ _))

theorem mul_congr {x₁ x₂ y₁ y₂ : pgame} (ox₁ : numeric x₁) (ox₂ : numeric x₂) (oy₁ : numeric y₁)
  (oy₂ : numeric y₂) (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ * y₁ ≈ x₂ * y₂ :=
(mul_congr_left ox₁ ox₂ oy₁ hx).trans (mul_congr_right ox₂ oy₁ oy₂ hy)

end pgame

namespace surreal

/-- Multiplication of surreal numbers is inherited from pre-game multiplication: the product of
`x = {xL | xR}` and `y = {yL | yR}` is
`{xL*y + x*yL - xL*yL, xR*y + x*yR - xR*yR | xL*y + x*yR - xL*yR, x*yL + xR*y - xR*yL }`. -/
def mul : surreal → surreal → surreal :=
surreal.lift₂
  (λ x y ox oy, ⟦⟨x * y, pgame.numeric_mul ox oy⟩⟧)
  (λ _ _ _ _ ox₁ oy₁ ox₂ oy₂ hx hy, quotient.sound (pgame.mul_congr ox₁ ox₂ oy₁ oy₂ hx hy))

instance : has_mul surreal := ⟨mul⟩

end surreal

-- We conclude with some ideas for further work on surreals; these would make fun projects.

-- TODO define the inclusion of groups `surreal → game`
-- TODO define the field structure on the surreals
