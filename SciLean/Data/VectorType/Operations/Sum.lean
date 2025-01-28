import SciLean.Data.VectorType.Operations.ToVec
import SciLean.Data.VectorType.Optimize
import SciLean.Data.VectorType.BaseSimps
import SciLean.Analysis.SpecialFunctions.StarRingEnd

namespace SciLean

open VectorType
section Simps

variable
  {R K} {_ : RealScalar R} {_ : Scalar R K}
  {n} {_ : IndexType n}
  {X} [VectorType.Base X n K]

-- linearity
def_fun_prop VectorType.sum in x with_transitive [VectorType.Lawful X] : IsContinuousLinearMap K by
  simp[vector_to_spec]
  fun_prop

#generate_linear_map_simps VectorType.Base.sum.arg_x.IsLinearMap_rule

-- fderiv
abbrev_fun_trans VectorType.sum in x [VectorType.Lawful X] : fderiv K by autodiff
abbrev_data_synth VectorType.sum in x [VectorType.Lawful X] (x₀) : (HasFDerivAt (𝕜:=K) · · x₀) by
  exact hasFDerivAt_from_isContinuousLinearMap

-- forward AD
abbrev_fun_trans VectorType.sum in x [VectorType.Lawful X] : fwdFDeriv K by autodiff

-- adjoint
open ComplexConjugate Classical in

open Classical in
abbrev_fun_trans VectorType.sum in x [Lawful X] [Dense X] : adjoint K by
  enter[y]; simp[vector_to_spec]
  fun_trans
  rw[← fromVec_toVec (Finset.sum _ _)]; simp[vector_to_spec]; simp [vector_from_spec]

abbrev_data_synth VectorType.sum in x [Lawful X] [Dense X] :
    HasAdjoint K by
  conv => enter[2,x]; simp[vector_to_spec]
  data_synth => enter[3]; simp[vector_from_spec,rsimp]

abbrev_data_synth VectorType.sum in x [Lawful X] [Dense X] :
    HasAdjointUpdate K by
  apply hasAdjointUpdate_from_hasAdjoint
  case adjoint => data_synth
  case simp => intros; simp [vector_optimize]; rfl


-- reverse AD
abbrev_fun_trans VectorType.sum in x [VectorType.Lawful X] [VectorType.Dense X] : revFDeriv K by
  unfold revFDeriv
  fun_trans

abbrev_data_synth VectorType.sum in x [VectorType.Lawful X] [VectorType.Dense X] :
    HasRevFDeriv K by
  apply hasRevFDeriv_from_hasFDerivAt_hasAdjoint
  case deriv => intros; data_synth
  case adjoint => intros; dsimp; data_synth
  case simp => rfl

abbrev_data_synth VectorType.sum in x [VectorType.Lawful X] [VectorType.Dense X] :
    HasRevFDerivUpdate K by
  apply hasRevFDerivUpdate_from_hasFDerivAt_hasAdjointUpdate
  case deriv => intros; data_synth
  case adjoint => intros; dsimp; data_synth
  case simp => rfl
