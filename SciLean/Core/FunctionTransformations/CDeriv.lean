import SciLean.Core.FunctionPropositions.IsDifferentiable 
import SciLean.Core.FunctionPropositions.IsDifferentiableAt
import SciLean.Core.NotationOverField

import SciLean.Tactic.FTrans.Basic

set_option linter.unusedVariables false

namespace SciLean

variable 
  (K : Type _) [IsROrC K]
  {X : Type _} [Vec K X]
  {Y : Type _} [Vec K Y]
  {Z : Type _} [Vec K Z]
  {ι : Type _} [EnumType ι]
  {E : ι → Type _} [∀ i, Vec K (E i)]

noncomputable
def cderiv (f : X → Y) (x dx : X) : Y := Curve.deriv (fun t : K => f (x + t•dx)) 0

--@[ftrans_unfold]
noncomputable
def scalarCDeriv (f : K → X) (t : K) : X := cderiv K f t 1

@[simp]
theorem cderiv_apply
  (f : X → Y → Z) (x dx : X) (y : Y)
  : cderiv K f x dx y
    =
    cderiv K (fun x' => f x' y) x dx := sorry_proof


-- Basic lambda calculus rules -------------------------------------------------
--------------------------------------------------------------------------------
variable (X)
theorem cderiv.id_rule 
  : (cderiv K fun x : X => x) = fun _ => fun dx => dx
  := by sorry_proof
variable {X}

variable (Y)
theorem cderiv.const_rule (x : X)
  : (cderiv K fun _ : Y => x) = fun _ => fun dx => 0
  := by sorry_proof
variable {Y}

variable (E)
theorem cderiv.proj_rule (i : ι)
  : (cderiv K fun (x : (i : ι) → E i) => x i)
    =
    fun _ => fun dx => dx i := 
by sorry_proof
variable {E}


theorem cderiv.comp_rule_at
  (f : Y → Z) (g : X → Y) (x : X)
  (hf : IsDifferentiableAt K f (g x)) (hg : IsDifferentiableAt K g x)
  : (cderiv K fun x : X => f (g x)) x
    =
    let y := g x
    fun dx =>
      let dy := cderiv K g x dx
      let dz := cderiv K f y dy
      dz :=
by sorry_proof


theorem cderiv.comp_rule
  (f : Y → Z) (g : X → Y) 
  (hf : IsDifferentiable K f) (hg : IsDifferentiable K g)
  : (cderiv K fun x : X => f (g x))
    =
    fun x => 
      let y := g x
      fun dx =>
        let dy := cderiv K g x dx
        let dz := cderiv K f y dy
        dz :=
by sorry_proof


theorem cderiv.let_rule_at
  (f : X → Y → Z) (g : X → Y) (x : X)
  (hf : IsDifferentiableAt K (fun xy : X×Y => f xy.1 xy.2) (x, g x)) 
  (hg : IsDifferentiableAt K g x)
  : (cderiv K
      fun x : X =>
        let y := g x
        f x y) x
    =
    let y  := g x
    fun dx =>
      let dy := cderiv K g x dx
      let dz := cderiv K (fun xy : X×Y => f xy.1 xy.2) (x,y) (dx, dy)
      dz :=
by sorry_proof


theorem cderiv.let_rule
  (f : X → Y → Z) (g : X → Y) 
  (hf : IsDifferentiable K fun xy : X×Y => f xy.1 xy.2) (hg : IsDifferentiable K g)
  : (cderiv K fun x : X =>
       let y := g x
       f x y)
    =
    fun x => 
      let y  := g x
      fun dx =>
        let dy := cderiv K g x dx
        let dz := cderiv K (fun xy : X×Y => f xy.1 xy.2) (x,y) (dx, dy)
        dz := 
by sorry_proof


theorem cderiv.pi_rule_at
  (f : X → (i : ι) → E i) (x : X) (hf : ∀ i, IsDifferentiableAt K (f · i) x)
  : (cderiv K fun (x : X) (i : ι) => f x i) x
    = 
    fun dx => fun i =>
      cderiv K (f · i) x dx
  := by sorry_proof


theorem cderiv.pi_rule
  (f : X → (i : ι) → E i) (hf : ∀ i, IsDifferentiable K (f · i))
  : (cderiv K fun (x : X) (i : ι) => f x i)
    = 
    fun x => fun dx => fun i =>
      cderiv K (f · i) x dx
  := by sorry_proof

variable {K}



-- Register `cderiv` as function transformation --------------------------------
--------------------------------------------------------------------------------

open Lean Meta Qq in
def cderiv.discharger (e : Expr) : SimpM (Option Expr) := do
  withTraceNode `fwdDeriv_discharger (fun _ => return s!"discharge {← ppExpr e}") do
  let cache := (← get).cache
  let config : FProp.Config := {}
  let state  : FProp.State := { cache := cache }
  let (proof?, state) ← FProp.fprop e |>.run config |>.run state
  modify (fun simpState => { simpState with cache := state.cache })
  if proof?.isSome then
    return proof?
  else
    -- if `fprop` fails try assumption
    let tac := FTrans.tacticToDischarge (Syntax.mkLit ``Lean.Parser.Tactic.assumption "assumption")
    let proof? ← tac e
    return proof?

open Lean Meta FTrans in
def cderiv.ftransExt : FTransExt where
  ftransName := ``cderiv

  getFTransFun? e := 
    if e.isAppOf ``cderiv then

      if let .some f := e.getArg? 6 then
        some f
      else 
        none
    else
      none

  replaceFTransFun e f := 
    if e.isAppOf ``cderiv then
      e.setArg 6 f
    else          
      e

  idRule  e X := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``id_rule #[K, X], origin := .decl ``id_rule, rfl := false} ]
      discharger e

  constRule e X y := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``const_rule #[K, X, y], origin := .decl ``const_rule, rfl := false} ]
      discharger e

  projRule e X i := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``proj_rule #[K, X, i], origin := .decl ``proj_rule, rfl := false} ]
      discharger e

  compRule e f g := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``comp_rule #[K, f, g], origin := .decl ``comp_rule, rfl := false},
         { proof := ← mkAppM ``comp_rule_at #[K, f, g], origin := .decl ``comp_rule, rfl := false} ]
      discharger e

  letRule e f g := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``let_rule #[K, f, g], origin := .decl ``let_rule, rfl := false},
         { proof := ← mkAppM ``let_rule_at #[K, f, g], origin := .decl ``let_rule, rfl := false} ]
      discharger e

  piRule  e f := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_rule #[K, f], origin := .decl ``pi_rule, rfl := false},
         { proof := ← mkAppM ``pi_rule_at #[K, f], origin := .decl ``pi_rule, rfl := false} ]
      discharger e

  discharger := cderiv.discharger


-- register cderiv
open Lean in
#eval show Lean.CoreM Unit from do
  modifyEnv (λ env => FTrans.ftransExt.addEntry env (``cderiv, cderiv.ftransExt))


end SciLean



--------------------------------------------------------------------------------
-- Function Rules --------------------------------------------------------------
--------------------------------------------------------------------------------

open SciLean

variable 
  {K : Type _} [IsROrC K]
  {X : Type _} [Vec K X]
  {Y : Type _} [Vec K Y]
  {Z : Type _} [Vec K Z]
  {W : Type _} [Vec K W]
  {ι : Type _} [EnumType ι]
  {E : ι → Type _} [∀ i, Vec K (E i)]


-- Prod.mk -----------------------------------v---------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem Prod.mk.arg_fstsnd.cderiv_rule_at
  (x : X)
  (g : X → Y) (hg : IsDifferentiableAt K g x)
  (f : X → Z) (hf : IsDifferentiableAt K f x)
  : cderiv K (fun x => (g x, f x)) x
    =
    fun dx =>
      (cderiv K g x dx, cderiv K f x dx) := 
by sorry_proof



@[ftrans]
theorem Prod.mk.arg_fstsnd.cderiv_rule
  (g : X → Y) (hg : IsDifferentiable K g)
  (f : X → Z) (hf : IsDifferentiable K f)
  : cderiv K (fun x => (g x, f x))
    =    
    fun x => fun dx =>
      (cderiv K g x dx, cderiv K f x dx) := 
by sorry_proof


-- Prod.fst --------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem Prod.fst.arg_self.cderiv_rule_at
  (x : X)
  (f : X → Y×Z) (hf : IsDifferentiableAt K f x)
  : cderiv K (fun x => (f x).1) x
    =
    fun dx => (cderiv K f x dx).1 := 
by sorry_proof



@[ftrans]
theorem Prod.fst.arg_self.cderiv_rule
  (f : X → Y×Z) (hf : IsDifferentiable K f)
  : cderiv K (fun x => (f x).1)
    =
    fun x => fun dx => (cderiv K f x dx).1 := 
by sorry_proof



-- Prod.snd --------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem Prod.snd.arg_self.cderiv_rule_at
  (x : X)
  (f : X → Y×Z) (hf : IsDifferentiableAt K f x)
  : cderiv K (fun x => (f x).2) x
    =
    fun dx => (cderiv K f x dx).2 := 
by sorry_proof


@[ftrans]
theorem Prod.snd.arg_self.cderiv_rule
  (f : X → Y×Z) (hf : IsDifferentiable K f)
  : cderiv K (fun x => (f x).2)
    =
    fun x => fun dx => (cderiv K f x dx).2 :=
by sorry_proof


-- id --------------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem id.arg_a.cderiv_rule
  : cderiv K (fun x : X => id x) 
    =
    fun _ => id := by unfold id; ftrans


-- Function.comp ---------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem Function.comp.arg_a0.cderiv_rule_at
  (f : Y → Z) (g : X → Y) (x : X)
  (hf : IsDifferentiableAt K f (g x)) (hg : IsDifferentiableAt K g x)
  : cderiv K (fun x => (f ∘ g) x) x
    =
    fun dx => 
      cderiv K f (g x) (cderiv K g x dx) := 
by 
  unfold Function.comp; ftrans

@[ftrans]
theorem Function.comp.arg_a0.cderiv_rule
  (f : Y → Z) (g : X → Y)
  (hf : IsDifferentiable K f) (hg : IsDifferentiable K g)
  : cderiv K (fun x => (f ∘ g) x)
    =
    fun x => cderiv K f (g x) ∘ (cderiv K g x) := 
by 
  unfold Function.comp; ftrans

@[ftrans]
theorem Function.comp.arg_fg_a0.cderiv_rule 
  (f : W → Y → Z) (g : W → X → Y)
  (hf : IsDifferentiable K (fun wy : W×Y => f wy.1 wy.2))
  (hg : IsDifferentiable K (fun wx : W×X => g wx.1 wx.2))
  : cderiv K (fun w x => ((f w) ∘ (g w)) x)
    =
    fun w dw x => 
      let y  := g w x
      let dydw := cderiv K g w dw x
      let dfdw := cderiv K f w dw y
      let dfdy := cderiv K (f w) y dydw
      dfdw + dfdy := 
by 
  unfold Function.comp; sorry_proof -- ftrans

-- @[ftrans]
-- theorem Function.comp.arg_fga0.cderiv_rule_at
--   (f : W → Y → Z) (g : W → X → Y) (a0 : W → X) (w : W)
--   (hf : IsDifferentiableAt K (fun wy : W×Y => f wy.1 wy.2) (w,g w (a0 w)))
--   (hg : IsDifferentiableAt K (fun wx : W×X => g wx.1 wx.2) (w,a0 w))
--   (ha0 : IsDifferentiableAt K a0 w)
--   : cderiv K (fun w => ((f w) ∘ (g w)) (a0 w))
--     =
--     fun w dw => 
--       let x  := a0 w
--       let dx := cderiv K a0 w dw
--       let y  := g w x
--       let dy := cderiv K (fun wx : W×X => g wx.1 wx.2) (w,x) (dw,dx)
--       let dz := cderiv K (fun wy : W×Y => f wy.1 wy.2) (w,y) (dw,dy)
--       dz := 
-- by 
--   unfold Function.comp; ftrans

@[ftrans]
theorem Function.comp.arg_fga0.cderiv_rule 
  (f : W → Y → Z) (g : W → X → Y) (a0 : W → X)
  (hf : IsDifferentiable K (fun wy : W×Y => f wy.1 wy.2))
  (hg : IsDifferentiable K (fun wx : W×X => g wx.1 wx.2))
  (ha0 : IsDifferentiable K a0)
  : cderiv K (fun w => ((f w) ∘ (g w)) (a0 w))
    =
    fun w dw => 
      let x  := a0 w
      let dx := cderiv K a0 w dw
      let y  := g w x
      let dy := cderiv K (fun wx : W×X => g wx.1 wx.2) (w,x) (dw,dx)
      let dz := cderiv K (fun wy : W×Y => f wy.1 wy.2) (w,y) (dw,dy)
      dz := 
by 
  unfold Function.comp; ftrans
  

-- HAdd.hAdd -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem HAdd.hAdd.arg_a0a1.cderiv_rule_at
  (x : X) (f g : X → Y) (hf : IsDifferentiableAt K f x) (hg : IsDifferentiableAt K g x)
  : (cderiv K fun x => f x + g x) x
    =
    fun dx =>
      cderiv K f x dx + cderiv K g x dx
  := by sorry_proof


@[ftrans]
theorem HAdd.hAdd.arg_a0a1.cderiv_rule
  (f g : X → Y) (hf : IsDifferentiable K f) (hg : IsDifferentiable K g)
  : (cderiv K fun x => f x + g x)
    =
    fun x => fun dx =>
      cderiv K f x dx + cderiv K g x dx
  := by sorry_proof



-- HSub.hSub -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem HSub.hSub.arg_a0a1.cderiv_rule_at
  (x : X) (f g : X → Y) (hf : IsDifferentiableAt K f x) (hg : IsDifferentiableAt K g x)
  : (cderiv K fun x => f x - g x) x
    =
    fun dx =>
      cderiv K f x dx - cderiv K g x dx
  := by sorry_proof


@[ftrans]
theorem HSub.hSub.arg_a0a1.cderiv_rule
  (f g : X → Y) (hf : IsDifferentiable K f) (hg : IsDifferentiable K g)
  : (cderiv K fun x => f x - g x)
    =
    fun x => fun dx =>
      cderiv K f x dx - cderiv K g x dx
  := by sorry_proof



-- Neg.neg ---------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem Neg.neg.arg_a0.cderiv_rule'
  (x : X) (f : X → Y)
  : (cderiv K fun x => - f x) x
    =
    fun dx =>
      - cderiv K f x dx
  := by sorry_proof


@[ftrans]
theorem Neg.neg.arg_a0.cderiv_rule
  (f : X → Y)
  : (cderiv K fun x => - f x)
    =
    fun x => fun dx =>
      - cderiv K f x dx
  := by sorry_proof


-- HMul.hmul -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem HMul.hMul.arg_a0a1.cderiv_rule_at
  (x : X) (f g : X → K)
  (hf : IsDifferentiableAt K f x) (hg : IsDifferentiableAt K g x)
  : (cderiv K fun x => f x * g x) x
    =
    let fx := f x
    let gx := g x
    fun dx =>
      (cderiv K g x dx) * fx + (cderiv K f x dx) * gx := 
by sorry_proof


@[ftrans]
theorem HMul.hMul.arg_a0a1.cderiv_rule
  (f g : X → K)
  (hf : IsDifferentiable K f) (hg : IsDifferentiable K g)
  : (cderiv K fun x => f x * g x)
    =
    fun x => 
      let fx := f x
      let gx := g x
      fun dx =>
        (cderiv K g x dx) * fx + (cderiv K f x dx) * gx := 
by sorry_proof


-- SMul.smul -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem HSMul.hSMul.arg_a0a1.cderiv_rule_at
  (x : X) (f : X → K) (g : X → Y) 
  (hf : IsDifferentiableAt K f x) (hg : IsDifferentiableAt K g x)
  : (cderiv K fun x => f x • g x) x
    =
    let k := f x
    let y := g x
    fun dx =>
      k • (cderiv K g x dx) + (cderiv K f x dx) • y  
  := by sorry_proof


@[ftrans]
theorem HSMul.hSMul.arg_a0a1.cderiv_rule
  (f : X → K) (g : X → Y) 
  (hf : IsDifferentiable K f) (hg : IsDifferentiable K g)
  : (cderiv K fun x => f x • g x)
    =
    fun x => 
      let k := f x
      let y := g x
      fun dx =>
        k • (cderiv K g x dx) + (cderiv K f x dx) • y  
  := by sorry_proof



-- HDiv.hDiv -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem HDiv.hDiv.arg_a0a1.cderiv_rule_at
  (x : X) (f : X → K) (g : X → K) 
  (hf : IsDifferentiableAt K f x) (hg : IsDifferentiableAt K g x) (hx : g x ≠ 0)
  : (cderiv K fun x => f x / g x) x
    =
    let k := f x
    let k' := g x
    fun dx =>
      ((cderiv K f x dx) * k' - k * (cderiv K g x dx)) / k'^2 := 
by sorry_proof


@[ftrans]
theorem HDiv.hDiv.arg_a0a1.cderiv_rule
  (f : X → K) (g : X → K) 
  (hf : IsDifferentiable K f) (hg : IsDifferentiable K g) (hx : ∀ x, g x ≠ 0)
  : (cderiv K fun x => f x / g x)
    =
    fun x => 
      let k := f x
      let k' := g x
      fun dx =>
        ((cderiv K f x dx) * k' - k * (cderiv K g x dx)) / k'^2 := 
by sorry_proof


-- HPow.hPow ---------------------------------------------------------------------
-------------------------------------------------------------------------------- 

@[ftrans]
def HPow.hPow.arg_a0.cderiv_rule_at
  (n : Nat) (x : X) (f : X → K) (hf : IsDifferentiableAt K f x)
  : cderiv K (fun x => f x ^ n) x
    =
    fun dx => n * cderiv K f x dx * (f x ^ (n-1)) :=
by
  induction n
  case zero =>
    simp; ftrans
  case succ n hn =>
    ext dx
    simp_rw[pow_succ]
    rw[HMul.hMul.arg_a0a1.cderiv_rule_at x f _ (by fprop) (by fprop)]
    rw[hn]
    induction n
    case zero => simp
    case succ =>
      rw[show ∀ (n : Nat), n.succ - 1 = n by simp]
      rw[pow_succ]
      simp; ring


@[ftrans]
def HPow.hPow.arg_a0.cderiv_rule
  (n : Nat) (f : X → K) (hf : IsDifferentiable K f)
  : cderiv K (fun x => f x ^ n)
    =
    fun x => fun dx => n * cderiv K f x dx * (f x ^ (n-1)) :=
by
  funext x; apply HPow.hPow.arg_a0.cderiv_rule_at n x f (hf x)


-- EnumType.sum ----------------------------------------------------------------
-------------------------------------------------------------------------------- 

@[ftrans]
theorem SciLean.EnumType.sum.arg_f.cderiv_rule_at
  (f : X → ι → Y) (x : X) (hf : ∀ i, IsDifferentiableAt K (f · i) x)
  : cderiv K (fun x => ∑ i, f x i) x
    =
    fun dx => ∑ i, cderiv K (f · i) x dx :=
by
  sorry_proof



@[ftrans]
theorem SciLean.EnumType.sum.arg_f.cderiv_rule
  (f : X → ι → Y) (hf : ∀ i, IsDifferentiable K (f · i))
  : cderiv K (fun x => ∑ i, f x i)
    =
    fun x dx => ∑ i, cderiv K (f · i) x dx :=
by
  funext x; apply SciLean.EnumType.sum.arg_f.cderiv_rule_at f x (fun i => hf i x)


--------------------------------------------------------------------------------

section InnerProductSpace

-- Inner -----------------------------------------------------------------------
-------------------------------------------------------------------------------- 

open ComplexConjugate

section OverReals

variable 
  {R : Type _} [RealScalar R]
  {X : Type _} [Vec R X]
  {Y : Type _} [SemiHilbert R Y]


@[ftrans]
theorem Inner.inner.arg_a0a1.cderiv_rule_at
  (f : X → Y) (g : X → Y) (x : X)
  (hf : IsDifferentiableAt R f x) (hg : IsDifferentiableAt R g x)
  : cderiv R (fun x => ⟪f x, g x⟫[R]) x
    =
    fun dx =>
      let y₁ := f x
      let dy₁ := cderiv R f x dx
      let y₂ := g x
      let dy₂ := cderiv R g x dx
      ⟪dy₁, y₂⟫[R] + ⟪y₁, dy₂⟫[R] := 
by 
  sorry_proof


@[ftrans]
theorem Inner.inner.arg_a0a1.cderiv_rule
  (f : X → Y) (g : X → Y)
  (hf : IsDifferentiable R f) (hg : IsDifferentiable R g)
  : cderiv R (fun x => ⟪f x, g x⟫[R])
    =
    fun x dx =>
      let y₁ := f x
      let dy₁ := cderiv R f x dx
      let y₂ := g x
      let dy₂ := cderiv R g x dx
      ⟪dy₁, y₂⟫[R] + ⟪y₁, dy₂⟫[R] := 
by 
  funext x; apply Inner.inner.arg_a0a1.cderiv_rule_at f g x (hf x) (hg x)

@[ftrans]
theorem SciLean.Norm2.norm2.arg_a0.cderiv_rule_at
  (f : X → Y) (x : X)
  (hf : IsDifferentiableAt R f x)
  : cderiv R (fun x => ‖f x‖₂²[R]) x
    =
    fun dx => 
      let y := f x
      let dy := cderiv R f x dx
      2 * ⟪dy, y⟫[R] := 
by
  simp_rw [← SemiInnerProductSpace.inner_norm2] 
  ftrans
  simp
  funext dx
  conv => 
    lhs; enter[2]
    rw [← SemiInnerProductSpace.conj_sym]
  simp
  ring

@[ftrans]
theorem SciLean.Norm2.norm2.arg_a0.cderiv_rule
  (f : X → Y) 
  (hf : IsDifferentiable R f)
  : cderiv R (fun x => ‖f x‖₂²[R])
    =
    fun x dx => 
      let y := f x
      let dy := cderiv R f x dx
      2 * ⟪dy, y⟫[R] := 
by
  funext x; apply SciLean.Norm2.norm2.arg_a0.cderiv_rule_at f x (hf x) 

open Scalar in
@[ftrans]
theorem SciLean.norm₂.arg_x.cderiv_rule
  (f : X → Y) (x : X)
  (hf : IsDifferentiableAt R f x) (hx : f x≠0)
  : cderiv R (fun x => ‖f x‖₂[R]) x
    =
    fun dx => 
      let y := f x
      let dy := cderiv R f x dx
      ‖y‖₂[R]⁻¹ * ⟪dy,y⟫[R] :=
by
  sorry_proof


end OverReals

end InnerProductSpace
