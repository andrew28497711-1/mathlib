/-
Copyright (c) 2022 Kexing Ying. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kexing Ying
-/
import probability.martingale.convergence

/-!

# Generalized Borel-Cantelli lemma

-/

open topological_space filter
open_locale nnreal ennreal measure_theory probability_theory big_operators topological_space

namespace measure_theory

variables {α : Type*} {m0 : measurable_space α} {μ : measure α}
  {ℱ : filtration ℕ m0} {f : ℕ → α → ℝ}

/-
for a (sub)martingale `f` with bounded difference,
`∀ᵐ x ∂μ, f n x converges ↔ (f n x) is bounded in n`
-/

/-- `least_ge f r n` is the stopping time corresponding to the first time `f ≥ r`. -/
noncomputable
def least_ge (f : ℕ → α → ℝ) (r : ℝ) (n : ℕ) := hitting f (set.Ici r) 0 n

lemma adapted.is_stopping_time_least_ge (r : ℝ) (n : ℕ) (hf : adapted ℱ f) :
  is_stopping_time ℱ (least_ge f r n) :=
hitting_is_stopping_time hf measurable_set_Ici

section move

lemma eventually_le.add_le_add {α β : Type*} [ordered_semiring β] {l : filter α}
  {f₁ f₂ g₁ g₂ : α → β} (hf : f₁ ≤ᶠ[l] f₂) (hg : g₁ ≤ᶠ[l] g₂) : f₁ + g₁ ≤ᶠ[l] f₂ + g₂ :=
by filter_upwards [hf, hg] with x hfx hgx using add_le_add hfx hgx

variables {β : Type*}
variables {u : ℕ → α → β} {τ : α → ℕ}

lemma stopped_process_eq' [add_comm_monoid β] (n : ℕ) :
  stopped_process u τ n =
  set.indicator {a | n + 1 ≤ τ a} (u n) +
    ∑ i in finset.range (n + 1), set.indicator {a | τ a = i} (u i) :=
begin
  have : {a | n ≤ τ a}.indicator (u n) =
    {a | n + 1 ≤ τ a}.indicator (u n) + {a | τ a = n}.indicator (u n),
  { ext x,
    rw [add_comm, pi.add_apply, ← set.indicator_union_of_not_mem_inter],
    { simp_rw [@eq_comm _ _ n, @le_iff_eq_or_lt _ _ n, nat.succ_le_iff],
      refl },
    { rintro ⟨h₁, h₂⟩,
      exact (nat.succ_le_iff.1 h₂).ne h₁.symm } },
  rw [stopped_process_eq, this, finset.sum_range_succ_comm, ← add_assoc],
end

lemma not_mem_of_lt_hitting {ι : Type*} [conditionally_complete_linear_order ι]
  {u : ι → α → β} {s : set β} {x : α} {n m k : ι}
  (hk₁ : k < hitting u s n m x) (hk₂ : n ≤ k) :
  u k x ∉ s :=
begin
  classical,
  intro h,
  have hexists : ∃ j ∈ set.Icc n m, u j x ∈ s,
  refine ⟨k, ⟨hk₂, le_trans hk₁.le $ hitting_le _⟩, h⟩,
  refine not_le.2 hk₁ _,
  simp_rw [hitting, if_pos hexists],
  exact cInf_le bdd_below_Icc.inter_of_left ⟨⟨hk₂, le_trans hk₁.le $ hitting_le _⟩, h⟩,
end

lemma hitting_eq_end_iff {ι : Type*} [conditionally_complete_linear_order ι]
  {u : ι → α → β} {s : set β} {n m : ι} {x : α} :
  hitting u s n m x = m ↔ (∃ j ∈ set.Icc n m, u j x ∈ s) →
    Inf (set.Icc n m ∩ {i : ι | u i x ∈ s}) = m :=
by rw [hitting, ite_eq_right_iff]

-- strictly stronger than `hitting_of_lt`
lemma hitting_of_le {ι : Type*} [conditionally_complete_linear_order ι]
  {u : ι → α → β} {s : set β} {n m : ι} {x : α} (hmn : m ≤ n) :
  hitting u s n m x = m :=
begin
  obtain (rfl | h) := le_iff_eq_or_lt.1 hmn,
  { simp only [hitting, set.Icc_self, ite_eq_right_iff, set.mem_Icc, exists_prop,
      forall_exists_index, and_imp],
    intros i hi₁ hi₂ hi,
    rw [set.inter_eq_left_iff_subset.2, cInf_singleton],
    exact set.singleton_subset_iff.2 (le_antisymm hi₂ hi₁ ▸ hi) },
  { exact hitting_of_lt h }
end

end move

lemma stopped_value_least_ge_eq (i : ℕ) (r : ℝ) :
  stopped_value f (least_ge f r i) = stopped_process f (least_ge f r i) i :=
begin
  ext x,
  exact congr_arg2 _ (min_eq_right (hitting_le x : least_ge f r i x ≤ i)).symm rfl
end

lemma least_ge_le {i : ℕ} {r : ℝ} (x : α) : least_ge f r i x ≤ i :=
hitting_le x

lemma nat.eq_zero_or_eq_one_of_le {a : ℕ} (h : a ≤ 1) : a = 0 ∨ a = 1 :=
by { rw ← nat.lt_one_iff, exact lt_or_eq_of_le h }

lemma submartingale.stopped_value_least_ge_zero [is_finite_measure μ]
  (hf : submartingale f ℱ μ) (r : ℝ) :
  stopped_value f (least_ge f r 0) ≤ᵐ[μ] μ[stopped_value f (least_ge f r 1)|ℱ 0] :=
begin
  have hlge0 : least_ge f r 0 = 0,
  { ext x,
    simp only [least_ge, hitting, set.Icc_self],
    split_ifs with hx,
    { by_cases hmem : 0 ∈ {i | f i x ∈ set.Ici r},
      { rw [set.inter_eq_left_iff_subset.2 (set.singleton_subset_iff.2 hmem),
          cInf_singleton, pi.zero_apply] },
      { rw [set.singleton_inter_eq_empty.2 hmem, nat.Inf_empty, pi.zero_apply] } },
    { refl } },
  simp_rw [hlge0, stopped_value_eq least_ge_le, finset.sum_range_succ,
    finset.range_zero, finset.sum_empty, zero_add, stopped_value, pi.zero_apply],
  refine eventually_le.trans _ (condexp_add
    ((hf.integrable 0).indicator $ ℱ.le _ _ $
      (hf.adapted.is_stopping_time_least_ge r 1).measurable_set_eq 0)
    ((hf.integrable 1).indicator $ ℱ.le _ _ $
      (hf.adapted.is_stopping_time_least_ge r 1).measurable_set_eq 1)).symm.le,
  calc f 0 = {x : α | least_ge f r 1 x = 0}.indicator (f 0)
            + {x : α | least_ge f r 1 x = 1}.indicator (f 0) :
  begin
    ext x,
    obtain heq | heq := nat.eq_zero_or_eq_one_of_le (@least_ge_le _ f 1 r x),
    { rw [pi.add_apply, set.indicator_of_mem, set.indicator_of_not_mem, add_zero];
      simp [heq] },
    { rw [pi.add_apply, set.indicator_of_not_mem, set.indicator_of_mem, zero_add];
      simp [heq] }
  end
        ... ≤ᵐ[μ] {x : α | least_ge f r 1 x = 0}.indicator (f 0)
            + {x : α | least_ge f r 1 x = 1}.indicator (μ[f 1|ℱ 0]) :
  begin
    refine eventually_le.add_le_add (eventually_le.refl _ _) (_ : _ ≤ᵐ[μ] _),
    filter_upwards [hf.2.1 0 1 zero_le_one] with x hx using set.indicator_le_indicator hx,
  end
        ... =ᵐ[μ] μ[{x : α | least_ge f r 1 x = 0}.indicator (f 0)|ℱ 0]
            + μ[{x : α | least_ge f r 1 x = 1}.indicator (f 1)|ℱ 0] :
  begin
    refine eventually_eq.add _ _,
    { rw (condexp_of_strongly_measurable (ℱ.le 0) _ ((hf.integrable _).indicator $
        ℱ.le _ _ ((hf.adapted.is_stopping_time_least_ge _ _).measurable_set_eq _))),
      exact strongly_measurable.indicator (hf.adapted 0)
        ((hf.adapted.is_stopping_time_least_ge _ _).measurable_set_eq _) },
    { rw (_ : {x | least_ge f r 1 x = 1} = {x : α | least_ge f r 1 x = 0}ᶜ),
      { exact (condexp_indicator (hf.integrable 1)
          ((hf.adapted.is_stopping_time_least_ge _ _).measurable_set_eq _).compl).symm },
      { ext x,
        rw [set.mem_set_of_eq, set.mem_compl_eq, set.mem_set_of_eq, ← ne.def,
          ← nat.one_le_iff_ne_zero],
        exact ⟨λ h, h.symm ▸ le_rfl, λ h, le_antisymm (least_ge_le x) h⟩ } }
  end
end

lemma least_ge_eq_lt_iff {n : ℕ} {r : ℝ} {k : ℕ} (hk : k < n) {x : α} :
  least_ge f r n x = k ↔ least_ge f r (n + 1) x = k :=
begin
  split; intro h,
  { rw [← h, eq_comm],
    rw [← h, least_ge, hitting_lt_iff _ le_rfl] at hk,
    obtain ⟨j, hj₁, hj₂⟩ := hk,
    exact hitting_eq_hitting_of_exists n.le_succ ⟨j, ⟨zero_le _, hj₁.2.le⟩, hj₂⟩,
    apply_instance },
  { rw ← h,
    rw [← h, least_ge, hitting_lt_iff _ n.le_succ] at hk,
    obtain ⟨j, hj₁, hj₂⟩ := hk,
    exact hitting_eq_hitting_of_exists n.le_succ ⟨j, ⟨zero_le _, hj₁.2.le⟩, hj₂⟩ }
end

lemma least_ge_succ_eq_iff (n : ℕ) {r : ℝ} {x : α} :
  least_ge f r (n + 1) x = n ↔ least_ge f r n x = n ∧ r ≤ f n x :=
begin
  split,
  { intro h,
    refine ⟨_, (_ : f n x ∈ set.Ici r)⟩,
    { rw ← h,
      refine hitting_eq_hitting_of_exists (hitting_le _) _,
      have : least_ge f r (n + 1) x < n + 1 := h.symm ▸ n.lt_succ_self,
      rw [least_ge, hitting_lt_iff (n + 1) le_rfl] at this,
      obtain ⟨j, hj₁, hj₂⟩ := this,
      exact ⟨j, ⟨zero_le _, h.symm ▸ nat.le_of_lt_succ hj₁.2⟩, hj₂⟩ },
    { refine h ▸ hitting_mem_set _,
      have : least_ge f r (n + 1) x < n + 1 := h.symm ▸ n.lt_succ_self,
      rw [least_ge, hitting_lt_iff (n + 1) le_rfl] at this,
      obtain ⟨j, hj₁, hj₂⟩ := this,
      exact ⟨j, ⟨zero_le _, hj₁.2.le⟩, hj₂⟩ } },
  { rintro ⟨h₁, h₂⟩,
    rw [← h₁, eq_comm],
    exact hitting_eq_hitting_of_exists (h₁.symm ▸ n.le_succ)
      ⟨n, ⟨zero_le _, le_rfl⟩, h₂⟩ }
end

lemma least_ge_succ_eq_iff' (n : ℕ) {r : ℝ} {x : α} :
  least_ge f r (n + 1) x = n + 1 ↔ least_ge f r n x = n ∧ f n x < r :=
begin
  split,
  { intro h,
    have : least_ge f r n x = n,
    { refine le_antisymm (hitting_le _) _,
      by_contra hlt,
      rw [not_le, least_ge] at hlt,
      refine ne_of_lt _ h,
      rw [least_ge, hitting_lt_iff _ le_rfl],
      exact ⟨least_ge f r n x, ⟨zero_le _, nat.lt_succ_of_le (hitting_le _)⟩,
        hitting_mem_set_of_hitting_lt hlt⟩,
      apply_instance },
    refine ⟨this, _⟩,
    by_contra h',
    rw not_lt at h',
    rw ((least_ge_succ_eq_iff n).2 ⟨this, h'⟩) at h,
    norm_num at h },
  { rintro ⟨h₁, h₂⟩,
    refine le_antisymm (hitting_le _) (nat.succ_le_of_lt _),
    by_contra h,
    have : least_ge f r (n + 1) x = least_ge f r n x :=
      le_antisymm (h₁.symm ▸ not_lt.1 h) (hitting_mono n.le_succ),
    rw h₁ at this,
    refine not_lt.2 _ h₂,
    refine this ▸ hitting_mem_set_of_hitting_lt _,
    rw [← least_ge, this],
    exact n.lt_succ_self },
end

lemma submartingale.stopped_value_least_ge [is_finite_measure μ]
  (hf : submartingale f ℱ μ) (r : ℝ) :
  submartingale (λ i, stopped_value f (least_ge f r i)) ℱ μ :=
begin
  classical,
  refine submartingale_nat (λ N, strongly_measurable_stopped_value_of_le
      hf.adapted.prog_measurable_of_nat
      (hf.adapted.is_stopping_time_least_ge _ _) (λ x, hitting_le _))
    (λ i, integrable_stopped_value (hf.adapted.is_stopping_time_least_ge _ _)
      hf.integrable (λ x, hitting_le _)) (λ i, _),
  by_cases hi : i = 0,
  { rw [hi, zero_add],
    exact hf.stopped_value_least_ge_zero r },
  rw [stopped_value_eq least_ge_le, finset.sum_range_succ],
  swap, { apply_instance },
  simp_rw [least_ge, hitting_eq_end_iff, imp_iff_not_or, set.set_of_or],
  rw set.indicator_union_of_disjoint,
  { have heq₁ : {x | Inf (set.Icc 0 i ∩ {i : ℕ | f i x ∈ set.Ici r}) = i} =
      {x | least_ge f r (i + 1) x = i},
    { ext x,
      rw [set.mem_set_of, set.mem_set_of, least_ge_succ_eq_iff],
      refine ⟨λ h, _, _⟩,
      { rw [least_ge, hitting, ite_eq_right_iff],
        refine ⟨λ _, h, _⟩,
        have : i ∈ set.Icc 0 i ∩ {i : ℕ | f i x ∈ set.Ici r},
        { conv_lhs { rw ← h },
          exact nat.Inf_mem
            (set.ne_empty_iff_nonempty.1 (λ hemp, hi $ h ▸ hemp.symm ▸ nat.Inf_empty)) },
        exact this.2 },
      { rintro ⟨h₁, h₂⟩,
        exact hitting_eq_end_iff.1 h₁ ⟨i, ⟨zero_le _, le_rfl⟩, h₂⟩ } },
    have heq₂ : {x | ¬∃ j ∈ set.Icc 0 i, f j x ∈ set.Ici r} =
      {x | least_ge f r (i + 1) x = i + 1},
    { ext x,
      rw [set.mem_set_of, set.mem_set_of, least_ge_succ_eq_iff'],
      refine ⟨λ h, ⟨if_neg h, not_le.1 $ λ hneq, h ⟨i, ⟨zero_le _, le_rfl⟩, hneq⟩⟩, _⟩,
      rintro ⟨h₁, h₂⟩ h,
      rw [least_ge, hitting_eq_end_iff] at h₁,
      rw ← h₁ h at h₂,
      refine not_lt.2 _ h₂,
      exact (set.inter_subset_right _ _ (nat.Inf_mem $
        set.ne_empty_iff_nonempty.1 (λ hemp, hi $ h₁ h ▸ hemp.symm ▸ nat.Inf_empty)) :
        Inf (set.Icc 0 i ∩ {i | f i x ∈ set.Ici r}) ∈
          {i | f i x ∈ set.Ici r}) },
    have heq₃ : ∑ j in finset.range i, {x | least_ge f r i x = j}.indicator (f j) =
      ∑ j in finset.range i, {x | least_ge f r (i + 1) x = j}.indicator (f j),
    { refine finset.sum_congr rfl (λ j hj, _),
      simp_rw [least_ge_eq_lt_iff (finset.mem_range.1 hj)] },
    calc ∑ j in finset.range i, {x | hitting f (set.Ici r) 0 i x = j}.indicator (f j)
      + (λ x, {x | ¬∃ j ∈ set.Icc 0 i, f j x ∈ set.Ici r}.indicator (f i) x
      + {x | Inf (set.Icc 0 i ∩ {i : ℕ | f i x ∈ set.Ici r}) = i}.indicator (f i) x)
      = ∑ j in finset.range (i + 1), {x | least_ge f r (i + 1) x = j}.indicator (f j)
      + {x | least_ge f r (i + 1) x = i + 1}.indicator (f i) :
    begin
      rw [heq₁, heq₂, ← least_ge, heq₃, finset.sum_range_succ],
      ext x,
      simp only [pi.add_apply, finset.sum_apply],
      ring,
    end
       ... = {x | least_ge f r (i + 1) x = i + 1}.indicator (f i)
           + μ[∑ j in finset.range (i + 1), {x | least_ge f r (i + 1) x = j}.indicator (f j)|ℱ i] :
    begin
      rw add_comm,
      refine congr_arg2 _ rfl (condexp_of_strongly_measurable (ℱ.le _) _ _).symm,
      refine finset.strongly_measurable_sum' _ (λ j hj, _),
      { exact ((hf.adapted j).mono (ℱ.mono (nat.lt_succ_iff.1 $ finset.mem_range.1 hj))).indicator
          (ℱ.mono (nat.lt_succ_iff.1 $ finset.mem_range.1 hj) _
          ((hf.adapted.is_stopping_time_least_ge r (i + 1)).measurable_set_eq j)) },
      { exact integrable_finset_sum' _ (λ j hj, (hf.integrable _).indicator $
          ℱ.le j _ ((hf.adapted.is_stopping_time_least_ge r (i + 1)).measurable_set_eq j)) },
    end
       ... ≤ᵐ[μ] μ[{x | least_ge f r (i + 1) x = i + 1}.indicator (f (i + 1))|ℱ i]
           + μ[∑ j in finset.range (i + 1), {x | least_ge f r (i + 1) x = j}.indicator (f j)|ℱ i] :
    begin
      change _ ≤ᵐ[μ] _,
      refine eventually_le.add_le_add _ (eventually_le.refl _ _),
      refine eventually_le.trans _ (condexp_indicator (hf.integrable (i + 1)) _).symm.le,
      { filter_upwards [hf.2.1 i (i + 1) i.le_succ] with x hx using set.indicator_le_indicator hx },
      { rw (_ : {x | least_ge f r (i + 1) x = i + 1} = {x : α | least_ge f r (i + 1) x ≤ i}ᶜ),
        { exact ((hf.adapted.is_stopping_time_least_ge r (i + 1)) i).compl },
        { ext x,
          simp only [set.mem_set_of_eq, set.mem_compl_eq, not_le],
          exact ⟨λ h, h.symm ▸ i.lt_succ_self, λ h,
            nat.eq_of_le_of_lt_succ (nat.succ_le_iff.2 h) (nat.lt_succ_iff.2 (least_ge_le x))⟩ } }
    end
       ... =ᵐ[μ] μ[stopped_value f (least_ge f r (i + 1))|ℱ i] :
    begin
      refine (condexp_add ((hf.integrable _).indicator $ ℱ.le _ _
        ((hf.adapted.is_stopping_time_least_ge r (i + 1)).measurable_set_eq _))
        (integrable_finset_sum' _ (λ j hj, _))).symm.trans _,
      { exact (hf.integrable _).indicator (ℱ.le j _
          ((hf.adapted.is_stopping_time_least_ge r (i + 1)).measurable_set_eq j)) },
      { refine condexp_congr_ae (eventually_of_forall $ λ x, _),
        rw [stopped_value_eq least_ge_le, add_comm],
        swap, { apply_instance },
        conv_rhs { rw [finset.sum_range_succ] } }
    end },
  { rintro x ⟨hx₁, hx₂⟩,
    rw [set.mem_set_of, (_ : set.Icc 0 i ∩ {i | f i x ∈ set.Ici r} = ∅),
      nat.Inf_empty] at hx₂,
    { exact false.elim (hi hx₂.symm) },
    { exact set.eq_empty_of_forall_not_mem (λ j ⟨hj₁, hj₂⟩, hx₁ ⟨j, hj₁, hj₂⟩) } },
end

variables {r : ℝ} {R : ℝ≥0}

lemma norm_stopped_value_least_ge_le (hr : 0 ≤ r) (hf0 : f 0 = 0)
  (hbdd : ∀ᵐ x ∂μ, ∀ i, |f (i + 1) x - f i x| ≤ R) (i : ℕ) :
  ∀ᵐ x ∂μ, stopped_value f (least_ge f r i) x ≤ r + R :=
begin
  filter_upwards [hbdd] with x hbddx,
  change f (least_ge f r i x) x ≤ r + R,
  by_cases heq : least_ge f r i x = 0,
  { rw [heq, hf0, pi.zero_apply],
    exact add_nonneg hr R.coe_nonneg },
  { obtain ⟨k, hk⟩ := nat.exists_eq_succ_of_ne_zero heq,
    rw [hk, add_comm, ← sub_le_iff_le_add],
    have := not_mem_of_lt_hitting (hk.symm ▸ k.lt_succ_self : k < least_ge f r i x) (zero_le _),
    simp only [set.mem_union_eq, set.mem_Iic, set.mem_Ici, not_or_distrib, not_le] at this,
    exact (sub_lt_sub_left this _).le.trans ((le_abs_self _).trans (hbddx _)) }
end

-- the `pos_part` name is consistent with `integral_eq_integral_pos_part_sub_integral_neg_part`
-- though it might be confusing with `pos`
lemma abs_eq_pos_part_add_neg_part (x : ℝ) : |x| = x.to_nnreal + (-x).to_nnreal :=
by simp

lemma snorm_one_le_of_le {r : ℝ≥0} {f : α → ℝ}
  (hfint : integrable f μ) (hfint' : 0 ≤ μ[f]) (hf : ∀ᵐ x ∂μ, f x ≤ r) :
  snorm f 1 μ ≤ 2 * μ set.univ * r :=
begin
  by_cases hr : r = 0,
  { suffices : f =ᵐ[μ] 0,
    { rw [snorm_congr_ae this, snorm_zero, hr, ennreal.coe_zero, mul_zero],
      exact le_rfl },
    rw [hr, nonneg.coe_zero] at hf,
    have hnegf : μ[-f] = 0,
    { rw [integral_neg', neg_eq_zero],
      exact le_antisymm (integral_nonpos_of_ae hf) hfint' },
    have := (integral_eq_zero_iff_of_nonneg_ae _ hfint.neg).1 hnegf,
    { filter_upwards [this] with x hx,
      rwa [pi.neg_apply, pi.zero_apply, neg_eq_zero] at hx },
    { filter_upwards [hf] with x hx,
      rwa [pi.zero_apply, pi.neg_apply, right.nonneg_neg_iff] } },
  by_cases hμ : is_finite_measure μ,
  swap,
  { have : μ set.univ = ∞,
    { by_contra hμ',
      exact hμ (is_finite_measure.mk $ lt_top_iff_ne_top.2 hμ') },
    rw [this, ennreal.mul_top, if_neg, ennreal.top_mul, if_neg],
    { exact le_top },
    { simp [hr] },
    { norm_num } },
  haveI := hμ,
  rw [integral_eq_integral_pos_part_sub_integral_neg_part hfint, sub_nonneg] at hfint',
  have hposbdd : ∫ x, max (f x) 0 ∂μ ≤ (μ set.univ).to_real • r,
  { rw ← integral_const,
    refine integral_mono_ae hfint.real_to_nnreal (integrable_const r) _,
    filter_upwards [hf] with x hx using real.to_nnreal_le_iff_le_coe.2 hx },
  rw [mem_ℒp.snorm_eq_integral_rpow_norm one_ne_zero ennreal.one_ne_top
      (mem_ℒp_one_iff_integrable.2 hfint),
    ennreal.of_real_le_iff_le_to_real (ennreal.mul_ne_top
      (ennreal.mul_ne_top ennreal.two_ne_top $ @measure_ne_top _ _ _ hμ _) ennreal.coe_ne_top)],
  simp_rw [ennreal.one_to_real, inv_one, real.rpow_one, real.norm_eq_abs,
    abs_eq_pos_part_add_neg_part],
  rw integral_add hfint.real_to_nnreal,
  { simp only [real.coe_to_nnreal', ennreal.to_real_mul, ennreal.to_real_bit0,
    ennreal.one_to_real, ennreal.coe_to_real] at hfint' ⊢,
    refine (add_le_add_left hfint' _).trans _,
    rwa [← two_mul, mul_assoc, mul_le_mul_left (two_pos)],
    apply_instance },
  { exact hfint.neg.sup (integrable_zero _ _ μ) }
end

lemma snorm_one_le_of_le' {r : ℝ} {f : α → ℝ}
  (hfint : integrable f μ) (hfint' : 0 ≤ μ[f]) (hf : ∀ᵐ x ∂μ, f x ≤ r) :
  snorm f 1 μ ≤ 2 * μ set.univ * ennreal.of_real r :=
begin
  refine snorm_one_le_of_le hfint hfint' _,
  simp only [real.coe_to_nnreal', le_max_iff],
  filter_upwards [hf] with x hx using or.inl hx,
end

lemma submartingale.stopped_value_least_ge_snorm_le [is_finite_measure μ]
  (hf : submartingale f ℱ μ) (hr : 0 ≤ r) (hf0 : f 0 = 0)
  (hbdd : ∀ᵐ x ∂μ, ∀ i, |f (i + 1) x - f i x| ≤ R) (i : ℕ) :
  snorm (stopped_value f (least_ge f r i)) 1 μ ≤ 2 * μ set.univ * ennreal.of_real (r + R) :=
begin
  refine snorm_one_le_of_le' ((hf.stopped_value_least_ge r).integrable _) _
    (norm_stopped_value_least_ge_le hr hf0 hbdd i),
  rw ← integral_univ,
  refine le_trans _ ((hf.stopped_value_least_ge r).set_integral_le (zero_le _)
    measurable_set.univ),
  simp_rw [stopped_value, least_ge, hitting_of_le le_rfl, hf0, integral_zero']
end

lemma submartingale.stopped_value_least_ge_snorm_le' [is_finite_measure μ]
  (hf : submartingale f ℱ μ) (hr : 0 ≤ r) (hf0 : f 0 = 0)
  (hbdd : ∀ᵐ x ∂μ, ∀ i, |f (i + 1) x - f i x| ≤ R) (i : ℕ) :
  snorm (stopped_value f (least_ge f r i)) 1 μ ≤
    ennreal.to_nnreal (2 * μ set.univ * ennreal.of_real (r + R)) :=
begin
  refine (hf.stopped_value_least_ge_snorm_le hr hf0 hbdd i).trans _,
  simp [ennreal.coe_to_nnreal (measure_ne_top μ _), ennreal.coe_to_nnreal],
end

lemma submartingale.exists_tendsto_of_abs_bdd_above [is_finite_measure μ]
  (hf : submartingale f ℱ μ) (hf0 : f 0 = 0)
  (hbdd : ∀ᵐ x ∂μ, ∀ i, |f (i + 1) x - f i x| ≤ R) :
  ∀ᵐ x ∂μ, bdd_above (set.range $ λ n, f n x) → ∃ c, tendsto (λ n, f n x) at_top (𝓝 c) :=
begin
  have ht : ∀ᵐ x ∂μ, ∀ i : ℕ, ∃ c, tendsto (λ n, stopped_value f (least_ge f i n) x) at_top (𝓝 c),
  { rw ae_all_iff,
    exact λ i, submartingale.exists_ae_tendsto_of_bdd (hf.stopped_value_least_ge i)
      (hf.stopped_value_least_ge_snorm_le' i.cast_nonneg hf0 hbdd) },
  filter_upwards [ht] with x hx hxb,
  rw bdd_above at hxb,
  obtain ⟨i, hi⟩ := exists_nat_gt hxb.some,
  have hib : ∀ n, f n x < i,
  { intro n,
    exact lt_of_le_of_lt ((mem_upper_bounds.1 hxb.some_mem) _ ⟨n, rfl⟩) hi },
  have heq : ∀ n, stopped_value f (least_ge f i n) x = f n x,
  { intro n,
    rw [least_ge, hitting, stopped_value],
    simp only,
    rw if_neg,
    simp only [set.mem_Icc, set.mem_union, set.mem_Ici],
    push_neg,
    exact λ j _, hib j },
  simp only [← heq, hx i],
end

lemma submartingale.bdd_above_iff_exists_tendsto_aux [is_finite_measure μ]
  (hf : submartingale f ℱ μ) (hf0 : f 0 = 0)
  (hbdd : ∀ᵐ x ∂μ, ∀ i, |f (i + 1) x - f i x| ≤ R) :
  ∀ᵐ x ∂μ, bdd_above (set.range $ λ n, f n x) ↔ ∃ c, tendsto (λ n, f n x) at_top (𝓝 c) :=
by filter_upwards [hf.exists_tendsto_of_abs_bdd_above hf0 hbdd] with x hx using
  ⟨hx, λ ⟨c, hc⟩, hc.bdd_above_range⟩

lemma submartingale.bdd_above_iff_exists_tendsto [is_finite_measure μ]
  (hf : submartingale f ℱ μ) (hbdd : ∀ᵐ x ∂μ, ∀ i, |f (i + 1) x - f i x| ≤ R) :
  ∀ᵐ x ∂μ, bdd_above (set.range $ λ n, f n x) ↔ ∃ c, tendsto (λ n, f n x) at_top (𝓝 c) :=
begin
  set g : ℕ → α → ℝ := λ n x, f n x - f 0 x with hgdef,
  have hg : submartingale g ℱ μ :=
    hf.sub_martingale (martingale_const_fun _ _ (hf.adapted 0) (hf.integrable 0)),
  have hg0 : g 0 = 0,
  { ext x,
    simp only [hgdef, sub_self, pi.zero_apply] },
  have hgbdd : ∀ᵐ (x : α) ∂μ, ∀ (i : ℕ), |g (i + 1) x - g i x| ≤ ↑R,
  { simpa only [sub_sub_sub_cancel_right] },
  filter_upwards [hg.bdd_above_iff_exists_tendsto_aux hg0 hgbdd] with x hx,
  convert hx using 1; rw eq_iff_iff,
  { simp only [hgdef],
    refine ⟨λ h, _, λ h, _⟩;
    obtain ⟨b, hb⟩ := h;
    refine ⟨b + |f 0 x|, λ y hy, _⟩;
    obtain ⟨n, rfl⟩ := hy,
    { simp_rw [sub_eq_add_neg],
      exact add_le_add (hb ⟨n, rfl⟩) (neg_le_abs_self _) },
    { exact sub_le_iff_le_add.1 (le_trans (sub_le_sub_left (le_abs_self _) _) (hb ⟨n, rfl⟩)) } },
  { simp only [hgdef],
    refine ⟨λ h, _, λ h, _⟩;
    obtain ⟨c, hc⟩ := h,
    { exact ⟨c - f 0 x, hc.sub_const _⟩ },
    { refine ⟨c + f 0 x, _⟩,
      have := hc.add_const (f 0 x),
      simpa only [sub_add_cancel] } }
end

namespace borel_cantelli

/-!

### Lévy's generalization of the Borel-Cantelli lemma

Lévy's generalization of Borel-Cantelli states: given a filtration `ℱ` and a sequence of sets
`s` such that `s n ∈ ℱ n`, we have
`limsup s = {∑ μ[s (n + 1) | ℱ n] = ∞}`

-/

noncomputable
def mgale (ℱ : filtration ℕ m0) (μ : measure α) (s : ℕ → set α) (n : ℕ) : α → ℝ :=
∑ k in finset.range n, ((s (k + 1)).indicator 1 - μ[(s (k + 1)).indicator 1 | ℱ k])

variables {s : ℕ → set α}

lemma mgale_succ (n : ℕ) :
  mgale ℱ μ s (n + 1) =
    mgale ℱ μ s n + ((s (n + 1)).indicator 1 - μ[(s (n + 1)).indicator 1 | ℱ n]) :=
begin
  rw [mgale, finset.sum_range_succ],
  refl,
end

lemma adapted_mgale (hs : ∀ n, measurable_set[ℱ n] (s n)) :
  adapted ℱ (mgale ℱ μ s) :=
λ n, finset.strongly_measurable_sum' _ (λ k hk, (strongly_measurable_one.indicator
  (ℱ.mono (nat.succ_le_of_lt (finset.mem_range.1 hk)) _ (hs _))).sub
  (strongly_measurable_condexp.mono (ℱ.mono (finset.mem_range.1 hk).le)))

variables [is_finite_measure μ]

lemma integrable_mgale (hs : ∀ n, measurable_set[ℱ n] (s n)) (n : ℕ) :
  integrable (mgale ℱ μ s n) μ :=
integrable_finset_sum' _ (λ k hk,
  ((integrable_indicator_iff (ℱ.le (k + 1) _ (hs $ k + 1))).2
  (integrable_const 1).integrable_on).sub integrable_condexp)

section

variables {ι F' : Type*} [normed_add_comm_group F'] [normed_space ℝ F'] [complete_space F']
  {m n : measurable_space α}

lemma finset.sum_eventually_eq {α β : Type*} [add_comm_monoid β]
  {s : finset ι} {l : filter α} {f g : ι → α → β} (hs : ∀ i ∈ s, f i =ᶠ[l] g i) :
  ∑ i in s, f i =ᶠ[l] ∑ i in s, g i :=
begin
  replace hs: ∀ᶠ x in l, ∀ i ∈ s, f i x = g i x,
  { rwa eventually_all_finset },
  filter_upwards [hs] with x hx,
  simp only [finset.sum_apply, finset.sum_congr rfl hx],
end

lemma condexp_finset_sum {s : finset ι} {f : ι → α → F'} (hf : ∀ i ∈ s, integrable (f i) μ) :
  μ[∑ i in s, f i | m] =ᵐ[μ] ∑ i in s, μ[f i | m] :=
begin
  classical,
  revert hf,
  refine finset.induction_on s _ _,
  { intro hf,
    rw [finset.sum_empty, finset.sum_empty, condexp_zero] },
  { intros i s his heq hf,
    rw [finset.sum_insert his, finset.sum_insert his],
    exact (condexp_add (hf i $ finset.mem_insert_self i s) $ integrable_finset_sum' _
      (λ j hmem, hf j $ finset.mem_insert_of_mem hmem)).trans
      ((eventually_eq.refl _ _).add (heq $ λ j hmem, hf j $ finset.mem_insert_of_mem hmem)) }
end

end

lemma martingale_mgale (hs : ∀ n, measurable_set[ℱ n] (s n)) :
  martingale (mgale ℱ μ s) ℱ μ :=
begin
  refine martingale_nat (adapted_mgale hs) (integrable_mgale hs)
    (λ n, eventually_eq.symm $ (condexp_finset_sum _).trans $
    (@finset.sum_eventually_eq _ _ _ _ _ _ _
    (λ k, (μ[(s (k + 1)).indicator 1|ℱ n] - μ[(s (k + 1)).indicator 1|ℱ k])) _).trans _),
  { intros k hk,
    exact ((integrable_indicator_iff (ℱ.le (k + 1) _ (hs $ k + 1))).2
      (integrable_const 1).integrable_on).sub integrable_condexp },
  { intros k hk,
    rw finset.mem_range_succ_iff at hk,
    refine (condexp_sub ((integrable_indicator_iff (ℱ.le (k + 1) _ (hs $ k + 1))).2
      (integrable_const 1).integrable_on) integrable_condexp).trans
      ((ae_eq_refl _).sub _),
    rw (condexp_of_strongly_measurable (ℱ.le _)
      (strongly_measurable.mono strongly_measurable_condexp (ℱ.mono hk)) integrable_condexp),
    apply_instance },
  simp_rw [finset.sum_range_succ, sub_self, add_zero, mgale],
  refine finset.sum_eventually_eq (λ i hi, eventually_eq.sub _ $ ae_eq_refl _),
  rw [finset.mem_range, ← nat.succ_le_iff] at hi,
  rw condexp_of_strongly_measurable (ℱ.le _)
    (strongly_measurable_one.indicator (ℱ.mono hi _ $ hs _)),
  { exact (integrable_indicator_iff (ℱ.le _ _ (hs $ _))).2 (integrable_const 1).integrable_on },
  { apply_instance },
end

-- you can show the difference is bounded by 1 but that is unnecessary for our purposes
lemma mgale_diff_le (hs : ∀ n, measurable_set[ℱ n] (s n)) (n : ℕ) :
  ∀ᵐ x ∂μ, |mgale ℱ μ s (n + 1) x - mgale ℱ μ s n x| ≤ 2 :=
begin
  have h₁ : μ[(s (n + 1)).indicator 1|ℱ n] ≤ᵐ[μ] 1,
  { change _ ≤ᵐ[μ] (λ x, 1 : α → ℝ),
    rw ← @condexp_const _ _ _ _ _ _ _ μ (ℱ.le n) (1 : ℝ),
    refine condexp_mono ((integrable_indicator_iff (ℱ.le _ _ (hs $ _))).2
      (integrable_const 1).integrable_on) (integrable_const 1)
      (eventually_of_forall $ λ x, set.indicator_le_self' (λ _ _, zero_le_one) x) },
  have h₂ : (0 : α → ℝ) ≤ᵐ[μ] μ[(s (n + 1)).indicator 1|ℱ n],
  { rw ← @condexp_zero α ℝ _ _ _ (ℱ n) _ μ,
    exact condexp_mono (integrable_zero _ _ _)
      ((integrable_indicator_iff (ℱ.le _ _ (hs $ _))).2 (integrable_const 1).integrable_on)
      (eventually_of_forall $ λ x, set.indicator_nonneg (λ _ _, zero_le_one) _) },
  filter_upwards [h₁, h₂] with x hx₁ hx₂,
  simp only [mgale, finset.sum_range_succ, pi.add_apply, pi.sub_apply,
    finset.sum_apply, add_sub_cancel', ← one_add_one_eq_two],
  refine (abs_add _ _).trans (add_le_add _ _),
  { rw ← real.norm_eq_abs,
    refine (norm_indicator_le_norm_self _ _).trans _,
    simp only [pi.one_apply, cstar_ring.norm_one] },
  { rwa [abs_neg, abs_of_nonneg hx₂] }
end

end borel_cantelli

end measure_theory
