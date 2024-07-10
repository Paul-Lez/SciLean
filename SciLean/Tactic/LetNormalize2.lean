/-
Copyright (c) 2023 Kyle Miller. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kyle Miller, Tomáš Skřivan
-/
import Mathlib.Tactic.Basic
import SciLean.Lean.Meta.Structure

/-!
# The `lift_lets` tactic

This module defines a tactic `lift_lets` that can be used to pull `let` bindings as far out
of an expression as possible.
-/

open Lean Elab Parser Meta Tactic

/-- Configuration for `Lean.Expr.liftLets` and the `lift_lets` tactic. -/
structure Lean.Expr.LiftLets2Config where
  /-- Whether to lift lets out of proofs. The default is not to. -/
  proofs : Bool := false
  /-- Whether to merge let bindings if they have the same type and value.
  This test is by syntactic equality, not definitional equality.
  The default is to merge. -/
  merge : Bool := true
  /-- Remove fvar binding. Remove let binding  -/
  removeSingleFVar : Bool := true
  /-- Remove binding with no free variables.  -/
  removeNoFVar : Bool := true
  /-- Split bindings of constructors into multiple let bindings.
  For example `let y := (a,b); ...` will be transformed into `let y₁ := a; let y₂ := b; ...`  -/
  splitCtors : Bool := true
  /-- Remove binding of lambda functions.  -/
  removeLambda : Bool := true
  /-- Remove binding of lambda functions.  -/
  removeOfNat : Bool := true
  /-- Pull let bindings out of lambda functions. -/
  pullLetOutOfLambda : Bool := true


/--
Auxiliary definition for `Lean.Expr.liftLets`. Takes a list of the accumulated fvars.
This list is used during the computation to merge let bindings.
-/
private partial def Lean.Expr.liftLets2Aux {α} (config : LiftLets2Config) (e : Expr) (fvars : Array Expr)
    (f : Array Expr → Expr → MetaM α) : MetaM α := do
  if (e.find? Expr.isLet).isNone then
    -- If `e` contains no `let` expressions, then we can avoid recursing into it.
    return ← f fvars e
  if !config.proofs then
    if ← Meta.isProof e then
      return ← f fvars e
  match e with
  | .letE n t v b _ =>
    t.liftLets2Aux config fvars fun fvars t' =>
      v.liftLets2Aux config fvars fun fvars v' => do
        if config.removeSingleFVar && v'.isFVar then
          return ← (b.instantiate1 v').liftLets2Aux config fvars f
        if config.removeNoFVar && ¬v'.hasFVar then
          return ← (b.instantiate1 v').liftLets2Aux config fvars f
        if config.removeLambda && v'.isLambda then
          return ← (b.instantiate1 v').liftLets2Aux config fvars f
        if config.removeOfNat && v'.isAppOfArity ``OfNat.ofNat 3 then
          return ← (b.instantiate1 v').liftLets2Aux config fvars f

        if config.splitCtors then
          if let .some (vs, _, mk) ← SciLean.splitByCtors? v' then
            let names := (Array.range vs.size).map fun i => n.appendAfter (toString i)
            return ← withLetDecls names vs fun fvars' =>
              (b.instantiate1 (mk.beta fvars')).liftLets2Aux config (fvars++fvars') f

        if config.merge then
          -- Eliminate the let binding if there is already one of the same type and value.
          let fvar? ← fvars.findM? (fun fvar => do
            let decl ← fvar.fvarId!.getDecl
            return decl.type == t' && decl.value? == some v')
          if let some fvar' := fvar? then
            return ← (b.instantiate1 fvar').liftLets2Aux config fvars f
        withLetDecl n t' v' fun fvar =>
          (b.instantiate1 fvar).liftLets2Aux config (fvars.push fvar) f
  | .app x y =>
    x.liftLets2Aux config fvars fun fvars x' => y.liftLets2Aux config fvars fun fvars y' =>
      f fvars (.app x' y')
  | .proj n idx s =>
    s.liftLets2Aux config fvars fun fvars s' => f fvars (.proj n idx s')
  | .lam n t b i =>
    t.liftLets2Aux config fvars fun fvars t => do
      -- Enter the binding, do liftLets, and lift out liftable lets
      let e' ← withLocalDecl n i t fun fvar => do
        (b.instantiate1 fvar).liftLets2Aux config fvars fun fvars2 b => do
          -- See which bindings can't be migrated out
          if config.pullLetOutOfLambda then
            let deps ← collectForwardDeps #[fvar] false
            let fvars2 := fvars2[fvars.size:].toArray
            let (fvars2, fvars2') := fvars2.partition deps.contains
            mkLetFVars fvars2' (← mkLambdaFVars #[fvar] (← mkLetFVars fvars2 b))
          else
            mkLambdaFVars #[fvar] (← mkLetFVars fvars2 b)
      -- Re-enter the new lets; we do it this way to keep the local context clean
      insideLets e' fvars fun fvars e'' => f fvars e''
  | .forallE n t b i =>
    t.liftLets2Aux config fvars fun fvars t => do
      -- Enter the binding, do liftLets, and lift out liftable lets
      let e' ← withLocalDecl n i t fun fvar => do
        (b.instantiate1 fvar).liftLets2Aux config fvars fun fvars2 b => do
          -- See which bindings can't be migrated out
          let deps ← collectForwardDeps #[fvar] false
          let fvars2 := fvars2[fvars.size:].toArray
          let (fvars2, fvars2') := fvars2.partition deps.contains
          mkLetFVars fvars2' (← mkForallFVars #[fvar] (← mkLetFVars fvars2[fvars.size:] b))
      -- Re-enter the new lets; we do it this way to keep the local context clean
      insideLets e' fvars fun fvars e'' => f fvars e''
  | .mdata _ e => e.liftLets2Aux config fvars f
  | _ => f fvars e
where
  -- Like the whole `Lean.Expr.liftLets`, but only handles lets
  insideLets {α} (e : Expr) (fvars : Array Expr) (f : Array Expr → Expr → MetaM α) : MetaM α := do
    match e with
    | .letE n t v b _ =>
      withLetDecl n t v fun fvar => insideLets (b.instantiate1 fvar) (fvars.push fvar) f
    | _ => f fvars e


variable [MonadControlT MetaM n] [Monad n]

/-- Take all the `let`s in an expression and move them outwards as far as possible.
All top-level `let`s are added to the local context, and then `f` is called with the list
of local bindings (each an fvar) and the new expression.

Let bindings are merged if they have the same type and value.

Use `e.liftLets mkLetFVars` to get a defeq expression with all `let`s lifted as far as possible. -/
def Lean.Expr.liftLets2 {α} (e : Expr) (f : Array Expr → Expr → n α)
    (config : LiftLets2Config := {}) : n α :=
  map2MetaM (fun k => e.liftLets2Aux config #[] k) f
