import SciLean.Mathlib.Data.Enumtype

import SciLean.Algebra.VectorSpace

namespace SciLean

namespace SemiInner

  class Trait (X : Type u) where
    R : Type v
    D : Type w
    eval : R → D → ℝ

  class Trait₂ (X Y : Type u) where
    R : Type v
    D : Type w
    eval : R → D → ℝ

  attribute [reducible] Trait.R Trait.D Trait.eval
  attribute [reducible] Trait₂.R Trait₂.D Trait₂.eval

  @[reducible] instance {X Y} [Trait X] : Trait₂ X Y := ⟨Trait.R X, Trait.D X, Trait.eval⟩
  @[reducible] instance {X Y} [Trait Y] : Trait₂ X Y := ⟨Trait.R Y, Trait.D Y, Trait.eval⟩

end SemiInner

class SemiInner (X : Type u) (R : outParam $ Type v) (D : outParam $ Type w) (eval : outParam $ R → D → ℝ) where  
  semiInner : X → X → R
  testFunction : D → X → Prop

namespace SemiInner

  @[reducible] instance (X) (R : Type u) (D : Type v) (e : R → D → ℝ) [SemiInner X R D e] : Trait X := ⟨R, D, e⟩

  -- open SemiInner in
  -- abbrev semiInner' {X : Type u} [Trait X] [SemiInner X (Trait.R X) (Trait.D X) Trait.eval] : X → X → (Trait.R X)
  --   := SemiInner.semiInner Trait.eval

  -- notation "⟪" e "|" x ", " y "⟫" => SemiInner.semiInner e x y  

  -- abbrev semiInner' {X} [Trait X] [inst : SemiInner X (Trait.R X) (Trait.D X) Trait.eval] (x y : X) 
  --   := SemiInner.semiInner (self := inst) _ x y

  abbrev testFunction' {X} [Trait X] [inst : SemiInner X (Trait.R X) (Trait.D X) Trait.eval]
    := SemiInner.testFunction (self := inst)

  notation "⟪" x ", " y "⟫" => semiInner x y 

  -- @[reducible] instance : Trait ℝ := ⟨ℝ, Unit, λ r _ => r⟩

  -- Reals
  instance : SemiInner ℝ ℝ Unit (λ r _ => r):=
  {
    semiInner := λ x y => x * y
    testFunction := λ _ _ => True
  }

  -- Product type
  instance (X Y R D e) [SemiInner X R D e] [SemiInner Y R D e] [Add R] 
    : SemiInner (X × Y) R D e :=
  { 
    semiInner     := λ (x,y) (x',y') => ⟪x,x'⟫ + ⟪y,y'⟫
    testFunction  := λ d (x,y) => testFunction' d x ∧ testFunction' d y
  }
  -- Maybe use Trait₂
  @[reducible] instance (X Y) [Trait X] : Trait (X × Y) 
    := ⟨Trait.R X, Trait.D X, Trait.eval⟩
  @[reducible] instance (X Y) [Trait Y] : Trait (X × Y) 
    := ⟨Trait.R Y, Trait.D Y, Trait.eval⟩

  -- Pi type
  instance (ι X R D e) [SemiInner X R D e] [Add R] [Zero R] [Enumtype ι] : SemiInner (ι → X) R D e :=
  {
    semiInner       := λ f g => ∑ i, ⟪f i, g i⟫
    testFunction := λ d f => ∀ i, testFunction' d (f i)
  }
  @[reducible] instance {X} [Trait X] [Enumtype ι] : Trait (ι → X) 
    := ⟨Trait.R X, Trait.D X, Trait.eval⟩

  -- example (X R D e) [SemiInner X R D e] [Enumtype ι] [Add R] [Zero R] 
  --   : SemiInner (ι → X) R D e := by infer_instance

end SemiInner

--   (R : outParam (Type v)) (D : outParam (Type w)) (e : outParam (R → D → ℝ))
open SemiInner in
class SemiHilbert (X) (R : Type u) (D : Type v) (e : R → D → ℝ) [outParam $ Vec R] extends Vec X, SemiInner X R D e where
  semi_inner_add : ∀ (x y z : X),      ⟪x + y, z⟫ = ⟪x, z⟫ + ⟪y, z⟫
  semi_inner_mul : ∀ (x y : X) (r : ℝ),  ⟪r*x, y⟫ = r*⟪x, y⟫
  semi_inner_sym : ∀ (x y : X),            ⟪x, y⟫ = ⟪y, x⟫
  semi_inner_pos : ∀ (x : X) D,  (e ⟪x, x⟫ D) ≥ (0 : ℝ)
  semi_inner_ext : ∀ (x : X), 
                     ((x = 0) 
                      ↔ 
                      (∀ D (x' : X) (h : testFunction D x'), e ⟪x, x'⟫ D = 0))


abbrev Hilbert (X : Type u) := SemiHilbert X ℝ Unit (λ r _ => r)
-- @[reducible] instance {X} [Hilbert X] : SemiInner.Trait X := by infer_instance
-- @[reducible] instance {X R D e} [SemiInner X R D e] : SemiInner.Trait X := by infer_instance

namespace SemiHilbert 

  open SemiInner

  instance : Hilbert ℝ := 
  {
    semi_inner_add := sorry
    semi_inner_mul := sorry
    semi_inner_sym := sorry
    semi_inner_pos := sorry
    semi_inner_ext := sorry
  }

  -- instance (X Y) [Trait₂ X Y] [Vec (Trait₂.R X Y)] 
  --   [SemiHilbert X (Trait₂.R X Y) (Trait₂.D X Y) Trait₂.eval] 
  --   [SemiHilbert Y (Trait₂.R X Y) (Trait₂.D X Y) Trait₂.eval] 
  --   : SemiHilbert (X × Y) (Trait₂.R X Y) (Trait₂.D X Y) Trait₂.eval := 
  instance (X Y R D e) [Trait₂ X Y] [Vec R]
    [SemiHilbert X R D e] 
    [SemiHilbert Y R D e] 
    : SemiHilbert (X × Y) R D e := 
  {
    semi_inner_add := sorry
    semi_inner_mul := sorry
    semi_inner_sym := sorry
    semi_inner_pos := sorry
    semi_inner_ext := sorry
  }
  -- instance {X Y} [Trait X] [Vec (Trait.sig X).R] [SemiHilbert X] [SemiHilbert' Y (Trait.sig X)]: SemiHilbert ℝ := SemiHilbert.mk
  -- instance {X Y} [Trait Y] [Vec (Trait.sig Y).R] [SemiHilbert Y] [SemiHilbert' X (Trait.sig Y)]: SemiHilbert ℝ := SemiHilbert.mk

  -- set_option trace.Meta.synthInstance true in
  -- example {X Y} [Hilbert X] [Hilbert Y] : Hilbert (X × Y) := by infer_instance


  -- instance (X) [Trait X] [Vec (Trait.R X)] 
  --   [SemiHilbert X (Trait.R X) (Trait.D X) Trait.eval] (ι : Type v) [Enumtype ι] 
  --   : SemiHilbert (ι → X) (Trait.R X) (Trait.D X) Trait.eval := 
  instance (X R D e) [Trait X] [Vec R]
    [SemiHilbert X R D e] (ι : Type v) [Enumtype ι] 
    : SemiHilbert (ι → X) R D e := 
  {
    semi_inner_add := sorry
    semi_inner_mul := sorry
    semi_inner_sym := sorry
    semi_inner_pos := sorry
    semi_inner_ext := sorry
  }
  -- instance {ι : Type v} {X} [Trait X] [Vec (Trait.sig X).R] [SemiHilbert X] [Enumtype ι] : SemiHilbert (ι → X) := SemiHilbert.mk

end SemiHilbert

-- set_option synthInstance.maxHeartbeats 5000
-- -- set_option trace.Meta.synthInstance true in
-- example {α β : Type} : Vec (α × β) := by infer_instance

-- variable (α β : Type)
-- #check_failure (by infer_instance : Vec (α × β))


-- import SciLean.Mathlib.Data.Enumtype

-- import SciLean.Algebra.VectorSpace

-- namespace SciLean

-- --  ___            _   ___                     ___             _         _
-- -- / __| ___ _ __ (_) |_ _|_ _  _ _  ___ _ _  | _ \_ _ ___  __| |_  _ __| |_
-- -- \__ \/ -_) '  \| |  | || ' \| ' \/ -_) '_| |  _/ '_/ _ \/ _` | || / _|  _|
-- -- |___/\___|_|_|_|_| |___|_||_|_||_\___|_|   |_| |_| \___/\__,_|\_,_\__|\__|

-- namespace SemiInner

--   structure Signature where
--     R : Type u
--     D : Type v
--     eval : R → D → ℝ

--   attribute [reducible] Signature.R Signature.D

--   @[reducible]
--   def Signature.addInterval (s : Signature) : Signature :=
--     ⟨(ℝ × ℝ) → s.R,
--      (ℝ × ℝ) × s.D,
--      λ f (I, d) => s.eval (f I) d⟩
  
--   class Trait (X : Type u) where
--     sig : Signature

-- end SemiInner

-- attribute [reducible] SemiInner.Trait.sig

-- open SemiInner in
-- class SemiInner' (X : Type u) (S : Signature) where  
--   semiInner : X → X → S.R
--   testFunction : S.D → X → Prop

-- -- open SemiInner in
-- -- class SemiInner (X : Type u) [Trait X] extends SemiInner' X (Trait.sig X)

-- -- #check @SemiInner'.semiInner (self := SemiInner.toSemiInner' _ (Trait.sig _))

-- -- instance {X} [SemiInner.Trait X] [SemiInner X] : SemiInner' X (SemiInner.Trait.sig X) := SemiInner.semi_inner_inst

-- namespace SemiInner

--   -- @[reducible]
--   -- instance {X S} [Signature S] [SemiInner X S] : Trait X := ⟨S⟩

--   -- export Trait (sigOf)

--   -- @[reducible]
--   -- abbrev domOf (X) [SemiInnerTrait X] [inst : SemiInner X (sigOf X)] 
--   --   := SignatureDom.Dom (sigOf X)

--   -- def testFunction {X S} [SemiInner X S]
--   --   (D : domOf X) (x : X) : Prop 
--   --   := SemiInner.testFunctionProp D x

--   abbrev semiInner' {X : Type u} [Trait X] [Vec (Trait.sig X).R] [SemiInner' X (Trait.sig X)] : X → X → (Trait.sig X).R
--     := SemiInner'.semiInner

--   -- How to set up priorities correctly? 
--   notation "⟪" S "|" x ", " y "⟫" => SemiInner'.semiInner (S := S) x y  
--   notation "⟪" x ", " y "⟫" => semiInner' x y  

--   notation "∥" x "∥"  => Math.sqrt (⟪x,x⟫)

--   abbrev RealSig : Signature := ⟨ℝ, Unit, λ r _ => r⟩
--   -- instance : Vec RealSig.R := by simp[RealSig] infer_instance done

--   open SemiInner'

--   -- Reals
--   instance : SemiInner' ℝ RealSig :=
--   {
--     semiInner := λ x y => x * y
--     testFunction := λ _ _ => True
--   }
--   -- @[reducible] instance : Trait ℝ := ⟨RealSig⟩
--   -- instance : SemiInner ℝ := SemiInner.mk

--   -- Product
--   instance (X Y S) [Vec S.R] [SemiInner' X S] [SemiInner' Y S] 
--   : SemiInner' (X × Y) S :=
--   { 
--     semiInner     := λ (x,y) (x',y') => ⟪S| x,x'⟫ + ⟪S| y,y'⟫
--     testFunction  := λ D (x,y) => testFunction D x ∧ testFunction D y
--   }
--   -- @[reducible] instance {X Y} [Trait X] : Trait (X × Y) := ⟨Trait.sig X⟩
--   -- @[reducible] instance {X Y} [Trait Y] : Trait (X × Y) := ⟨Trait.sig Y⟩
--   -- instance (X Y) [Trait X] [SemiInner X] [SemiInner' Y (Trait.sig X)] [Vec (Trait.sig X).R] : SemiInner (X × Y) := SemiInner.mk
--   -- instance (X Y) [Trait Y] [SemiInner Y] [SemiInner' X (Trait.sig Y)] [Vec (Trait.sig Y).R] : SemiInner (X × Y) := SemiInner.mk

--   -- Function space over finite set
--   instance (ι X S) [SemiInner' X S] [Vec S.R] [Enumtype ι] : SemiInner' (ι → X) S :=
--   {
--     semiInner       := λ f g => ∑ i, ⟪S| f i, g i⟫
--     testFunction := λ D f => ∀ i, testFunction D (f i)
--   }
--   -- @[reducible] instance {ι X} [Trait X] [Enumtype ι] : Trait (ι → X) := ⟨Trait.sig X⟩
--   -- instance (ι : Type u) (X) [Trait X] [SemiInner X] [Enumtype ι] [Vec (Trait.sig X).R] : SemiInner (ι → X) := SemiInner.mk

-- end SemiInner


-- --  ___            _   _  _ _ _ _             _     ___
-- -- / __| ___ _ __ (_) | || (_) | |__  ___ _ _| |_  / __|_ __  __ _ __ ___
-- -- \__ \/ -_) '  \| | | __ | | | '_ \/ -_) '_|  _| \__ \ '_ \/ _` / _/ -_)
-- -- |___/\___|_|_|_|_| |_||_|_|_|_.__/\___|_|  \__| |___/ .__/\__,_\__\___|
-- --                                                     |_|
-- section SemiHilbert
-- open SemiInner

-- class SemiHilbert' (X : Type u) (S : Signature) [outParam $ Vec S.R] extends SemiInner' X S, Vec X where
--   semi_inner_add : ∀ (x y z : X),     ⟪S| x + y, z⟫ = ⟪S| x,z⟫ + ⟪S| y,z⟫
--   semi_inner_mul : ∀ (x y : X) (r : ℝ),  ⟪S| r*x,y⟫ = r*⟪S| x,y⟫
--   semi_inner_sym : ∀ (x y : X),            ⟪S| x,y⟫ = ⟪S| y,x⟫
--   semi_inner_pos : ∀ (x : X) D, (S.eval ⟪S| x,x⟫ D) ≥ (0 : ℝ)
--   semi_inner_ext : ∀ (x : X), 
--                      ((x = 0) 
--                       ↔ 
--                       (∀ D (x' : X) (h : testFunction D x'), S.eval ⟪S| x,x'⟫ D = 0))
--   -- Add test functions form a subspace


-- -- class SemiHilbert (X : Type u) [outParam $ Trait X] [outParam $ Vec (Trait.sig X).R] extends SemiHilbert' X (Trait.sig X)
-- -- instance {X} [Trait X] [Vec (Trait.sig X).R] [SemiHilbert X] : SemiInner X := SemiInner.mk

--  -- SemiHilbert (X : Type u) [SemiInner X] [Vec (SemiInner.sig X).R] := SemiHilbert' X (SemiInner.sig X)

-- abbrev Hilbert (X : Type u) := SemiHilbert' X SemiInner.RealSig
-- @[reducible] instance {X} [Hilbert X] : Trait X := ⟨SemiInner.RealSig⟩
-- -- instance {X} [Hilbert X] : SemiInner X := SemiInner.mk

-- -- I really do not understand why is this necessary ... I think it is a bug
-- -- reported here: https://leanprover.zulipchat.com/#narrow/stream/270676-lean4/topic/Odd.20type.20class.20failure
-- -- instance {X} [SemiHilbert' X SemiInner.RealSig] : Vec X := SemiHilbert'.toVec SemiInner.RealSig
-- -- Alternatively we can change [Vec S.R] to [outParam $ Vec S.R] 
-- -- but this causes some timeouts somewhere else ...

-- namespace SemiHilbert 

--   open SemiInner

--   instance : SemiHilbert' ℝ RealSig := 
--   {
--     semi_inner_add := sorry
--     semi_inner_mul := sorry
--     semi_inner_sym := sorry
--     semi_inner_pos := sorry
--     semi_inner_ext := sorry
--   }
--   -- instance : SemiHilbert ℝ := SemiHilbert.mk

--   instance (X Y S) [Vec S.R] [SemiHilbert' X S] [SemiHilbert' Y S] 
--     : SemiHilbert' (X × Y) S := 
--   {
--     semi_inner_add := sorry
--     semi_inner_mul := sorry
--     semi_inner_sym := sorry
--     semi_inner_pos := sorry
--     semi_inner_ext := sorry
--   }
--   -- instance {X Y} [Trait X] [Vec (Trait.sig X).R] [SemiHilbert X] [SemiHilbert' Y (Trait.sig X)]: SemiHilbert ℝ := SemiHilbert.mk
--   -- instance {X Y} [Trait Y] [Vec (Trait.sig Y).R] [SemiHilbert Y] [SemiHilbert' X (Trait.sig Y)]: SemiHilbert ℝ := SemiHilbert.mk


--   instance (ι : Type v) (X S) [Vec S.R] [SemiHilbert' X S] [Enumtype ι] 
--     : SemiHilbert' (ι → X) S := 
--   {
--     semi_inner_add := sorry
--     semi_inner_mul := sorry
--     semi_inner_sym := sorry
--     semi_inner_pos := sorry
--     semi_inner_ext := sorry
--   }
--   -- instance {ι : Type v} {X} [Trait X] [Vec (Trait.sig X).R] [SemiHilbert X] [Enumtype ι] : SemiHilbert (ι → X) := SemiHilbert.mk

-- end SemiHilbert
