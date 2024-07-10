import SciLean.Core.Rand.PushPullExpectation

namespace SciLean.Rand


macro "rand_AD" : conv =>
  `(conv| (simp  (disch:=sorry) only [ftrans_simp]))

macro "rand_push_E" : conv =>
  `(conv| (simp (config := {zeta:=false}) (disch:=sorry) only [rand_push_E,id,ContinuousLinearMap.coe_id']))

macro "rand_pull_E" : conv =>
  `(conv| simp (config := {zeta:=false}) (disch:=sorry) only [rand_pull_E])

macro "rand_fdE_as_E" R:term ", " x:term : conv =>
  `(conv| simp (config := {zeta:=false}) only [FDRand.fdE_as_E $R $x, FDRand.fdE'_as_E $R $x])

macro "rand_compute_mean" : conv =>
  `(conv| simp (config := {zeta:=false}) (disch:=sorry) only [Rand.mean,Rand.E,rand_simp,id,weightByDensity',ftrans_simp,weightByDensityM'])


open Lean Meta Elab.Term Parser.Tactic.Conv in
elab " derive_random_approx " e:term " by " t:convSeq : term => do
  --
  let e ← elabTerm (← `(term| $e rewrite_by $t)).raw none

  lambdaTelescope e fun xs b => do

  let args := b.getAppArgs
  unless (b.isAppOf ``Rand.mean) && args.size ≥ 4 do
    throwError "deriving probabilistic derivative should end with a term of the form `Rand.mean _`"

  if args.size = 5 then
    return ← mkLambdaFVars xs args[4]!
  else
    let X ← inferType (b.stripArgsN (args.size-5))
    let f ← withLocalDeclD `x X fun x => do
      let b ← mkAppOptM ``Pure.pure #[← mkConstWithFreshMVarLevels ``Rand, none, none, mkAppN x args[5:]]
      mkLambdaFVars #[x] b
    let b' ← mkAppM ``Bind.bind #[args[4]!, f]
    return ← mkLambdaFVars xs b'


open Lean Meta Elab.Term Parser.Tactic.Conv in
elab " derive_random_approx' " e:term " by " t:convSeq : term => do
  --
  let e ← elabTerm e none
  let (e,_prf) ← elabConvRewrite e #[] (← `(conv| ($t)))

  letTelescope e fun xs e => do

    unless e.isAppOfArity ``Rand.mean 6 do
      throwError "deriving probabilistic derivative should end with a term of the form `Rand.mean _`"

    mkLambdaFVars xs e.appArg!

def print_mean_variance {R} [RealScalar R] [ToString R] (r : Rand R) (n : ℕ) (msg : String) : IO Unit := do
  let mut xs : Array R := #[]
  for _ in [0:n] do
    xs := xs.push (← r.get)

  let mean := ((1:R)/n) • xs.foldl (init:=(0:R)) (fun s x => s + x)
  let var := Scalar.sqrt (((1:R)/(n-1)) •  xs.foldl (init:=(0:R)) (fun s x => s + (x - mean)^2))
  IO.println s!"Estimates value{msg}: {mean} ± {var}"
