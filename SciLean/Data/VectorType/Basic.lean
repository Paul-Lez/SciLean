import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Normed.Lp.PiLp
import Mathlib.Analysis.Normed.Lp.WithLp
import Mathlib.Data.Matrix.Basic

import SciLean.Analysis.AdjointSpace.Basic
import SciLean.Analysis.Scalar
import SciLean.Data.IndexType

import SciLean.Data.VectorType.Init

namespace SciLean

open InnerProductSpace

/-- `VectorType X n K` says that `X` behaves like a vector indexed by `n` and with values in `K`.

Providing an instance of `VectorType X n K` will automatically provide the following instances
  - `Add X`, `Sub X`, `Neg X`, `SMul K X`, `Zero X`, `Inner K X`, ...
  - `NormedAddCommGroup X` with l₂ norm
  - `InnerProductSpace K X`
  - `AdjointSpace K X`
  - `FiniteDimensional K X`

This class is designed to provide Basic Linear Algebra Subprograms(BLAS) which allows us to define
vector space structure on `X` that is computationally efficient.
 -/
class VectorType (X : Type*) (n : outParam (Type*)) {R : outParam (Type*)} (K : outParam (Type*))
        [Scalar R K] [Fintype n] where
  equiv : X ≃ (n → K) -- maybe EuclideanSpace K n?

  const (k : K) : X

  scal (alpha : K) (x : X) : X

  asum (x : X) : R
  nrm2 (x : X) : R
  iamax (x : X) : n
  dot (x y : X) : K

  axpy (alpha : K) (x y : X) : X
  axpby (alpha beta : K) (x y : X) : X := axpy alpha x (scal beta y)

  const_spec (k : K) : equiv (const k) = fun _ => k

  scal_spec (alpha : K) (x : X) :
    equiv (scal alpha x) = alpha • equiv x

  asum_spec (x : X) : nrm2 x = Scalar.ofReal (K:=K) ‖(WithLp.equiv 1 (n → K)).symm (equiv x)‖
  nrm2_spec (x : X) : nrm2 x = Scalar.ofReal (K:=K) ‖(WithLp.equiv 2 (n → K)).symm (equiv x)‖
  iamax_spec (x : X) : Scalar.abs (equiv x (iamax x)) = Scalar.ofReal (K:=K) ‖equiv x‖

  dot_spec (x y : X) :
    (dot x y) =
    let x' := (WithLp.equiv 2 (n → K)).symm (equiv x)
    let y' := (WithLp.equiv 2 (n → K)).symm (equiv y)
    (⟪x',y'⟫_K)

  axpy_spec (alpha : K) (x y : X) :
    equiv (axpy alpha x y) = alpha • equiv x + equiv y

  axpby_spec (alpha beta : K) (x y : X) :
    equiv (axpby alpha beta x y) = alpha • equiv x + beta • equiv y


namespace VectorType

attribute [vector_to_spec]
  const_spec
  scal_spec
  asum_spec
  nrm2_spec
  iamax_spec
  dot_spec
  axpy_spec
  axpby_spec

attribute [vector_from_spec ←]
  const_spec
  scal_spec
  asum_spec
  nrm2_spec
  iamax_spec
  dot_spec
  axpy_spec
  axpby_spec

section BasicOperations

variable
  {X : Type*} {n R K :  Type*}
  [Scalar R K] [Fintype n] [VectorType X n K]

open VectorType

instance : Add X := ⟨fun x y => axpy 1 x y⟩
instance : Sub X := ⟨fun x y => axpby 1 (-1) x y⟩
instance : Neg X := ⟨fun x => scal (-1) x⟩
instance : SMul K X := ⟨fun s x => scal s x⟩

instance : Zero X := ⟨const 0⟩

instance : Inner K X := ⟨fun x y => dot x y⟩
instance : Norm X := ⟨fun x => Scalar.toReal (K:=K) (nrm2 x)⟩
instance : Dist X := ⟨fun x y => ‖x-y‖⟩

@[vector_to_spec, vector_from_spec ←]
theorem add_spec (x y : X) : equiv (x + y) = equiv x + equiv y := by
  simp only [HAdd.hAdd, Add.add, axpy_spec, Pi.smul_apply, smul_eq_mul, one_mul]

@[vector_to_spec, vector_from_spec ←]
theorem sub_spec (x y : X) : equiv (x - y) = equiv x - equiv y := by
  conv => lhs; simp only [HSub.hSub,Sub.sub,axpby_spec]
  simp only [one_smul, neg_smul, sub_eq_add_neg]

@[vector_to_spec, vector_from_spec ←]
theorem neg_spec (x : X) : equiv (- x) = - equiv x := by
  simp only [Neg.neg, scal_spec, neg_smul, Pi.smul_apply, smul_eq_mul, one_mul]

@[vector_to_spec, vector_from_spec ←]
theorem smul_spec (k : K) (x : X) : equiv (k • x) = k • equiv x := by
  conv => lhs; simp only [HSMul.hSMul, SMul.smul,scal_spec]
  funext i; simp only [Pi.smul_apply, smul_eq_mul]

@[vector_to_spec, vector_from_spec ←]
theorem zero_spec : equiv (0 : X) = 0 := by
  conv => lhs; simp only [Zero.zero,OfNat.ofNat,const_spec]
  rfl

@[vector_to_spec, vector_from_spec ←]
theorem inner_spec (x y : X) :
    ⟪x,y⟫_K
    =
    ⟪(WithLp.equiv 2 (n → K)).symm (equiv x), (WithLp.equiv 2 (n → K)).symm (equiv y)⟫_K := by
  simp only [inner, dot_spec, WithLp.equiv_symm_pi_apply]

@[vector_to_spec, vector_from_spec ←]
theorem norm_spec (x : X) :
    ‖x‖
    =
    ‖(WithLp.equiv 2 (n → K)).symm (equiv x)‖ := by
  conv => lhs; simp only [norm]; simp only [nrm2_spec]
  simp only [Scalar.toReal_ofReal]

@[vector_to_spec, vector_from_spec ←]
theorem dist_spec (x y : X) :
    dist x y
    =
    dist ((WithLp.equiv 2 (n → K)).symm (equiv x)) ((WithLp.equiv 2 (n → K)).symm (equiv y)) := by
  conv => lhs; simp [Dist.dist,vector_to_spec]
  conv => rhs; rw[NormedAddCommGroup.dist_eq]

end BasicOperations


section AlgebraicInstances

variable
  {X : Type*} {n R K :  Type*}
  [Scalar R K] [Fintype n] [VectorType X n K]

open VectorType

instance : AddCommGroup X where
  add_assoc := by intros; apply equiv.injective; simp only [add_spec, add_assoc]
  zero_add := by intros; apply equiv.injective; simp only [add_spec, zero_spec, zero_add]
  add_zero := by intros; apply equiv.injective; simp only [add_spec, zero_spec, add_zero]
  neg_add_cancel := by intros; apply equiv.injective; simp only [add_spec, neg_spec, neg_add_cancel, zero_spec]
  add_comm := by intros; apply equiv.injective; simp only [add_spec, add_comm]
  sub_eq_add_neg := by intros; apply equiv.injective; simp only [sub_spec, sub_eq_add_neg, add_spec, neg_spec]
  nsmul n x := scal (n:K) x
  nsmul_zero := by intros; apply equiv.injective; simp only [CharP.cast_eq_zero, scal_spec, zero_smul, zero_spec]
  nsmul_succ := by intros; apply equiv.injective; simp only [Nat.cast_add, Nat.cast_one, scal_spec, add_smul, one_smul, add_spec]
  zsmul n x := scal (n:K) x
  zsmul_zero' := by intros; apply equiv.injective; simp[scal_spec,vector_to_spec]
  zsmul_neg' := by intros; apply equiv.injective; simp[zsmul_neg',scal_spec,add_smul,vector_to_spec]
  zsmul_succ' := by intros; apply equiv.injective; simp[scal_spec,add_smul,vector_to_spec]

instance : PseudoMetricSpace X where
  dist_self := by intros; simp[dist_spec]
  dist_comm := by intros; simp[dist_spec,dist_comm]
  dist_triangle := by intros; simp[dist_spec,dist_triangle]

instance : NormedAddCommGroup X where
  dist_eq := by intros; rfl
  eq_of_dist_eq_zero := by
    intro x y h;
    apply equiv.injective;
    apply (WithLp.equiv 2 (n → K)).symm.injective
    simp only [dist_spec] at h
    exact (eq_of_dist_eq_zero h)

instance : NormedSpace K X where
  one_smul := by intros; apply equiv.injective; simp[vector_to_spec]
  mul_smul := by intros; apply equiv.injective; simp[mul_smul,vector_to_spec]
  smul_zero := by intros; apply equiv.injective; simp[vector_to_spec]
  smul_add := by intros; apply equiv.injective; simp[vector_to_spec]
  add_smul := by intros; apply equiv.injective; simp[add_smul,vector_to_spec]
  zero_smul := by intros; apply equiv.injective; simp[vector_to_spec]
  norm_smul_le := by
    simp only [norm_spec]
    simp [norm_smul_le,vector_to_spec]


instance : InnerProductSpace K X where
  norm_sq_eq_inner := by
    simp only [inner_spec,norm_spec]
    intro x
    apply norm_sq_eq_inner
  conj_symm := by
    simp only [inner_spec]
    intro x y;
    apply conj_symm
  add_left := by
    intros; simp only [inner_spec,add_spec, WithLp.equiv_symm_add,add_left]
  smul_left := by
    intros; simp only [inner_spec,smul_spec, WithLp.equiv_symm_smul,smul_left]


instance : AdjointSpace K X where
  inner_top_equiv_norm := by
    use 1; use 1
    simp only [inner_spec,norm_spec]
    constructor
    · simp only [gt_iff_lt, zero_lt_one]
    constructor
    · simp only [gt_iff_lt, zero_lt_one]
    · intro x
      constructor
      · rw[norm_sq_eq_inner (𝕜:=K)]; simp only [one_smul,le_refl]
      · rw[norm_sq_eq_inner (𝕜:=K)]; simp only [one_smul,le_refl]
  conj_symm := by
    simp only [inner_spec]
    intro x y;
    apply conj_symm
  add_left := by
    intros; simp only [inner_spec,add_spec, WithLp.equiv_symm_add,add_left]
  smul_left := by
    intros; simp only [inner_spec,smul_spec, WithLp.equiv_symm_smul,smul_left]


/-- Linear equivalence between vector type `X` and `n → K` -/
def equivₗ : X ≃ₗ[K] (n → K) :=
  LinearEquiv.mk ⟨⟨equiv,by simp[vector_to_spec]⟩,by simp[vector_to_spec]⟩
    equiv.symm (equiv.left_inv) (equiv.right_inv)


/-- Continuous linear equivalence between vector type `X` and `n → K` -/
def equivL : X ≃L[K] (n → K) := ContinuousLinearEquiv.mk equivₗ (by sorry) (by sorry)


instance : FiniteDimensional K X :=
   FiniteDimensional.of_injective (V₂:=n→K) (equivₗ (X:=X) (n:=n) (K:=K)).1
  (equivₗ.left_inv.injective)


variable (X)
noncomputable
def basis : Basis n K X := Basis.ofEquivFun (ι:=n) (R:=K) (M:=X) equivₗ
variable {X}


@[simp, simp_core]
theorem finrank_eq_index_card : Module.finrank K X = Fintype.card n :=
  Module.finrank_eq_card_basis (basis X)


end AlgebraicInstances
