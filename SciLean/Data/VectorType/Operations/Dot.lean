import SciLean.Data.VectorType.Operations.ToVec
import SciLean.Analysis.SpecialFunctions.Inner
import SciLean.Analysis.SpecialFunctions.StarRingEnd

namespace SciLean

open VectorType ComplexConjugate

-- linear, continuous, differentiable
def_fun_prop dot in y [Lawful X] : IsContinuousLinearMap K by
  simp[vector_to_spec]
  fun_prop

def_fun_prop dot in y
    add_suffix _real
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    IsContinuousLinearMap R by
  simp[vector_to_spec]
  fun_prop

def_fun_prop dot in x
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    IsContinuousLinearMap R by
  simp[vector_to_spec]
  fun_prop

def_fun_prop dot in x y [Lawful X] : Continuous by
  simp[vector_to_spec]
  fun_prop

def_fun_prop dot in x y
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    Differentiable R by
  simp only [dot_spec, PiLp.inner_apply, WithLp.equiv_symm_pi_apply, RCLike.inner_apply]
  fun_prop

-- fderiv
abbrev_fun_trans dot in x y
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    fderiv R by
  simp[blas_to_module]
  autodiff


-- forward AD
abbrev_fun_trans dot in x y
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    fwdFDeriv R by
  simp[blas_to_module]
  autodiff


-- adjoint
abbrev_fun_trans dot in x
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    adjoint R by
  simp[blas_to_module]
  fun_trans

abbrev_fun_trans dot in y
    [Lawful X] :
    adjoint K by
  simp[blas_to_module]
  fun_trans

abbrev_fun_trans dot in y
    add_suffix _real
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    adjoint R by
  simp[blas_to_module]
  fun_trans

abbrev_data_synth dot in x
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    HasAdjoint R by
  simp[blas_to_module]
  data_synth => enter[3]; simp [vector_optimize]

abbrev_data_synth dot in x
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    HasAdjointUpdate R by
  simp[blas_to_module]
  data_synth => enter[3]; simp [vector_optimize]

abbrev_data_synth dot in y
    [Lawful X] :
    HasAdjoint K by
  simp[blas_to_module]
  data_synth => enter[3]; simp [vector_optimize]

abbrev_data_synth dot in y
    [Lawful X] :
    HasAdjointUpdate K by
  simp[blas_to_module]
  data_synth => enter[3]; simp [vector_optimize]

-- reverse AD
abbrev_fun_trans dot in x y
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    revFDeriv R by
  simp[blas_to_module]
  fun_trans
  simp[vector_optimize]; to_ssa; to_ssa; lsimp

abbrev_data_synth dot in x y
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    HasRevFDeriv R by
  simp[blas_to_module]
  data_synth => enter[3]; simp[vector_optimize]; to_ssa; to_ssa; lsimp

abbrev_data_synth dot in x y
    [ScalarSMul R K] [ScalarInner R K] [Lawful X] [RealOp X] :
    HasRevFDerivUpdate R by
  simp[blas_to_module]
  data_synth => enter[3]; simp[vector_optimize]; to_ssa; to_ssa; lsimp
