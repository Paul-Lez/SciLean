import SciLean.Core.FunctionTransformations
-- import SciLean.Core.Meta.GenerateRevDeriv

open ComplexConjugate

namespace SciLean.Scalar

variable
  {R C} [Scalar R C] [RealScalar R]
  {W} [Vec C W]
  {U} [SemiInnerProductSpace C U]


--------------------------------------------------------------------------------
-- Exp -------------------------------------------------------------------------
--------------------------------------------------------------------------------

set_option linter.unusedVariables false in
@[fun_prop]
theorem exp.arg_x.DifferentiableAt_rule
    {W} [NormedAddCommGroup W] [NormedSpace C W]
    (w : W) (x : W → C) (hx : DifferentiableAt C x w) :
    DifferentiableAt C (fun w => exp (x w)) w := sorry_proof


@[fun_prop]
theorem exp.arg_x.Differentiable_rule
    {W} [NormedAddCommGroup W] [NormedSpace C W]
    (x : W → C) (hx : Differentiable C x) :
    Differentiable C fun w => exp (x w) := by intro x; fun_prop


set_option linter.unusedVariables false in
@[fun_trans]
theorem exp.arg_x.fderiv_rule
    {W} [NormedAddCommGroup W] [NormedSpace C W]
    (x : W → C) (hx : Differentiable C x) :
    fderiv C (fun w => exp (x w))
    =
    fun w => fun dw =>L[C]
      let x'  := x w
      let dx' := fderiv C x w dw
      dx' * exp x' := sorry_proof


@[fun_trans]
theorem exp.arg_x.fwdFDeriv_rule
    {W} [NormedAddCommGroup W] [NormedSpace C W]
    (x : W → C) (hx : Differentiable C x) :
    fwdFDeriv C (fun w => exp (x w))
    =
    fun w dw =>
      let xdx := fwdFDeriv C x w dw
      let y := exp xdx.1
      (y, xdx.2 * y) := by

  unfold fwdFDeriv
  fun_trans


@[fun_trans]
theorem exp.arg_x.revFDeriv_rule
    {W} [NormedAddCommGroup W] [AdjointSpace C W] [CompleteSpace W]
    (x : W → C) (hx : Differentiable C x) :
    revFDeriv C (fun w => exp (x w))
    =
    fun w =>
      let xdx := revFDeriv C x w
      let y := exp xdx.1
      (y,
       fun dy =>
         let s := conj y
         s • xdx.2 dy) := by

  unfold revFDeriv
  fun_trans


set_option linter.unusedVariables false in
@[fun_prop]
theorem exp.arg_x.CDifferentiable_rule
  (x : W → C) (hx : CDifferentiable C x)
  : CDifferentiable C fun w => exp (x w) := sorry_proof

set_option linter.unusedVariables false in
@[fun_trans]
theorem exp.arg_x.ceriv_rule
  (x : W → C) (hx : CDifferentiable C x)
  : cderiv C (fun w => exp (x w))
    =
    fun w dw =>
      let xdx := fwdDeriv C x w dw
      let e := exp xdx.1
      xdx.2 * e := sorry_proof

@[fun_trans]
theorem exp.arg_x.fwdDeriv_rule
    (x : W → C) (hx : CDifferentiable C x) :
    fwdDeriv C (fun w => exp (x w))
    =
    fun w dw =>
      let xdx := fwdDeriv C x w dw
      let e := exp xdx.1
      (e, xdx.2 * e) := by
  unfold fwdDeriv; fun_trans; rfl

@[fun_prop]
theorem exp.arg_x.HasAdjDiff_rule
    (x : U → C) (hx : HasAdjDiff C x) :
    HasAdjDiff C (fun u => exp (x u)) := by
  intro x
  constructor
  fun_prop
  fun_trans [fwdDeriv]; fun_prop

open ComplexConjugate
@[fun_trans]
theorem exp.arg_x.revDeriv_rule
    (x : U → C) (hx : HasAdjDiff C x) :
    revDeriv C (fun u => exp (x u))
    =
    fun u =>
      let xdx := revDeriv C x u
      (exp xdx.1, fun dy => xdx.2 (conj (exp xdx.1) * dy)) := by
  unfold revDeriv
  fun_trans only [fwdDeriv, smul_push, ftrans_simp]



--------------------------------------------------------------------------------
-- Log -------------------------------------------------------------------------
--------------------------------------------------------------------------------

section Log

variable
  {R : Type _} [RealScalar R]
  {W : Type _} [Vec R W]
  {U : Type _} [SemiInnerProductSpace R U]


set_option linter.unusedVariables false in
@[fun_prop]
theorem log.arg_x.CDifferentiableAt_rule
    (w : W) (x : W → R) (hx : CDifferentiableAt R x w) (hw : x w ≠ 0) :
    CDifferentiableAt R (fun w => log (x w)) w := sorry_proof

@[fun_prop]
theorem log.arg_x.CDifferentiable_rule
    (x : W → R) (hx : CDifferentiable R x) (hw : ∀ w, x w ≠ 0) :
    CDifferentiable R (fun w => log (x w)) := by
  intro x; fun_prop (disch:=aesop)

set_option linter.unusedVariables false in
@[fun_trans]
theorem log.arg_x.cderiv_rule_at
    (w : W) (x : W → R) (hx : CDifferentiableAt R x w) (hw : x w ≠ 0) :
    cderiv R (fun w => log (x w)) w
    =
    fun dw =>
      let xdx := fwdDeriv R x w dw
      xdx.2 / abs xdx.1 := sorry_proof

@[fun_trans]
theorem log.arg_x.cderiv_rule
    (x : W → R) (hx : CDifferentiable R x) (hw : ∀ w, x w ≠ 0) :
    cderiv R (fun w => log (x w))
    =
    fun w dw =>
      let xdx := fwdDeriv R x w dw
      xdx.2 / abs xdx.1 := by
  funext x
  fun_trans (disch:=aesop)

@[fun_trans]
theorem log.arg_x.fwdDeriv_rule_at
    (w : W) (x : W → R) (hx : CDifferentiableAt R x w) (hw : x w ≠ 0) :
    fwdDeriv R (fun w => log (x w)) w
    =
    fun dw =>
      let xdx := fwdDeriv R x w dw
      let l := log xdx.1
      (l, xdx.2 / abs xdx.1) :=
by
  unfold fwdDeriv; fun_trans (disch:=assumption); simp[fwdDeriv]

@[fun_trans]
theorem log.arg_x.fwdDeriv_rule
    (x : W → R) (hx : CDifferentiable R x) (hw : ∀ w, x w ≠ 0) :
    fwdDeriv R (fun w => log (x w))
    =
    fun w dw =>
      let xdx := fwdDeriv R x w dw
      let l := log xdx.1
      (l, xdx.2 / abs xdx.1) :=
by
  unfold fwdDeriv; fun_trans (disch:=assumption); simp[fwdDeriv]

@[fun_prop]
theorem log.arg_x.HasAdjDiffAt_rule
    (u : U) (x : U → R) (hx : HasAdjDiffAt R x u) (hu : x u ≠ 0) :
    HasAdjDiffAt R (fun u => log (x u)) u := by
  constructor
  fun_prop (disch:=aesop)
  fun_trans (disch:=aesop) [fwdDeriv]; fun_prop

@[fun_prop]
theorem log.arg_x.HasAdjDiff_rule
    (x : U → R) (hx : HasAdjDiff R x) (hu : ∀ u, x u ≠ 0) :
    HasAdjDiff R (fun u => log (x u)) := by
  intro u;
  fun_prop (disch:=aesop)

open ComplexConjugate
@[fun_trans]
theorem log.arg_x.revDeriv_rule_at
    (u : U) (x : U → R) (hx : HasAdjDiffAt R x u) (hu : x u ≠ 0) :
    revDeriv R (fun u => log (x u)) u
    =
    let xdx := revDeriv R x u
    (log xdx.1, fun dy => xdx.2 ((abs (x u))⁻¹ * dy)) := by
  unfold revDeriv
  fun_trans (disch:=aesop) only [fwdDeriv, smul_push, ftrans_simp]

open ComplexConjugate
@[fun_trans]
theorem log.arg_x.revDeriv_rule
    (x : U → R) (hx : HasAdjDiff R x) (hu : ∀ u, x u ≠ 0) :
    revDeriv R (fun u => log (x u))
    =
    fun u =>
      let xdx := revDeriv R x u
      (log xdx.1, fun dy => xdx.2 ((abs (x u))⁻¹ * dy)) := by
  unfold revDeriv
  fun_trans (disch:=aesop) only [fwdDeriv, smul_push, ftrans_simp]


@[simp, ftrans_simp]
theorem log_one : Scalar.log (1:R) = 0 := sorry_proof
@[simp, ftrans_simp]
theorem log_exp (x : R) : Scalar.log (Scalar.exp x) = x := sorry_proof
theorem log_mul (x y : R) : Scalar.log (x*y) = Scalar.log x + Scalar.log y := sorry_proof
theorem log_div (x y : R) : Scalar.log (x/y) = Scalar.log x - Scalar.log y := sorry_proof
theorem log_inv (x : R) : Scalar.log x⁻¹ = - Scalar.log x := sorry_proof

end Log
