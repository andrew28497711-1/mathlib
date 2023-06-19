/-
Copyright (c) 2022 Yaël Dillies, Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies, Bhavik Mehta
-/
import combinatorics.simple_graph.regularity.uniform
import combinatorics.simple_graph.triangle.basic
import data.real.basic
import order.partition.equipartition

/-!
# Triangle counting lemma

In this file, we prove the triangle counting lemma.

## References

[Yaël Dillies, Bhavik Mehta, *Formalising Szemerédi’s Regularity Lemma in Lean*][srl_itp]
-/

-- TODO: This instance is bad because it creates data out of a Prop
local attribute [-instance] decidable_eq_of_subsingleton

open finset fintype
open_locale big_operators

variables {α : Type*} (G G' : simple_graph α) [decidable_rel G.adj] {ε : ℝ} {s t u : finset α}

namespace simple_graph

/-- The pairs of vertices whose density is big. -/
private noncomputable def bad_vertices (ε : ℝ) (s t : finset α) :=
s.filter (λ x, ((t.filter (G.adj x)).card : ℝ) < (G.edge_density s t - ε) * t.card)

variables [decidable_eq α]

lemma interedges_bad_vertices :
  rel.interedges G.adj (bad_vertices G ε s t) t =
    (bad_vertices G ε s t).bUnion (λ x, (t.filter (G.adj x)).image (λ y, (x, y))) :=
begin
  ext ⟨x, y⟩,
  simp only [mem_bUnion, mem_image, exists_prop, mem_filter, prod.mk.inj_iff,
    exists_eq_right_right, rel.mem_interedges_iff],
end

lemma pairs_card_bad_le :
  ((rel.interedges G.adj (bad_vertices G ε s t) t).card : ℝ) ≤
    (bad_vertices G ε s t).card * t.card * (G.edge_density s t - ε) :=
begin
  refine (nat.cast_le.2 $ (card_le_of_subset $ subset_of_eq G.interedges_bad_vertices).trans
    card_bUnion_le).trans _,
  simp_rw [nat.cast_sum, card_image_of_injective _ (prod.mk.inj_left _), ←nsmul_eq_mul,
    smul_mul_assoc, mul_comm (t.card : ℝ)],
  exact sum_le_card_nsmul _ _ _ (λ x hx, (mem_filter.1 hx).2.le),
end

lemma edge_density_bad_vertices (hε : 0 ≤ ε) (dst : 2 * ε ≤ G.edge_density s t) :
  (G.edge_density (bad_vertices G ε s t) t : ℝ) ≤ G.edge_density s t - ε :=
begin
  rw edge_density_def,
  push_cast,
  refine div_le_of_nonneg_of_le_mul (by positivity) (sub_nonneg_of_le $ by linarith) _,
  rw mul_comm,
  exact G.pairs_card_bad_le,
end

lemma few_bad_vertices (dst : 2 * ε ≤ G.edge_density s t) (hst : G.is_uniform ε s t) :
  ((bad_vertices G ε s t).card : ℝ) ≤ s.card * ε :=
begin
  have hε : ε ≤ 1 := (le_mul_of_one_le_of_le_of_nonneg (by norm_num) le_rfl hst.pos.le).trans
    (dst.trans $ by exact_mod_cast edge_density_le_one _ _ _),
  by_contra,
  rw not_le at h,
  have : |(G.edge_density (bad_vertices G ε s t) t : ℝ) - G.edge_density s t| < ε :=
    hst (filter_subset _ _) subset.rfl h.le (mul_le_of_le_one_right (nat.cast_nonneg _) hε),
  rw abs_sub_lt_iff at this,
  linarith [G.edge_density_bad_vertices hst.pos.le dst],
end

-- A subset of the triangles constructed in a weird way to make them easy to count
lemma triangle_split_helper :
  (s \ (bad_vertices G ε s t ∪ bad_vertices G ε s u)).bUnion
    (λ x, ((t.filter (G.adj x) ×ˢ u.filter (G.adj x)).filter
      (λ (yz : _ × _), G.adj yz.1 yz.2)).image (prod.mk x)) ⊆
  (s ×ˢ t ×ˢ u).filter
    (λ (xyz : α × α × α), G.adj xyz.1 xyz.2.1 ∧ G.adj xyz.1 xyz.2.2 ∧ G.adj xyz.2.1 xyz.2.2) :=
begin
  rintro ⟨x, y, z⟩,
  simp only [mem_filter, mem_product, mem_bUnion, mem_sdiff, exists_prop, mem_union,
    mem_image, prod.exists, and_assoc, exists_imp_distrib, and_imp, prod.mk.inj_iff],
  rintro x hx - y z hy xy hz xz yz rfl rfl rfl,
  exact ⟨hx, hy, hz, xy, xz, yz⟩,
end

lemma good_vertices_triangle_card (dst : 2 * ε ≤ G.edge_density s t)
  (dsu : 2 * ε ≤ G.edge_density s u) (dtu : 2 * ε ≤ G.edge_density t u) (utu : G.is_uniform ε t u)
  (x : α) (hx : x ∈ s \ (bad_vertices G ε s t ∪ bad_vertices G ε s u)) :
  ε^3 * t.card * u.card ≤ ((((t.filter (G.adj x)) ×ˢ (u.filter (G.adj x))).filter
      (λ (yz : _ × _), G.adj yz.1 yz.2)).image (prod.mk x)).card :=
begin
  simp only [mem_sdiff, bad_vertices, mem_union, not_or_distrib, mem_filter, not_and_distrib,
    not_lt] at hx,
  rw [←or_and_distrib_left, and_or_distrib_left] at hx,
  simp only [false_or, and_not_self, mul_comm ((_ : ℝ) - _)] at hx,
  rcases hx with ⟨hx, hxY, hsu⟩,
  have hY : (t.card : ℝ) * ε ≤ (filter (G.adj x) t).card,
  { exact (mul_le_mul_of_nonneg_left (by linarith) (nat.cast_nonneg _)).trans hxY },
  have hZ : (u.card : ℝ) * ε ≤ (filter (G.adj x) u).card,
  { exact (mul_le_mul_of_nonneg_left (by linarith) (nat.cast_nonneg _)).trans hsu },
  rw card_image_of_injective _ (prod.mk.inj_left _),
  have := utu (filter_subset (G.adj x) _) (filter_subset (G.adj x) _) hY hZ,
  have : ε ≤ G.edge_density (filter (G.adj x) t) (filter (G.adj x) u),
  { rw abs_sub_lt_iff at this,
    linarith },
  rw [edge_density_def] at this,
  push_cast at this,
  have hε := utu.pos.le,
  refine le_trans _ (mul_le_of_nonneg_of_le_div (nat.cast_nonneg _) (by positivity) this),
  refine eq.trans_le _ (mul_le_mul_of_nonneg_left (mul_le_mul hY hZ (by positivity) $
    by positivity) hε),
  ring,
end

lemma triangle_counting
  (dst : 2 * ε ≤ G.edge_density s t) (hst : G.is_uniform ε s t)
  (dsu : 2 * ε ≤ G.edge_density s u) (uXZ : G.is_uniform ε s u)
  (dtu : 2 * ε ≤ G.edge_density t u) (utu : G.is_uniform ε t u) :
  (1 - 2 * ε) * ε^3 * s.card * t.card * u.card ≤
    ((s ×ˢ t ×ˢ u).filter $ λ xyz : α × α × α,
      G.adj xyz.1 xyz.2.1 ∧ G.adj xyz.1 xyz.2.2 ∧ G.adj xyz.2.1 xyz.2.2).card :=
begin
  have h₁ : ((bad_vertices G ε s t).card : ℝ) ≤ s.card * ε := G.few_bad_vertices dst hst,
  have h₂ : ((bad_vertices G ε s u).card : ℝ) ≤ s.card * ε := G.few_bad_vertices dsu uXZ,
  let X' := s \ (bad_vertices G ε s t ∪ bad_vertices G ε s u),
  have : X'.bUnion _ ⊆ (s.product (t.product u)).filter
    (λ (xyz : α × α × α), G.adj xyz.1 xyz.2.1 ∧ G.adj xyz.1 xyz.2.2 ∧ G.adj xyz.2.1 xyz.2.2),
  { apply triangle_split_helper },
  refine le_trans _ (nat.cast_le.2 $ card_le_of_subset this),
  rw [card_bUnion, nat.cast_sum],
  { have := λ x hx, G.good_vertices_triangle_card dst dsu dtu utu x hx,
    apply le_trans _ (card_nsmul_le_sum X' _ _ this),
    rw nsmul_eq_mul,
    have := hst.pos.le,
    suffices hX' : (1 - 2 * ε) * s.card ≤ X'.card,
    { exact eq.trans_le (by ring) (mul_le_mul_of_nonneg_right hX' $ by positivity) },
    have i : bad_vertices G ε s t ∪ bad_vertices G ε s u ⊆ s,
    { apply union_subset (filter_subset _ _) (filter_subset _ _) },
    rw [sub_mul, one_mul, card_sdiff i, nat.cast_sub (card_le_of_subset i), sub_le_sub_iff_left,
      mul_assoc, mul_comm ε, two_mul],
    refine (nat.cast_le.2 $ card_union_le _ _).trans _,
    rw nat.cast_add,
    exact add_le_add h₁ h₂ },
  rintro x hx y hy t,
  rw disjoint_left,
  simp only [prod.forall, mem_image, not_exists, exists_prop, mem_filter, prod.mk.inj_iff,
    exists_imp_distrib, and_imp, not_and, mem_product, or.assoc],
  rintro - - - - - - _ _ _ rfl rfl _ _ _ _ _ _ _ rfl _,
  exact t rfl,
end

private lemma triple_eq_triple_of_mem (hst : disjoint s t) (hsu : disjoint s u) (htu : disjoint t u)
  {x₁ x₂ y₁ y₂ z₁ z₂ : α} (h : ({x₁, y₁, z₁} : finset α) = {x₂, y₂, z₂})
  (hx₁ : x₁ ∈ s) (hx₂ : x₂ ∈ s) (hy₁ : y₁ ∈ t) (hy₂ : y₂ ∈ t) (hz₁ : z₁ ∈ u) (hz₂ : z₂ ∈ u) :
  (x₁, y₁, z₁) = (x₂, y₂, z₂) :=
begin
  simp only [finset.subset.antisymm_iff, subset_iff, mem_insert, mem_singleton, forall_eq_or_imp,
    forall_eq] at h,
  rw disjoint_left at hst hsu htu,
  rw [prod.mk.inj_iff, prod.mk.inj_iff],
  simp only [and.assoc, @or.left_comm _ (y₁ = y₂), @or.comm _ (z₁ = z₂),
    @or.left_comm _ (z₁ = z₂)] at h,
  refine ⟨h.1.resolve_right (not_or _ _), h.2.1.resolve_right (not_or _ _),
    h.2.2.1.resolve_right (not_or _ _)⟩;
  { rintro rfl,
    solve_by_elim }
end

variables [fintype α] {P : finpartition (univ : finset α)}

lemma triangle_counting2
  (dst : 2 * ε ≤ G.edge_density s t) (ust : G.is_uniform ε s t) (hst : disjoint s t)
  (dsu : 2 * ε ≤ G.edge_density s u) (uXZ : G.is_uniform ε s u) (hsu : disjoint s u)
  (dtu : 2 * ε ≤ G.edge_density t u) (utu : G.is_uniform ε t u) (htu : disjoint t u) :
  (1 - 2 * ε) * ε^3 * s.card * t.card * u.card ≤ (G.clique_finset 3).card :=
begin
  apply (G.triangle_counting dst ust dsu uXZ dtu utu).trans _,
  rw nat.cast_le,
  refine card_le_card_of_inj_on (λ xyz, {xyz.1, xyz.2.1, xyz.2.2}) _ _,
  { rintro ⟨x, y, z⟩,
    simp only [and_imp, mem_filter, mem_product, mem_clique_finset_iff, is_3_clique_triple_iff],
    exact λ hx hy hz xy xz yz, ⟨xy, xz, yz⟩ },
  rintro ⟨x₁, y₁, z₁⟩ h₁ ⟨x₂, y₂, z₂⟩ h₂ t,
  simp only [mem_filter, mem_product] at h₁ h₂,
  apply triple_eq_triple_of_mem hst hsu htu t;
  tauto
end

variables {G G'}

lemma reduced_double_edges :
  univ.filter (λ xy : α × α, G.adj xy.1 xy.2) \
    univ.filter (λ xy : α × α, (G.reduced P (ε/8) (ε/4)).adj xy.1 xy.2) ⊆
      (P.non_uniforms G (ε/8)).bUnion (λ UV, UV.1 ×ˢ UV.2) ∪
        P.parts.bUnion off_diag ∪
          (P.parts.off_diag.filter $ λ UV : _ × _, ↑(G.edge_density UV.1 UV.2) < ε/4).bUnion
            (λ UV, (UV.1 ×ˢ UV.2).filter $ λ xy, G.adj xy.1 xy.2) :=
begin
  rintro ⟨x, y⟩,
  simp only [mem_sdiff, mem_filter, mem_univ, true_and, reduced_adj, not_and, not_exists,
    not_le, mem_bUnion, mem_union, exists_prop, mem_product, prod.exists, mem_off_diag, and_imp,
    or.assoc, and.assoc, P.mk_mem_non_uniforms_iff],
  intros h h',
  replace h' := h' h,
  obtain ⟨U, hU, hx⟩ := P.exists_mem (mem_univ x),
  obtain ⟨V, hV, hy⟩ := P.exists_mem (mem_univ y),
  rcases eq_or_ne U V with rfl | hUV,
  { exact or.inr (or.inl ⟨U, hU, hx, hy, G.ne_of_adj h⟩) },
  by_cases h₂ : G.is_uniform (ε/8) U V,
  { exact or.inr (or.inr ⟨U, V, hU, hV, hUV, h' _ hU _ hV hx hy hUV h₂, hx, hy, h⟩) },
  { exact or.inl ⟨U, V, hU, hV, hUV, h₂, hx, hy⟩ }
end

-- We will break up the sum more later
lemma non_uniform_killed_card :
  (((P.non_uniforms G ε).bUnion $ λ UV, UV.1 ×ˢ UV.2).card : ℝ) ≤
    ∑ i in P.non_uniforms G ε, i.1.card * i.2.card :=
by { norm_cast, simp_rw ←card_product, exact card_bUnion_le }

lemma internal_killed_card (hP : P.is_equipartition) :
  ((P.parts.bUnion off_diag).card : ℝ) ≤ card α * (card α + P.parts.card) / P.parts.card :=
begin
  have : (P.parts.bUnion off_diag).card ≤
    P.parts.card * (card α / P.parts.card) * (card α / P.parts.card + 1),
  { rw mul_assoc,
    refine card_bUnion_le_card_mul _ _ _ (λ U hU, _),
    suffices : (U.card - 1) * U.card ≤ card α / P.parts.card * (card α / P.parts.card + 1),
    { rwa [nat.mul_sub_right_distrib, one_mul, ←off_diag_card] at this },
    have := hP.card_part_le_average_add_one hU,
    refine nat.mul_le_mul ((nat.sub_le_sub_right this 1).trans _) this,
    simp only [nat.add_succ_sub_one, add_zero, card_univ] },
  refine (nat.cast_le.2 this).trans _,
  casesI is_empty_or_nonempty α,
  { simp [fintype.card_eq_zero] },
  have i : (_ : ℝ) ≠ 0 := nat.cast_ne_zero.2 (P.parts_nonempty univ_nonempty.ne_empty).card_pos.ne',
  rw [mul_div_assoc, div_add_same i, nat.cast_mul, nat.cast_add_one],
  refine mul_le_mul _ _ (by positivity) (by positivity),
  { rw [nat.cast_le, mul_comm],
    exact nat.div_mul_le_self _ _ },
  exact add_le_add_right nat.cast_div_le _,
end

lemma sparse_card (hP : P.is_equipartition) (hε : 0 ≤ ε) :
  (((P.parts.off_diag.filter $ λ UV : _ × _, ↑(G.edge_density UV.1 UV.2) < ε).bUnion $
      λ UV, (UV.1 ×ˢ UV.2).filter $ λ xy, G.adj xy.1 xy.2).card : ℝ) ≤
    ε * (card α + P.parts.card)^2 :=
begin
  refine (nat.cast_le.2 card_bUnion_le).trans _,
  rw nat.cast_sum,
  change ∑ x in _, ↑(G.interedges _ _).card ≤ _,
  have : ∀ UV ∈ P.parts.off_diag.filter (λ (UV : _ × _), ↑(G.edge_density UV.1 UV.2) < ε),
    ↑(G.interedges UV.1 UV.2).card ≤ ε * (UV.1.card * UV.2.card),
    simp only [and_imp, mem_off_diag, mem_filter, ne.def, simple_graph.edge_density_def],
  { push_cast,
    rintro ⟨U, V⟩ hU hV hUV e,
    apply le_of_lt,
    rwa ←div_lt_iff,
    have := P.nonempty_of_mem_parts hU,
    have := P.nonempty_of_mem_parts hV,
    positivity },
  apply (sum_le_sum this).trans,
  refine (sum_le_sum_of_subset_of_nonneg (filter_subset _ _) $ λ i hi _, _).trans _,
  { positivity },
  rw ←mul_sum,
  refine mul_le_mul_of_nonneg_left _ hε,
  refine (sum_le_card_nsmul P.parts.off_diag (λ i, (i.1.card * i.2.card : ℝ))
    ((card α / P.parts.card + 1)^2 : ℕ) _).trans _,
  { simp only [prod.forall, finpartition.mk_mem_non_uniforms_iff, and_imp, mem_off_diag, sq],
    rintro U V hU hV -,
    exact_mod_cast nat.mul_le_mul (hP.card_part_le_average_add_one hU)
      (hP.card_part_le_average_add_one hV) },
  rw [nsmul_eq_mul, ←nat.cast_mul, ←nat.cast_add, ←nat.cast_pow, nat.cast_le, off_diag_card,
    nat.mul_sub_right_distrib, ←sq, ←mul_pow, mul_add_one],
  exact (nat.sub_le _ _).trans
    (nat.pow_le_pow_of_le_left (add_le_add_right (nat.mul_div_le _ _) _) _),
end

private lemma aux {i j : ℕ} (hj : 0 < j) : j * (j - 1) * (i / j + 1) ^ 2 < (i + j) ^ 2 :=
begin
  have : j * (j-1) < j^2,
  { rw sq,
    exact nat.mul_lt_mul_of_pos_left (nat.sub_lt hj zero_lt_one) hj },
  apply (nat.mul_lt_mul_of_pos_right this $ pow_pos nat.succ_pos' _).trans_le,
  rw ←mul_pow,
  exact nat.pow_le_pow_of_le_left (add_le_add_right (nat.mul_div_le i j) _) _,
end

lemma sum_irreg_pairs_le_of_uniform [nonempty α] (hε : 0 < ε) (hP : P.is_equipartition)
  (hG : P.is_uniform G ε) :
  (∑ i in P.non_uniforms G ε, i.1.card * i.2.card : ℝ) < ε * (card α + P.parts.card)^2 :=
begin
  refine (sum_le_card_nsmul (P.non_uniforms G ε) (λ i, (i.1.card * i.2.card : ℝ))
    ((card α / P.parts.card + 1)^2 : ℕ) _).trans_lt _,
  { simp only [prod.forall, finpartition.mk_mem_non_uniforms_iff, and_imp],
    rintro U V hU hV hUV -,
    rw [sq, ←nat.cast_mul, nat.cast_le],
    exact nat.mul_le_mul (hP.card_part_le_average_add_one hU)
      (hP.card_part_le_average_add_one hV) },
  rw nsmul_eq_mul,
  refine (mul_le_mul_of_nonneg_right hG $ nat.cast_nonneg _).trans_lt _,
  rw [mul_right_comm _ ε, mul_comm ε],
  apply mul_lt_mul_of_pos_right _ hε,
  norm_cast,
  exact aux (P.parts_nonempty $ univ_nonempty.ne_empty).card_pos,
end

lemma sum_irreg_pairs_le_of_uniform' [nonempty α] (hε : 0 < ε) (hP : P.is_equipartition)
  (hG : P.is_uniform G ε) :
  (((P.non_uniforms G ε).bUnion $ λ UV, UV.1 ×ˢ UV.2).card : ℝ) < 4 * ε * (card α)^2 :=
begin
  refine (non_uniform_killed_card.trans_lt $ sum_irreg_pairs_le_of_uniform hε hP hG).trans_le _,
  suffices : ε * ((card α) + P.parts.card)^2 ≤ ε * (card α + card α)^2,
  { exact this.trans_eq (by ring) },
  refine mul_le_mul_of_nonneg_left (pow_le_pow_of_le_left (by positivity) _ _) hε.le,
  exact add_le_add_left (nat.cast_le.2 P.card_parts_le_card) _,
end

lemma sum_sparse (hε : 0 ≤ ε) (hP : P.is_equipartition) :
  (((P.parts.off_diag.filter $ λ (UV : _ × _), ↑(G.edge_density UV.1 UV.2) < ε).bUnion $
            λ UV, (UV.1 ×ˢ UV.2).filter $ λ xy, G.adj xy.1 xy.2).card : ℝ) ≤
              4 * ε * (card α)^2 :=
begin
  refine (sparse_card hP hε).trans _,
  suffices : ε * ((card α) + P.parts.card)^2 ≤ ε * (card α + card α)^2,
  { exact this.trans_eq (by ring) },
  refine mul_le_mul_of_nonneg_left (pow_le_pow_of_le_left (by positivity) _ _) hε,
  exact add_le_add_left (nat.cast_le.2 P.card_parts_le_card) _,
end

lemma internal_killed_card' (hε : 0 < ε) (hP : P.is_equipartition) (hP' : 4 / ε ≤ P.parts.card) :
  ((P.parts.bUnion off_diag).card : ℝ) ≤ ε / 2 * (card α)^2 :=
begin
  casesI is_empty_or_nonempty α,
  { rw [subsingleton.elim (P.parts.bUnion off_diag) ∅, finset.card_empty, nat.cast_zero],
    positivity },
  have := P.parts_nonempty univ_nonempty.ne_empty,
  apply (internal_killed_card hP).trans,
  rw div_le_iff (by positivity : 0 < (P.parts.card : ℝ)),
  have : (card α : ℝ) + P.parts.card ≤ 2 * card α,
  { rw two_mul,
    exact add_le_add_left (nat.cast_le.2 P.card_parts_le_card) _ },
  refine (mul_le_mul_of_nonneg_left this $ by positivity).trans _,
  suffices : 1 ≤ ε/4 * P.parts.card,
  { rw [mul_left_comm, ←sq],
    convert mul_le_mul_of_nonneg_left this (mul_nonneg zero_le_two $ sq_nonneg (card α)) using 1;
    ring },
  rwa [←div_le_iff', one_div_div],
  positivity,
end

end simple_graph
