import topology.algebra.ring.basic
import algebra.big_operators.basic
import order.filter.at_top_bot
import analysis.specific_limits.normed
import topology.metric_space.cau_seq_filter
import tactic

open filter

open_locale big_operators topology

universe u
/--
`partial_sum f n` is the sum `f 0 + f 1 + f 2 + ... + f (n - 1)`. Note that this does not include
the term `f n`.
-/
def partial_sum {R : Type u} [add_comm_monoid R] (f : ℕ → R) (n : ℕ) :=
∑ i in finset.range n, f i

@[simp]
lemma partial_sum_zero {R : Type u} [add_comm_monoid R] (f : ℕ → R) : partial_sum f 0 = 0 :=
begin
  unfold partial_sum,
  simp,
end

lemma partial_sum_next {R : Type u} [add_comm_monoid R] (f : ℕ → R) (n : ℕ) :
  partial_sum f (n + 1) = f n + partial_sum f n :=
begin
  unfold partial_sum,
  rw finset.range_succ,
  apply finset.sum_insert,
  exact finset.not_mem_range_self
end

lemma partial_sum_neg {R : Type u} [add_comm_group R] (f : ℕ → R) (n : ℕ) :
  partial_sum (λ m, - (f m)) n = - (partial_sum f n) :=
begin
  induction n with n hi,
  { simp },
  { simp [partial_sum_next, hi, add_comm] }
end

lemma converges_absolutely_iff_converges_of_all_terms_nonneg (a : ℕ → ℝ) (h : ∀ n, 0 ≤ a n) :
  (∃ C, tendsto (partial_sum a) at_top (𝓝 C)) ↔
    (∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) :=
begin
  have : (λ n, ‖a n‖) = a := begin
    funext n,
    exact real.norm_of_nonneg (h n),
  end,
  rw this
end

lemma converges_absolutely_iff_converges_of_all_terms_nonpos (a : ℕ → ℝ) (h : ∀ n, a n ≤ 0) :
  (∃ C, tendsto (partial_sum a) at_top (𝓝 C)) ↔
    (∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) :=
begin
  rw show (λ n, ‖a n‖) = (λ n, - a n), from funext (λ (n : ℕ), real.norm_of_nonpos (h n)),
  rw show (partial_sum (λ n, - a n)) = λ n, - (partial_sum a n),
    from funext (λ n, partial_sum_neg a n),
  split; rintros ⟨C, hC⟩; use -C,
  { exact tendsto.neg hC },
  { simpa using tendsto.neg hC }
end

lemma diff_partial_sums_of_agrees' {a b : ℕ → ℝ} {k : ℕ} (h : ∀ n : ℕ, k ≤ n → a n = b n) (n : ℕ)
  : partial_sum a (n + k) - partial_sum b (n + k) = partial_sum a k - partial_sum b k :=
begin
  induction n with n hi,
  { simp },
  have : a (n + k) + partial_sum a (n + k) - (b (n + k) + partial_sum b (n + k)) =
    (a (n + k) - b (n + k)) + (partial_sum a (n + k) - partial_sum b (n + k)) := by ring,
  simp [this, (show n + 1 + k = n + k + 1, by ring), partial_sum_next, hi, h (n + k) (le_add_self)]
end

lemma diff_partial_sums_of_agrees {a b : ℕ → ℝ} {k : ℕ} (h : ∀ n : ℕ, k ≤ n → a n = b n) {n : ℕ}
  (hn : k ≤ n) : partial_sum a n - partial_sum b n = partial_sum a k - partial_sum b k :=
begin
  have := diff_partial_sums_of_agrees' h (n - k),
  rw nat.sub_add_cancel hn at this,
  exact this,
end

-- Shifts a neighborhood of a topological abelian group up d units
lemma shift_neighborhood {R : Type*} [add_comm_group R] [topological_space R]
  [topological_add_group R] {c : R} {S : set R} (hS : S ∈ 𝓝 c) (d : R)
  : {x : R | x + d ∈ S} ∈ 𝓝 (c - d) :=
begin
  letI : uniform_space R := topological_add_group.to_uniform_space R,
  haveI : uniform_add_group R := topological_add_comm_group_is_uniform,

  rw uniform_space.mem_nhds_iff at ⊢ hS,
  rcases hS with ⟨V, hV, hS⟩,

  have := uniformity_translate_add d,
  rw ←this at hV,
  rw filter.mem_map at hV,

  let W : set (R × R) := (λ (x : R × R), (x.fst + d, x.snd + d)) ⁻¹' V,
  use W,
  have h₁ : ∀ x : R, (x ∈ uniform_space.ball (c - d) W) → (x + d ∈ S) := begin
    intros x hx,
    unfold uniform_space.ball at hx hS,
    apply hS,
    simpa using hx,
  end,
  exact ⟨hV, h₁⟩,
end

lemma converges_of_agrees_converges {a b : ℕ → ℝ} {k : ℕ} (h : ∀ n : ℕ, k ≤ n → a n = b n)
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C)) : ∃ C, tendsto (partial_sum b) at_top (𝓝 C) :=
begin
  cases h₁ with C ha,
  let D := partial_sum b k - partial_sum a k,
  use C + D,
  rw tendsto_def at ⊢ ha,
  intros S hS,

  -- U is the neighborhood that results from shifting S by D units
  let U := {x : ℝ | x + D ∈ S},
  have hU : U ∈ 𝓝 C := by simpa using shift_neighborhood hS D,

  -- By hypothesis, there exists an N such that for all n ≥ N, partial_sum a n ∈ U.
  specialize ha U hU,
  rw mem_at_top_sets at ha,
  cases ha with N ha,

  -- We will show that for all m ≥ max N k, partial_sum b m ∈ S.
  rw mem_at_top_sets,
  use max N k,
  intros m hm,

  -- Since m ≥ N, partial_sum a m ∈ U.
  specialize ha m (le_of_max_le_left hm),
  rw set.mem_preimage at ha,

  -- Since partial_sum b m - partial_sum a m = D, we know b m ∈ S.
  change partial_sum a m + (partial_sum b k - partial_sum a k) ∈ S at ha,
  rw ←diff_partial_sums_of_agrees (λ n hn, (h n hn).symm) (le_of_max_le_right hm) at ha,
  rw set.mem_preimage,
  simpa using ha
end

lemma agrees_converges {a b : ℕ → ℝ} {k : ℕ} (h : ∀ n : ℕ, k ≤ n → a n = b n) :
  (∃ C, tendsto (partial_sum a) at_top (𝓝 C)) ↔ (∃ C, tendsto (partial_sum b) at_top (𝓝 C)) :=
begin
  split; intro h₁,
  { exact converges_of_agrees_converges h h₁ },
  { exact converges_of_agrees_converges (λ n hn, (h n hn).symm) h₁ }
end

lemma frequently_exists_pos_of_conditionally_converging {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C))
  : ∃ᶠ (n : ℕ) in at_top, 0 < a n :=
begin
  rw filter.frequently_at_top,
  intro k,
  by_contra h,
  push_neg at h,

  let b := λ n, if k ≤ n then a n else 0,
  have hb : ∀ n, k ≤ n → a n = b n := begin
    intros n hn,
    change a n = if k ≤ n then a n else 0,
    rw if_pos hn,
  end,

  have hb' : ∀ n, k ≤ n → ‖a n‖ = ‖b n‖ := begin
    intros n hn,
    rw hb n hn
  end,

  have hb_nonpos : ∀ n, b n ≤ 0 := begin
    intro n,
    by_cases hn : k ≤ n,
    { specialize h n hn,
      rw (hb n hn) at h,
      exact h },
    { change (if k ≤ n then a n else 0) ≤ 0,
      rw if_neg hn }
  end,

  have := converges_absolutely_iff_converges_of_all_terms_nonpos b hb_nonpos,
  rw agrees_converges hb at h₁,
  rw agrees_converges hb' at h₂,
  exact absurd (this.mp h₁) h₂
end

lemma frequently_exists_neg_of_conditionally_converging {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C))
  : ∃ᶠ (n : ℕ) in at_top, a n < 0 :=
begin
  rw filter.frequently_at_top,
  intro k,
  by_contra h,
  push_neg at h,

  let b := λ n, if k ≤ n then a n else 0,
  have hb : ∀ n, k ≤ n → a n = b n := begin
    intros n hn,
    change a n = if k ≤ n then a n else 0,
    rw if_pos hn,
  end,

  have hb' : ∀ n, k ≤ n → ‖a n‖ = ‖b n‖ := begin
    intros n hn,
    rw hb n hn
  end,

  have hb_nonneg : ∀ n, 0 ≤ b n := begin
    intro n,
    by_cases hn : k ≤ n,
    { specialize h n hn,
      rw (hb n hn) at h,
      exact h },
    { change 0 ≤ (if k ≤ n then a n else 0),
      rw if_neg hn }
  end,

  have := converges_absolutely_iff_converges_of_all_terms_nonneg b hb_nonneg,
  rw agrees_converges hb at h₁,
  rw agrees_converges hb' at h₂,
  exact absurd (this.mp h₁) h₂
end

lemma exists_pos_not_in_finset_of_conditionally_converging {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) (s : finset ℕ)
  : ∃ n, n ∉ s ∧ 0 < a n :=
begin
  have := frequently_exists_pos_of_conditionally_converging h₁ h₂,
  obtain ⟨n, hn₁, hn₂⟩ := frequently_at_top.mp this (if h : s.nonempty then s.max' h + 1 else 0),
  use n,
  split,
  { by_cases hs : s.nonempty,
    { rw dif_pos hs at hn₁,
      intro h,
      exact absurd (finset.le_max' s n h) (not_le_of_lt (nat.lt_of_succ_le hn₁)) },
    { unfold finset.nonempty at hs,
      push_neg at hs,
      exact hs n } },
  { exact hn₂ }
end

lemma exists_neg_not_in_finset_of_conditionally_converging {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) (s : finset ℕ)
  : ∃ n, n ∉ s ∧ a n < 0 :=
begin
  have := frequently_exists_neg_of_conditionally_converging h₁ h₂,
  obtain ⟨n, hn₁, hn₂⟩ := frequently_at_top.mp this (if h : s.nonempty then s.max' h + 1 else 0),
  use n,
  split,
  { by_cases hs : s.nonempty,
    { rw dif_pos hs at hn₁,
      intro h,
      exact absurd (finset.le_max' s n h) (not_le_of_lt (nat.lt_of_succ_le hn₁)) },
    { unfold finset.nonempty at hs,
      push_neg at hs,
      exact hs n } },
  { exact hn₂ }
end

noncomputable def rearrangement (a : ℕ → ℝ) (M : ℝ) : ℕ → ℕ
| 0 := 0
| (n+1) :=
  if ∑ (x : fin (n + 1)) in finset.univ, a (rearrangement ↑x) ≤ M then
    -- We could demonstrate that there exists a positive `a k` rather than a nonnegative one but then
    -- this function wouldn't be surjective
    Inf {k : ℕ | k ∉ set.range (λ x : fin (n + 1), rearrangement ↑x) ∧ 0 ≤ a k}
  else
    Inf {k : ℕ | k ∉ set.range (λ x : fin (n + 1), rearrangement ↑x) ∧ a k < 0}

lemma exists_nonneg_terms_not_in_range_fin_rearrangement {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) (M : ℝ) (n : ℕ)
  : ∃ k, k ∉ set.range (λ x : fin (n + 1), rearrangement a M ↑x) ∧ 0 ≤ a k :=
begin
  obtain ⟨n, hn₁, hn₂⟩ := exists_pos_not_in_finset_of_conditionally_converging h₁ h₂
        ((set.range (λ x : fin (n + 1), rearrangement a M ↑x)).to_finset),
  use n,
  rw ←set.mem_to_finset,
  exact ⟨hn₁, hn₂.le⟩
end

lemma exists_neg_terms_not_in_range_fin_rearrangement {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) (M : ℝ) (n : ℕ)
  : ∃ k, k ∉ set.range (λ x : fin (n + 1), rearrangement a M ↑x) ∧ a k < 0 :=
begin
  obtain ⟨n, hn₁, hn₂⟩ := exists_neg_not_in_finset_of_conditionally_converging h₁ h₂
        ((set.range (λ x : fin (n + 1), rearrangement a M ↑x)).to_finset),
  use n,
  rw ←set.mem_to_finset,
  exact ⟨hn₁, hn₂⟩
end

lemma rearrangement_fin_sum_def (a : ℕ → ℝ) (M : ℝ) (n : ℕ)
  : ∑ (x : fin n) in finset.univ, a (rearrangement a M ↑x) =
    partial_sum (λ k, a (rearrangement a M k)) n :=
fin.sum_univ_eq_sum_range (λ k, a (rearrangement a M k)) n

lemma rearrangement_def {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) (M : ℝ) (n : ℕ)
  : rearrangement a M (n + 1) =
    if partial_sum (λ k, a (rearrangement a M k)) (n + 1) ≤ M then
      nat.find (show ∃ k, k ∉ set.range (λ x : fin (n + 1), rearrangement a M ↑x) ∧ 0 ≤ a k,
        from exists_nonneg_terms_not_in_range_fin_rearrangement h₁ h₂ M n)
    else
      nat.find (show ∃ k, k ∉ set.range (λ x : fin (n + 1), rearrangement a M ↑x) ∧ a k < 0,
        from exists_neg_terms_not_in_range_fin_rearrangement h₁ h₂ M n) :=
begin
  unfold rearrangement,
  rw nat.Inf_def (show set.nonempty {k : ℕ | k ∉ set.range
    (λ x : fin (n + 1), rearrangement a M ↑x) ∧ 0 ≤ a k},
      from exists_nonneg_terms_not_in_range_fin_rearrangement h₁ h₂ M n),
  rw nat.Inf_def (show set.nonempty {k : ℕ | k ∉ set.range
    (λ x : fin (n + 1), rearrangement a M ↑x) ∧ a k < 0},
      from exists_neg_terms_not_in_range_fin_rearrangement h₁ h₂ M n),
  simp [rearrangement_fin_sum_def]
end

lemma rearrangement_nonneg {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) {M : ℝ} {n : ℕ}
  (h : partial_sum (λ k, a (rearrangement a M k)) (n + 1) ≤ M)
  : rearrangement a M (n + 1) =
    nat.find (show ∃ k, k ∉ set.range (λ x : fin (n + 1), rearrangement a M ↑x) ∧ 0 ≤ a k,
      from exists_nonneg_terms_not_in_range_fin_rearrangement h₁ h₂ M n) :=
begin
  rw rearrangement_def,
  exact if_pos h
end

lemma rearrangement_neg {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) {M : ℝ} {n : ℕ}
  (h : M < partial_sum (λ k, a (rearrangement a M k)) (n + 1))
  : rearrangement a M (n + 1) =
    nat.find (show ∃ k, k ∉ set.range (λ x : fin (n + 1), rearrangement a M ↑x) ∧ a k < 0,
      from exists_neg_terms_not_in_range_fin_rearrangement h₁ h₂ M n) :=
begin
  rw rearrangement_def,
  exact if_neg (by { push_neg, exact h })
end

lemma rearrangement_zero (a : ℕ → ℝ) (M : ℝ) : rearrangement a M 0 = 0 :=
by unfold rearrangement

lemma rearrangement_nonneg_spec {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) {M : ℝ} {n : ℕ}
  (h : partial_sum (λ k, a (rearrangement a M k)) (n + 1) ≤ M)
  : rearrangement a M (n + 1) ∉ set.range (λ x : fin (n + 1), rearrangement a M ↑x) ∧
    0 ≤ a (rearrangement a M (n + 1)) :=
begin
  have := nat.find_spec (exists_nonneg_terms_not_in_range_fin_rearrangement h₁ h₂ M n),
  rw rearrangement_nonneg h₁ h₂ h,
  exact this
end

lemma rearrangement_nonneg_spec' {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) {M : ℝ} {n : ℕ}
  (h : partial_sum (λ k, a (rearrangement a M k)) n ≤ M) (hn : n ≠ 0)
  : rearrangement a M n ∉ set.range (λ x : fin n, rearrangement a M ↑x) ∧
    0 ≤ a (rearrangement a M n) :=
begin
  cases n,
  { contradiction },
  { exact rearrangement_nonneg_spec h₁ h₂ h }
end

lemma rearrangement_neg_spec {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) {M : ℝ} {n : ℕ}
  (h : M < partial_sum (λ k, a (rearrangement a M k)) (n + 1))
  : rearrangement a M (n + 1) ∉ set.range (λ x : fin (n + 1), rearrangement a M ↑x) ∧
    a (rearrangement a M (n + 1)) < 0 :=
begin
  have := nat.find_spec (exists_neg_terms_not_in_range_fin_rearrangement h₁ h₂ M n),
  rw rearrangement_neg h₁ h₂ h,
  exact this
end

lemma rearrangement_neg_spec' {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) {M : ℝ} {n : ℕ}
  (h : M < partial_sum (λ k, a (rearrangement a M k)) n) (hn : n ≠ 0)
  : rearrangement a M n ∉ set.range (λ x : fin n, rearrangement a M ↑x) ∧
    a (rearrangement a M n) < 0 :=
begin
  cases n,
  { contradiction },
  { exact rearrangement_neg_spec h₁ h₂ h }
end

lemma rearrangement_not_mem {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) (M : ℝ) (n : ℕ)
  : rearrangement a M n ∉ set.range (λ x : fin n, rearrangement a M ↑x) :=
begin
  cases n,
  { simp },
  { by_cases h : partial_sum (λ k, a (rearrangement a M k)) (n + 1) ≤ M,
    { exact (rearrangement_nonneg_spec h₁ h₂ h).left },
    { push_neg at h,
      exact (rearrangement_neg_spec h₁ h₂ h).left } }
end

lemma rearrangement_nonneg_min' {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) {M : ℝ} {n : ℕ}
  (h : partial_sum (λ k, a (rearrangement a M k)) (n + 1) ≤ M)
  {m : ℕ} (hm : m ∉ set.range (λ x : fin (n + 1), rearrangement a M ↑x) ∧ 0 ≤ a m)
  : rearrangement a M (n + 1) ≤ m :=
begin
  have := nat.find_min' (exists_nonneg_terms_not_in_range_fin_rearrangement h₁ h₂ M n) hm,
  rw rearrangement_nonneg h₁ h₂ h,
  exact this
end

lemma rearrangement_neg_min' {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) {M : ℝ} {n : ℕ}
  (h : M < partial_sum (λ k, a (rearrangement a M k)) (n + 1))
  {m : ℕ} (hm : m ∉ set.range (λ x : fin (n + 1), rearrangement a M ↑x) ∧ a m < 0)
  : rearrangement a M (n + 1) ≤ m :=
begin
  have := nat.find_min' (exists_neg_terms_not_in_range_fin_rearrangement h₁ h₂ M n) hm,
  rw rearrangement_neg h₁ h₂ h,
  exact this
end

lemma rearrangement_injective {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) (M : ℝ)
  : function.injective (rearrangement a M) :=
begin
  unfold function.injective,
  intros n m,
  contrapose,
  intro hnm,
  wlog h : n < m,
  { push_neg at h,
    specialize this h₁ h₂ M (ne.symm hnm) (lt_of_le_of_ne h (ne.symm hnm)),
    exact ne.symm this },
  clear hnm,
  intro hr,
  apply rearrangement_not_mem h₁ h₂ M m,
  rw ←hr,
  use n,
  { exact h },
  { refl }
end

lemma rearrangement_surjective {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) (M : ℝ)
  : function.surjective (rearrangement a M) :=
begin
  sorry
end

lemma rearrangement_bijective {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) (M : ℝ)
  : function.bijective (rearrangement a M) :=
⟨rearrangement_injective h₁ h₂ M, rearrangement_surjective h₁ h₂ M⟩

@[reducible]
noncomputable def sumto (a : ℕ → ℝ) (M : ℝ) : ℕ → ℝ :=
partial_sum (λ i, a (rearrangement a M i))

/--
  An index is a "switchpoint" when the previous parital sum in the series is on the "opposite side"
  of M. (This is not standard terminology.)
-/
inductive rearrangement_switchpoint (a : ℕ → ℝ) (M : ℝ) (n : ℕ) : Prop
| start : n = 0 → rearrangement_switchpoint
| under_to_over : sumto a M (n - 1) < M ∧ M ≤ sumto a M n → rearrangement_switchpoint
| over_to_under : M ≤ sumto a M (n - 1) ∧ sumto a M n < M → rearrangement_switchpoint

/--
  Helper instance to make it easier to use rearrangement_switchpoint in nat.find_greatest
-/
noncomputable instance decidable_rearrangement_switchpoint (a : ℕ → ℝ) (M : ℝ) (n : ℕ)
  : decidable (rearrangement_switchpoint a M n) :=
begin
  classical,
  apply_instance
end

lemma diff_M_le_switchpoint (a : ℕ → ℝ) (M : ℝ) {d : ℕ} (hd : rearrangement_switchpoint a M d)
  (hd₁ : d ≠ 0)
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C))
  : ‖sumto a M d - M‖ ≤ ‖a (rearrangement a M (d - 1))‖ :=
begin
  have h : sumto a M d - sumto a M (d - 1) = a (rearrangement a M (d - 1)),
  { unfold sumto,
    rw ←(nat.sub_add_cancel (nat.one_le_iff_ne_zero.mpr hd₁)),
    simp [partial_sum_next] },
  cases hd,
  { contradiction },
  { have : sumto a M d - M < sumto a M d - sumto a M (d - 1) := by simp [hd.left],
    rw h at this,
    rw real.norm_of_nonneg (show 0 ≤ sumto a M d - M, by simp [hd.right]),
    /-have q : 0 ≤ a (rearrangement a M (d - 1)) := begin
      linarith
      --have := @rearrangement_nonneg_spec' _ h₁ h₂ M (d - 1) hd.left.le
    end,-/
    rw real.norm_of_nonneg (show 0 ≤ a (rearrangement a M (d - 1)), by linarith),
    exact this.le },
  {
    have h₃ : -(sumto a M d - M) ≤ -(sumto a M d - sumto a M (d - 1)) := by simp [hd.left],
    rw h at h₃,
    rw real.norm_of_nonpos (show sumto a M d - M ≤ 0, by simp [hd.right.le]),
    have : a (rearrangement a M (d - 1)) ≤ 0 := by linarith,
    rw real.norm_of_nonpos this,
    exact h₃
  }
end

-- TODO: Check the statement of this lemma very carefully
 /-lemma switchpoints_tendto_M (a : ℕ → ℝ) (M : ℝ) (n : ℕ)
  : tendsto (λ i, ‖sumto A M i - a (nat.find_greatest (rearrangement_switchpoint a M) i)‖) at_top (𝓝 0) :=
begin
  sorry
end-/

lemma rearrangement_tendsto_M {a : ℕ → ℝ}
  (h₁ : ∃ C, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C, tendsto (partial_sum (λ n, ‖a n‖)) at_top (𝓝 C)) (M : ℝ)
  : tendsto (partial_sum (λ n, a (rearrangement a M n))) at_top (𝓝 M) :=
begin
  rw tendsto_def,
  intros s hs,
  rw filter.mem_at_top_sets,
  use 0, -- TODO: Change to a value that works
  intros b hb,
  rw set.mem_preimage,
  sorry
end

theorem riemann_series_theorem {a : ℕ → ℝ} (h₁ : ∃ C : ℝ, tendsto (partial_sum a) at_top (𝓝 C))
  (h₂ : ¬∃ C : ℝ, tendsto (partial_sum (λ k, ‖a k‖)) at_top (𝓝 C)) (M : ℝ) : ∃ (p : equiv.perm ℕ),
    tendsto (partial_sum (λ n, a (p n))) filter.at_top (𝓝 M) :=
⟨equiv.of_bijective _ (rearrangement_bijective h₁ h₂ M), rearrangement_tendsto_M h₁ h₂ M⟩
