import SciLean.Data.DataArray
import SciLean.Data.ArrayType
import SciLean.Core.FunctionTransformations
import SciLean.Core.FunctionPropositions
import SciLean.Core.Integral.ParametricInverse
import SciLean.Core.Integral.Jacobian
import SciLean.Core.Integral.BoundingBall
import SciLean.Core.Notation
import SciLean.Tactic.InferVar

namespace SciLean

variable
  {R : Type _} [RealScalar R] [PlainDataType R]

set_default_scalar R

/-- Given collection of `n` vectors return orthonormal set of vectors obtained by Gram-Shcmidt
algorithm.  -/
def gramSchmidtArrayImpl {X} [SemiHilbert R X] (u : Array X) : Array X := Id.run do
  let mut u := u
  for i in IndexType.univ (Fin u.size) do
    let i : Fin u.size := ⟨i, sorry_proof⟩
    let mut ui := u[i]
    for j in [0:i.1] do
      let j : Fin u.size := ⟨j,sorry_proof⟩
      let uj := u[j]
      ui -= ⟪uj,ui⟫ • uj
    u := u.set i (vecNormalize R ui)
  return u


/-- Given collection of `n` vectors return orthonormal set of vectors obtained by Gram-Shcmidt
algorithm.  -/
def gramSchmidtDataArrayImpl {X} [SemiHilbert R X] [PlainDataType X] (u : X^[n]) : X^[n] :=
  Id.run do
  let mut u := u
  for i in IndexType.univ (Fin n) do
    let mut ui := u[i]
    for j in [0:i.1] do
      let j : Fin n := ⟨j,sorry_proof⟩
      let uj := u[j]
      ui -= ⟪uj,ui⟫ • uj
    u[i] := vecNormalize R ui
  return u


open IndexType Scalar FinVec in
/-- Given a plane `{x | ⟪u,x⟫=0}` this function decomposes `R^[n]` into this plane and its
orthogonal complement.

TODO: Fix this function for `u = 0`!!! -/
def planeDecomposition
    {n} {ι} [IndexType ι] [LawfulIndexType ι] [DecidableEq ι] {X} [FinVec ι R X]
    (u : X)
    (hn : n + 1 = card ι := by first | assumption | infer_var) :
    R×R^[n] ≃ X := Id.run do

  have : Inhabited ι := ⟨fromFin ⟨0, by omega⟩⟩

  -- Find the maximal component of `u`
  let i' := toFin (IndexType.argMax (fun i : ι => |u[i]|))

  -- Initiali collection of basis vectors
  -- `u` is take as the first basis vector
  -- and we complete it with the canonical bases on `R^[n]` but we omit the basis vector
  -- that corresponds to the largest component of `u`
  let basis : Array X := .ofFn fun (i : Fin (n+1)) =>
    if i.1 = 0 then
      u
    else if i.1 ≤ i'.1 then
      let i'' : ι := fromFin ⟨i.1-1, sorry_proof⟩
      ⅇ i''
    else
      let i'' : ι := fromFin ⟨i.1, sorry_proof⟩
      ⅇ i''

  let basis := gramSchmidtArrayImpl (R:=R) basis

  {
    toFun := fun (t,y) =>
      t • basis.get ⟨0,sorry_proof⟩
      +
      ∑ i : Fin n, y.get i • basis.get ⟨i.1+1, sorry_proof⟩
    invFun := fun x =>
      (⟪x,basis.get ⟨0,sorry_proof⟩⟫, ⊞ (j : Fin n) => ⟪x, basis.get ⟨j.1+1, sorry_proof⟩⟫)
    left_inv := sorry_proof
    right_inv := sorry_proof
  }


open IndexType in
theorem planeDecomposition_normal_dir
    {n} {ι} [IndexType ι] [LawfulIndexType ι] [DecidableEq ι]
    {X} [FinVec ι R X]
    (u : X)
    (hn : n + 1 = card ι) :
    planeDecomposition (R:=R) u hn (t,0) = (t • vecNormalize R u) := sorry_proof

open IndexType in
theorem planeDecomposition_orthogonal_dir
    {n} {ι} [IndexType ι] [LawfulIndexType ι] [DecidableEq ι] {X} [FinVec ι R X]
    (u : X) (y : R^[n])
    (hn : n + 1 = card ι) :
    ⟪u, planeDecomposition (R:=R) u hn (t,y)⟫ = t * ‖u‖₂ := sorry_proof


variable
  {ι} [IndexType ι] [LawfulIndexType ι] [DecidableEq ι]
  {X} [FinVec ι R X]

variable (f : X → R)

open IndexType in
@[gtrans]
theorem parametric_inverse_affine {n} (f : X → R) (c : R) (hf : IsAffineMap R f)
    (hn : n + 1 = card ι := by first | assumption | infer_var) :
    let u  := ∇ f 0
    let dec := planeDecomposition (R:=R) u hn
    ParametricInverseAt f c
      (I:=Unit)
      (p:=fun _ y t => dec (t,y))
      (g:=fun _ _ => (c - f 0) / ‖u‖₂)
      (dom := fun _ => ⊤) := by

  simp[ParametricInverseAt,arrayTypeCont]
  have h : f = fun x => ⟪(∇ f 0), x⟫ + f 0 := sorry_proof -- use the fact that `f` is affine here
  rw[h]; fun_trans [scalarGradient,planeDecomposition_orthogonal_dir]
  have : ‖(<∂ f 0).2 1‖₂[R] ≠ 0 := sorry_proof
  field_simp


open IndexType in
theorem parametric_inverse_affine' (f : X → R) (c : R) (hf : IsAffineMap R f) :
    let u  := ∇ f 0
    let dec := planeDecomposition (n:=card ι - 1) (R:=R) u sorry_proof
    ParametricInverseAt f c
      (I:=Unit)
      (p:=fun _ y t => dec (t,y))
      (g:=fun _ _ => (c - f 0) / ‖u‖₂)
      (dom := fun _ => ⊤) := by

  simp[ParametricInverseAt,arrayTypeCont]
  have h : f = fun x => ⟪(∇ f 0), x⟫ + f 0 := sorry_proof -- use the fact that `f` is affine here
  rw[h]; fun_trans [scalarGradient,planeDecomposition_orthogonal_dir]
  have : ‖(<∂ f 0).2 1‖₂[R] ≠ 0 := sorry_proof
  field_simp



#exit

open IndexType in
@[simp, fun_trans]
theorem planeDecomposition.arg_a0.jacobian_rule
    {n} {ι} [IndexType ι] [LawfulIndexType ι] [DecidableEq ι]
    {X} [SemiHilbert R X]
    {Y} [FinVec ι R Y]
    (u : Y)
    (hn : n + 1 = card ι := by first | assumption | infer_var) (a : R)
    (f : X → R^[n]) (hf : HasAdjDiff R f):
    jacobian R (fun x => planeDecomposition u hn (a, f x))
    =
    fun x => jacobian R f x := sorry_proof


open IndexType in
@[gtrans]
theorem planeDecomposition_bounding_ball
    {n} {ι} [IndexType ι] [LawfulIndexType ι] [DecidableEq ι] {X} [FinVec ι R X] [MetricSpaceP X 2]
    (u : X) (hn : n + 1 = card ι := by first | assumption | infer_var)
    (A : Set X) (center : X) (radius : ℝ)
    (hA : BoundingBall A center radius) :
    let dec := (planeDecomposition (R:=R) u hn)
    let center' := (dec.symm center)
    BoundingBall (dec ⁻¹' A) center' radius := sorry_proof
