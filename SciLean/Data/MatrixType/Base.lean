import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Matrix.RowCol
import SciLean.Data.IndexType

import SciLean.Analysis.Scalar
import SciLean.Analysis.AdjointSpace.Basic
import SciLean.Analysis.Convenient.SemiInnerProductSpace
import SciLean.Analysis.Matrix

import SciLean.Data.VectorType.Base
import SciLean.Data.MatrixType.Init

namespace SciLean

open Matrix VectorType

/-- `MatrixType M X Y` says that `M` is a matrix transforming vectors of type `X` to vectors
of type `Y`.

This class provides functionality implementable using BLAS. -/
class MatrixType.Base
      (M : Type*)
      {m n : outParam (Type*)} [IndexType m] [IndexType n]
      {R K : outParam (Type*)} [RealScalar R] [Scalar R K]
      (X Y : outParam (Type*)) [VectorType.Base X n K] [VectorType.Base Y m K]
  extends
    VectorType.Base M (m×n) K
  where

  toMatrix (A: M) : Matrix m n K

  toVec_eq_toMatrix (A : M) : toVec A = fun (i,j) => toMatrix A i j

  /-    Row and column operations    -/
  /- Setting rows and columns is found in `MatrixType.Dense` -/

  -- TODO: This should return `SubMatrix m n (point i) id`
  /-- Get row of matrix -/
  row (A : M) (i : m) : X
  row_spec (A : M) (i : m) :
    VectorType.toVec (row A i)
    =
    let A := toMatrix A
    fun j => A i j

  /-- Sum rows of a matrix. -/
  sumRows (A : M) : Y
  sumRows_spec (A : M):
    VectorType.toVec (sumRows A)
    =
    let A := toMatrix A
    fun i => ∑ j, A i j

  -- TODO: This should return `SubMatrix m n id (point j)`
  /-- Get column of matrix -/
  col (A : M) (j : n) : Y
  col_spec (A : M) (j : n) :
    VectorType.toVec (col A j)
    =
    let A := (toMatrix A)
    fun i => A i j

  /-- Sum columns of a matrix -/
  sumCols (A : M) : X
  sumCols_spec (A : M):
    VectorType.toVec (sumCols A)
    =
    let A := toMatrix A
    fun j => ∑ i, A i j


  /- Level 2 like BLAS operations -/

  /-- Matrix vector multiplication.

  Implementable using BLAS `gemv`. -/
  gemv (alpha beta : K) (A : M) (x : X) (y : Y) : Y

  gemv_spec (alpha beta : K) (A : M) (x : X) (y : Y) :
    VectorType.toVec (gemv alpha beta A x y)
    =
    let A := toMatrix A
    let x := VectorType.toVec x
    let y := VectorType.toVec y
    alpha • A *ᵥ x + beta • y

  /-- Transpose matrix vector multiplication.

  Implementable using BLAS `gemv`. -/
  gemvT (alpha beta : K) (A : M) (y : Y) (x : X) : X

  gemvT_spec (alpha beta : K) (A : M) (y : Y) (x : X) :
    VectorType.toVec (gemvT alpha beta A y x)
    =
    let A := toMatrix A
    let x := VectorType.toVec x
    let y := VectorType.toVec y
    alpha • Aᵀ *ᵥ y + beta • x


  /-- Conjugate transpose matrix vector multiplication.

  Implementable using BLAS `gemv`. -/
  gemvH (alpha beta : K) (A : M) (y : Y) (x : X) : X

  gemvH_spec (alpha beta : K) (A : M) (y : Y) (x : X) :
    VectorType.toVec (gemvH alpha beta A y x)
    =
    let A := toMatrix A
    let x := VectorType.toVec x
    let y := VectorType.toVec y
    alpha • Aᴴ *ᵥ y + beta • x

-- open MatrixType.Base Function in
-- class MatrixType.Lawful
--     (M : Type*)
--     {m n : outParam (Type*)} {_ : outParam (IndexType m)} {_ : outParam (IndexType n)}
--     {R K : outParam (Type*)} {_ : outParam (RealScalar R)} {_ : outParam (Scalar R K)}
--     {X Y : outParam (Type*)} [VectorType.Base X n K] [VectorType.Base Y m K]
--     [MatrixType.Base M X Y]
--   -- extends
--   --   VectorType.Lawful M (m×n) K
--   where
--   toMatrix_injective : Injective (toMatrix (M:=M))


-- -- should this be instance? then we would get to `@[ext]` theorems on matrix type `M`
-- open MatrixType Base Lawful in
-- def MatrixType.vectorTypeLawful (M : Type*)
--     {m n : outParam (Type*)} {_ : outParam (IndexType m)} {_ : outParam (IndexType n)}
--     {R K : outParam (Type*)} {_ : outParam (RealScalar R)} {_ : outParam (Scalar R K)}
--     {X Y : outParam (Type*)} [VectorType.Base X n K] [VectorType.Base Y m K]
--     [MatrixType.Base M X Y] [MatrixType.Lawful M] : VectorType.Lawful M where

--   toVec_injective := by
--     intro A B h
--     simp only [toVec_eq_toMatrix] at h
--     apply toMatrix_injective
--     funext i j
--     exact congrFun h (i,j)


namespace MatrixType

export MatrixType.Base (toMatrix toVec_eq_toMatrix row row_spec sumRows sumRows_spec
  col col_spec sumCols sumCols_spec gemv gemv_spec gemvT gemvT_spec gemvH gemvH_spec)

-- export MatrixType.Lawful (toMatrix_injective)

attribute [vector_to_spec] row_spec sumRows_spec
  col_spec sumCols_spec gemv_spec gemvT_spec gemvH_spec


section BasicOperations

variable
  {R K} {_ : RealScalar R} {_ : Scalar R K}
  {m n : Type*} {_ : IndexType m} {_ : IndexType n}
  {X Y} [VectorType.Base X n K] [VectorType.Base Y m K]
  {M} [MatrixType.Base M X Y]

@[vector_to_spec]
theorem toMatrix_eq_toVec (A : M) : toMatrix A = fun i j => toVec A (i,j) := by
  rw[toVec_eq_toMatrix A]

set_default_scalar K

theorem toMatrix_injective [Lawful M] : Function.Injective (toMatrix : M → Matrix m n K) := sorry_proof

theorem ext [Lawful M] (A B : M) :
    (∀ i j, toMatrix A i j = toMatrix B i j) → A = B := by
  intro h; apply toMatrix_injective; funext i j;
  exact h i j

-- to we need these theorems?
@[matrix_to_spec]
theorem toMatrix_add (A B : M) : toMatrix (A + B) = toMatrix A + toMatrix B := by
  funext i j
  simp[vector_to_spec]

@[matrix_to_spec]
theorem toMatrix_sub (A B : M) : toMatrix (A - B) = toMatrix A - toMatrix B := by
  funext i j
  simp[vector_to_spec]

@[matrix_to_spec]
theorem toMatrix_neg (A : M) : toMatrix (-A) = -toMatrix A := by
  funext i j
  simp[toMatrix_eq_toVec, vector_to_spec]

@[matrix_to_spec]
theorem toMatrix_smul (a : K) (A : M) : toMatrix (a • A) = a • toMatrix A := by
  funext i j
  simp[toMatrix_eq_toVec, vector_to_spec]

@[matrix_to_spec]
theorem toMatrix_zero : toMatrix (0 : M) = 0 := by
  funext i j
  simp[toMatrix_eq_toVec, vector_to_spec]

set_option pp.notation false in
@[matrix_to_spec]
theorem inner_spec (A B : M) : ⟪A, B⟫ = ⟪toMatrix A, toMatrix B⟫ := by
  simp[vector_to_spec, ← Finset.univ_product_univ,Finset.sum_product,Inner.inner,sum_to_finset_sum]
-- @[matrix_to_spec, matrix_from_spec ←]
-- theorem norm_spec (A : M) : ‖A‖ = ‖toMatrix A‖ := by
--   simp only [norm, Norm.norm, Scalar.toReal, nrm2, matrix_to_spec]

-- @[matrix_to_spec, matrix_from_spec ←]
-- theorem dist_spec (A B : M) : dist A B = ‖toMatrix A - toMatrix B‖ := by
--   simp only [dist, Norm.dist, norm, Norm.norm, Scalar.toReal, nrm2, matrix_to_spec]

end BasicOperations

end MatrixType

end SciLean
