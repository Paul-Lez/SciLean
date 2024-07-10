import SciLean.Core.Distribution.Basic
import SciLean.Core.FunctionTransformations
import SciLean.Core.FunctionPropositions
import SciLean.Core.Notation

set_option linter.unusedVariables false


open MeasureTheory

namespace SciLean

open Distribution

variable
  {R} [RealScalar R]
  {W} [Vec R W]
  {X} [Vec R X] [MeasureSpace X]
  {Y} [Vec R Y] [Module ℝ Y]
  {Z} [Vec R Z] [Module ℝ Z]
  {U} [Vec R U] -- [Module ℝ U]
  {V} [Vec R V] -- [Module ℝ U]


set_default_scalar R


noncomputable
def diracDeriv (x dx : X) : 𝒟' X := fun φ ⊸ cderiv R φ x dx

@[fun_prop]
def DistribDifferentiableAt (f : X → 𝒟'(Y,Z)) (x : X) :=
  ∀ (φ : X → 𝒟 Y), CDifferentiableAt R φ x → CDifferentiableAt R (fun x => f x (φ x)) x


theorem distribDifferentiableAt_const_test_fun
    {f : X → 𝒟'(Y,Z)} {x : X}
    (hf : DistribDifferentiableAt f x)
    {φ : 𝒟 Y} :
    CDifferentiableAt R (fun x => f x φ) x := by
  apply hf
  fun_prop


@[fun_prop]
def DistribDifferentiable (f : X → 𝒟'(Y,Z)) :=
  ∀ x, DistribDifferentiableAt f x


-- TODO:
-- probably change the definition of `parDistribDeriv` to:
-- ⟨⟨fun φ =>
--    if h : DistribDifferentiableAt f x then
--      ∂ (x':=x;dx), ⟪f x', φ⟫
--    else
--      0 , sorry_proof⟩⟩
-- I believe in that case the function is indeed linear in φ

open Classical in
@[fun_trans]
noncomputable
def parDistribDeriv (f : X → 𝒟'(Y,Z)) (x dx : X) : 𝒟'(Y,Z) :=
  ⟨fun φ => ∂ (x':=x;dx), f x' φ, sorry_proof⟩


@[simp, ftrans_simp]
theorem action_parDistribDeriv (f : X → 𝒟'(Y,Z)) (x dx : X) (φ : 𝒟 Y) :
    parDistribDeriv f x dx φ = ∂ (x':=x;dx), f x' φ := rfl


----------------------------------------------------------------------------------------------------
-- Const rule --------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

@[fun_prop]
theorem DistribDiffrentiable.const_rule (T : 𝒟'(X,Y)) :
    DistribDifferentiable (fun _ : W => T) := by
  intro _ φ hφ; simp; fun_prop

@[fun_trans]
theorem parDistribDeriv.const_rule (T : 𝒟'(X,Y)) :
    parDistribDeriv (fun _ : W => T)
    =
    fun w dw =>
      0 := by
  funext w dw; ext φ
  unfold parDistribDeriv
  fun_trans


----------------------------------------------------------------------------------------------------
-- Pure --------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

@[fun_prop]
theorem dirac.arg_xy.DistribDiffrentiable_rule
    (x : W → X) (hx : CDifferentiable R x) :
    DistribDifferentiable (R:=R) (fun w => dirac (x w))  := by
  intro x
  unfold DistribDifferentiableAt
  intro φ hφ
  simp [action_dirac, dirac]
  fun_prop


@[fun_trans]
theorem dirac.arg_x.parDistribDeriv_rule
    (x : W → X) (hx : CDifferentiable R x) :
    parDistribDeriv (R:=R) (fun w => dirac (x w))
    =
    fun w dw =>
      let xdx := fwdDeriv R x w dw
      diracDeriv xdx.1 xdx.2 := by --= (dpure (R:=R) ydy.1 ydy.2) := by
  funext w dw; ext φ
  unfold parDistribDeriv dirac diracDeriv
  simp [pure, fwdDeriv, DistribDifferentiableAt]
  fun_trans


----------------------------------------------------------------------------------------------------
-- Composition -------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

@[fun_prop]
theorem DistribDiffrentiable.comp_rule
    (f : Y → 𝒟'(Z,U)) (g : X → Y)
    (hf : DistribDifferentiable f) (hg : CDifferentiable R g) :
    DistribDifferentiable (fun x => f (g x)) := by
  intro x
  unfold DistribDifferentiableAt
  intro φ _
  apply CDifferentiable.comp_rule (K:=R) (f:=fun xy : X×Y => f xy.2 (φ xy.1)) (g:=fun x => (x, g x))
    (hg:=by fun_prop)
  intro x
  sorry_proof -- is this even true ?


@[fun_trans]
theorem parDistribDeriv.comp_rule
    (f : Y → 𝒟'(Z,U)) (g : X → Y)
    (hf : DistribDifferentiable f) (hg : CDifferentiable R g) :
    parDistribDeriv (fun x => f (g x))
    =
    fun x dx =>
      let ydy := fwdDeriv R g x dx
      parDistribDeriv f ydy.1 ydy.2 := by

  funext x dx; ext φ
  unfold parDistribDeriv
  simp[hg]
  sorry_proof


----------------------------------------------------------------------------------------------------
-- Bind --------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------


-- The assumptions here are definitely not right!!!
-- I think `f` has to be `deg`
@[fun_prop]
theorem Bind.bind.arg_fx.DistribDifferentiable_rule
    (f : X → Y → 𝒟'(Z,V)) (g : X → 𝒟'(Y,U)) (L : U ⊸ V ⊸ W)
    (hf : DistribDifferentiable (fun (x,y) => f x y)) -- `f` has to be nice enough to accomodate action of `g`
    (hg : DistribDifferentiable g) :
    DistribDifferentiable (fun x => (g x).bind (f x) L) := by

  intro x
  unfold DistribDifferentiableAt
  intro φ hφ
  simp
  sorry_proof


@[fun_trans]
theorem Bind.bind.arg_fx.parDistribDiff_rule
    (f : W → X → 𝒟'(Y,V)) (g : W → 𝒟'(X,U)) (L : U ⊸ V ⊸ W)
    (hf : DistribDifferentiable (fun (w,x) => f w x)) -- `f` has to be nice enough to accomodate action of `g`
    (hg : DistribDifferentiable g) :
    parDistribDeriv (fun w => (g w).bind (f w) L)
    =
    fun w dw =>
      ((parDistribDeriv g w dw).bind (f x · ) L)
      +
      ((g w).bind (fun x => parDistribDeriv (f · x) w dw) L) := sorry_proof



----------------------------------------------------------------------------------------------------
-- Move these around -------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

@[fun_prop]
theorem Distribution.restrict.arg_T.IsSmoothLinearMap_rule (T : W → 𝒟'(X,Y)) (A : Set X)
    (hT : IsSmoothLinearMap R T) :
    IsSmoothLinearMap R (fun w => (T w).restrict A) := sorry_proof

@[fun_prop]
theorem Distribution.restrict.arg_T.IsSmoothLinearMap_rule_simple (A : Set X) :
    IsSmoothLinearMap R (fun (T : 𝒟'(X,Y)) => T.restrict A) := sorry_proof


@[fun_trans]
theorem Distribution.restrict.arg_T.parDistribDeriv_rule (T : W → 𝒟'(X,Y)) (A : Set X)
    (hT : DistribDifferentiable T) :
    parDistribDeriv (fun w => (T w).restrict A)
    =
    fun w dw =>
      (parDistribDeriv T w dw).restrict A := sorry_proof

@[fun_prop]
theorem Function.toDistribution.arg_f.CDifferentiable_rule (f : W → X → Y)
    (hf : ∀ x, CDifferentiable R (f · x)) :
    CDifferentiable R (fun w => (fun x => f w x).toDistribution (R:=R)) := sorry_proof

@[fun_trans]
theorem Function.toDistribution.arg_f.cderiv_rule (f : W → X → Y)
    (hf : ∀ x, CDifferentiable R (f · x)) :
    cderiv R (fun w => (fun x => f w x).toDistribution (R:=R))
    =
    fun w dw =>
      (fun x =>
        let dy := cderiv R (f · x) w dw
        dy).toDistribution := sorry_proof

@[fun_trans]
theorem toDistribution.linear_parDistribDeriv_rule (f : W → X → Y) (L : Y → Z)
    (hL : IsSmoothLinearMap R L) :
    parDistribDeriv (fun w => (fun x => L (f w x)).toDistribution)
    =
    fun w dw =>
      parDistribDeriv (fun w => (fun x => f w x).toDistribution) w dw |>.postComp (fun y ⊸ L y) := by
  funext w dw
  unfold parDistribDeriv Distribution.postComp Function.toDistribution
  ext φ
  simp [ftrans_simp] -- , Distribution.mk_extAction_simproc]
  sorry_proof



----------------------------------------------------------------------------------------------------
-- Integral ----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

variable [MeasureSpace X] [MeasureSpace Y] [MeasureSpace (X×Y)]

open Notation

@[fun_trans]
theorem cintegral.arg_f.cderiv_distrib_rule (f : W → X → Y) :
    cderiv R (fun w => ∫' x, f w x)
    =
    fun w dw =>
      (parDistribDeriv (fun w => (f w ·).toDistribution) w dw).extAction (fun _ => (1:R)) (fun y ⊸ fun r ⊸ r • y) := sorry_proof


@[fun_trans]
theorem cintegral.arg_f.cderiv_distrib_rule' (f : W → X → R) (A : Set X):
    cderiv R (fun w => ∫' x in A, f w x)
    =
    fun w dw =>
       (parDistribDeriv (fun w => (f w ·).toDistribution) w dw).restrict A |>.extAction (fun _ => (1:R)) (fun y ⊸ fun r ⊸ r • y) := sorry_proof


@[fun_trans]
theorem cintegral.arg_f.parDistribDeriv_rule (f : W → X → Y → Z) :
    parDistribDeriv (fun w => (fun x => ∫' y, f w x y).toDistribution (R:=R))
    =
    fun w dw =>
      let Tf := (fun w => (fun x => (fun y => f w x y).toDistribution (R:=R)).toDistribution (R:=R))
      parDistribDeriv Tf w dw |>.postComp (fun T ⊸ T.extAction (fun _ => (1:R)) (fun z ⊸ fun r ⊸ r • z)) := by
  funext w dw
  unfold parDistribDeriv postComp Function.toDistribution
  ext φ
  simp [ftrans_simp] -- , Distribution.mk_extAction_simproc]
  sorry_proof


@[fun_trans]
theorem cintegral.arg_f.parDistribDeriv_rule' (f : W → X → Y → Z) (B : X → Set Y) :
    parDistribDeriv (fun w => (fun x => ∫' y in B x, f w x y).toDistribution)
    =
    fun w dw =>
      let Tf := (fun w => (fun x => ((fun y => f w x y).toDistribution (R:=R)).restrict (B x)).toDistribution (R:=R))
      parDistribDeriv Tf w dw |>.postComp (fun T ⊸ T.extAction (fun _ => (1:R)) (fun z ⊸ fun r ⊸ r • z)) := sorry_proof





----------------------------------------------------------------------------------------------------
-- Add ---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------


@[fun_prop]
theorem HAdd.hAdd.arg_a0a1.DistribDifferentiable_rule (f g : W → 𝒟'(X,Y))
    (hf : DistribDifferentiable f) (hg : DistribDifferentiable g) :
    DistribDifferentiable (fun w => f w + g w) := sorry_proof


@[fun_trans]
theorem HAdd.hAdd.arg_a0a1.parDistribDeriv_rule (f g : W → 𝒟'(X,Y))
    (hf : DistribDifferentiable f) (hg : DistribDifferentiable g) :
    parDistribDeriv (fun w => f w + g w)
    =
    fun w dw =>
      let dy := parDistribDeriv f w dw
      let dz := parDistribDeriv g w dw
      dy + dz := sorry_proof


----------------------------------------------------------------------------------------------------
-- Sub ---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------


@[fun_prop]
theorem HSub.hSub.arg_a0a1.DistribDifferentiable_rule (f g : W → 𝒟'(X,Y)) :
    -- (hf : DistribDifferentiable f) (hg : DistribDifferentiable g) :
    DistribDifferentiable (fun w => f w - g w) := sorry_proof


@[fun_trans]
theorem HSub.hSub.arg_a0a1.parDistribDeriv_rule (f g : W → 𝒟'(X,Y)) :
    -- (hf : DistribDifferentiable f) (hg : DistribDifferentiable g) :
    parDistribDeriv (fun w => f w - g w)
    =
    fun w dw =>
      let dy := parDistribDeriv f w dw
      let dz := parDistribDeriv g w dw
      dy - dz := sorry_proof




-- ----------------------------------------------------------------------------------------------------
-- -- Sub ---------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------

-- @[fun_prop]
-- theorem HSub.hSub.arg_a0a1.DistribDifferentiable_rule (f g : W → X → Y)
--     /- (hf : ∀ x, CDifferentiable R (f · x)) (hg : ∀ x, CDifferentiable R (g · x)) -/ :
--     DistribDifferentiable (fun w => (fun x => f w x - g w x).toDistribution (R:=R)) := by
--   intro _ φ hφ; simp; sorry_proof -- fun_prop (disch:=assumption)


-- @[fun_trans]
-- theorem HSub.hSub.arg_a0a1.parDistribDeriv_rule (f g : W → X → Y)
--     /- (hf : ∀ x, CDifferentiable R (f · x)) (hg : ∀ x, CDifferentiable R (g · x)) -/ :
--     parDistribDeriv (fun w => (fun x => f w x - g w x).toDistribution)
--     =
--     fun w dw =>
--       parDistribDeriv (fun w => (f w ·).toDistribution) w dw
--       -
--       parDistribDeriv (fun w => (g w ·).toDistribution (R:=R)) w dw := by
--   funext w dw; ext φ; simp[parDistribDeriv]
--   sorry_proof


-- ----------------------------------------------------------------------------------------------------
-- -- Mul ---------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------

-- @[fun_prop]
-- theorem HMul.hMul.arg_a0a1.DistribDifferentiable_rule (f : W → X → R) (r : R)
--     /- (hf : ∀ x, CDifferentiable R (f · x)) (hg : ∀ x, CDifferentiable R (g · x)) -/ :
--     DistribDifferentiable (fun w => (fun x => r * f w x).toDistribution (R:=R)) := by
--   intro _ φ hφ; simp; sorry_proof -- fun_prop (disch:=assumption)


-- @[fun_trans]
-- theorem HMul.hMul.arg_a0a1.parDistribDeriv_rule (f : W → X → R) (r : R)
--     /- (hf : ∀ x, CDifferentiable R (f · x)) (hg : ∀ x, CDifferentiable R (g · x)) -/ :
--     parDistribDeriv (fun w => (fun x => r * f w x).toDistribution)
--     =
--     fun w dw =>
--       r • (parDistribDeriv (fun w => (f w ·).toDistribution (R:=R)) w dw) := by
--   funext w dw; ext φ; simp[parDistribDeriv]
--   sorry_proof


-- ----------------------------------------------------------------------------------------------------
-- -- Smul ---------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------

-- @[fun_prop]
-- theorem HSMul.hSMul.arg_a0a1.DistribDifferentiable_rule (f : W → X → Y) (r : R)
--     /- (hf : ∀ x, CDifferentiable R (f · x)) (hg : ∀ x, CDifferentiable R (g · x)) -/ :
--     DistribDifferentiable (fun w => (fun x => r • f w x).toDistribution (R:=R)) := by
--   intro _ φ hφ; simp; sorry_proof -- fun_prop (disch:=assumption)


-- @[fun_trans]
-- theorem HSMul.hSMul.arg_a0a1.parDistribDeriv_rule (f : W → X → Y) (r : R)
--     /- (hf : ∀ x, CDifferentiable R (f · x)) (hg : ∀ x, CDifferentiable R (g · x)) -/ :
--     parDistribDeriv (fun w => (fun x => r • f w x).toDistribution)
--     =
--     fun w dw =>
--       r • (parDistribDeriv (fun w => (f w ·).toDistribution (R:=R)) w dw) := by
--   funext w dw; ext φ; simp[parDistribDeriv]
--   sorry_proof



-- ----------------------------------------------------------------------------------------------------
-- -- Div ---------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------

-- @[fun_prop]
-- theorem HDiv.hDiv.arg_a0a1.DistribDifferentiable_rule (f : W → X → R) (r : R)
--     /- (hf : ∀ x, CDifferentiable R (f · x)) (hg : ∀ x, CDifferentiable R (g · x)) -/ :
--     DistribDifferentiable (fun w => (fun x => f w x / r).toDistribution (R:=R)) := by
--   intro _ φ hφ; simp; sorry_proof -- fun_prop (disch:=assumption)


-- @[fun_trans]
-- theorem HDiv.hDiv.arg_a0a1.parDistribDeriv_rule (f : W → X → R) (r : R)
--     /- (hf : ∀ x, CDifferentiable R (f · x)) (hg : ∀ x, CDifferentiable R (g · x)) -/ :
--     parDistribDeriv (fun w => (fun x => f w x / r).toDistribution)
--     =
--     fun w dw =>
--       r⁻¹ • (parDistribDeriv (fun w => (f w ·).toDistribution (R:=R)) w dw) := by
--   funext w dw; ext φ; simp[parDistribDeriv]
--   sorry_proof
