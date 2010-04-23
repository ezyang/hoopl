{-# LANGUAGE GADTs, RankNTypes, ScopedTypeVariables #-}

-- | Utilities for clients of Hoopl, not used internally.

module Compiler.Hoopl.XUtil
  ( firstXfer, distributeXfer, distributeFact
  , foldNodes
  )
where

import Data.Maybe

import Compiler.Hoopl.Label
import Compiler.Hoopl.Graph

-- | A utility function so that a transfer function for a first
-- node can be given just a fact; we handle the lookup.  This
-- function is planned to be made obsolete by changes in the dataflow
-- interface.

firstXfer :: Edges n => (n C O -> f -> f) -> (n C O -> FactBase f -> f)
firstXfer xfer n fb = xfer n $ fromJust $ lookupFact fb $ entryLabel n

-- | This utility function handles a common case in which a transfer function
-- produces a single fact out of a last node, which is then distributed
-- over the outgoing edges.
distributeXfer :: Edges n => (n O C -> f -> f) -> (n O C -> f -> FactBase f)
distributeXfer xfer n f = mkFactBase [ (l, xfer n f) | l <- successors n ]

-- | This utility function handles a common case in which a transfer function
-- for a last node takes the incoming fact unchanged and simply distributes
-- that fact over the outgoing edges.
distributeFact :: Edges n => n O C -> f -> FactBase f
distributeFact n f = mkFactBase [ (l, f) | l <- successors n ]

-- | Fold a function over every node in a graph.
-- The fold function must be polymorphic in the shape of the nodes.
foldNodes :: forall n a .
             (forall e x . n e x       -> a -> a)
          -> (forall e x . Graph n e x -> a -> a)
foldNodes f = graph
    where graph :: forall e x . Graph n e x -> a -> a
          block :: forall e x . Block n e x -> a -> a
          lift  :: forall thing ex . (thing -> a -> a) -> (MaybeO ex thing -> a -> a)

          graph GNil             = id
          graph (GUnit b)        = block b
          graph (GMany e b x)    = lift block e . body b . lift block x
          block (BUnit node)     = f node
          block (b1 `BCat` b2)   = block b1 . block b2
          body (BodyEmpty)       = id
          body (BodyUnit b)      = block b
          body (b1 `BodyCat` b2) = body b1 . body b2
          lift _ NothingO        = id
          lift f (JustO thing)   = f thing

                        
