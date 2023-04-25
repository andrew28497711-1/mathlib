import category_theory.monoidal.internal.Module
import category_theory.monoidal.transport
import algebra.category.Module.monoidal
import ring_theory.tensor_product
universes v u w x
noncomputable theory
open category_theory
namespace Algebra
variables {R : Type u} [comm_ring R]
#exit
open_locale tensor_product

local attribute [ext] tensor_product.algebra_tensor_module.ext

/-- (implementation) tensor product of R-modules -/
def tensor_obj (M N : Algebra R) : Algebra R := Algebra.of R (M ⊗[R] N)
--def tensor_obj_iso (M N : Algebra R) : tensor_obj R M N ≅ Algebra.of R (Al)
/-- (implementation) tensor product of morphisms R-modules -/
def tensor_hom {M N M' N' : Algebra R} (f : M ⟶ N) (g : M' ⟶ N') :
  tensor_obj M M' ⟶ tensor_obj N N' :=
algebra.tensor_product.map f g

lemma tensor_id (M N : Algebra R) : tensor_hom (𝟙 M) (𝟙 N) = 𝟙 (Algebra.of R (M ⊗ N)) :=
by { ext1, refl }

lemma tensor_comp {X₁ Y₁ Z₁ X₂ Y₂ Z₂ : Algebra R}
  (f₁ : X₁ ⟶ Y₁) (f₂ : X₂ ⟶ Y₂) (g₁ : Y₁ ⟶ Z₁) (g₂ : Y₂ ⟶ Z₂) :
    tensor_hom (f₁ ≫ g₁) (f₂ ≫ g₂) = tensor_hom f₁ f₂ ≫ tensor_hom g₁ g₂ :=
by { ext1, refl }
#check Algebra.of_self_iso

def tensor_of_left (M : Algebra.{v} R) (N : Algebra.{w} R) (K : Algebra.{x} R) :
  tensor_obj (tensor_obj M N) K ≅ Algebra.of R (M ⊗[R] N ⊗[R] K) :=
iso.refl _

def tensor_of_right (M : Algebra.{v} R) (N : Algebra.{w} R) (K : Algebra.{x} R) :
  tensor_obj M (tensor_obj N K) ≅ Algebra.of R (M ⊗[R] (N ⊗[R] K)) :=
iso.refl _

#check (algebra.tensor_product.assoc R _ _ _).to_Algebra_iso
/-- (implementation) the associator for R-modules -/
lemma associator (M : Algebra.{v} R) (N : Algebra.{w} R) (K : Algebra.{x} R) :
  tensor_obj (tensor_obj M N) K ≅ tensor_obj M (tensor_obj N K) :=
(tensor_of_left M N K) ≪≫ (algebra.tensor_product.assoc R M N K).to_Algebra_iso
  ≪≫ (tensor_of_right M N K).symm

#exit
  --Algebra.of R ((Algebra.of R (M ⊗[R] N)) ⊗[R] K) ≅ Algebra.of R (M ⊗[R] (Algebra.of R (N ⊗[R] K))) :=
sorry--(algebra.tensor_product.assoc R M N K).to_Algebra_iso

section

/-! The `associator_naturality` and `pentagon` lemmas below are very slow to elaborate.

We give them some help by expressing the lemmas first non-categorically, then using
`convert _aux using 1` to have the elaborator work as little as possible. -/

open tensor_product (assoc map)
#exit
private lemma associator_naturality_aux
  {X₁ X₂ X₃ : Type*}
  [add_comm_monoid X₁] [add_comm_monoid X₂] [add_comm_monoid X₃]
  [module R X₁] [module R X₂] [module R X₃]
  {Y₁ Y₂ Y₃ : Type*}
  [add_comm_monoid Y₁] [add_comm_monoid Y₂] [add_comm_monoid Y₃]
  [module R Y₁] [module R Y₂] [module R Y₃]
  (f₁ : X₁ →ₗ[R] Y₁) (f₂ : X₂ →ₗ[R] Y₂) (f₃ : X₃ →ₗ[R] Y₃) :
  (↑(assoc R Y₁ Y₂ Y₃) ∘ₗ (map (map f₁ f₂) f₃)) = ((map f₁ (map f₂ f₃)) ∘ₗ ↑(assoc R X₁ X₂ X₃)) :=
begin
  apply tensor_product.ext_threefold,
  intros x y z,
  refl
end

variables (R)

private lemma pentagon_aux
  (W X Y Z : Type*)
  [add_comm_monoid W] [add_comm_monoid X] [add_comm_monoid Y] [add_comm_monoid Z]
  [module R W] [module R X] [module R Y] [module R Z] :
  ((map (1 : W →ₗ[R] W) (assoc R X Y Z).to_alg_hom).comp (assoc R W (X ⊗[R] Y) Z).to_alg_hom)
    .comp (map ↑(assoc R W X Y) (1 : Z →ₗ[R] Z)) =
  (assoc R W X (Y ⊗[R] Z)).to_alg_hom.comp (assoc R (W ⊗[R] X) Y Z).to_alg_hom :=
begin
  apply tensor_product.ext_fourfold,
  intros w x y z,
  refl
end

end

lemma associator_naturality {X₁ X₂ X₃ Y₁ Y₂ Y₃ : Algebra R}
  (f₁ : X₁ ⟶ Y₁) (f₂ : X₂ ⟶ Y₂) (f₃ : X₃ ⟶ Y₃) :
    tensor_hom (tensor_hom f₁ f₂) f₃ ≫ (associator Y₁ Y₂ Y₃).hom =
    (associator X₁ X₂ X₃).hom ≫ tensor_hom f₁ (tensor_hom f₂ f₃) :=
by convert associator_naturality_aux f₁ f₂ f₃ using 1

lemma pentagon (W X Y Z : Algebra R) :
  tensor_hom (associator W X Y).hom (𝟙 Z) ≫ (associator W (tensor_obj X Y) Z).hom
  ≫ tensor_hom (𝟙 W) (associator X Y Z).hom =
    (associator (tensor_obj W X) Y Z).hom ≫ (associator W X (tensor_obj Y Z)).hom :=
by convert pentagon_aux R W X Y Z using 1

/-- (implementation) the left unitor for R-modules -/
def left_unitor (M : Algebra.{u} R) : Algebra.of R (R ⊗[R] M) ≅ M :=
(alg_equiv.to_Algebra_iso (tensor_product.lid R M) : of R (R ⊗ M) ≅ of R M).trans (of_self_iso M)

lemma left_unitor_naturality {M N : Algebra R} (f : M ⟶ N) :
  tensor_hom (𝟙 (Algebra.of R R)) f ≫ (left_unitor N).hom = (left_unitor M).hom ≫ f :=
begin
  ext x y, dsimp,
  erw [tensor_product.lid_tmul, tensor_product.lid_tmul],
  rw alg_hom.map_smul,
  refl,
end

/-- (implementation) the right unitor for R-modules -/
def right_unitor (M : Algebra.{u} R) : Algebra.of R (M ⊗[R] R) ≅ M :=
(alg_equiv.to_Algebra_iso (tensor_product.rid R M) : of R (M ⊗ R) ≅ of R M).trans (of_self_iso M)

lemma right_unitor_naturality {M N : Algebra R} (f : M ⟶ N) :
  tensor_hom f (𝟙 (Algebra.of R R)) ≫ (right_unitor N).hom = (right_unitor M).hom ≫ f :=
begin
  ext x y, dsimp,
  erw [tensor_product.rid_tmul, tensor_product.rid_tmul],
  rw alg_hom.map_smul,
  refl,
end

lemma triangle (M N : Algebra.{u} R) :
  (associator M (Algebra.of R R) N).hom ≫ tensor_hom (𝟙 M) (left_unitor N).hom =
    tensor_hom (right_unitor M).hom (𝟙 N) :=
begin
  apply tensor_product.ext_threefold,
  intros x y z,
  change R at y,
  dsimp [tensor_hom, associator],
  erw [tensor_product.lid_tmul, tensor_product.rid_tmul],
  exact (tensor_product.smul_tmul _ _ _).symm
end

end monoidal_category

open monoidal_category

instance monoidal_category : monoidal_category (Algebra.{u} R) :=
{ -- data
  tensor_obj   := tensor_obj,
  tensor_hom   := @tensor_hom _ _,
  tensor_unit  := Algebra.of R R,
  associator   := associator,
  left_unitor  := left_unitor,
  right_unitor := right_unitor,
  -- properties
  tensor_id'               := λ M N, tensor_id M N,
  tensor_comp'             := λ M N K M' N' K' f g h, tensor_comp f g h,
  associator_naturality'   := λ M N K M' N' K' f g h, associator_naturality f g h,
  left_unitor_naturality'  := λ M N f, left_unitor_naturality f,
  right_unitor_naturality' := λ M N f, right_unitor_naturality f,
  pentagon'                := λ M N K L, pentagon M N K L,
  triangle'                := λ M N, triangle M N, }

/-- Remind ourselves that the monoidal unit, being just `R`, is still a commutative ring. -/
instance : comm_ring ((𝟙_ (Algebra.{u} R) : Algebra.{u} R) : Type u) :=
(by apply_instance : comm_ring R)

namespace monoidal_category

@[simp]
lemma hom_apply {K L M N : Algebra.{u} R} (f : K ⟶ L) (g : M ⟶ N) (k : K) (m : M) :
  (f ⊗ g) (k ⊗ₜ m) = f k ⊗ₜ g m := rfl

@[simp]
lemma left_unitor_hom_apply {M : Algebra.{u} R} (r : R) (m : M) :
  ((λ_ M).hom : 𝟙_ (Algebra R) ⊗ M ⟶ M) (r ⊗ₜ[R] m) = r • m :=
tensor_product.lid_tmul m r

@[simp]
lemma left_unitor_inv_apply {M : Algebra.{u} R} (m : M) :
  ((λ_ M).inv : M ⟶ 𝟙_ (Algebra.{u} R) ⊗ M) m = 1 ⊗ₜ[R] m :=
tensor_product.lid_symm_apply m

@[simp]
lemma right_unitor_hom_apply {M : Algebra.{u} R} (m : M) (r : R) :
  ((ρ_ M).hom : M ⊗ 𝟙_ (Algebra R) ⟶ M) (m ⊗ₜ r) = r • m :=
tensor_product.rid_tmul m r

@[simp]
lemma right_unitor_inv_apply {M : Algebra.{u} R} (m : M) :
  ((ρ_ M).inv : M ⟶ M ⊗ 𝟙_ (Algebra.{u} R)) m = m ⊗ₜ[R] 1 :=
tensor_product.rid_symm_apply m

@[simp]
lemma associator_hom_apply {M N K : Algebra.{u} R} (m : M) (n : N) (k : K) :
  ((α_ M N K).hom : (M ⊗ N) ⊗ K ⟶ M ⊗ (N ⊗ K)) ((m ⊗ₜ n) ⊗ₜ k) = (m ⊗ₜ (n ⊗ₜ k)) := rfl

@[simp]
lemma associator_inv_apply {M N K : Algebra.{u} R} (m : M) (n : N) (k : K) :
  ((α_ M N K).inv : M ⊗ (N ⊗ K) ⟶ (M ⊗ N) ⊗ K) (m ⊗ₜ (n ⊗ₜ k)) = ((m ⊗ₜ n) ⊗ₜ k) := rfl

end monoidal_category

/-- (implementation) the braiding for R-modules -/
def braiding (M N : Algebra R) : tensor_obj M N ≅ tensor_obj N M :=
alg_equiv.to_Algebra_iso (tensor_product.comm R M N)

@[simp] lemma braiding_naturality {X₁ X₂ Y₁ Y₂ : Algebra.{u} R} (f : X₁ ⟶ Y₁) (g : X₂ ⟶ Y₂) :
  (f ⊗ g) ≫ (Y₁.braiding Y₂).hom =
    (X₁.braiding X₂).hom ≫ (g ⊗ f) :=
begin
  apply tensor_product.ext',
  intros x y,
  refl
end

@[simp] lemma hexagon_forward (X Y Z : Algebra.{u} R) :
  (α_ X Y Z).hom ≫ (braiding X _).hom ≫ (α_ Y Z X).hom =
  ((braiding X Y).hom ⊗ 𝟙 Z) ≫ (α_ Y X Z).hom ≫ (𝟙 Y ⊗ (braiding X Z).hom) :=
begin
  apply tensor_product.ext_threefold,
  intros x y z,
  refl,
end

@[simp] lemma hexagon_reverse (X Y Z : Algebra.{u} R) :
  (α_ X Y Z).inv ≫ (braiding _ Z).hom ≫ (α_ Z X Y).inv =
  (𝟙 X ⊗ (Y.braiding Z).hom) ≫ (α_ X Z Y).inv ≫ ((X.braiding Z).hom ⊗ 𝟙 Y) :=
begin
  apply (cancel_epi (α_ X Y Z).hom).1,
  apply tensor_product.ext_threefold,
  intros x y z,
  refl,
end

local attribute [ext] tensor_product.ext

/-- The symmetric monoidal structure on `Algebra R`. -/
instance symmetric_category : symmetric_category (Algebra.{u} R) :=
{ braiding := braiding,
  braiding_naturality' := λ X₁ X₂ Y₁ Y₂ f g, braiding_naturality f g,
  hexagon_forward' := hexagon_forward,
  hexagon_reverse' := hexagon_reverse, }

namespace monoidal_category

@[simp] lemma braiding_hom_apply {M N : Algebra.{u} R} (m : M) (n : N) :
  ((β_ M N).hom : M ⊗ N ⟶ N ⊗ M) (m ⊗ₜ n) = n ⊗ₜ m := rfl

@[simp] lemma braiding_inv_apply {M N : Algebra.{u} R} (m : M) (n : N) :
  ((β_ M N).inv : N ⊗ M ⟶ M ⊗ N) (n ⊗ₜ m) = m ⊗ₜ n := rfl

end monoidal_category

open opposite

instance : monoidal_preadditive (Algebra.{u} R) :=
by refine ⟨_, _, _, _⟩; dsimp only [auto_param]; intros;
  refine tensor_product.ext (alg_hom.ext $ λ x, alg_hom.ext $ λ y, _);
  simp only [alg_hom.compr₂_apply, tensor_product.mk_apply, monoidal_category.hom_apply,
    alg_hom.zero_apply, tensor_product.tmul_zero, tensor_product.zero_tmul,
    alg_hom.add_apply, tensor_product.tmul_add, tensor_product.add_tmul]

instance : monoidal_linear R (Algebra.{u} R) :=
by refine ⟨_, _⟩; dsimp only [auto_param]; intros;
  refine tensor_product.ext (alg_hom.ext $ λ x, alg_hom.ext $ λ y, _);
  simp only [alg_hom.compr₂_apply, tensor_product.mk_apply, monoidal_category.hom_apply,
    alg_hom.smul_apply, tensor_product.tmul_smul, tensor_product.smul_tmul]

/--
Auxiliary definition for the `monoidal_closed` instance on `Algebra R`.
(This is only a separate definition in order to speed up typechecking. )
-/
@[simps]
def monoidal_closed_hom_equiv (M N P : Algebra.{u} R) :
  ((monoidal_category.tensor_left M).obj N ⟶ P) ≃
    (N ⟶ ((linear_coyoneda R (Algebra R)).obj (op M)).obj P) :=
{ to_fun := λ f, alg_hom.compr₂ (tensor_product.mk R N M) ((β_ N M).hom ≫ f),
  inv_fun := λ f, (β_ M N).hom ≫ tensor_product.lift f,
  left_inv := λ f, begin ext m n,
    simp only [tensor_product.mk_apply, tensor_product.lift.tmul, alg_hom.compr₂_apply,
      function.comp_app, coe_comp, monoidal_category.braiding_hom_apply],
  end,
  right_inv := λ f, begin ext m n,
    simp only [tensor_product.mk_apply, tensor_product.lift.tmul, alg_hom.compr₂_apply,
      symmetric_category.symmetry_assoc],
  end, }

instance : monoidal_closed (Algebra.{u} R) :=
{ closed' := λ M,
  { is_adj :=
    { right := (linear_coyoneda R (Algebra.{u} R)).obj (op M),
      adj := adjunction.mk_of_hom_equiv
      { hom_equiv := λ N P, monoidal_closed_hom_equiv M N P, } } } }

-- I can't seem to express the function coercion here without writing `@coe_fn`.
@[simp]
lemma monoidal_closed_curry {M N P : Algebra.{u} R} (f : M ⊗ N ⟶ P) (x : M) (y : N) :
  @coe_fn _ _ alg_hom.has_coe_to_fun ((monoidal_closed.curry f : N →ₗ[R] (M →ₗ[R] P)) y) x =
    f (x ⊗ₜ[R] y) :=
rfl

@[simp]
lemma monoidal_closed_uncurry {M N P : Algebra.{u} R}
  (f : N ⟶ (M ⟶[Algebra.{u} R] P)) (x : M) (y : N) :
  monoidal_closed.uncurry f (x ⊗ₜ[R] y) = (@coe_fn _ _ alg_hom.has_coe_to_fun (f y)) x :=
by { simp only [monoidal_closed.uncurry, ihom.adjunction, is_left_adjoint.adj], simp, }

end Algebra


end Algebra
