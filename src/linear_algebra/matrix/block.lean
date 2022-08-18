/-
Copyright (c) 2019 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Patrick Massot, Casper Putz, Anne Baanen
-/
import linear_algebra.matrix.determinant
import linear_algebra.matrix.nonsingular_inverse
import tactic.fin_cases

/-!
# Block matrices and their determinant

This file defines a predicate `matrix.block_triangular` saying a matrix
is block triangular, and proves the value of the determinant for various
matrices built out of blocks.

## Main definitions

 * `matrix.block_triangular` expresses that a `o` by `o` matrix is block triangular,
   if the rows and columns are ordered according to some order `b : o → α`

## Main results
  * `det_of_block_triangular`: the determinant of a block triangular matrix
    is equal to the product of the determinants of all the blocks
  * `det_of_upper_triangular` and `det_of_lower_triangular`: the determinant of
    a triangular matrix is the product of the entries along the diagonal

## Tags

matrix, diagonal, det, block triangular

-/

open finset function order_dual
open_locale big_operators matrix

universes v

variables {α β m n o : Type*} {m' n' : α → Type*}
variables {R : Type v} [comm_ring R] {M : matrix m m R} {b : m → α}

namespace matrix

section has_lt
variables [has_lt α]

/-- Let `b` map rows and columns of a square matrix `M` to blocks indexed by `α`s. Then
`block_triangular M n b` says the matrix is block triangular. -/
def block_triangular (M : matrix m m R) (b : m → α) : Prop := ∀ ⦃i j⦄, b j < b i → M i j = 0

@[simp] protected lemma block_triangular.minor {f : n → m} (h : M.block_triangular b) :
  (M.minor f f).block_triangular (b ∘ f) :=
λ i j hij, h hij

lemma block_triangular_reindex_iff {b : n → α} {e : m ≃ n} :
  (reindex e e M).block_triangular b ↔ M.block_triangular (b ∘ e) :=
begin
  refine ⟨λ h, _, λ h, _⟩,
  { convert h.minor,
    simp only [reindex_apply, minor_minor, minor_id_id, equiv.symm_comp_self] },
  { convert h.minor,
    simp only [comp.assoc b e e.symm, equiv.self_comp_symm, comp.right_id] }
end

protected lemma block_triangular.transpose :
  M.block_triangular b → Mᵀ.block_triangular (to_dual ∘ b) := swap

@[simp] protected lemma block_triangular_transpose_iff {b : m → αᵒᵈ} :
  Mᵀ.block_triangular b ↔ M.block_triangular (of_dual ∘ b) := forall_swap

lemma block_triangular_zero : block_triangular (0 : matrix m m R) b := λ i j h, rfl

protected lemma block_triangular.neg (hM : block_triangular M b) :
  block_triangular (- M) b :=
λ i j h, show - M i j = 0, by rw [hM h, neg_zero]

lemma block_triangular_add {M N : matrix m m R}
    (hM : block_triangular M b) (hN : block_triangular N b) :
  block_triangular (M + N) b :=
λ i j h, show M i j + N i j = 0, by rw [hM h, hN h, zero_add]

lemma block_triangular_sub {M N : matrix m m R}
    (hM : block_triangular M b) (hN : block_triangular N b) :
  block_triangular (M - N) b :=
λ i j h, show M i j - N i j = 0, by rw [hM h, hN h, zero_sub_zero]

end has_lt

section preorder
variables [preorder α]

lemma block_triangular_diagonal [decidable_eq m] (d : m → R) :
  block_triangular (diagonal d) b :=
λ i j h, diagonal_apply_ne' d (λ h', ne_of_lt h (congr_arg _ h'))

lemma block_triangular_block_diagonal' [decidable_eq α] (d : Π (i : α), matrix (m' i) (m' i) R) :
  block_triangular (block_diagonal' d) sigma.fst :=
begin
  rintros ⟨i, i'⟩ ⟨j, j'⟩ h,
  apply block_diagonal'_apply_ne d i' j' (λ h', ne_of_lt h h'.symm),
end

lemma block_triangular_block_diagonal [decidable_eq α] (d : α → matrix m m R) :
  block_triangular (block_diagonal d) prod.snd :=
begin
  rintros ⟨i, i'⟩ ⟨j, j'⟩ h,
  rw [block_diagonal'_eq_block_diagonal, block_triangular_block_diagonal'],
  exact h
end

end preorder

section linear_order
variables [linear_order α]

lemma lower_triangular_mul [fintype m]
  {M N : matrix m m R} (hM : block_triangular M b) (hN : block_triangular N b):
  block_triangular (M * N) b :=
begin
  intros i j hij,
  apply finset.sum_eq_zero,
  intros k hk,
  by_cases hki : b k < b i,
  { simp_rw [hM hki, zero_mul], },
  { simp_rw [hN (lt_of_lt_of_le hij (le_of_not_lt hki)), mul_zero] },
end

end linear_order

lemma upper_two_block_triangular' (A : matrix m m R) (B : matrix m n R) (D : matrix n n R) :
  block_triangular (from_blocks A B 0 D) (sum.elim (λ i, (0 : fin 2)) (λ j, 1)) :=
begin
  intros k1 k2 hk12,
  have h0 : ∀ (k : m ⊕ n), sum.elim (λ i, (0 : fin 2)) (λ j, 1) k = 0 → ∃ i, k = sum.inl i,
  { simp },
  have h1 : ∀ (k : m ⊕ n), sum.elim (λ i, (0 : fin 2)) (λ j, 1) k = 1 → ∃ j, k = sum.inr j,
  { simp },
  set mk1 := (sum.elim (λ i, (0 : fin 2)) (λ j, 1)) k1 with hmk1,
  set mk2 := (sum.elim (λ i, (0 : fin 2)) (λ j, 1)) k2 with hmk2,
  fin_cases mk1 using h; fin_cases mk2 using h_1; rw [h, h_1] at hk12,
  { exact absurd hk12 (nat.not_lt_zero 0) },
  { exact absurd hk12 (by norm_num) },
  { rw hmk1 at h,
    obtain ⟨i, hi⟩ := h1 k1 h,
    rw hmk2 at h_1,
    obtain ⟨j, hj⟩ := h0 k2 h_1,
    rw [hi, hj], simp },
  { exact absurd hk12 (irrefl 1) }
end

lemma upper_two_block_triangular (A : matrix m m R) (B : matrix m n R) (D : matrix n n R) :
  block_triangular (from_blocks A B 0 D) (sum.elim (λ i, 0) (λ j, 1)) :=
begin
  intros k1 k2 hk12,
  have h01 : ∀ (k : m ⊕ n), sum.elim (λ i, 0) (λ j, 1) k = 0 ∨ sum.elim (λ i, 0) (λ j, 1) k = 1,
  { simp },
  have h0 : ∀ (k : m ⊕ n), sum.elim (λ i, 0) (λ j, 1) k = 0 → ∃ i, k = sum.inl i, { simp },
  have h1 : ∀ (k : m ⊕ n), sum.elim (λ i, 0) (λ j, 1) k = 1 → ∃ j, k = sum.inr j, { simp },
  cases (h01 k1) with hk1 hk1; cases (h01 k2) with hk2 hk2; rw [hk1, hk2] at hk12,
  { exact absurd hk12 (nat.not_lt_zero 0) },
  { exact absurd hk12 (nat.not_lt_zero 1) },
  { obtain ⟨i, hi⟩ := h1 k1 hk1,
    obtain ⟨j, hj⟩ := h0 k2 hk2,
    rw [hi, hj], simp },
  { exact absurd hk12 (irrefl 1) }
end

/-! ### Determinant -/

variables [decidable_eq m] [fintype m] [decidable_eq n] [fintype n]

lemma equiv_block_det (M : matrix m m R) {p q : m → Prop} [decidable_pred p] [decidable_pred q]
  (e : ∀ x, q x ↔ p x) : (to_square_block_prop M p).det = (to_square_block_prop M q).det :=
by convert matrix.det_reindex_self (equiv.subtype_equiv_right e) (to_square_block_prop M q)

@[simp] lemma det_to_square_block_id (M : matrix m m R) (i : m) :
  (M.to_square_block id i).det = M i i :=
begin
  letI : unique {a // id a = i} := ⟨⟨⟨i, rfl⟩⟩, λ j, subtype.ext j.property⟩,
  exact (det_unique _).trans rfl,
end

lemma det_to_block (M : matrix m m R) (p : m → Prop) [decidable_pred p] :
  M.det = (from_blocks (to_block M p p) (to_block M p $ λ j, ¬p j)
    (to_block M (λ j, ¬p j) p) $ to_block M (λ j, ¬p j) $ λ j, ¬p j).det :=
begin
  rw ←matrix.det_reindex_self (equiv.sum_compl p).symm M,
  rw [det_apply', det_apply'],
  congr, ext σ, congr, ext,
  generalize hy : σ x = y,
  cases x; cases y;
  simp only [matrix.reindex_apply, to_block_apply, equiv.symm_symm,
    equiv.sum_compl_apply_inr, equiv.sum_compl_apply_inl,
    from_blocks_apply₁₁, from_blocks_apply₁₂, from_blocks_apply₂₁, from_blocks_apply₂₂,
    matrix.minor_apply],
end

lemma two_block_triangular_det (M : matrix m m R) (p : m → Prop) [decidable_pred p]
  (h : ∀ i, ¬ p i → ∀ j, p j → M i j = 0) :
  M.det = (to_square_block_prop M p).det * (to_square_block_prop M (λ i, ¬p i)).det :=
begin
  rw det_to_block M p,
  convert det_from_blocks_zero₂₁ (to_block M p p) (to_block M p (λ j, ¬p j))
    (to_block M (λ j, ¬p j) (λ j, ¬p j)),
  ext,
  exact h ↑i i.2 ↑j j.2
end

lemma two_block_triangular_det' (M : matrix m m R) (p : m → Prop) [decidable_pred p]
  (h : ∀ i, p i → ∀ j, ¬ p j → M i j = 0) :
  M.det = (to_square_block_prop M p).det * (to_square_block_prop M (λ i, ¬p i)).det :=
begin
  rw [M.two_block_triangular_det (λ i, ¬ p i), mul_comm],
  simp_rw not_not,
  congr' 1,
  exact equiv_block_det _ (λ _, not_not.symm),
  simpa only [not_not] using h,
end

-- TODO: move
lemma xxx [decidable_eq α] (k : α):
  image (λ i : {a // b a ≠ k}, b ↑i) univ = (image b univ).erase k :=
begin
  apply subset_antisymm,
  { rw image_subset_iff,
    intros i _,
    apply mem_erase_of_ne_of_mem i.2 (mem_image_of_mem _ (mem_univ _)) },
  { intros i hi,
    rw mem_image,
    rcases mem_image.1 (erase_subset _ _ hi) with ⟨a, _, ha⟩,
    subst ha,
    exact ⟨⟨a, ne_of_mem_erase hi⟩, mem_univ _, rfl⟩ }
end

protected lemma block_triangular.det [decidable_eq α] [linear_order α] (hM : block_triangular M b) :
  M.det = ∏ a in univ.image b, (M.to_square_block b a).det :=
begin
  unfreezingI { induction hs : univ.image b using finset.strong_induction
    with s ih generalizing m },
  subst hs,
  by_cases h : univ.image b = ∅,
  { haveI := univ_eq_empty_iff.1 (image_eq_empty.1 h),
    simp [h] },
  { let k := (univ.image b).max' (nonempty_of_ne_empty h),
    rw two_block_triangular_det' M (λ i, b i = k),
    { have : univ.image b = insert k ((univ.image b).erase k),
      { rw insert_erase, apply max'_mem },
      rw [this, prod_insert (not_mem_erase _ _)],
      refine congr_arg _ _,
      let b' := λ i : {a // b a ≠ k}, b ↑i,
      have h' :  block_triangular (M.to_square_block_prop (λ (i : m), b i ≠ k)) b',
      { intros i j, apply hM },
      have hb' : image b' univ = (image b univ).erase k := by apply xxx,
      rw ih ((univ.image b).erase k) (erase_ssubset (max'_mem _ _)) h' hb',
      apply finset.prod_congr rfl,
      intros l hl,
      let he : {a // b' a = l} ≃ {a // b a = l},
      { have hc : ∀ (i : m), (λ a, b a = l) i → (λ a, b a ≠ k) i,
        { intros i hbi, rw hbi, exact ne_of_mem_erase hl },
        exact equiv.subtype_subtype_equiv_subtype hc },
      simp only [to_square_block_def],
      rw ← matrix.det_reindex_self he.symm (λ (i j : {a // b a = l}), M ↑i ↑j),
      refine congr_arg _ _,
      ext,
      simp [to_square_block_def, to_square_block_prop_def] },
  { intros i hi j hj,
    apply hM,
    rw hi,
    apply lt_of_le_of_ne _ hj,
    exact finset.le_max' (univ.image b) _ (mem_image_of_mem _ (mem_univ _)) } }
end

lemma block_triangular.det_fintype [decidable_eq α] [fintype α] [linear_order α]
  (h : block_triangular M b) :
  M.det = ∏ k : α, (M.to_square_block b k).det :=
begin
  refine h.det.trans (prod_subset (subset_univ _) $ λ a _ ha, _),
  have : is_empty {i // b i = a} := ⟨λ i, ha $ mem_image.2 ⟨i, mem_univ _, i.2⟩⟩,
  exactI det_is_empty,
end

/-! ### Invertible -/


lemma xxxx [decidable_eq α] (k : α) (hk : k ∈ image b univ) (p : α → Prop) [decidable_pred p] (hp : ¬ p k) :
  image (λ i : {a // p (b a)}, b ↑i) univ ⊂ image b univ :=
begin
  split,
  { intros x hx,
    rcases mem_image.1 hx with ⟨y, _, hy⟩,
    exact hy ▸ mem_image_of_mem b (mem_univ y) },
  { intros h,
    rw mem_image at hk,
    rcases hk with ⟨k', _, hk'⟩, subst hk',
    have := h (mem_image_of_mem b (mem_univ k')),
    rw mem_image at this,
    rcases this with ⟨j, hj, hj'⟩,
    exact hp (hj' ▸ j.2) }
end

lemma to_block_mul {m n k : Type*} [fintype n] (p : m → Prop) (q : k → Prop)
    (A : matrix m n R) (B : matrix n k R) :
  (A ⬝ B).to_block p q = A.to_block p (λ _, true) ⬝ B.to_block (λ _, true) q :=
begin
  ext i k,
  simp only [to_block_apply, mul_apply],
  rw sum_subtype,
  simp,
end

lemma to_block_mul' {m n k : Type*} [fintype n] (p : m → Prop) (q : n → Prop) [decidable_pred q] (r : k → Prop)
    (A : matrix m n R) (B : matrix n k R) :
  (A ⬝ B).to_block p r =
    A.to_block p q ⬝ B.to_block q r + A.to_block p (λ i, ¬ q i) ⬝ B.to_block (λ i, ¬ q i) r :=
begin
  classical,
  ext i k,
  simp only [to_block_apply, mul_apply, pi.add_apply],
  convert (fintype.sum_subtype_add_sum_subtype q (λ x, A ↑i x * B x ↑k)).symm
end

lemma to_block_diagonal_eq (d : m → R) (p : m → Prop) :
  matrix.to_block (diagonal d) p p = diagonal (λ i : subtype p, d ↑i) :=
begin
  ext i j,
  by_cases i = j,
  { simp [h] },
  { simp [has_one.one, h, λ h', h $ subtype.ext h'], }
end

lemma to_block_diagonal_ne (d : m → R) (p : m → Prop) :
  matrix.to_block (diagonal d) (λ i, ¬ p i) p = 0 :=
begin
  ext ⟨i, hi⟩ ⟨j, hj⟩,
  have : i ≠ j, from λ h, hi (h.symm ▸ hj),
  simp [diagonal_apply_ne d this]
end

lemma to_block_one_eq (p : m → Prop) : matrix.to_block (1 : matrix m m R) p p = 1 :=
to_block_diagonal_eq _ p

lemma to_block_one_ne (p : m → Prop) : matrix.to_block (1 : matrix m m R) (λ i, ¬ p i) p = 0 :=
to_block_diagonal_ne _ p

lemma to_block_inverse_of_block_triangular [linear_order α]
  [invertible M] (hM : block_triangular M b) (k : α) :
  M⁻¹.to_block (λ i, b i < k) (λ i, b i < k) ⬝ M.to_block (λ i, b i < k) (λ i, b i < k) = 1 :=
begin
  let p := (λ i, b i < k),
  have h_sum : M⁻¹.to_block p p ⬝ M.to_block p p +
      M⁻¹.to_block p (λ i, ¬ p i) ⬝ M.to_block (λ i, ¬ p i) p = 1,
    by rw [←to_block_mul', inv_mul_of_invertible M, to_block_one_eq],
  have h_zero : M.to_block (λ i, ¬ p i) p = 0,
  { ext i j,
    simpa using hM (lt_of_lt_of_le j.2 (le_of_not_lt i.2)) },
  simpa [h_zero] using h_sum
end

lemma nonsingular_inv_to_block_of_block_triangular [linear_order α]
  [invertible M] (hM : block_triangular M b) (k : α) :
  (M.to_block (λ i, b i < k) (λ i, b i < k))⁻¹ = M⁻¹.to_block (λ i, b i < k) (λ i, b i < k) :=
inv_eq_left_inv (to_block_inverse_of_block_triangular hM k)

lemma to_block_inverse_of_block_triangular' [linear_order α]
  [invertible M] (hM : block_triangular M b) (k : α) :
  M.to_block (λ i, k ≤ b i) (λ i, k ≤ b i) ⬝ M⁻¹.to_block (λ i, k ≤ b i) (λ i, k ≤ b i) = 1:=
begin
  let p := (λ i, k ≤ b i),
  have h_sum : M.to_block p p ⬝ M⁻¹.to_block p p +
      M.to_block p (λ i, ¬ p i) ⬝ M⁻¹.to_block (λ i, ¬ p i) p = 1,
    by rw [←to_block_mul', mul_inv_of_invertible M, to_block_one_eq],
  have h_zero : M.to_block p (λ i, ¬ p i) = 0,
  { ext i j,
    simpa using hM (lt_of_lt_of_le (lt_of_not_le j.2) i.2) },
  simpa [h_zero] using h_sum
end

noncomputable def invertible_to_block_of_block_triangular
  [linear_order α] [invertible M] (hM : block_triangular M b) (k : α) :
  invertible (M.to_block (λ i, b i < k) (λ i, b i < k)) :=
invertible_of_left_inverse _ _ (to_block_inverse_of_block_triangular hM k)

lemma to_block_inverse_eq_zero [linear_order α]
  [invertible M] (hM : block_triangular M b) (k : α) :
  M⁻¹.to_block (λ i, k ≤ b i) (λ i, b i < k) = 0 :=
begin
  have := mul_inv_of_invertible M,
  have h_iff : (λ i, k ≤ b i) = (λ i, ¬ b i < k),
  { ext i, simp },
  let p := (λ i, b i < k),
  let q := (λ i, ¬ b i < k),
  have h_sum : M⁻¹.to_block q p ⬝ M.to_block p p +
      M⁻¹.to_block q q ⬝ M.to_block q p = 0,
    by rw [←to_block_mul', inv_mul_of_invertible M, to_block_one_ne],
  have h_zero : M.to_block q p = 0,
  { ext i j,
    simpa using hM (lt_of_lt_of_le j.2 (le_of_not_lt i.2)) },
  have h_mul_eq_zero : M⁻¹.to_block q p ⬝ M.to_block p p = 0,
    by simpa [h_zero] using h_sum,
  haveI : invertible (M.to_block p p) := invertible_to_block_of_block_triangular hM k,
  rw [h_iff, ← matrix.zero_mul (M.to_block p p)⁻¹, ← h_mul_eq_zero,
    mul_inv_cancel_right_of_invertible],
end

lemma invertible_square_block_of_block_triangular
    [invertible M] [linear_order α] (hM : block_triangular M b) :
  block_triangular M⁻¹ b :=
begin
  unfreezingI { induction hs : univ.image b using finset.strong_induction
    with s ih generalizing m },
  subst hs,
  by_cases h : univ.image b = ∅,
  { intros i j,
    rw [image_eq_empty, univ_eq_empty_iff] at h,
    exact false.elim (@is_empty.false _ h i) },
  { let k := (univ.image b).max' (nonempty_of_ne_empty h),
    let b' := λ i : {a // b a < k}, b ↑i,
    let A := M.to_block (λ i, b i < k) (λ j, b j < k),
    let B := M.to_block (λ i, b i < k) (λ j, b j ≤ k),
    let C := M.to_block (λ i, b i ≤ k) (λ j, b j < k),
    let D := M.to_block (λ i, b i ≤ k) (λ j, b j ≤ k),
    show M⁻¹.block_triangular b,
    { intros i j hij,
      by_cases hbi : b i = k,
      { have hi : k ≤ b i := le_of_eq hbi.symm,
        have hj : b j < k := hbi ▸ hij,
        have : M⁻¹.to_block (λ (i : m), k ≤ b i) (λ (i : m), b i < k) ⟨i, hi⟩ ⟨j, hj⟩ = 0 :=
          by simp only [to_block_inverse_eq_zero hM k, pi.zero_apply],
        simp [this.symm] },
      { haveI : invertible A,
        { apply invertible_to_block_of_block_triangular hM },
        have hA : A.block_triangular b',
        { intros i j, apply hM },
        have hb' : image b' univ ⊂ (image b univ),
          by apply xxxx k (max'_mem _ _) (λ a, a < k) (lt_irrefl _),
        have hA : A⁻¹.block_triangular b',
          from ih (image b' univ) hb' hA rfl,
        have hi : b i < k,
          from lt_of_le_of_ne (le_max' (univ.image b) (b i) (mem_image_of_mem _ (mem_univ _))) hbi,
        have hj : b j < k, from lt_trans hij hi,
        have hij' : b' ⟨j, hj⟩ < b' ⟨i, hi⟩, by simp_rw [b', subtype.coe_mk, hij],
        have hA := hA hij',
        have h_A_inv: A⁻¹ = M⁻¹.to_block (λ (i : m), b i < k) (λ (i : m), b i < k),
        { simp_rw [A],
          exact nonsingular_inv_to_block_of_block_triangular hM k },
        rw h_A_inv at hA,
        simp [hA.symm] } } }
end

end matrix
