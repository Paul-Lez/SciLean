import SciLean.Data.MatrixType.Base
import SciLean.Analysis.Calculus.RevFDeriv
import SciLean.Analysis.Calculus.FwdFDeriv
-- import SciLean.Tactic.DataSynth.HasRevFDerivUpdate
import SciLean.Data.VectorType.Operations.Scal
import SciLean.Data.VectorType.Operations.Mul
import SciLean.Data.MatrixType.Operations.ToMatrix
import SciLean.Data.VectorType.Optimize
import SciLean.Data.MatrixType.Optimize
import SciLean.Lean.ToSSA

namespace SciLean


section Simps

variable
  {M : Type u_1} {m : outParam (Type u_2)}
  {n : outParam (Type u_3)} {_: IndexType m} {_ : IndexType n} {R : outParam (Type u_4)}
  {K : outParam (Type u_5)} {_ : RealScalar R} {_ : Scalar R K} {X : outParam (Type u_6)}
  {Y : outParam (Type u_7)} {_ : VectorType.Base X n K} {_ : VectorType.Base Y m K}
  [self : MatrixType.Base M X Y] [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y]


omit [VectorType.Lawful M] [VectorType.Lawful X] in
@[simp, simp_core]
theorem MatrixType.gemv_zero_alpha (b : K) (A : M) (x : X) (y : Y) :
    MatrixType.gemv 0 b A x y = b•y := by
  ext i; simp[vector_to_spec,matrix_to_spec]

omit [VectorType.Lawful X] in
@[simp, simp_core]
theorem MatrixType.gemv_zero_A (a b : K) (x : X) (y : Y) :
    MatrixType.gemv a b (0:M) x y = b•y := by
  ext i; simp[vector_to_spec,matrix_to_spec]

omit [VectorType.Lawful M] in
@[simp, simp_core]
theorem MatrixType.gemv_zero_x (a b : K) (A : M) (y : Y) :
    MatrixType.gemv a b A 0 y = b•y := by
  ext i; simp[vector_to_spec,matrix_to_spec]

end Simps


namespace GemvImpl
-- local macro does not work for some reason, so we use scoped macro
scoped macro "linearity_proof" : tactic =>
  `(tactic|
    (apply (IsContinuousLinearMap.injective_comp_iff VectorType.toVec (by fun_prop) (VectorType.Lawful.toVec_injective)).2
     simp +unfoldPartialApp [vector_to_spec, Matrix.mulVec, dotProduct]
     fun_prop))
end GemvImpl
open GemvImpl

-- All possible combinations or arguments that makes `gemv` a linear function
def_fun_prop MatrixType.gemv in alpha beta [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    IsContinuousLinearMap K by linearity_proof

def_fun_prop MatrixType.gemv in alpha y [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    IsContinuousLinearMap K by linearity_proof

def_fun_prop MatrixType.gemv in A beta [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    IsContinuousLinearMap K by linearity_proof

def_fun_prop MatrixType.gemv in A y [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    IsContinuousLinearMap K by linearity_proof

def_fun_prop MatrixType.gemv in x beta [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    IsContinuousLinearMap K by linearity_proof

def_fun_prop MatrixType.gemv in x y [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    IsContinuousLinearMap K by linearity_proof

-- Differentiable
def_fun_prop MatrixType.gemv in alpha beta A x y
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    Differentiable K by
  apply (Differentiable.injective_comp_iff VectorType.toVec (by fun_prop) (VectorType.Lawful.toVec_injective)).2
  simp +unfoldPartialApp [matrix_to_spec, vector_to_spec, Matrix.mulVec, dotProduct]
  fun_prop

-- fderiv
abbrev_fun_trans MatrixType.gemv in alpha beta A x y
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    fderiv K by
  equals (fun x => ContinuousLinearMap.mk' K (fun dx =>
    let' (a,b,A,x,y) := x
    let' (da,db,dA,dx,dy) := dx
    let dz₁ := MatrixType.gemv a b A dx dy
    let dz₂ := MatrixType.gemv da db A x y
    MatrixType.gemv a (1:K) dA x (dz₁+dz₂)) (by simp; fun_prop)) => sorry_proof

abbrev_fun_trans MatrixType.gemv in alpha beta A x y -- arg_subsets -- too slow :(
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    fwdFDeriv K by
  unfold fwdFDeriv
  autodiff; to_ssa

abbrev_data_synth MatrixType.gemv in A x y
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] (Axy₀) :
    (HasFDerivAt (𝕜:=K) · · Axy₀) by
  apply hasFDerivAt_from_fderiv
  case deriv => conv => rhs; fun_trans
  case diff => dsimp [autoParam]; fun_prop

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in A x
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] (Axy₀) :
    (HasFDerivAt (𝕜:=K) · · Axy₀) by
  apply hasFDerivAt_from_hasFDerivAt
  case deriv =>
    apply hasFDerivAt_comp
              (g:=fun Ax : M×X => (Ax.1,Ax.2,y))
              (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
              (hg:=by data_synth)
              (hf:=by data_synth)
  case simp => conv =>
    rhs; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in A y
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] (Axy₀) :
    (HasFDerivAt (𝕜:=K) · · Axy₀) by
  apply hasFDerivAt_from_hasFDerivAt
  case deriv =>
    apply hasFDerivAt_comp
              (g:=fun Ay : M×Y => (Ay.1,x,Ay.2))
              (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
              (hg:=by data_synth)
              (hf:=by data_synth)
  case simp => conv => rhs; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in x y
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] (Axy₀) :
    (HasFDerivAt (𝕜:=K) · · Axy₀) by
  apply hasFDerivAt_from_hasFDerivAt
  case deriv =>
    apply hasFDerivAt_comp
              (g:=fun xy : X×Y => (A,xy.1,xy.2))
              (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
              (hg:=by data_synth)
              (hf:=by data_synth)
  case simp => conv => rhs; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in A
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] (Axy₀) :
    (HasFDerivAt (𝕜:=K) · · Axy₀) by
  apply hasFDerivAt_from_hasFDerivAt
  case deriv =>
    apply hasFDerivAt_comp
              (g:=fun A : M => (A,x,y))
              (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
              (hg:=by data_synth)
              (hf:=by data_synth)
  case simp => conv => rhs; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in x
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] (Axy₀) :
    (HasFDerivAt (𝕜:=K) · · Axy₀) by
  apply hasFDerivAt_from_hasFDerivAt
  case deriv =>
    apply hasFDerivAt_comp
              (g:=fun x : X => (A,x,y))
              (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
              (hg:=by data_synth)
              (hf:=by data_synth)
  case simp => conv => rhs; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in y
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] (Axy₀) :
    (HasFDerivAt (𝕜:=K) · · Axy₀) by
  apply hasFDerivAt_from_hasFDerivAt
  case deriv =>
    apply hasFDerivAt_comp
              (g:=fun y : Y => (A,x,y))
              (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
              (hg:=by data_synth)
              (hf:=by data_synth)
  case simp => conv => rhs; lsimp

-- forward AD
abbrev_fun_trans MatrixType.gemv in A x y
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    fwdFDeriv K by
  unfold fwdFDeriv
  autodiff; to_ssa

open ComplexConjugate in
abbrev_fun_trans MatrixType.gemv in x y
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    adjoint K by
  equals (fun z => (MatrixType.gemvH (conj alpha) 0 A z 0, VectorType.scal (conj beta) z)) =>
    funext z
    apply AdjointSpace.ext_inner_left K
    intro x
    rw[← adjoint_ex _ (by fun_prop)]
    -- simp +unfoldPartialApp [vector_to_spec, matrix_to_spec, sum_pull,Inner.inner,
    --      Matrix.mulVec, dotProduct, Finset.mul_sum, Finset.sum_mul]
    sorry_proof

open ComplexConjugate in
abbrev_fun_trans MatrixType.gemv in A y
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    adjoint K by
  equals (fun z => (MatrixType.outerprodAdd (conj alpha) z x 0, VectorType.scal (conj beta) z)) =>
    funext z
    apply AdjointSpace.ext_inner_left K
    intro x
    rw[← adjoint_ex _ (by fun_prop)]
    -- simp +unfoldPartialApp [vector_to_spec, matrix_to_spec, sum_pull,Inner.inner,
    --      Matrix.mulVec, dotProduct, Finset.mul_sum, Finset.sum_mul]
    sorry_proof

abbrev_fun_trans MatrixType.gemv in alpha beta
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    adjoint K by
  equals (fun z => (VectorType.dot (MatrixType.gemv 1 0 A x 0) z, VectorType.dot y z)) =>
    funext z
    apply AdjointSpace.ext_inner_left K
    intro x
    rw[← adjoint_ex _ (by fun_prop)]
    -- simp +unfoldPartialApp [vector_to_spec, matrix_to_spec, sum_pull,Inner.inner,
    --      Matrix.mulVec, dotProduct, Finset.mul_sum, Finset.sum_mul]
    sorry_proof

open ComplexConjugate
abbrev_data_synth MatrixType.gemv in x y
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasAdjoint K by
  conv => enter[3]; assign (fun z => (MatrixType.gemvH (conj alpha) 0 A z 0,
                                      VectorType.scal (conj beta) z))
  sorry_proof

open ComplexConjugate
abbrev_data_synth MatrixType.gemv in x y
    [VectorType.Lawful M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasAdjointUpdate K by
  apply hasAdjointUpdate_from_hasAdjoint
  case adjoint => data_synth
  case simp => intros; conv => rhs; simp[Prod.add_def,vector_optimize]

open ComplexConjugate
abbrev_data_synth MatrixType.gemv in A y
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasAdjoint K by
  conv => enter[3]; assign (fun z : Y => (MatrixType.outerprodAdd (conj alpha) z x (0:M),
                                          VectorType.scal (conj beta) z))
  sorry_proof

abbrev_data_synth MatrixType.gemv in A y
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasAdjointUpdate K by
  apply hasAdjointUpdate_from_hasAdjoint
  case adjoint => data_synth
  case simp => intros; conv => rhs; simp[Prod.add_def,vector_optimize]


-- reverse AD
abbrev_fun_trans MatrixType.gemv in alpha beta A x y
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    revFDeriv K by
  unfold revFDeriv
  fun_trans

abbrev_fun_trans MatrixType.gemv in A x y
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    revFDeriv K by
  unfold revFDeriv
  fun_trans

abbrev_data_synth MatrixType.gemv in A x y
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasRevFDeriv K by
  apply hasRevFDeriv_from_hasFDerivAt_hasAdjoint
  case deriv => intros; dsimp; data_synth
  case adjoint => intros; dsimp; data_synth
  case simp => conv => rhs; lsimp

abbrev_data_synth MatrixType.gemv in A x y
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasRevFDerivUpdate K by
  apply hasRevFDerivUpdate_from_hasFDerivAt_hasAdjointUpdate
  case deriv => intros; dsimp; data_synth
  case adjoint => intros; dsimp; data_synth
  case simp => conv => rhs; simp[vector_optimize]; to_ssa; to_ssa; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in A x
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasRevFDeriv K by
  apply hasRevFDeriv_from_hasRevFDeriv
  case deriv =>
    apply HasRevFDeriv.comp_rule
            (g:=fun Ax : M×X => (Ax.1,Ax.2,y))
            (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
            (hg:=by data_synth)
            (hf:=by data_synth)
  case simp =>
    conv => rhs; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in A x
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasRevFDerivUpdate K by
  apply hasRevFDerivUpdate_from_hasRevFDerivUpdate
  case deriv =>
    apply HasRevFDerivUpdate.comp_rule
            (g:=fun Ax : M×X => (Ax.1,Ax.2,y))
            (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
            (hg:=by data_synth)
            (hf:=by data_synth)
  case simp =>
    conv => rhs; simp[vector_optimize]; to_ssa; to_ssa; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in x
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasRevFDeriv K by
  apply hasRevFDeriv_from_hasRevFDeriv
  case deriv =>
    apply HasRevFDeriv.comp_rule
            (g:=fun x : X => (A,x,y))
            (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
            (hg:=by data_synth)
            (hf:=by data_synth)
  case simp =>
    conv => rhs; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in x
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasRevFDerivUpdate K by
  apply hasRevFDerivUpdate_from_hasRevFDerivUpdate
  case deriv =>
    apply HasRevFDerivUpdate.comp_rule
            (g:=fun x : X => (A,x,y))
            (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
            (hg:=by data_synth)
            (hf:=by data_synth)
  case simp =>
    conv => rhs; simp[vector_optimize]; to_ssa; to_ssa; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in y
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasRevFDeriv K by
  apply hasRevFDeriv_from_hasRevFDeriv
  case deriv =>
    apply HasRevFDeriv.comp_rule
            (g:=fun y : Y => (A,x,y))
            (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
            (hg:=by data_synth)
            (hf:=by data_synth)
  case simp =>
    conv => rhs; lsimp

-- argument subset - todo: automate this!
abbrev_data_synth MatrixType.gemv in y
    [VectorType.Lawful M] [MatrixType.Dense M] [VectorType.Lawful X] [VectorType.Lawful Y] :
    HasRevFDerivUpdate K by
  apply hasRevFDerivUpdate_from_hasRevFDerivUpdate
  case deriv =>
    apply HasRevFDerivUpdate.comp_rule
            (g:=fun y : Y => (A,x,y))
            (f:=fun Axy : M×X×Y => MatrixType.gemv alpha beta Axy.1 Axy.2.1 Axy.2.2)
            (hg:=by data_synth)
            (hf:=by data_synth)
  case simp =>
    conv => rhs; simp[vector_optimize]; to_ssa; to_ssa; lsimp
